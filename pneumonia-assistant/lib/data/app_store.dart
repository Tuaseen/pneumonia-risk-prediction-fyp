import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models.dart';

/// Thrown when no risk score can be calculated because the API cannot be reached.
/// The app never substitutes a score of its own.
class BackendUnavailableException implements Exception {
  const BackendUnavailableException([
    this.message = 'The risk assessment service is offline, so no risk score was calculated. '
        'Your readings have been saved. Please try again when the connection is restored.',
  ]);
  final String message;

  @override
  String toString() => message;
}

class AppStore extends ChangeNotifier {
  final bool firebaseEnabled;
  final SharedPreferences preferences;

  AppStore({
    required this.preferences,
    this.firebaseEnabled = false,
  });

  bool signedIn = false;
  bool demo = false;
  bool doctor = false;
  String role = 'patient'; // 'patient' or 'doctor'
  String doctorName = 'Doctor';
  String doctorSpecialty = 'Pulmonology';
  String doctorEmail = '';
  bool busy = false;
  String uid = '';

  bool get isDoctor => role == 'doctor' || doctor;
  bool get isPatient => !isDoctor;

  // Server API configuration
  String apiUrl = 'http://127.0.0.1:8000';
  bool apiOnline = false;

  Profile profile = const Profile();
  List<Reading> readings = [];
  LabResults? labs;
  List<Assessment> assessments = [];
  List<ChatMessage> chatMessages = [];

  // Doctor care workspace state
  List<Map<String, dynamic>> patients = [];
  String? selectedPatient;
  Profile? patientProfile;
  List<Reading> patientReadings = [];
  LabResults? patientLabs;
  List<Assessment> patientAssessments = [];

  StreamSubscription? _authSubscription;
  StreamSubscription? _readingSubscription;
  String? syncError;

  // Active critical alerts from latest readings
  List<Alert> get criticalAlerts => computeAlerts(latestReading);

  bool get isCloudConnected => signedIn && !demo && firebaseEnabled;

  Reading? get latestReading => readings.isNotEmpty ? readings.first : null;
  Assessment? get latestAssessment =>
      assessments.isNotEmpty ? assessments.first : null;

  // Initialize demo or saved state (supporting both patient and doctor roles)
  Future<void> startDemo({String role = 'patient'}) async {
    demo = true;
    this.role = role;
    doctor = (role == 'doctor');
    uid = role == 'doctor' ? 'doctor_demo_01' : 'patient_demo_01';
    syncError = null;
    selectedPatient = null;

    if (role == 'doctor') {
      doctorName = 'Dr. Sarah Chen';
      doctorSpecialty = 'Pulmonology';
      await loadDoctorPatients();
    } else {
      profile = Profile.alexMorgan();

      final saved = preferences.getString('pneumonia.demo.v2');
      if (saved != null) {
        try {
          final data = jsonDecode(saved) as Map<String, dynamic>;
          profile = Profile.fromJson(data['profile'] ?? {});
          readings = (data['readings'] as List? ?? [])
              .map((r) => Reading.fromJson(Map<String, dynamic>.from(r)))
              .toList();
          labs = data['labs'] != null ? LabResults.fromJson(data['labs']) : null;
          assessments = (data['assessments'] as List? ?? [])
              .map((a) => Assessment.fromJson(Map<String, dynamic>.from(a)))
              .toList();
          chatMessages = (data['chat'] as List? ?? [])
              .map((c) => ChatMessage.fromJson(Map<String, dynamic>.from(c)))
              .toList();
        } catch (_) {
          _seedDemoData();
        }
      } else {
        _seedDemoData();
      }

      if (chatMessages.isEmpty) {
        chatMessages = [
          ChatMessage(
            id: 'welcome-1',
            role: 'assistant',
            text:
                'Hello! I am your Pneumonia Risk Assistant. I evaluate your daily symptoms and help detect early warning signs. How are you feeling today?',
            timestamp: DateTime.now(),
          ),
        ];
      }

      _sortData();
    }

    signedIn = true;
    notifyListeners();
    checkApiConnection();
  }

  void _seedDemoData() {
    profile = const Profile(
      patientId: 'patient_demo_01',
      name: 'Alex Morgan',
      age: 58,
      sex: 'female',
      doctorIds: ['dr_sarah_chen'],
      conditions: {
        'copd': 0,
        'asthma': 1,
        'heart_failure': 0,
        'renal': 0,
        'diabetes': 0,
        'hypertension': 1,
      },
    );
    readings = generateDemoReadings();
    labs = generateDemoLabs();
    assessments = [
      Assessment(
        id: 'initial-assessment-1',
        at: DateTime.now().subtract(const Duration(hours: 4)),
        band: RiskBand.low,
        stage: 2,
        riskScoreStage1: 0.18,
        riskScoreStage2: 0.15,
        alerts: const [],
        recommendation:
            'All vital signs and symptoms remain within standard target limits. Continue usual monitoring.',
        symptoms: const {
          'respiratory_distress': 0,
          'cough': 0,
          'fever': 0,
          'weakness': 0,
        },
        labs: labs,
      ),
    ];
  }

