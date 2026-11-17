/// Build-time configuration.
///
/// Point the app at a local backend with:
/// `flutter run --dart-define=API_BASE=http://192.168.1.20/atomshop/api/brand-app`
class Env {
  const Env._();

  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://atomshop.pk/api/brand-app',
  );

  /// Label stored against the Sanctum token (`device_name`).
  static const deviceName = String.fromEnvironment(
    'DEVICE_NAME',
    defaultValue: 'Atombrand App',
  );
}
