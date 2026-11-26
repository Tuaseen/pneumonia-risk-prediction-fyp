import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/app_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var enabled = false;
  String? error;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    enabled = true;
  } catch (e) {
    enabled = false;
    error = e.toString();
  }

  final preferences = await SharedPreferences.getInstance();
  final store = AppStore(preferences: preferences, firebaseEnabled: enabled);

  if (enabled) {
    await store.initFirebaseSession();
  }

  runApp(
    PneumoniaAssistantApp(
      store: store,
      startupError: error,
    ),
  );
}
