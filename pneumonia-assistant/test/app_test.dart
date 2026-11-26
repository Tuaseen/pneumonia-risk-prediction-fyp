import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pneumonia_assistant/app.dart';
import 'package:pneumonia_assistant/data/app_store.dart';
import 'package:pneumonia_assistant/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AppStore> makeStore() async =>
      AppStore(preferences: await SharedPreferences.getInstance());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Vital ranges and alert evaluations work correctly', () {
    expect(evaluateVital('spo2', 98.0), VitalRangeStatus.normal);
    expect(evaluateVital('spo2', 88.0), VitalRangeStatus.below);
    expect(evaluateVital('heart_rate', 110.0), VitalRangeStatus.above);
    expect(evaluateVital('temperature', 98.6), VitalRangeStatus.normal);

    final r = Reading(
      id: 'r1',
      at: DateTime.now(),
      values: {
        'spo2': 88.0,
        'respiratory_rate': 26.0,
        'temperature': 101.5,
      },
      source: 'device',
    );
    expect(r.spo2, 88.0);
    expect(r.respiratoryRate, 26.0);
    expect(r.temperature, 101.5);
  });

  test('Daily check without the API gives no score and saves the readings', () async {
    final store = await makeStore();
    await store.startDemo();
    final before = store.assessments.length;
    final readingsBefore = store.readings.length;

    const symptoms = SymptomCheck(
      respiratoryDistress: 1,
      cough: 1,
      fever: 1,
      weakness: 1,
    );
    // The API is not running in tests: the app must refuse to invent a risk score.
    await expectLater(
      store.assessDailyCheck(symptoms, selfVitals: const {'spo2': 89, 'respiratory_rate': 26}),
      throwsA(isA<BackendUnavailableException>()),
    );
    expect(store.assessments.length, before);
    expect(store.readings.length, readingsBefore + 1);
  });

  testWidgets('App renders login screen and enters patient companion', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await makeStore();
    await tester.pumpWidget(PneumoniaAssistantApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Pneumonia Assistant'), findsWidgets);
    expect(find.text('Account Sign In'), findsOneWidget);

    await store.startDemo(role: 'patient');
    await tester.pumpAndSettle();

    expect(find.textContaining('Hello,'), findsOneWidget);
    expect(find.text('Recent Health Reports'), findsOneWidget);
    expect(find.text('Run a Daily Check'), findsOneWidget);
  });

  testWidgets('App enters doctor portal and renders clinical workspace', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await makeStore();
    await tester.pumpWidget(PneumoniaAssistantApp(store: store));
    await tester.pumpAndSettle();

    await store.startDemo(role: 'doctor');
    await tester.pumpAndSettle();

    expect(find.text('Clinical Workspace'), findsOneWidget);
    expect(find.text('Monitored Patient Roster'), findsOneWidget);
    expect(find.text('Total Patients'), findsOneWidget);
  });
}
