// STUB — replace by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=YOUR_PROJECT_ID --platforms=android
//
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('R8 MVP is Android-first.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('R8 MVP targets Android first.');
    }
  }

  /// Placeholder values — flutterfire configure overwrites this file.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_API_KEY',
    appId: '1:000000000000:android:replace_me',
    messagingSenderId: '000000000000',
    projectId: 'r8-replace-me',
    storageBucket: 'r8-replace-me.appspot.com',
  );

  static bool get isConfigured =>
      android.apiKey != 'REPLACE_WITH_FIREBASE_API_KEY';
}
