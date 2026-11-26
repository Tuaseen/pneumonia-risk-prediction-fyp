import 'dart:math';
import 'package:flutter/material.dart';

// --- Vitals Metadata ---
const List<String> vitalKeys = [
  'heart_rate',
  'respiratory_rate',
  'sbp',
  'spo2',
  'temperature',
];

const Map<String, String> vitalNames = {
  'heart_rate': 'Heart rate',
  'respiratory_rate': 'Breathing rate',
  'sbp': 'Blood pressure (top)',
  'spo2': 'Blood oxygen',
  'temperature': 'Temperature',
};

const Map<String, String> vitalUnits = {
  'heart_rate': 'bpm',
  'respiratory_rate': '/min',
  'sbp': 'mmHg',
  'spo2': '%',
  'temperature': '°F',
};

const Map<String, int> vitalDigits = {
  'heart_rate': 0,
  'respiratory_rate': 0,
  'sbp': 0,
  'spo2': 0,
  'temperature': 1,
};

const Map<String, List<double>> vitalRanges = {
  'heart_rate': [60.0, 100.0],
  'respiratory_rate': [12.0, 20.0],
  'sbp': [90.0, 120.0],
  'spo2': [95.0, 100.0],
  'temperature': [97.0, 99.0],
};

const Map<String, Color> vitalColors = {
  'heart_rate': Color(0xFFE11D48), // Rose
  'respiratory_rate': Color(0xFF0891B2), // Cyan
  'sbp': Color(0xFFDC2626), // Red
  'spo2': Color(0xFF2563EB), // Blue
  'temperature': Color(0xFFEA580C), // Orange
};

const Color labThemeColor = Color(0xFF7C3AED); // Purple

// --- Comorbidities Metadata ---
const Map<String, String> conditionLabels = {
  'copd': 'COPD (chronic lung disease)',
  'asthma': 'Asthma',
  'heart_failure': 'Heart failure',
  'renal': 'Kidney disease',
  'diabetes': 'Diabetes',
  'hypertension': 'High blood pressure',
};

const List<String> conditionKeys = [
  'copd',
  'asthma',
  'heart_failure',
  'renal',
  'diabetes',
  'hypertension',
];

// --- Risk Bands ---
enum RiskBand { low, pending, moderate, watch, high }

extension RiskBandExt on RiskBand {
  String get key => name[0].toUpperCase() + name.substring(1);

  String get label => switch (this) {
    RiskBand.low => 'No concern right now',
    RiskBand.pending => 'More information needed',
    RiskBand.moderate => 'Keep an eye on it',
    RiskBand.watch => 'Possible concern: re-checking',
    RiskBand.high => 'See a doctor today',
  };

  String get summary => switch (this) {
    RiskBand.low => 'Your latest check found no signs of concern.',
    RiskBand.pending => 'The check needs a little more information to finish.',
    RiskBand.moderate => 'Some readings are outside the usual range.',
    RiskBand.watch => 'The check flagged a possible concern and will confirm it soon.',
    RiskBand.high => 'Your results suggest a raised risk of a chest infection.',
  };

  Color get color => switch (this) {
    RiskBand.low => const Color(0xFF16A34A),
    RiskBand.pending => const Color(0xFF64748B),
    RiskBand.moderate => const Color(0xFFCA8A04),
    RiskBand.watch => const Color(0xFFEA580C),
    RiskBand.high => const Color(0xFFDC2626),
  };

  Color get backgroundColor => switch (this) {
    RiskBand.low => const Color(0xFFDCFCE7),
    RiskBand.pending => const Color(0xFFF1F5F9),
    RiskBand.moderate => const Color(0xFFFEF9C3),
    RiskBand.watch => const Color(0xFFFFEDD5),
    RiskBand.high => const Color(0xFFFEE2E2),
  };

  Color get textColor => switch (this) {
    RiskBand.low => const Color(0xFF15803D),
    RiskBand.pending => const Color(0xFF475569),
    RiskBand.moderate => const Color(0xFFA16207),
    RiskBand.watch => const Color(0xFFC2410C),
    RiskBand.high => const Color(0xFFB91C1C),
  };

  IconData get icon => switch (this) {
    RiskBand.low => Icons.check_circle_outline,
    RiskBand.pending => Icons.hourglass_empty,
    RiskBand.moderate => Icons.remove_red_eye_outlined,
    RiskBand.watch => Icons.refresh,
    RiskBand.high => Icons.medical_services_outlined,
  };
}

