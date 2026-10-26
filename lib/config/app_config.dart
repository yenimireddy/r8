/// Compile-time flags.
///
/// Use mock without Firebase:
///   flutter run --dart-define=USE_MOCK=true
///
/// Default: Firebase (requires lib/firebase_options.dart from FlutterFire).
class AppConfig {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'asia-south1',
  );
}
