import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'access.dart';

/// The add-ons the server last said this account has.
///
/// Kept on the phone for one reason: the Offline add-on has to be known
/// on a launch with **no signal**, and that is the one launch that cannot
/// ask. `billing/plan` (owners) and `account` (agents) both
/// need the network, so without this the app forgets it may work offline
/// exactly when it must — the copy is on the phone, and nothing reads it.
///
/// This is a remembered answer, not a licence. The server still has the
/// last word: its own 404s hide what is off, `sync/check` can refuse the
/// copy (`offline.allowed`), and the add-on's `offline_until` bounds how
/// long a phone may stay away before 11.6 stops it. All it does is carry
/// the last answer across a launch.
///
/// It is kept per person. Another sign-in on the same phone does not
/// inherit it.
abstract final class AddonStore {
  static const _key = 'v2_addons';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  /// What [userId] last had, or null when nothing is kept for them.
  static Future<Map<Addon, AddonState>?> read(int userId) async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final parts = raw.split('|');
      if (parts.length != 2 || parts.first != '$userId') return null;
      // `inventory=trial,team=active`; an older bare key means active.
      final out = <Addon, AddonState>{};
      for (final part in parts[1].split(',')) {
        final kv = part.trim().split('=');
        final addon = Addon.fromKey(kv.first);
        if (addon == null) continue;
        out[addon] = kv.length > 1
            ? AddonState.fromKey(kv[1])
            : AddonState.active;
      }
      return out;
    } catch (e) {
      debugPrint('[access] unreadable stored add-ons: $e');
      return null;
    }
  }

  /// Keeps what the server just said. Failing to write is not an error:
  /// the next launch simply asks again, as it did before.
  static Future<void> write(int userId, Map<Addon, AddonState> addons) async {
    try {
      await _storage.write(
        key: _key,
        value:
            '$userId|${addons.entries.map((e) => '${e.key.key}=${e.value.name}').join(',')}',
      );
    } catch (e) {
      debugPrint('[access] could not keep the add-ons: $e');
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
