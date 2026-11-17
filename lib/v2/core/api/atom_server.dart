/// Which atomshop server the app talks to.
///
/// Release builds always use atomshop.pk. For testing against a local
/// server (XAMPP on this PC), build with:
///
///   adb reverse tcp:80 tcp:80
///   flutter run --dart-define=ATOM_SERVER=http://localhost/atomshop/
///
/// `adb reverse` makes the phone's `localhost` this PC (over USB), so the
/// same address works on a phone and an emulator.
abstract final class AtomServer {
  static const _production = 'https://atomshop.pk/';
  static const _fromBuild = String.fromEnvironment('ATOM_SERVER');

  /// The site root, always ending in `/` (`https://atomshop.pk/`).
  static final String site = _fromBuild.isEmpty
      ? _production
      : (_fromBuild.endsWith('/') ? _fromBuild : '$_fromBuild/');

  /// The Brand App API root (`https://atomshop.pk/api/brand-app/`). Every
  /// repository path is relative to it (`me`, `orders`, `sync/check`).
  static final String api = '${site}api/brand-app/';

  /// True when built against a server other than atomshop.pk.
  static bool get isLocal => site != _production;

  /// Where the server keeps uploaded files.
  ///
  /// They sit under `public/` (`storage/…`, `images/…`); at the site root
  /// they were a 404, so no photo ever showed.
  static final String filesBase = '${site}public/';

  /// A file's full address from the path the server stores, or null for
  /// no file. Already a full address passes through.
  ///
  /// One place, because the Offline add-on keeps downloaded photos under
  /// this address: the engine and the screen have to agree on it exactly
  /// or a photo that is on the phone would never be found again.
  static String? fileUrl(Object? path) {
    final p = path is String ? path.trim() : null;
    if (p == null || p.isEmpty) return null;
    return p.startsWith('http') ? p : '$filesBase$p';
  }
}
