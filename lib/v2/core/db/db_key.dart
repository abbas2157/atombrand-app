import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The key the outbox is encrypted with (SQLCipher).
///
/// Made on this phone, never leaves it, and kept in the Keystore /
/// Keychain through `flutter_secure_storage` — the same place the session
/// token and the PIN hash live.
///
/// **Never wrapped by the PIN, on purpose.** The outbox is a day of
/// collecting that exists nowhere else yet, so a forgotten PIN must never
/// be able to lock it away. The copy, which can always be downloaded
/// again, has its own key, wrapped by the PIN (`CopyKey`, `RULES.md` §5).
///
/// Wrong PINs never wipe it: only the server does (`sync/check` → `wipe`).
abstract final class DbKey {
  static const _name = 'v2_db_key';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  /// 32 bytes, as the 64 hex characters SQLCipher takes as a raw key, so
  /// no passphrase is stretched on every open.
  static const bytes = 32;

  /// The outbox's key, made the first time it is opened.
  ///
  /// This is the key the single database used before the copy moved out,
  /// and the outbox kept that file: a phone upgrading opens what it
  /// already had, with the rows it already had in it.
  ///
  /// **A new key only when there is nothing to lose.** If the outbox file
  /// already holds data, a key that reads back empty is a key the Keystore
  /// failed to give back — seen on an Android 17 emulator, where a launch
  /// could not decrypt anything it had stored. Making a new one then would
  /// lock that file for good, and every payment waiting in it with it. So
  /// this refuses instead ([OutboxKeyUnreadable]): the outbox is shut for
  /// this run, nothing in it is touched, and the next launch, with a
  /// Keystore that answers, opens it as before.
  static Future<String> readOrCreate({File? file}) async {
    final held = await _storage.read(key: _name);
    if (held != null && held.length == bytes * 2) return held;
    if (file != null && await file.exists() && await file.length() > 0) {
      throw const OutboxKeyUnreadable();
    }
    final key = newKey();
    await _storage.write(key: _name, value: key);
    return key;
  }

  /// A fresh 32-byte key as 64 hex characters.
  @visibleForTesting
  static String newKey() {
    final rnd = Random.secure();
    return [
      for (var i = 0; i < bytes; i++)
        rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// Wiped by the server: the key goes, which makes the outbox file
  /// unreadable even if it is still on the phone. Never on a wrong PIN.
  static Future<void> forget() async {
    try {
      await _storage.delete(key: _name);
    } catch (e) {
      debugPrint('[db] could not forget the outbox key: $e');
    }
  }
}

/// The outbox file has data but its key can't be read. Thrown rather than
/// replacing the key, which would make the file unreadable for good.
class OutboxKeyUnreadable implements Exception {
  const OutboxKeyUnreadable();
  @override
  String toString() =>
      'OutboxKeyUnreadable: the outbox has data and its key did not come '
      'back; not replacing it';
}
