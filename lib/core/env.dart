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

  /// OAuth **Web** client ID from Google Cloud. Google returns the ID token
  /// for this audience, and the server verifies it. Empty = Google sign-in off.
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Label stored against the Sanctum token (`device_name`).
  static const deviceName = String.fromEnvironment(
    'DEVICE_NAME',
    defaultValue: 'AtomShop Brand App',
  );
}
