import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../lock/bio_prompt.dart';

/// What the fingerprint prompt says when it is asked for the copy's key.
typedef CopyPrompt = ({String title, String subtitle, String cancel});

/// How asking the fingerprint for the copy's key ended.
enum CopyBioResult {
  /// The copy is open.
  opened,

  /// The seller closed the prompt. Nothing changes; they can try again.
  cancelled,

  /// The fingerprint could not give the key — new fingerprints were
  /// enrolled, or the Keystore lost it. The PIN can, so the PIN pad opens.
  usePin,

  /// The phone has a PIN but its key was never wrapped by it (set up
  /// before the wrap, and opened only by fingerprint since). One PIN, once,
  /// wraps it and hands the fingerprint its copy; after that the
  /// fingerprint opens everything as before.
  pinToProtect,
}

/// Thrown when the copy is asked for while its key is wrapped and nothing
/// has unwrapped it yet. The app is locked, or was opened by fingerprint
/// before the fingerprint held a copy of the key.
class CopyLocked implements Exception {
  const CopyLocked();
  @override
  String toString() => 'CopyLocked: the copy opens with the PIN';
}

/// The key the phone's copy is encrypted with, and the PIN that wraps it
/// (`RULES.md` §5).
///
/// **What is wrapped and what is not.** Only the copy — the server's rows,
/// which can always be downloaded again. The outbox has its own file and
/// its own key ([DbKey]) and is never wrapped, so a forgotten PIN costs a
/// download and never a day of collecting.
///
/// **How it is kept.** With no PIN on the phone the key is held as it is,
/// in the Keystore, as before. Once there is a PIN, what is held is the
/// key encrypted (AES-256-GCM) under a key derived from the PIN
/// (PBKDF2-HMAC-SHA256). The plain key is then only ever in memory, from
/// the moment the PIN is entered until the app is closed.
///
/// A four-digit PIN has ten thousand values, so the derivation alone would
/// not stop someone holding the wrapped blob from trying them all. What
/// stops them is that the blob is in the Keystore, which a stolen phone
/// does not give up. The two together are the protection; neither alone.
///
/// **The fingerprint.** It can't derive anything, so when fingerprint
/// unlock is on, a second copy of the key is kept behind the fingerprint
/// in its own Keystore namespace. Reading it *is* the fingerprint unlock:
/// one prompt, not two. If that copy is ever unreadable — new fingerprints,
/// or the Keystore fault seen on an Android 17 emulator — the PIN opens
/// it instead and the fingerprint's copy is written again.
///
/// **Wrong PINs never wipe.** Only the server does. When the wrapped key
/// genuinely can't be opened (Forgot PIN, or someone else signing in on
/// the phone), the copy starts over: a new key, an empty file, and a full
/// download. The outbox is not touched.
abstract final class CopyKey {
  static const _name = 'v2_db_copy_key';
  static const _checkName = 'v2_db_copy_check';
  static const _bioMarkName = 'v2_db_copy_bio';
  static const _bioName = 'db_copy_key';
  static const _stagePubName = 'v2_db_stage_pub';
  static const _keystore = FlutterSecureStorage(aOptions: AndroidOptions());

  /// The Keystore, or — in a host test, which has none — a store that
  /// fails at once. Every caller already handles a failing Keystore (the
  /// copy stays shut and the app carries on), so tests take that path
  /// instead of waiting on a platform call that never answers under the
  /// test clock.
  static _Keys get _store => _noKeystore ? const _NoKeys() : const _Keys();
  static bool _noKeystore = false;

  /// Host tests: behave as a phone whose Keystore is not there. Set once,
  /// in `test/flutter_test_config.dart`.
  @visibleForTesting
  static void noKeystoreForTest() => _noKeystore = true;

  /// Whether a copy with data is on disk.
  static Future<bool> _copyOnDisk() async {
    try {
      final f = await file();
      return await f.exists() && await f.length() > 0;
    } catch (_) {
      return false;
    }
  }

