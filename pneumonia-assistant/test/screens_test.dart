import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pneumonia_assistant/app.dart';
import 'package:pneumonia_assistant/data/app_store.dart';

void main() {
  testWidgets('App navigation through Dashboard, Assistant, History & Reports, and Profile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = AppStore(
      preferences: await SharedPreferences.getInstance(),
    );
    await store.startDemo();

    await tester.pumpWidget(PneumoniaAssistantApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Recent Health Reports'), findsOneWidget);
    expect(find.text('Run a Daily Check'), findsOneWidget);

    // Navigate to Assistant
    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();
    expect(find.text('Pneumonia Assistant'), findsWidgets);

    // Navigate to History & Reports
    await tester.tap(find.text('History & Reports'));
    await tester.pumpAndSettle();
    expect(find.text('History & Reports'), findsWidgets);

    // Navigate to Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile & Settings'), findsOneWidget);
  });
}