RiskBand parseRiskBand(String? name) {
  if (name == null) return RiskBand.pending;
  final clean = name.trim().toLowerCase();
  for (final band in RiskBand.values) {
    if (band.name.toLowerCase() == clean) return band;
  }
  return RiskBand.pending;
}

// --- Range Evaluation ---
enum VitalRangeStatus { normal, below, above }

VitalRangeStatus evaluateVital(String vital, double value) {
  final range = vitalRanges[vital];
  if (range == null) return VitalRangeStatus.normal;
  if (value < range[0]) return VitalRangeStatus.below;
  if (value > range[1]) return VitalRangeStatus.above;
  return VitalRangeStatus.normal;
}

// --- Alert Model ---
class Alert {
  final String code;
  final String message;
  final double value;

  const Alert({
    required this.code,
    required this.message,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'value': value,
  };

  factory Alert.fromJson(Map<String, dynamic> j) => Alert(
    code: j['code'] ?? '',
    message: j['message'] ?? '',
    value: (j['value'] as num?)?.toDouble() ?? 0.0,
  );
}

// --- Lab Results ---
/// Any lab value may be missing (null): labs are optional and a missing value is never guessed.
class LabResults {
  final double? wbc; // x10^9/L
  final double? neutrophils; // %
  final double? lymphocytes; // %
  final double? crp; // mg/L
  final DateTime takenAt;

  const LabResults({
    this.wbc,
    this.neutrophils,
    this.lymphocytes,
    this.crp,
    required this.takenAt,
  });

  Map<String, dynamic> toJson() => {
    'wbc': wbc,
    'neutrophils': neutrophils,
    'lymphocytes': lymphocytes,
    'crp': crp,
    'taken_at': takenAt.toUtc().toIso8601String(),
  };

  factory LabResults.fromJson(Map<String, dynamic> j) => LabResults(
    wbc: (j['wbc'] as num?)?.toDouble(),
    neutrophils: (j['neutrophils'] as num?)?.toDouble(),
    lymphocytes: (j['lymphocytes'] as num?)?.toDouble(),
    crp: (j['crp'] as num?)?.toDouble(),
    takenAt: j['taken_at'] != null
        ? DateTime.parse(j['taken_at']).toLocal()
        : DateTime.now(),
  );
}

// --- Reading Model ---
class Reading {
  final String id;
  final DateTime at;
  final Map<String, double> values;
  final String source;
  final String? deviceId;

  const Reading({
    required this.id,
    required this.at,
    required this.values,
    required this.source,
    this.deviceId,
  });

  bool get isSimulated => source == 'simulator';

  double? get heartRate => values['heart_rate'];
  double? get respiratoryRate => values['respiratory_rate'];
  double? get sbp => values['sbp'];
  double? get spo2 => values['spo2'];
  double? get temperature => values['temperature'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toUtc().toIso8601String(),
    'values': values,
    'source': source,
    'deviceId': deviceId,
    'schemaVersion': 2,
  };

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
    id: j['id'] ?? '',
    at: DateTime.parse(j['at']).toLocal(),
    values: (j['values'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
    source: j['source'] ?? 'device',
    deviceId: j['deviceId'],
  );
}

// --- Symptom Check Model ---
class SymptomCheck {
  final int? respiratoryDistress; // 0 or 1
  final int? cough; // 0 or 1
  final int? fever; // 0 or 1
  final int? weakness; // 0 or 1

  const SymptomCheck({
    this.respiratoryDistress,
    this.cough,
    this.fever,
    this.weakness,
  });

  bool get isComplete =>
      respiratoryDistress != null &&
      cough != null &&
      fever != null &&
      weakness != null;

  Map<String, int> toMap() => {
    'respiratory_distress': respiratoryDistress ?? 0,
    'cough': cough ?? 0,
    'fever': fever ?? 0,
    'weakness': weakness ?? 0,
  };

  Map<String, dynamic> toJson() => toMap();

  factory SymptomCheck.fromMap(Map<String, dynamic> m) => SymptomCheck(
    respiratoryDistress: (m['respiratory_distress'] as num?)?.toInt(),
    cough: (m['cough'] as num?)?.toInt(),
    fever: (m['fever'] as num?)?.toInt(),
    weakness: (m['weakness'] as num?)?.toInt(),
  );
}

// --- Assessment Model ---
class Assessment {
  final String id;
  final DateTime at;
  final RiskBand band;
  final int? stage;
  final double? riskScoreStage1;
  final double? riskScoreStage2;
  final List<Alert> alerts;
  final String? criticalNotice;
  final String? recommendation;
  final List<String> missing;
  final Map<String, int> symptoms;
  final Map<String, double> vitals;
  final LabResults? labs;
  final Map<String, dynamic> profileSnapshot;
  final String? plainSummary;