  Future<void> loadDoctorPatients() async {
    patients = [];
    if (!firebaseEnabled) {
      notifyListeners();
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final currentDoctor = FirebaseAuth.instance.currentUser;
      final currentEmail = (currentDoctor?.email ?? doctorEmail).trim().toLowerCase();
      final currentUid = (currentDoctor?.uid ?? uid).trim().toLowerCase();

      // 1. Fetch real patients from patients collection in Firestore
      final querySnapshot = await firestore.collection('patients').get();

      final List<Map<String, dynamic>> loaded = [];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final profileData = (data['profile'] as Map<String, dynamic>?) ?? {};

        // 2. PRIVACY FILTER: Doctor only sees patients who linked this doctor
        final List<dynamic> rawDoctorIds = [
          ...(profileData['doctorIds'] as List? ?? []),
          ...(data['doctorIds'] as List? ?? []),
        ];
        final linkedDoctorIds = rawDoctorIds
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();

        final bool isLinked = (currentEmail.isNotEmpty && linkedDoctorIds.contains(currentEmail)) ||
            (currentUid.isNotEmpty && linkedDoctorIds.contains(currentUid));

        if (!isLinked) {
          continue; // Patient did not link this doctor - strictly protect patient privacy
        }

        final latestAss = (data['latestAssessment'] as Map<String, dynamic>?) ?? {};
        final name = (profileData['name'] as String?)?.trim();
        final email = (data['email'] as String?) ?? '';
        final displayName = (name != null && name.isNotEmpty)
            ? name
            : (email.isNotEmpty ? email : 'Patient #${doc.id.substring(0, 6)}');

        final age = (profileData['age'] as num?)?.toInt() ?? 25;
        final sex = (profileData['sex'] as String?) ?? 'male';

        final bandStr = (latestAss['band'] as String?) ?? 'low';
        final band = parseRiskBand(bandStr);
        final hasAlert = (latestAss['alerts'] as List? ?? []).isNotEmpty;
        final vitals = (latestAss['vitals'] as Map<String, dynamic>?) ?? {};

        DateTime lastChecked = DateTime.now();
        if (latestAss['at'] != null) {
          try {
            lastChecked = DateTime.parse(latestAss['at']).toLocal();
          } catch (_) {}
        }

        loaded.add({
          'id': doc.id,
          'name': displayName,
          'age': age,
          'sex': sex,
          'band': band,
          'hasAlert': hasAlert,
          'lastChecked': lastChecked,
          'spo2': (vitals['spo2'] as num?)?.toDouble() ?? 98.0,
          'hr': (vitals['heart_rate'] as num?)?.toDouble() ?? 72.0,
          'rr': (vitals['respiratory_rate'] as num?)?.toDouble() ?? 16.0,
          'temp': (vitals['temperature'] as num?)?.toDouble() ?? 98.6,
        });
      }

      patients = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading doctor patients from Firestore: $e');
    }
  }

  Future<bool> checkApiConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$apiUrl/docs'))
          .timeout(const Duration(seconds: 2));
      apiOnline = (res.statusCode == 200 || res.statusCode == 307);
    } catch (_) {
      apiOnline = false;
    }
    notifyListeners();
    return apiOnline;
  }

  void setApiUrl(String url) {
    apiUrl = url.trim();
    checkApiConnection();
  }

  // --- Compute Alerts from Vitals ---
  List<Alert> computeAlerts(Reading? r) {
    if (r == null) return [];
    final alerts = <Alert>[];

    final spo2 = r.spo2;
    if (spo2 != null && spo2 < 90.0) {
      alerts.add(Alert(
        code: 'CRITICAL_SPO2_LOW',
        message: 'Blood oxygen is low (${spo2.toInt()}%)',
        value: spo2,
      ));
    }

    final rr = r.respiratoryRate;
    if (rr != null && rr >= 24.0) {
      alerts.add(Alert(
        code: 'TACHYPNEA',
        message: 'Breathing rate is elevated (${rr.toInt()}/min)',
        value: rr,
      ));
    }

    final temp = r.temperature;
    if (temp != null && temp >= 100.4) {
      alerts.add(Alert(
        code: 'FEVER',
        message: 'Elevated body temperature (${temp.toStringAsFixed(1)}°F)',
        value: temp,
      ));
    }

    final sbp = r.sbp;
    if (sbp != null && sbp < 90.0) {
      alerts.add(Alert(
        code: 'HYPOTENSION',
        message: 'Systolic blood pressure is low (${sbp.toInt()} mmHg)',
        value: sbp,
      ));
    }

    final hr = r.heartRate;
    if (hr != null && hr > 115.0) {
      alerts.add(Alert(
        code: 'TACHYCARDIA',
        message: 'Heart rate is elevated (${hr.toInt()} bpm)',
        value: hr,
      ));
    }

    return alerts;
  }

  // Signed-in users send their Firebase ID token; the offline demo build can be given
  // the backend's key with --dart-define=API_KEY=... (see run_app.sh).
  static const _demoApiKey = String.fromEnvironment('API_KEY');

  Future<Map<String, String>> _apiHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    String? token;
    if (firebaseEnabled && !demo) {
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {}
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (_demoApiKey.isNotEmpty) {
      headers['X-API-Key'] = _demoApiKey;
    }
    return headers;
  }

  /// Body for POST /demo/run: up to the last 7 days of readings with the time each was
  /// taken (oldest first, at most 200 per vital), the profile, today's answers and labs.
  /// The server uses the last 24 h for Stage 1 and everything for Stage 2, so a result
  /// comes back whether the patient has one day of readings or a full week. The server
  /// builds every model feature itself, so the app never computes a score.
  Map<String, dynamic> _demoRunBody(SymptomCheck symptoms, LabResults? labs, DateTime now) {
    final since = now.subtract(const Duration(days: 7));
    final recent = readings.where((r) => r.at.isAfter(since) && !r.at.isAfter(now)).toList()
      ..sort((x, y) => x.at.compareTo(y.at));
    final values = <String, List<double>>{};
    final times = <String, List<String>>{};
    for (final r in recent) {
      r.values.forEach((vital, value) {
        values.putIfAbsent(vital, () => []).add(value);
        times.putIfAbsent(vital, () => []).add(r.at.toUtc().toIso8601String());
      });
    }
    for (final vital in values.keys) {
      final n = values[vital]!.length;
      if (n > 200) {
        values[vital] = values[vital]!.sublist(n - 200);
        times[vital] = times[vital]!.sublist(n - 200);
      }
    }
    // Unanswered questions are sent as null so the server reports them as missing.
    return {
      'readings': values,
      'taken_at': times,
      'age': profile.age ?? 0,
      'sex': profile.sex,
      for (final c in ['copd', 'heart_failure', 'renal', 'asthma', 'diabetes', 'hypertension'])
        c: profile.conditions[c] ?? 0,
      'respiratory_distress': symptoms.respiratoryDistress,
      'cough': symptoms.cough,
      'fever': symptoms.fever,
      'weakness': symptoms.weakness,
      // Labs are optional; only the values actually entered are sent.
      if (labs != null && now.difference(labs.takenAt).inDays < 7)
        'labs': {
          if (labs.wbc != null) 'wbc': labs.wbc,
          if (labs.neutrophils != null) 'neutrophils': labs.neutrophils,
          if (labs.lymphocytes != null) 'lymphocytes': labs.lymphocytes,
          if (labs.crp != null) 'crp': labs.crp,
        },
    };
  }

  // --- Run Daily Pneumonia Risk Assessment ---
  Future<Assessment> assessDailyCheck(
    SymptomCheck symptoms, {
    Map<String, double>? selfVitals,
    LabResults? selfLabs,
  }) async {
    busy = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final effectiveVitals = selfVitals ?? (latestReading?.values ?? {});
      final effectiveLabs = selfLabs ?? labs;

      // Always save newly submitted vitals into the 7-day readings timeline
      if (selfVitals != null && selfVitals.isNotEmpty) {
        final newReading = Reading(
          id: now.millisecondsSinceEpoch.toString(),
          at: now,
          values: selfVitals,
          source: 'daily_check',
        );
        readings.insert(0, newReading);
        if (!demo && firebaseEnabled && uid.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(uid)
                .collection('readings')
                .doc(newReading.id)
                .set(newReading.toJson());
          } catch (_) {}
        }
      }

      // Check if remote backend is accessible (retry once in case it came up after start-up)
      if (apiOnline || await checkApiConnection()) {
        try {
          final response = await http
              .post(
                Uri.parse('$apiUrl/demo/run'),
                headers: await _apiHeaders(),
                body: jsonEncode(_demoRunBody(symptoms, effectiveLabs, now)),
              )
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 422) {
            final errs = (jsonDecode(response.body)['errors'] as List? ?? [])
                .map((e) => e['message'])
                .join(' ');
            throw Exception('The server rejected these inputs: $errs');
          }
          if (response.statusCode == 200 && jsonDecode(response.body)['band'] == null) {
            final missing = (jsonDecode(response.body)['missing'] as List? ?? [])
                .map((m) => m['message'] ?? m['item'])
                .join(' ');
            throw Exception('No score yet. $missing');
          }
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final assessed = Assessment(
              id: now.millisecondsSinceEpoch.toString(),
              at: now,
              band: parseRiskBand(data['band']),
              stage: (data['stage'] as num?)?.toInt() ?? 1,
              riskScoreStage1: (data['risk_score_stage1'] as num?)?.toDouble(),
              riskScoreStage2: (data['risk_score_stage2'] as num?)?.toDouble(),
              alerts: (data['alerts'] as List? ?? [])
                  .map((a) => Alert.fromJson(Map<String, dynamic>.from(a)))
                  .toList(),
              criticalNotice: data['critical_notice'],
              recommendation: data['recommendation'],
              symptoms: symptoms.toMap(),
              vitals: effectiveVitals,
              labs: effectiveLabs,
              profileSnapshot: profile.toJson(),
            );
            assessments.insert(0, assessed);
            await _persist();
            if (!demo && firebaseEnabled && uid.isNotEmpty) {
              try {
                await FirebaseFirestore.instance
                    .collection('patients')
                    .doc(uid)
                    .collection('assessments')
                    .doc(assessed.id)
                    .set(assessed.toJson());
              } catch (_) {}
            }
            return assessed;
          }
          throw BackendUnavailableException(
              'The risk service returned an error (HTTP ${response.statusCode}). No score was calculated.');
        } on TimeoutException {
          throw const BackendUnavailableException();
        } on http.ClientException {
          throw const BackendUnavailableException();
        }
      }

      // Risk scores only ever come from the server's models (Stage 1 + Stage 2 v2).
      // Without the server there is no score: the readings above are still saved.
      throw const BackendUnavailableException();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // --- Add Reading ---
  Future<void> addReading(Reading reading) async {
    readings = [reading, ...readings.where((r) => r.id != reading.id)];
    _sortData();
    await _persist();
    notifyListeners();
  }

  // --- Save Labs ---
  Future<void> saveLabs(LabResults newLabs) async {
    labs = newLabs;
    await _persist();
    notifyListeners();
  }

  // --- Parse CSV Labs ---
  Future<void> parseAndSaveCsvLabs(String csvText) async {
    final lines = csvText.trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) {
      throw StateError('CSV file must have a header row and at least one data row.');
    }

    final headers = lines[0].toLowerCase().split(',').map((h) => h.trim()).toList();
    final values = lines.last.split(',').map((v) => v.trim()).toList();

    double findValue(String key) {
      final idx = headers.indexOf(key);
      if (idx == -1 || idx >= values.length) {
        throw StateError('Missing required column "$key" in CSV.');
      }
      final parsed = double.tryParse(values[idx]);
      if (parsed == null) throw StateError('Invalid numeric value for "$key".');
      return parsed;
    }

    final parsedLabs = LabResults(
      wbc: findValue('wbc'),
      neutrophils: findValue('neutrophils'),
      lymphocytes: findValue('lymphocytes'),
      crp: findValue('crp'),
      takenAt: DateTime.now(),
    );

    await saveLabs(parsedLabs);
  }

  // --- Send Chat Message ---
  Future<void> sendChatMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      text: query,
      timestamp: DateTime.now(),
    );
    chatMessages.add(userMsg);
    busy = true;
    notifyListeners();

    try {
      // 1. Check if the message contains vitals, symptoms, or day check data to evaluate
      final parsed = _extractHealthDataFromText(query);
      if (parsed != null) {
        // Run Stage 1 & Stage 2 clinical assessment (this already logs vitals to readings and Firestore)
        final Assessment assessment;
        try {
          assessment = await assessDailyCheck(
            parsed.symptoms,
            selfVitals: parsed.vitals.isNotEmpty ? parsed.vitals : null,
            selfLabs: parsed.labs,
          );
        } on BackendUnavailableException catch (e) {
          chatMessages.add(ChatMessage(
            id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
            role: 'assistant',
            text: '${e.message}\n\n• **Logged Vitals**: ${parsed.summary}',
            timestamp: DateTime.now(),
          ));
          await _persist();
          return;
        }

        final scorePct = ((assessment.displayScore ?? 0) * 100).toStringAsFixed(1);
        final p1Pct = ((assessment.riskScoreStage1 ?? 0) * 100).toStringAsFixed(1);
        final p2Pct = ((assessment.riskScoreStage2 ?? 0) * 100).toStringAsFixed(1);

        final reply = '✅ **Health Check Successfully Calculated & Saved!**\n\n'
            '• **Pneumonia Risk**: ${assessment.riskTierTitle} ($scorePct%)\n'
            '• **Stage 1 (Rapid Screening)**: $p1Pct%\n'
            '• **Stage 2 (Clinical Model)**: $p2Pct%\n'
            '• **Logged Vitals**: ${parsed.summary}\n'
            '• **Clinical Recommendation**: ${assessment.recommendation ?? "Vitals are stable."}\n\n'
            '*(Saved to Cloud Firestore and visible on your Dashboard & History tab)*';

        chatMessages.add(ChatMessage(
          id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
          role: 'assistant',
          text: reply,
          timestamp: DateTime.now(),
        ));
        await _persist();
        notifyListeners();
        return;
      }

      // 2. Check if remote API is available for natural conversation
      if (apiOnline) {
        try {
          final res = await http.post(
            Uri.parse('$apiUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': query, 'patient_id': uid}),
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            chatMessages.add(ChatMessage(
              id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
              role: 'assistant',
              text: data['reply'] ?? '',
              timestamp: DateTime.now(),
            ));
            await _persist();
            return;
          }
        } catch (_) {
          // Fall back to local assistant response
        }
      }

      // 3. Local conversational logic
      await Future.delayed(const Duration(milliseconds: 300));
      final reply = await _generateLocalAssistantReply(query);
      chatMessages.add(ChatMessage(
        id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        text: reply,
        timestamp: DateTime.now(),
      ));
      await _persist();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // --- Health Data Extractor for Chat Messages ---
  _ParsedHealthQuery? _extractHealthDataFromText(String text) {
    final lower = text.toLowerCase();

    // Regex extractors for vitals
    final spo2Match = RegExp(r'(?:spo2|oxygen|o2)[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final tempMatch = RegExp(r'(?:temp|temperature)[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final hrMatch = RegExp(r'(?:heart\s*rate|hr|pulse)[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final rrMatch = RegExp(r'(?:breathing(?:\s*rate)?|respiratory(?:\s*rate)?|rr)[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final bpMatch = RegExp(r'(?:blood\s*pressure|sbp|bp)[\s:=]+(\d+(?:\.\d+)?)(?:[\s/]+(\d+(?:\.\d+)?))?', caseSensitive: false).firstMatch(text);

    // Regex extractors for labs
    final wbcMatch = RegExp(r'wbc[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final crpMatch = RegExp(r'crp[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final neutMatch = RegExp(r'neutrophils?[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);
    final lymphMatch = RegExp(r'lymphocytes?[\s:=]+(\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(text);

    final Map<String, double> detectedVitals = {};
    if (spo2Match != null) detectedVitals['spo2'] = double.tryParse(spo2Match.group(1)!) ?? 98.0;
    if (tempMatch != null) detectedVitals['temperature'] = double.tryParse(tempMatch.group(1)!) ?? 98.6;
    if (hrMatch != null) detectedVitals['heart_rate'] = double.tryParse(hrMatch.group(1)!) ?? 72.0;
    if (rrMatch != null) detectedVitals['respiratory_rate'] = double.tryParse(rrMatch.group(1)!) ?? 16.0;
    if (bpMatch != null) {
      detectedVitals['sbp'] = double.tryParse(bpMatch.group(1)!) ?? 120.0;
    }

    LabResults? detectedLabs;
    if (wbcMatch != null || crpMatch != null || neutMatch != null || lymphMatch != null) {
      detectedLabs = LabResults(
        wbc: wbcMatch != null ? double.tryParse(wbcMatch.group(1)!) : null,
        crp: crpMatch != null ? double.tryParse(crpMatch.group(1)!) : null,
        neutrophils: neutMatch != null ? double.tryParse(neutMatch.group(1)!) : null,
        lymphocytes: lymphMatch != null ? double.tryParse(lymphMatch.group(1)!) : null,
        takenAt: DateTime.now(),
      );
    }

    // Symptom extraction
    int resp = 0;
    int cough = 0;
    int fever = 0;
    int weak = 0;

    if (lower.contains('short of breath: yes') || (lower.contains('short of breath') && !lower.contains('short of breath: no') && !lower.contains('no short of breath'))) {
      resp = 1;
    }
    if (lower.contains('coughing: yes') || lower.contains('cough: yes') || (lower.contains('cough') && !lower.contains('no cough') && !lower.contains('cough: no') && !lower.contains('coughing: no'))) {
      cough = 1;
    }
    if (lower.contains('feverish: yes') || lower.contains('fever: yes') || (lower.contains('fever') && !lower.contains('no fever') && !lower.contains('fever: no') && !lower.contains('feverish: no'))) {
      fever = 1;
    }
    if (lower.contains('tired: yes') || lower.contains('weak: yes') || (lower.contains('tired') && !lower.contains('no tired') && !lower.contains('tired: no')) || (lower.contains('weak') && !lower.contains('no weak') && !lower.contains('weak: no'))) {
      weak = 1;
    }

    if (detectedVitals.isNotEmpty || detectedLabs != null || (resp + cough + fever + weak > 0)) {
      final List<String> summaryParts = [];
      if (detectedVitals.containsKey('spo2')) summaryParts.add('SpO₂: ${detectedVitals['spo2']!.toInt()}%');
      if (detectedVitals.containsKey('temperature')) summaryParts.add('Temp: ${detectedVitals['temperature']}°F');
      if (detectedVitals.containsKey('heart_rate')) summaryParts.add('HR: ${detectedVitals['heart_rate']!.toInt()} bpm');
      if (detectedVitals.containsKey('respiratory_rate')) summaryParts.add('RR: ${detectedVitals['respiratory_rate']!.toInt()}/min');
      if (detectedVitals.containsKey('sbp')) summaryParts.add('SBP: ${detectedVitals['sbp']!.toInt()} mmHg');
      if (detectedLabs != null) {
        summaryParts.addAll([
          if (detectedLabs.wbc != null) 'WBC: ${detectedLabs.wbc}',
          if (detectedLabs.neutrophils != null) 'Neutrophils: ${detectedLabs.neutrophils}%',
          if (detectedLabs.lymphocytes != null) 'Lymphocytes: ${detectedLabs.lymphocytes}%',
          if (detectedLabs.crp != null) 'CRP: ${detectedLabs.crp}',
        ]);
      }

      return _ParsedHealthQuery(
        vitals: detectedVitals,
        labs: detectedLabs,
        symptoms: SymptomCheck(
          respiratoryDistress: resp,
          cough: cough,
          fever: fever,
          weakness: weak,
        ),
        summary: summaryParts.isNotEmpty ? summaryParts.join(', ') : 'Symptoms evaluated',
      );
    }

    return null;
  }

  Future<String> _generateLocalAssistantReply(String query) async {
    final q = query.toLowerCase();
    final r = latestReading;
    final a = latestAssessment;

    if (q.contains('how am i') || q.contains('feeling') || q.contains('status')) {
      if (a != null) {
        return 'Your current pneumonia risk band is "${a.band.label}". '
            'Your last recorded SpO2 was ${r?.spo2?.toInt() ?? 97}% and heart rate was ${r?.heartRate?.toInt() ?? 74} bpm. '
            '${a.recommendation ?? "Everything is being tracked steadily."}';
      }
      return 'Your vitals are steady. Would you like to run a daily check on the Dashboard?';
    }

    if (q.contains('check') || q.contains('run a check') || q.contains('assess') || q.contains('calculate')) {
      final Assessment assessed;
      try {
        assessed = await assessDailyCheck(
          const SymptomCheck(respiratoryDistress: 0, cough: 0, fever: 0, weakness: 0),
        );
      } on BackendUnavailableException catch (e) {
        return e.message;
      }
      return 'I have run a health evaluation on your current record:\n\n'
          '• **Pneumonia Risk**: ${assessed.riskTierTitle} (${((assessed.displayScore ?? 0) * 100).toStringAsFixed(1)}%)\n'
          '• **Stage 1 (Screening)**: ${((assessed.riskScoreStage1 ?? 0) * 100).toStringAsFixed(1)}%\n'
          '• **Stage 2 (Clinical)**: ${((assessed.riskScoreStage2 ?? 0) * 100).toStringAsFixed(1)}%\n'
          '• **Recommendation**: ${assessed.recommendation ?? "Everything is within stable limits."}\n\n'
          'You can also use the "Run a Daily Check" card on the Dashboard to input new vitals or symptoms.';
    }

    if (q.contains('result') || q.contains('score') || q.contains('mean')) {
      if (a != null && a.displayScore != null) {
        return 'Your latest pneumonia risk score is ${(a.displayScore! * 100).toStringAsFixed(1)}%. '
            'The risk band is set by the server against the Stage 2 decision threshold, '
            'so read the band rather than the percentage on its own.';
      }
      return 'Your results reflect your multi-modal vital signs, laboratory biomarkers (WBC, CRP), and self-reported symptoms.';
    }

    if (q.contains('oxygen') || q.contains('spo2')) {
      final o2 = r?.spo2?.toInt() ?? 97;
      if (o2 < 90) {
        return 'Caution: Your latest blood oxygen is $o2%, which is below the normal range. Please sit upright, rest, and contact a medical professional if you feel breathless.';
      }
      return 'Your blood oxygen is $o2%, which is in the typical resting range (95–100%).';
    }

    if (q.contains('fever') || q.contains('temp')) {
      return 'Body temperatures above 100.4°F (38.0°C) are considered feverish. Be sure to stay hydrated and note if you develop a cough or shortness of breath.';
    }

    if (q.contains('breath') || q.contains('short of breath') || q.contains('respiratory')) {
      return 'Shortness of breath at rest is a key symptom evaluated by our Stage 2 pneumonia model. If you experience severe chest tightness or difficulty breathing, please seek immediate medical evaluation.';
    }

    return 'I am monitoring your daily readings and lab results. You can enter vitals directly here (e.g., "SpO2: 98, Temp: 98.6, Heart rate: 72") or ask me about your symptoms and risk score.';
  }

  // --- Save Profile ---
  Future<void> saveProfile(Profile newProfile) async {
    profile = newProfile;
    await _persist();
    if (!demo && firebaseEnabled && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('patients').doc(uid).set({
          'profile': profile.toJson(),
          'doctorIds': profile.doctorIds,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving profile to Firestore: $e');
      }
    }
    notifyListeners();
  }

  // --- Link / Unlink Doctor ---
  Future<void> linkDoctor(String doctorEmailOrId) async {
    final clean = doctorEmailOrId.trim();
    if (clean.isEmpty) return;
    final lower = clean.toLowerCase();
    if (!profile.doctorIds.map((d) => d.toLowerCase()).contains(lower)) {
      final updated = [...profile.doctorIds, clean];
      profile = profile.copyWith(doctorIds: updated);
      await _persist();
      if (!demo && firebaseEnabled && uid.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('patients').doc(uid).set({
            'profile': profile.toJson(),
            'doctorIds': updated,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error linking doctor in Firestore: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> unlinkDoctor(String id) async {
    final lower = id.trim().toLowerCase();
    final updated = profile.doctorIds.where((d) => d.trim().toLowerCase() != lower).toList();
    profile = profile.copyWith(doctorIds: updated);
    await _persist();
    if (!demo && firebaseEnabled && uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('patients').doc(uid).set({
          'profile': profile.toJson(),
          'doctorIds': updated,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error unlinking doctor in Firestore: $e');
      }
    }
    notifyListeners();
  }

  // --- Doctor Mode Operations ---
  void toggleDoctorMode() {
    doctor = !doctor;
    selectedPatient = null;
    notifyListeners();
  }

  Future<void> openPatient(String id) async {
    selectedPatient = id;
    patientProfile = null;
    patientReadings = [];
    patientLabs = null;
    patientAssessments = [];
    notifyListeners();

    if (!firebaseEnabled) return;

    try {
      final firestore = FirebaseFirestore.instance;
      // 1. Fetch patient document
      final doc = await firestore.collection('patients').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['profile'] != null) {
          patientProfile = Profile.fromJson(Map<String, dynamic>.from(data['profile']));
        } else {
          final email = data['email'] as String? ?? '';
          patientProfile = Profile(
            patientId: id,
            name: email.isNotEmpty ? email : 'Patient #${id.substring(0, 6)}',
          );
        }
        if (data['labs'] != null) {
          patientLabs = LabResults.fromJson(Map<String, dynamic>.from(data['labs']));
        }
      } else {
        patientProfile = Profile(
          patientId: id,
          name: 'Patient #${id.substring(0, 6)}',
        );
      }

      // 2. Fetch patient assessments subcollection
      final assSnap = await firestore
          .collection('patients')
          .doc(id)
          .collection('assessments')
          .orderBy('at', descending: true)
          .limit(25)
          .get();

      patientAssessments = assSnap.docs
          .map((d) => Assessment.fromJson(d.data()))
          .toList();

      // 3. Fetch patient readings subcollection
      final readSnap = await firestore
          .collection('patients')
          .doc(id)
          .collection('readings')
          .orderBy('at', descending: true)
          .limit(50)
          .get();

      patientReadings = readSnap.docs
          .map((d) => Reading.fromJson(d.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error opening patient $id from Firestore: $e');
      if (patientProfile == null) {
        patientProfile = Profile(
          patientId: id,
          name: 'Patient #${id.substring(0, 6)}',
        );
        notifyListeners();
      }
    }
  }

  void closePatientDetail() {
    selectedPatient = null;
    patientProfile = null;
    patientReadings = [];
    patientLabs = null;
    patientAssessments = [];
    notifyListeners();
  }

  // --- Auth / Firebase Support ---
  Future<void> _loadUserData(
    String userId, {
    String? defaultName,
    String? defaultEmail,
  }) async {
    uid = userId;
    demo = false;
    signedIn = true;
    selectedPatient = null;

    // 1. Load locally cached profile & assessments first
    final saved = preferences.getString('pneumonia.user.$uid');
    if (saved != null) {
      try {
        final data = jsonDecode(saved) as Map<String, dynamic>;
        profile = Profile.fromJson(data['profile'] ?? {});
        labs = data['labs'] != null ? LabResults.fromJson(data['labs']) : null;
        assessments = (data['assessments'] as List? ?? [])
            .map((a) => Assessment.fromJson(Map<String, dynamic>.from(a)))
            .toList();
      } catch (_) {}
    } else {
      profile = Profile(
        patientId: uid,
        name: (defaultName != null && defaultName.trim().isNotEmpty)
            ? defaultName.trim()
            : (defaultEmail ?? 'Patient'),
        age: null,
        sex: 'male',
      );
      assessments = [];
      labs = null;
    }

    // 2. Fetch live profile and assessments from Cloud Firestore
    if (firebaseEnabled) {
      try {
        final firestore = FirebaseFirestore.instance;
        final doc = await firestore.collection('patients').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['profile'] != null) {
            profile = Profile.fromJson(Map<String, dynamic>.from(data['profile']));
          }
        } else {
          // Document was deleted from Firestore: reset local state cleanly
          profile = Profile(
            patientId: uid,
            name: (defaultName != null && defaultName.trim().isNotEmpty)
                ? defaultName.trim()
                : (defaultEmail ?? 'Patient'),
            age: null,
            sex: 'male',
          );
          assessments = [];
          readings = [];
          labs = null;
          await preferences.remove('pneumonia.user.$uid');
          await firestore.collection('patients').doc(uid).set({
            'profile': profile.toJson(),
            'email': defaultEmail,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        final snapshot = await firestore
            .collection('patients')
            .doc(uid)
            .collection('assessments')
            .orderBy('at', descending: true)
            .limit(50)
            .get();

        // Sync exactly with Firestore (if empty in cloud, reflect empty in app)
        assessments = snapshot.docs
            .map((d) => Assessment.fromJson(d.data()))
            .toList();

        final readSnap = await firestore
            .collection('patients')
            .doc(uid)
            .collection('readings')
            .orderBy('at', descending: true)
            .limit(50)
            .get();

        readings = readSnap.docs
            .map((d) => Reading.fromJson(d.data()))
            .toList();
      } catch (e) {
        debugPrint('Firestore sync notice: $e');
      }
    }

    _sortData();
    notifyListeners();
  }

  Future<void> initFirebaseSession() async {
    if (!firebaseEnabled) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      uid = current.uid;
      demo = false;
      signedIn = true;

      // Resolve role from Firestore
      String resolvedRole = 'patient';
      try {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (uDoc.exists && uDoc.data() != null && uDoc.data()!['role'] != null) {
          resolvedRole = uDoc.data()!['role'] ?? 'patient';
        } else {
          // If users doc missing/deleted, check doctors collection
          final dDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
          if (dDoc.exists) {
            resolvedRole = 'doctor';
          }
        }
      } catch (_) {}

      role = resolvedRole;
      doctor = (role == 'doctor');

      if (doctor) {
        doctorEmail = current.email ?? '';
        try {
          final dDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
          if (dDoc.exists && dDoc.data() != null) {
            doctorName = dDoc.data()!['name'] ?? 'Doctor';
            doctorSpecialty = dDoc.data()!['specialty'] ?? 'Pulmonology';
          }
        } catch (_) {}
        await loadDoctorPatients();
      } else {
        await _loadUserData(
          current.uid,
          defaultName: current.displayName,
          defaultEmail: current.email,
        );
      }
    } else {
      signedIn = false;
    }
    notifyListeners();
  }

  Future<void> signIn(
    String email,
    String password, {
    bool register = false,
    String role = 'patient',
    String? name,
    int? age,
    String? sex,
    String? specialty,
  }) async {
    if (!firebaseEnabled) {
      // In standalone demo environment, sign in as demo directly
      await startDemo(role: role);
      return;
    }
    final auth = FirebaseAuth.instance;
    UserCredential cred;
    if (register) {
      try {
        cred = await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Email already registered in Firebase Auth!
          // Authenticate with the credentials provided so user isn't blocked:
          cred = await auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (name != null && name.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(name.trim());
      }
      final current = cred.user!;
      uid = current.uid;
      demo = false;
      signedIn = true;
      this.role = role;
      doctor = (role == 'doctor');

      // Record in central users directory for clean role routing
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': current.email,
          'role': role,
          'name': name ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user directory notice: $e');
      }

      if (role == 'doctor') {
        doctorName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Doctor';
        doctorSpecialty = specialty ?? 'Pulmonology';
        await loadDoctorPatients();
        try {
          await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
            'uid': uid,
            'name': doctorName,
            'specialty': doctorSpecialty,
            'email': current.email,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore doctor profile error: $e');
        }
      } else {
        profile = Profile(
          patientId: uid,
          name: (name != null && name.trim().isNotEmpty)
              ? name.trim()
              : (current.email ?? 'Patient'),
          age: age,
          sex: sex ?? 'male',
          conditions: const {
            'copd': 0,
            'asthma': 0,
            'heart_failure': 0,
            'renal': 0,
            'diabetes': 0,
            'hypertension': 0,
          },
        );
        assessments = [];
        await _persist();
      }
      notifyListeners();
      return;
    } else {
      cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final current = cred.user!;
      uid = current.uid;
      demo = false;
      signedIn = true;

      // Resolve role strictly from Firestore based on the account's registered role
      String resolvedRole = 'patient';
      try {
        final uDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (uDoc.exists && uDoc.data() != null && uDoc.data()!['role'] != null) {
          resolvedRole = uDoc.data()!['role'];
        } else {
          // If users doc was deleted or lacks role, check if doctor doc exists
          final dDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
          if (dDoc.exists) {
            resolvedRole = 'doctor';
          }
        }
      } catch (_) {}

      this.role = resolvedRole;
      doctor = (this.role == 'doctor');

      if (doctor) {
        doctorEmail = current.email ?? '';
        try {
          final dDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
          if (dDoc.exists && dDoc.data() != null) {
            doctorName = dDoc.data()!['name'] ?? 'Doctor';
            doctorSpecialty = dDoc.data()!['specialty'] ?? 'Pulmonology';
          } else {
            // If doctor doc is missing, initialize it
            await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
              'uid': uid,
              'name': doctorName,
              'specialty': doctorSpecialty,
              'email': current.email,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        } catch (_) {}
        await loadDoctorPatients();
        notifyListeners();
      } else {
        await _loadUserData(
          current.uid,
          defaultName: current.displayName,
          defaultEmail: current.email,
        );
      }
    }
  }

  Future<void> signOut() async {
    if (!demo && firebaseEnabled) {
      await FirebaseAuth.instance.signOut();
    }
    signedIn = false;
    demo = false;
    doctor = false;
    role = 'patient';
    selectedPatient = null;
    profile = const Profile();
    assessments = [];
    patients = [];
    notifyListeners();
  }

  Future<void> refresh() async {
    await checkApiConnection();
    if (isCloudConnected) {
      if (isDoctor) {
        await loadDoctorPatients();
      } else {
        await _loadUserData(uid);
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    if (demo) {
      await preferences.setString(
        'pneumonia.demo.v2',
        jsonEncode({
          'profile': profile.toJson(),
          'readings': readings.map((r) => r.toJson()).toList(),
          'labs': labs?.toJson(),
          'assessments': assessments.map((a) => a.toJson()).toList(),
          'chat': chatMessages.map((c) => c.toJson()).toList(),
        }),
      );
    } else if (uid.isNotEmpty) {
      // 1. Cache to local storage so user data loads instantly offline
      await preferences.setString(
        'pneumonia.user.$uid',
        jsonEncode({
          'profile': profile.toJson(),
          'labs': labs?.toJson(),
          'assessments': assessments.map((a) => a.toJson()).toList(),
        }),
      );

      // 2. Sync to Cloud Firestore
      if (firebaseEnabled) {
        try {
          await FirebaseFirestore.instance.collection('patients').doc(uid).set({
            'profile': profile.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
            'latestAssessment': latestAssessment?.toJson(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore persist profile error: $e');
        }
      }
    }
  }

  final Map<String, Set<int>> _doctorChecklists = {};

  Set<int> getDoctorChecklist(String patientId) {
    if (_doctorChecklists.containsKey(patientId)) {
      return _doctorChecklists[patientId]!;
    }
    final key = 'pneumonia.checklist.${uid}_$patientId';
    final saved = preferences.getStringList(key) ?? const [];
    final parsed = saved.map(int.tryParse).whereType<int>().toSet();
    _doctorChecklists[patientId] = parsed;
    return parsed;
  }

  Future<void> toggleDoctorChecklist(String patientId, int index) async {
    final current = Set<int>.from(getDoctorChecklist(patientId));
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
    }
    _doctorChecklists[patientId] = current;
    notifyListeners();
    final key = 'pneumonia.checklist.${uid}_$patientId';
    await preferences.setStringList(key, current.map((i) => i.toString()).toList());
  }

  void _sortData() {
    readings.sort((a, b) => b.at.compareTo(a.at));
    assessments.sort((a, b) => b.at.compareTo(a.at));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _readingSubscription?.cancel();
    super.dispose();
  }
}

class _ParsedHealthQuery {
  final Map<String, double> vitals;
  final LabResults? labs;
  final SymptomCheck symptoms;
  final String summary;

  _ParsedHealthQuery({
    required this.vitals,
    this.labs,
    required this.symptoms,
    required this.summary,
  });
}

