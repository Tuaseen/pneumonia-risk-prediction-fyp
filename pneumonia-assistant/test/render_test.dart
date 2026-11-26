import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pneumonia_assistant/app.dart';
import 'package:pneumonia_assistant/data/app_store.dart';

void main() {
  testWidgets('Render smoke test', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(preferences: await SharedPreferences.getInstance());
    await store.startDemo();

    await tester.pumpWidget(PneumoniaAssistantApp(store: store));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
