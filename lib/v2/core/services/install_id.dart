import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'uuid.dart';

/// This install's own id, sent as `device_id` when someone signs in.
///
/// The sync contract (`docs/seller-app-sync-api.md` §2) asks for a uuid
/// made once per install and kept. It is what ties the token to this
/// phone in `seller_devices`, and without it the server answers
/// `offline.allowed: false, device_registered: false` — so the phone may
/// not hold a copy, Atomshop's "sync now" nudge can't reach it, and the
/// owner can't sign it out or wipe it from the dashboard.
///
/// It is **not** the session. It outlives signing out, so the same phone
/// coming back is the same row rather than a new one. Losing it (a wiped
/// Keystore, a reinstall) is not an error: the next sign-in makes a new
/// one and registers as a new phone, and the old row goes stale on its
/// own.
abstract final class InstallId {
  static const _key = 'v2_install_id';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static String? _cached;

  /// This install's id, made on first use. Null only when the Keystore
  /// can't be reached at all, and then sign-in simply sends no
  /// `device_id`, exactly as it did before.
  static Future<String?> read() async {
    if (_cached != null) return _cached;
    try {
      final found = await _storage.read(key: _key);
      if (found != null && found.isNotEmpty) return _cached = found;
      final made = newUuid();
      await _storage.write(key: _key, value: made);
      return _cached = made;
    } catch (e) {
      debugPrint('[install] could not read or make this phone\'s id: $e');
      return null;
    }
  }

  @visibleForTesting
  static void forgetForTest() => _cached = null;
}