  const Assessment({
    required this.id,
    required this.at,
    required this.band,
    this.stage,
    this.riskScoreStage1,
    this.riskScoreStage2,
    this.alerts = const [],
    this.criticalNotice,
    this.recommendation,
    this.missing = const [],
    this.symptoms = const {},
    this.vitals = const {},
    this.labs,
    this.profileSnapshot = const {},
    this.plainSummary,
  });

  double? get displayScore => riskScoreStage2 ?? riskScoreStage1;

  String get riskTierTitle => switch (band) {
    RiskBand.low => 'Low Pneumonia Risk (Normal & Stable)',
    RiskBand.moderate => 'Moderate Risk (Monitor Symptoms Closely)',
    RiskBand.watch => 'Borderline Risk (Clinical Follow-up Advised)',
    RiskBand.high => 'High Pneumonia Risk (Medical Review Recommended)',
    RiskBand.pending => 'Assessment Pending',
  };

  String get plainLanguageSummary {
    if (plainSummary != null && plainSummary!.isNotEmpty) return plainSummary!;
    switch (band) {
      case RiskBand.low:
        return 'Based on your reported symptoms and health indicators, you are currently showing no characteristic signs of active pneumonia. Your breathing and vital indicators remain in a safe range.';
      case RiskBand.moderate:
        return 'You reported mild symptoms (such as a cough, mild fever, or fatigue) that may suggest an early respiratory issue. While not critical right now, you should rest, monitor how you feel, and repeat the check tomorrow.';
      case RiskBand.watch:
        return 'Some of your reported signs are on the borderline of concern. Continued monitoring and consulting a doctor or nurse is recommended if you do not feel better soon.';
      case RiskBand.high:
        return 'Your combination of symptoms and health indicators shows a high likelihood of a chest infection or pneumonia. We strongly recommend that you contact a healthcare provider, clinic, or urgent care doctor today for a clinical examination.';
      case RiskBand.pending:
        return 'Complete a daily check to see your plain-language health summary.';
    }
  }

  List<String> get simpleActionSteps => switch (band) {
    RiskBand.low => const [
      'Continue standard daily hydration and healthy rest.',
      'Take another check-in tomorrow morning or if any new symptoms arise.',
      'Protect yourself from sudden cold drafts and environmental smoke.',
    ],
    RiskBand.moderate => const [
      'Get plenty of rest and drink warm fluids throughout the day.',
      'Take your temperature twice daily (morning and evening).',
      'Use an over-the-counter fever reducer if recommended by your physician.',
      'If your cough deepens or fever rises above 101°F, contact your clinic.',
    ],
    RiskBand.watch => const [
      'Schedule a routine check-up with your general practitioner.',
      'Avoid strenuous physical exertion.',
      'Keep a written log of your temperature and breathing comfort.',
    ],
    RiskBand.high => const [
      'Contact your primary care doctor or local urgent care center promptly.',
      'Share this report and your symptoms with the examining medical professional.',
      'Do not wait if breathing feels noticeably harder or painful.',
      'Have someone drive you to the clinic if you feel lightheaded or weak.',
    ],
    RiskBand.pending => const ['Submit your daily symptom responses to generate guidance.'],
  };

  List<String> get emergencyWarningSigns => const [
    'Severe shortness of breath or gasping for air even while sitting still.',
    'Chest pain that is sharp or worsens when inhaling deeply.',
    'Bluish or grayish tint to your lips, gums, or nail beds.',
    'Confusion, unusual drowsiness, or trouble staying awake.',
    'High fever that does not decrease after taking fever medication.',
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at.toUtc().toIso8601String(),
    'band': band.name,
    'stage': stage,
    'riskScoreStage1': riskScoreStage1,
    'riskScoreStage2': riskScoreStage2,
    'alerts': alerts.map((a) => a.toJson()).toList(),
    'criticalNotice': criticalNotice,
    'recommendation': recommendation,
    'missing': missing,
    'symptoms': symptoms,
    'vitals': vitals,
    'labs': labs?.toJson(),
    'profileSnapshot': profileSnapshot,
    'plainSummary': plainSummary ?? plainLanguageSummary,
  };

