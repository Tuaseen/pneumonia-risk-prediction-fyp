// End-to-end check against a running backend. Skipped unless LIVE_API is set:
//   flutter test test/live_api_test.dart --dart-define=LIVE_API=http://127.0.0.1:8000 --dart-define=API_KEY=...
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pneumonia_assistant/data/app_store.dart';
import 'package:pneumonia_assistant/domain/models.dart';

const liveApi = String.fromEnvironment('LIVE_API');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;   // the test binding would otherwise answer every request with 400
  });

  Future<AppStore> demoStore() async {
    final store = AppStore(preferences: await SharedPreferences.getInstance());
    await store.startDemo();
    store.apiUrl = liveApi;
    return store;
  }

  test('Daily check is scored by the server models', () async {
    final store = await demoStore();
    final a = await store.assessDailyCheck(
      const SymptomCheck(respiratoryDistress: 1, cough: 1, fever: 1, weakness: 1),
      selfVitals: const {'heart_rate': 112, 'respiratory_rate': 26, 'sbp': 104, 'spo2': 89, 'temperature': 101.2},
    );
    // ignore: avoid_print
    print('band=${a.band.key} stage=${a.stage} s1=${a.riskScoreStage1} s2=${a.riskScoreStage2} '
        'alerts=${a.alerts.map((x) => x.code).toList()}');
    expect(store.apiOnline, isTrue);
    expect(a.riskScoreStage1, isNotNull);
    expect(store.assessments.first.id, a.id);
  }, skip: liveApi.isEmpty ? 'set --dart-define=LIVE_API=<url>' : false);

  test('A healthy check stops at Stage 1', () async {
    final store = await demoStore();
    store.readings = [];
    final a = await store.assessDailyCheck(
      const SymptomCheck(respiratoryDistress: 0, cough: 0, fever: 0, weakness: 0),
      selfVitals: const {'heart_rate': 72, 'respiratory_rate': 14, 'sbp': 122, 'spo2': 98, 'temperature': 98.4},
    );
    // ignore: avoid_print
    print('band=${a.band.key} stage=${a.stage} s1=${a.riskScoreStage1} s2=${a.riskScoreStage2}');
    expect(a.band, RiskBand.low);
    expect(a.stage, 1);
    expect(a.riskScoreStage2, isNull);
  }, skip: liveApi.isEmpty ? 'set --dart-define=LIVE_API=<url>' : false);

  test('Any number of days from 1 to 7 gives a Stage 2 result', () async {
    for (var days = 1; days <= 7; days++) {
      final store = await demoStore();
      final now = DateTime.now();
      store.readings = [
        for (var d = 0; d < days; d++)
          for (var h in [2, 6])
            Reading(
              id: 'r$d$h',
              at: now.subtract(Duration(days: d, hours: h)),
              values: {'heart_rate': 100.0 + d, 'respiratory_rate': 24, 'sbp': 108, 'spo2': 92, 'temperature': 100.8},
              source: 'daily_check',
            ),
      ];
      final a = await store.assessDailyCheck(
        const SymptomCheck(respiratoryDistress: 1, cough: 1, fever: 1, weakness: 1),
      );
      // ignore: avoid_print
      print('days=$days band=${a.band.key} stage=${a.stage} s1=${a.riskScoreStage1} s2=${a.riskScoreStage2}');
      expect(a.stage, 2, reason: '$days day(s) of readings');
      expect(a.riskScoreStage2, isNotNull);
    }
  }, skip: liveApi.isEmpty ? 'set --dart-define=LIVE_API=<url>' : false);

  test('Sick vitals twice and no labs still reach Stage 2', () async {
    final store = await demoStore();
    store.readings = [];
    store.labs = null;
    const sick = {'heart_rate': 112.0, 'respiratory_rate': 26.0, 'sbp': 104.0, 'spo2': 89.0, 'temperature': 101.2};
    const answers = SymptomCheck(respiratoryDistress: 0, cough: 0, fever: 0, weakness: 0);
    final first = await store.assessDailyCheck(answers, selfVitals: sick);
    final second = await store.assessDailyCheck(answers, selfVitals: sick);
    // ignore: avoid_print
    print('first: band=${first.band.key} stage=${first.stage} | second: band=${second.band.key} '
        'stage=${second.stage} s1=${second.riskScoreStage1} s2=${second.riskScoreStage2}');
    expect(second.stage, 2);
    expect(second.riskScoreStage2, isNotNull);
  }, skip: liveApi.isEmpty ? 'set --dart-define=LIVE_API=<url>' : false);
}
