import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVAMMlHuouX0VsmQsiqkX6H_boC3br-7E',
    appId: '1:676066145660:android:3269aea36c60a61a8460f9',
    messagingSenderId: '676066145660',
    projectId: 'pneumonia-assistant-fyp',
    authDomain: 'pneumonia-assistant-fyp.firebaseapp.com',
    storageBucket: 'pneumonia-assistant-fyp.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVAMMlHuouX0VsmQsiqkX6H_boC3br-7E',
    appId: '1:676066145660:android:3269aea36c60a61a8460f9',
    messagingSenderId: '676066145660',
    projectId: 'pneumonia-assistant-fyp',
    authDomain: 'pneumonia-assistant-fyp.firebaseapp.com',
    storageBucket: 'pneumonia-assistant-fyp.firebasestorage.app',
  );
}