  factory Assessment.fromJson(Map<String, dynamic> j) => Assessment(
    id: j['id'] ?? '',
    at: DateTime.parse(j['at']).toLocal(),
    band: parseRiskBand(j['band']),
    stage: (j['stage'] as num?)?.toInt(),
    riskScoreStage1: (j['riskScoreStage1'] as num?)?.toDouble(),
    riskScoreStage2: (j['riskScoreStage2'] as num?)?.toDouble(),
    alerts: (j['alerts'] as List? ?? [])
        .map((a) => Alert.fromJson(Map<String, dynamic>.from(a)))
        .toList(),
    criticalNotice: j['criticalNotice'],
    recommendation: j['recommendation'],
    missing: List<String>.from(j['missing'] ?? []),
    symptoms: Map<String, int>.from(j['symptoms'] ?? {}),
    vitals: (j['vitals'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
    labs: j['labs'] != null ? LabResults.fromJson(j['labs']) : null,
    profileSnapshot: Map<String, dynamic>.from(j['profileSnapshot'] ?? {}),
    plainSummary: j['plainSummary'],
  );
}

// --- Chat Message Model ---
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final bool error;
  final Assessment? assessment;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.error = false,
    this.assessment,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'error': error,
    'assessment': assessment?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] ?? '',
    role: j['role'] ?? 'assistant',
    text: j['text'] ?? '',
    timestamp: DateTime.parse(j['timestamp']).toLocal(),
    error: j['error'] == true,
    assessment: j['assessment'] != null
        ? Assessment.fromJson(j['assessment'])
        : null,
  );
}

// --- Profile Model ---
class Profile {
  final String patientId;
  final String name;
  final int? age;
  final String sex;
  final List<String> doctorIds;
  final Map<String, int> conditions;

  const Profile({
    this.patientId = '',
    this.name = '',
    this.age,
    this.sex = 'male',
    this.doctorIds = const [],
    this.conditions = const {
      'copd': 0,
      'asthma': 0,
      'heart_failure': 0,
      'renal': 0,
      'diabetes': 0,
      'hypertension': 0,
    },
  });

  static Profile alexMorgan() => const Profile(
    patientId: 'patient_demo_01',
    name: 'Alex Morgan',
    age: 58,
    sex: 'female',
    doctorIds: [],
    conditions: {
      'copd': 0,
      'asthma': 0,
      'heart_failure': 0,
      'renal': 0,
      'diabetes': 0,
      'hypertension': 1,
    },
  );

  bool get isComplete => name.trim().isNotEmpty && age != null;

  Profile copyWith({
    String? patientId,
    String? name,
    int? age,
    String? sex,
    List<String>? doctorIds,
    Map<String, int>? conditions,
  }) => Profile(
    patientId: patientId ?? this.patientId,
    name: name ?? this.name,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    doctorIds: doctorIds ?? this.doctorIds,
    conditions: conditions ?? this.conditions,
  );

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'name': name,
    'age': age,
    'sex': sex,
    'doctorIds': doctorIds,
    'conditions': conditions,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    patientId: j['patientId'] ?? '',
    name: j['name'] ?? '',
    age: (j['age'] as num?)?.toInt(),
    sex: j['sex'] ?? 'male',
    doctorIds: List<String>.from(j['doctorIds'] ?? []),
    conditions: Map<String, int>.from(j['conditions'] ?? {
      'copd': 0,
      'asthma': 0,
      'heart_failure': 0,
      'renal': 0,
      'diabetes': 0,
      'hypertension': 0,
    }),
  );
}

// --- Demo Vitals Generator ---
List<Reading> generateDemoReadings({DateTime? now}) {
  final end = now ?? DateTime.now();
  // 14 readings over the last 7 days (twice daily)
  return List.generate(14, (i) {
    final t = end.subtract(Duration(hours: (13 - i) * 12));
    final wave = sin(i * 0.6);
    return Reading(
      id: 'demo-reading-$i',
      at: t,
      source: 'device',
      deviceId: 'PNEUMO-IOT-01',
      values: {
        'heart_rate': (74 + wave * 6).clamp(55, 120).roundToDouble(),
        'respiratory_rate': (17 + wave * 2).clamp(12, 30).roundToDouble(),
        'sbp': (118 + wave * 5).clamp(85, 160).roundToDouble(),
        'spo2': (97 + wave * 1).clamp(88, 100).roundToDouble(),
        'temperature': double.parse((98.4 + wave * 0.4).toStringAsFixed(1)),
      },
    );
  });
}

LabResults generateDemoLabs({DateTime? now}) {
  final t = (now ?? DateTime.now()).subtract(const Duration(hours: 14));
  return LabResults(
    wbc: 7.4,
    neutrophils: 62.0,
    lymphocytes: 28.5,
    crp: 4.2,
    takenAt: t,
  );
}
