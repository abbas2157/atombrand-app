import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'session.dart';

/// Keeps the session on the phone.
abstract interface class SessionStore {
  Future<BrandSession?> read();
  Future<void> write(BrandSession session);
  Future<void> clear();
}

/// The session in the Keystore / Keychain, as one JSON value.
///
/// One key, not v1's nine: the session is read and written whole, and a v1
/// session (no `who`) is simply not found, so a person moving to v2 signs in
/// once and gets their role and add-ons. Reads are bounded, for the same
/// reason as in v1's BrandSessionManager: a slow Keystore read can block
/// every platform-channel read behind it.
class SecureSessionStore implements SessionStore {
  const SecureSessionStore();

  static const _key = 'v2_session';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());
  static const _readTimeout = Duration(seconds: 5);

  @override
  Future<BrandSession?> read() async {
    try {
      final raw = await _storage.read(key: _key).timeout(_readTimeout);
      if (raw == null) return null;
      final session = BrandSession.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return session.token.isEmpty ? null : session;
    } on TimeoutException {
      return null;
    } catch (e) {
      // A value we can't read is treated as no session: signing in again
      // writes a good one.
      debugPrint('[session] unreadable stored session: $e');
      return null;
    }
  }

  @override
  Future<void> write(BrandSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// For tests.
class MemorySessionStore implements SessionStore {
  MemorySessionStore([this._session]);

  BrandSession? _session;

  @override
  Future<BrandSession?> read() async => _session;

  @override
  Future<void> write(BrandSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
