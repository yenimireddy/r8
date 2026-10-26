import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'data/r8_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var useMock = AppConfig.useMock || !DefaultFirebaseOptions.isConfigured;

  if (!useMock) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e, st) {
      debugPrint('Firebase init failed ($e). Using mock. $st');
      useMock = true;
    }
  } else {
    debugPrint(
      'R8 running in MOCK mode. '
      'Configure Firebase (see SETUP_YOU_MUST_DO.md) for production.',
    );
  }

  final store = R8Store.create(useMock: useMock);
  await store.init();
  runApp(R8App(store: store, usingMock: useMock));
}