  /// The copy's file. One place, so starting over and opening agree.
  static Future<File> file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'atom_copy.db'));
  }

  static String? _open;

  /// Told whenever the copy opens or closes, for the providers that read
  /// it. Not a Riverpod type: this class is below the app.
  static final ValueNotifier<bool> opened = ValueNotifier(false);

  static void _set(String? key) {
    _open = key;
    opened.value = key != null;
    // Whenever the key is in hand, its public half is kept where a locked
    // phone can reach it, so the background can seal what it fetches.
    if (key != null) _keepStagePublic(key);
  }

  static bool get isOpen => _open != null;

  /// Which copy this is: a short fingerprint of its key, or null while it
  /// is shut. A new key means a new, empty file — after an upgrade, or
  /// after starting over — and the sync engine uses this to tell that its
  /// cursors (kept in the outbox, which outlives the copy) belong to a
  /// copy that is no longer here.
  static String? currentId() {
    final key = _open;
    return key == null ? null : _check(key);
  }

  /// For the copy's database: the key, or [CopyLocked].
  static Future<String> read() async {
    final open = _open;
    if (open != null) return open;
    if (await openIfNotWrapped()) return _open!;
    throw const CopyLocked();
  }

  /// At launch, and whenever no PIN stands in the way: opens the copy when
  /// its key is not wrapped, making one on a phone that has none. True
  /// when the copy is open afterwards.
  static Future<bool> openIfNotWrapped() async {
    if (_open != null) return true;
    try {
      final held = await _store.read(key: _name);
      if (held == null) {
        // A copy already on disk with no key coming back is the Keystore
        // failing, not a new phone: stay shut rather than orphan it.
        if (await _copyOnDisk()) return false;
        final key = _newKey();
        await _store.write(key: _name, value: key);
        await _store.write(key: _checkName, value: _check(key));
        _set(key);
        return true;
      }
      if (_isPlain(held)) {
        _set(held);
        return true;
      }
    } catch (e) {
      debugPrint('[copy] could not read its key: $e');
    }
    return false;
  }

  /// The PIN was entered and matched. Opens the copy, and wraps its key
  /// under [pin] if it was not already — a phone that set its PIN before
  /// this, or whose key was made with no PIN.
  ///
  /// When the wrapped key won't open with [pin] — it was wrapped under a
  /// PIN that is gone — the copy starts over. That is a download, not a
  /// loss: the outbox is somewhere else.
  static Future<void> openWithPin(String pin) async {
    try {
      final held = await _store.read(key: _name);
      String? key = _open;
      // Wrapping costs a derivation, so only when something isn't wrapped
      // yet: no key, a key still held as it is (a phone from before this,
      // or opened at launch with no wrap yet), or a copy that started over.
      var wrap = held == null || _isPlain(held);
      if (key == null && held != null) {
        key = _isPlain(held) ? held : await _unwrap(held, pin);
      }
      if (key == null) {
        // Nothing came back but a copy is on disk: the Keystore failed this
        // launch. Leave both alone; a launch it answers opens them again.
        if (held == null && await _copyOnDisk()) return;
        if (held != null) await startOver();
        key = _newKey();
        wrap = true;
      }
      if (wrap) {
        await _store.write(key: _name, value: await _wrap(key, pin));
        await _store.write(key: _checkName, value: _check(key));
      }
      _set(key);
    } catch (e) {
      // The Keystore itself is failing. The app still opens; the copy
      // stays shut and the server answers instead.
      debugPrint('[copy] could not open with the PIN: $e');
    }
  }

  /// A new PIN while the app is open: the same key, wrapped again under
  /// [pin]. With nothing open (Forgot PIN, a new person) there is no key
  /// to wrap, so the copy starts over under the new PIN.
  static Future<void> rewrap(String pin) async {
    // The Keystore first: with none (a host test, an odd platform) there
    // is nothing to wrap into, and the derivation is not started at all.
    try {
      await _store.read(key: _name);
    } catch (e) {
      debugPrint('[copy] no Keystore to wrap the key in: $e');
      return;
    }
    var key = _open;
    if (key == null) {
      await startOver();
      key = _newKey();
    }
    try {
      await _store.write(key: _name, value: await _wrap(key, pin));
      await _store.write(key: _checkName, value: _check(key));
      _set(key);
    } catch (e) {
      debugPrint('[copy] could not wrap with the new PIN: $e');
    }
  }

  /// The PIN is gone (Remove PIN, or skipped at sign-in). The key goes back
  /// to being held as it is; with no key in hand to do that with, the copy
  /// starts over unwrapped.
  static Future<void> noPin() async {
    var key = _open;
    try {
      final held = await _store.read(key: _name);
      if (key == null && held != null && _isPlain(held)) key = held;
      if (key == null) {
        if (held == null) return;
        await startOver();
        key = _newKey();
      }
      await _store.write(key: _name, value: key);
      await _store.write(key: _checkName, value: _check(key));
      await forgetBiometric();
      _set(key);
    } catch (e) {
      debugPrint('[copy] could not unwrap: $e');
    }
  }

  // ───────────────────────────────────────────────── the fingerprint

  static FlutterSecureStorage _bio(CopyPrompt prompt) {
    if (_noKeystore) throw StateError('no Keystore in this test');
    return _bioStorage(prompt);
  }

  static FlutterSecureStorage _bioStorage(CopyPrompt prompt) =>
      FlutterSecureStorage(
        aOptions: AndroidOptions.biometric(
          enforceBiometrics: true,
          migrateOnAlgorithmChange: false,
          biometricType: AndroidBiometricType.strongBiometricOnly,
          storageNamespace: FingerprintVault.namespace,
          biometricPromptTitle: prompt.title,
          biometricPromptSubtitle: prompt.subtitle,
          biometricPromptNegativeButton: prompt.cancel,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
          accessControlFlags: [AccessControlFlag.biometryCurrentSet],
        ),
      );

  /// Whether the fingerprint is needed to open the copy: its key is
  /// wrapped and not open yet. When false, fingerprint unlock is the plain
  /// check it always was.
  static Future<bool> needsFingerprint() async {
    if (_open != null) return false;
    try {
      final held = await _store.read(key: _name);
      return held != null && !_isPlain(held);
    } catch (_) {
      return false;
    }
  }

  /// The fingerprint unlock, when the copy is shut: one prompt that opens
  /// both the app and the copy.
  static Future<CopyBioResult> openWithBiometrics(CopyPrompt prompt) async {
    try {
      final check = await _store.read(key: _checkName);
      final marked = await _store.read(key: _bioMarkName);
      // Never written for this key: no point asking.
      if (check == null || marked != check) return CopyBioResult.usePin;
      final key = await untilPromptCloses(_bio(prompt).read(key: _bioName));
      FingerprintVault.unlocked = true;
      if (key == null || !_isPlain(key) || _check(key) != check) {
        await _store.delete(key: _bioMarkName);
        return CopyBioResult.usePin;
      }
      _set(key);
      return CopyBioResult.opened;
    } on PlatformException catch (e) {
      final why = classifyBio(e);
      if (why == BioFailure.cancelled) return CopyBioResult.cancelled;
      try {
        await _store.delete(key: _bioMarkName);
      } catch (_) {}
      return CopyBioResult.usePin;
    } catch (e) {
      debugPrint('[copy] the fingerprint could not open it: $e');
      return CopyBioResult.usePin;
    }
  }

  /// Whether the fingerprint holds the current key. False after a new
  /// key, new fingerprints, or before fingerprint unlock was ever on.
  static Future<bool> biometricIsCurrent() async {
    try {
      final check = await _store.read(key: _checkName);
      return check != null && await _store.read(key: _bioMarkName) == check;
    } catch (_) {
      return false;
    }
  }

  /// Keeps the open key behind the fingerprint: when fingerprint unlock is
  /// switched on, and after the PIN had to stand in for it. Asks for the
  /// fingerprint, since writing behind it needs one. False when it could
  /// not; fingerprint unlock still works, the copy just waits for the PIN.
  static Future<bool> keepForBiometrics(CopyPrompt prompt) async {
    final key = _open;
    if (key == null) return false;
    try {
      await untilPromptCloses(_bio(prompt).write(key: _bioName, value: key));
      FingerprintVault.unlocked = true;
      await _store.write(key: _bioMarkName, value: _check(key));
      return true;
    } catch (e) {
      debugPrint('[copy] could not keep the key behind the fingerprint: $e');
      return false;
    }
  }

  /// Fingerprint unlock is off: its copy of the key is no longer wanted.
  /// The entry itself is overwritten the next time it is switched on; the
  /// mark is what says it is current.
  static Future<void> forgetBiometric() async {
    try {
      await _store.delete(key: _bioMarkName);
    } catch (_) {}
  }

  // ───────────────────────────────────────────────── sealed pages

  /// The copy's sealing keys, derived from its key: X25519, so sealing
  /// needs only the public half and opening needs the private one. The
  /// public half is held as it is — it seals and can't open — and the
  /// private half is never stored: it is made again from the key, which
  /// only the PIN gives back.
  static Future<SimpleKeyPair> _stagePair(String key) => X25519()
      .newKeyPairFromSeed(sha256.convert(utf8.encode('stage:$key')).bytes);

  static Future<void> _keepStagePublic(String key) async {
    try {
      final pub = await (await _stagePair(key)).extractPublicKey();
      final text = base64Url.encode(pub.bytes);
      if (await _store.read(key: _stagePubName) != text) {
        await _store.write(key: _stagePubName, value: text);
      }
    } catch (e) {
      debugPrint('[copy] could not keep the sealing key: $e');
    }
  }

  static Future<SecretKey> _stageSecret(
    SimpleKeyPair mine,
    List<int> theirs,
  ) async {
    final shared = await X25519().sharedSecretKey(
      keyPair: mine,
      remotePublicKey: SimplePublicKey(theirs, type: KeyPairType.x25519),
    );
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      nonce: const [],
      info: utf8.encode('atom-stage-v1'),
    );
  }

  /// Which copy is on the phone, readable while it is shut: the same
  /// fingerprint as [currentId], from what is stored. Null with none.
  static Future<String?> storedId() async {
    try {
      return await _store.read(key: _checkName);
    } catch (_) {
      return null;
    }
  }

  /// Seals [text] to the copy, so only the copy's key can open it. Works
  /// with the copy shut — that is what it is for. Null when there is no
  /// sealing key yet (the copy has never been opened on this phone).
  static Future<String?> seal(String text) async {
    try {
      final held = await _store.read(key: _stagePubName);
      if (held == null) return null;
      return await _sealTo(text, base64Url.decode(held));
    } catch (e) {
      debugPrint('[copy] could not seal: $e');
      return null;
    }
  }

  /// Seals [text] to the copy whose key is [key], as the background would
  /// with its public half.
  @visibleForTesting
  static Future<String> sealForTest(String text, String key) async =>
      _sealTo(text, (await (await _stagePair(key)).extractPublicKey()).bytes);

  static Future<String> _sealTo(String text, List<int> theirs) async {
    final mine = await X25519().newKeyPair();
    final secret = await _stageSecret(mine, theirs);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(text),
      secretKey: secret,
    );
    final ephemeral = await mine.extractPublicKey();
    return [
      's1',
      base64Url.encode(ephemeral.bytes),
      base64Url.encode(box.nonce),
      base64Url.encode(box.cipherText),
      base64Url.encode(box.mac.bytes),
    ].join(':');
  }

  /// Opens what [seal] made. Needs the copy open; null when it is shut,
  /// or when [blob] was sealed to a different copy.
  static Future<String?> openSealed(String blob) async {
    final key = _open;
    if (key == null) return null;
    final parts = blob.split(':');
    if (parts.length != 5 || parts[0] != 's1') return null;
    try {
      final secret = await _stageSecret(
        await _stagePair(key),
        base64Url.decode(parts[1]),
      );
      final plain = await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Url.decode(parts[3]),
          nonce: base64Url.decode(parts[2]),
          mac: Mac(base64Url.decode(parts[4])),
        ),
        secretKey: secret,
      );
      return utf8.decode(plain);
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void openForTest(String key) => _open = key;

  // ───────────────────────────────────────────────── starting over

  /// The copy can't be opened any more: its file and its key go, and the
  /// next sync downloads everything into a new one. The outbox is a
  /// different file and is not touched.
  static Future<void> startOver() async {
    _set(null);
    try {
      final f = await file();
      for (final path in [f.path, '${f.path}-wal', '${f.path}-shm']) {
        final part = File(path);
        if (await part.exists()) await part.delete();
      }
    } catch (e) {
      debugPrint('[copy] could not delete the old copy: $e');
    }
    try {
      await _store.delete(key: _name);
      await _store.delete(key: _checkName);
      await _store.delete(key: _bioMarkName);
      await _store.delete(key: _stagePubName);
    } catch (_) {}
  }

  /// Signed out, revoked or wiped: the key goes, which makes the file
  /// unreadable even if it is still on the phone.
  static Future<void> forget() => startOver();

  /// Signed out: the key leaves memory and the copy shuts. Nothing is
  /// deleted — ten wrong PINs sign the phone out, and §5 says wrong PINs
  /// never wipe. A copy nobody can open any more is replaced the first
  /// time a new PIN can't open it ([rewrap]); one the same person can
  /// open again is still there for them.
  static void close() => _set(null);

  /// Whether the key is held as it is — not wrapped. False when nothing is
  /// held or the Keystore can't be read: only a definite yes counts.
  static Future<bool> isHeldPlain() async {
    try {
      final held = await _store.read(key: _name);
      return held != null && _isPlain(held);
    } catch (_) {
      return false;
    }
  }

  /// Whether the key is held wrapped by a PIN, rather than as it is.
  static Future<bool> isWrapped() async {
    try {
      final held = await _store.read(key: _name);
      return held != null && !_isPlain(held);
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static void closeForTest() => _set(null);

  // ───────────────────────────────────────────────── the wrapping

  static const bytes = 32;
  static const _iterations = 100000;
  static const _prefix = 'w1:';

  static bool _isPlain(String held) =>
      held.length == bytes * 2 && RegExp(r'^[0-9a-f]+$').hasMatch(held);

  static String _newKey() {
    final rnd = Random.secure();
    return [
      for (var i = 0; i < bytes; i++)
        rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// A short fingerprint of the key, to tell whether something stored is
  /// for this key. Of a random 256-bit key, so it gives nothing away.
  static String _check(String key) =>
      sha256.convert(utf8.encode('copy:$key')).toString().substring(0, 16);

  /// `w1:<salt>:<nonce>:<cipher text>:<mac>`, each base64.
  @visibleForTesting
  static Future<String> wrapForTest(String key, String pin) => _wrap(key, pin);

  @visibleForTesting
  static Future<String?> unwrapForTest(String blob, String pin) =>
      _unwrap(blob, pin);

  static Future<String> _wrap(String key, String pin) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final secret = await _derive(pin, salt);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(key),
      secretKey: SecretKey(secret),
    );
    return [
      'w1',
      base64Url.encode(salt),
      base64Url.encode(box.nonce),
      base64Url.encode(box.cipherText),
      base64Url.encode(box.mac.bytes),
    ].join(':');
  }

  /// The key under [blob], or null when [pin] is not the one it was
  /// wrapped with.
  static Future<String?> _unwrap(String blob, String pin) async {
    if (!blob.startsWith(_prefix)) return null;
    final parts = blob.split(':');
    if (parts.length != 5) return null;
    try {
      final secret = await _derive(pin, base64Url.decode(parts[1]));
      final plain = await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Url.decode(parts[3]),
          nonce: base64Url.decode(parts[2]),
          mac: Mac(base64Url.decode(parts[4])),
        ),
        secretKey: SecretKey(secret),
      );
      final key = utf8.decode(plain);
      return _isPlain(key) ? key : null;
    } on SecretBoxAuthenticationError {
      return null;
    } catch (e) {
      debugPrint('[copy] could not unwrap: $e');
      return null;
    }
  }

  /// The PIN's key. A hundred thousand rounds take a moment, so they run
  /// off the isolate that draws the screen.
  static Future<List<int>> _derive(String pin, List<int> salt) =>
      Isolate.run(() async {
        final derived = await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: _iterations,
          bits: 256,
        ).deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
        return derived.extractBytes();
      });
}

/// The Keystore entries [CopyKey] keeps.
class _Keys {
  const _Keys();
  Future<String?> read({required String key}) =>
      CopyKey._keystore.read(key: key);
  Future<void> write({required String key, required String? value}) =>
      CopyKey._keystore.write(key: key, value: value);
  Future<void> delete({required String key}) =>
      CopyKey._keystore.delete(key: key);
}

/// No Keystore: every call fails straight away.
class _NoKeys extends _Keys {
  const _NoKeys();
  static Never _none() => throw StateError('no Keystore in this test');
  @override
  Future<String?> read({required String key}) async => _none();
  @override
  Future<void> write({required String key, required String? value}) async =>
      _none();
  @override
  Future<void> delete({required String key}) async => _none();
}
