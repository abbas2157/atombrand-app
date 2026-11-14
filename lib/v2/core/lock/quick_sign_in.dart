import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../session/session.dart';
import '../session/session_controller.dart';
import 'app_lock.dart';
import 'bio_prompt.dart';

/// Sign in with the fingerprint after signing out (2.1 → 3.0): the login and
/// password are kept on this phone behind the fingerprint. On Android the
/// AES key is hardware-backed and released only after a strong biometric;
/// on iOS the Keychain item needs the current set of fingerprints or face.
///
/// The password never goes anywhere but this store and the login call, and
/// is never logged.

/// Who the saved sign-in belongs to. Not secret: 3.0 shows it before the
/// fingerprint ("Welcome back, Asad", "Madina Electronics · Main shop").
@immutable
class QuickProfile {
  const QuickProfile({
    required this.userId,
    required this.firstName,
    required this.shopLine,
    required this.isOwner,
  });

  final int userId;
  final String firstName;
  final String shopLine;
  final bool isOwner;

  Map<String, Object?> toJson() => {
    'user': userId,
    'name': firstName,
    'shop': shopLine,
    'owner': isOwner,
  };

  static QuickProfile? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['user'];
    if (id is! num) return null;
    return QuickProfile(
      userId: id.toInt(),
      firstName: '${raw['name'] ?? ''}',
      shopLine: '${raw['shop'] ?? ''}',
      isOwner: raw['owner'] == true,
    );
  }
}

/// The secret part: what `login` takes.
@immutable
class QuickSecret {
  const QuickSecret({required this.login, required this.password});
  final String login;
  final String password;

  @override
  String toString() => 'QuickSecret(•••)';
}

/// What the fingerprint did.
sealed class QuickResult {
  const QuickResult();
}

final class QuickOk extends QuickResult {
  const QuickOk([this.secret]);

  /// Set on a read.
  final QuickSecret? secret;
}

/// The person closed the prompt, or it didn't recognise them.
final class QuickCancelled extends QuickResult {
  const QuickCancelled();
}

/// The phone's fingerprints changed (the key is invalidated) or there are
/// none any more: the saved password is gone.
final class QuickKeyChanged extends QuickResult {
  const QuickKeyChanged();
}

/// Anything else (the sensor is locked out after too many tries).
final class QuickFailed extends QuickResult {
  const QuickFailed();
}

/// The three texts of the system prompt.
typedef QuickPrompt = ({String title, String subtitle, String cancel});

abstract interface class QuickSignInStore {
  /// Who is saved, without a prompt; null when nothing is.
  Future<QuickProfile?> profile();

  /// Saves both parts. Shows the fingerprint prompt.
  Future<QuickResult> save(
    QuickProfile profile,
    QuickSecret secret,
    QuickPrompt prompt,
  );

  /// Reads the secret. Shows the fingerprint prompt.
  Future<QuickResult> read(QuickPrompt prompt);

  /// Forgets it, without a prompt.
  Future<void> erase();
}

/// The phone's store.
///
/// The plugin keeps a namespace unlocked for the rest of the process once
/// the fingerprint released its key, and asks for the fingerprint before
/// any call, a delete included. So:
/// - after the first unlock, each later read asks [Biometrics] first, so
///   every sign-in still takes a fingerprint;
/// - erasing drops the profile (in normal secure storage) at once, so the
///   app never offers or reads the secret again, and deletes the secret
///   itself when the namespace is already unlocked, or the next time it is
///   (the next save overwrites it anyway).
class SecureQuickSignInStore implements QuickSignInStore {
  SecureQuickSignInStore(this._biometrics);
  final Biometrics _biometrics;

  static const _profileKey = 'v2_quick_sign_in_profile';
  static const _staleKey = 'v2_quick_sign_in_stale';
  static const _secretKey = 'quick_sign_in';
  static const _plain = FlutterSecureStorage(aOptions: AndroidOptions());

  static FlutterSecureStorage _secure(QuickPrompt p) => FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      // A fresh namespace has no algorithm markers. With migration on, the
      // plugin runs a migration that needs its own fingerprint, so a cancel
      // there resets and asks again; off, the first prompt is the only one.
      // A key invalidated by new fingerprints is still reset (resetOnError).
      migrateOnAlgorithmChange: false,
      biometricType: AndroidBiometricType.strongBiometricOnly,
      storageNamespace: FingerprintVault.namespace,
      biometricPromptTitle: p.title,
      biometricPromptSubtitle: p.subtitle,
      biometricPromptNegativeButton: p.cancel,
    ),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      accessControlFlags: [AccessControlFlag.biometryCurrentSet],
    ),
  );

  @override
  Future<QuickProfile?> profile() async {
    try {
      final raw = await _plain.read(key: _profileKey);
      return raw == null ? null : QuickProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<QuickResult> save(
    QuickProfile profile,
    QuickSecret secret,
    QuickPrompt prompt,
  ) async {
    final value = jsonEncode({'l': secret.login, 'p': secret.password});
    try {
      await _untilPromptCloses(
        _secure(prompt).write(key: _secretKey, value: value),
      );
      FingerprintVault.unlocked = true;
      await _plain.write(key: _profileKey, value: jsonEncode(profile.toJson()));
      await _plain.delete(key: _staleKey);
    } on PlatformException catch (e) {
      return _classify(e);
    } on Exception catch (e) {
      // No plugin (an odd platform): nothing is saved.
      debugPrint('[quick sign-in] could not save: ${e.runtimeType}');
      return const QuickFailed();
    }
    return const QuickOk();
  }

  @override
  Future<QuickResult> read(QuickPrompt prompt) async {
    if (await profile() == null) return const QuickKeyChanged();
    // Already unlocked in this process: the plugin won't ask again.
    if (FingerprintVault.unlocked && !await _biometrics.check(prompt.title)) {
      return const QuickCancelled();
    }
    String? raw;
    try {
      raw = await _untilPromptCloses(_secure(prompt).read(key: _secretKey));
    } on PlatformException catch (e) {
      final r = _classify(e);
      if (r is QuickKeyChanged) await erase();
      return r;
    } on Exception catch (e) {
      debugPrint('[quick sign-in] could not read: ${e.runtimeType}');
      return const QuickFailed();
    }
    FingerprintVault.unlocked = true;
    // The plugin resets a namespace whose key was invalidated (new
    // fingerprints), so the secret comes back empty.
    final map = raw == null ? null : jsonDecode(raw);
    if (map is! Map || map['l'] is! String || map['p'] is! String) {
      await erase();
      return const QuickKeyChanged();
    }
    return QuickOk(
      QuickSecret(login: map['l'] as String, password: map['p'] as String),
    );
  }

  @override
  Future<void> erase() async {
    try {
      await _plain.delete(key: _profileKey);
      if (FingerprintVault.unlocked) {
        try {
          await _secure(_silent).delete(key: _secretKey);
          await _plain.delete(key: _staleKey);
          return;
        } catch (_) {}
      }
      // Overwritten by the next save, or deleted the next time it unlocks.
      await _plain.write(key: _staleKey, value: '1');
    } catch (e) {
      debugPrint('[quick sign-in] could not erase: ${e.runtimeType}');
    }
  }

  /// [call], or a cancel when the fingerprint prompt has closed and [call]
  /// still hasn't answered a moment later. On some phones the plugin never
  /// answers a prompt closed with Cancel or Back, which left Continue on
  /// 2.4 (and the circle on 3.0) waiting for good.
  static Future<T> _untilPromptCloses<T>(Future<T> call) =>
      untilPromptCloses(call);

  /// No prompt shows for an unlocked namespace; the texts are unused.
  static const QuickPrompt _silent = (title: '', subtitle: '', cancel: '');

  /// The plugin's errors: `Biometric authentication error [code]: …` from
  /// Android's BiometricPrompt, `BIOMETRIC_UNAVAILABLE` / none enrolled, or
  /// the Keychain's.
  static QuickResult _classify(PlatformException e) => switch (classifyBio(e)) {
    BioFailure.cancelled => const QuickCancelled(),
    BioFailure.keyChanged => const QuickKeyChanged(),
    BioFailure.failed => const QuickFailed(),
  };
}

/// For tests: in memory, with the prompt's answer chosen.
class MemoryQuickSignIn implements QuickSignInStore {
  MemoryQuickSignIn({this.saved, this.secret});
  QuickProfile? saved;
  QuickSecret? secret;

  /// What the next prompt does.
  QuickResult Function() next = () => const QuickOk();
  int prompts = 0;

  @override
  Future<QuickProfile?> profile() async => saved;

  @override
  Future<QuickResult> save(
    QuickProfile profile,
    QuickSecret secret,
    QuickPrompt prompt,
  ) async {
    prompts++;
    final r = next();
    if (r is! QuickOk) return r;
    saved = profile;
    this.secret = secret;
    return const QuickOk();
  }

  @override
  Future<QuickResult> read(QuickPrompt prompt) async {
    if (saved == null) return const QuickKeyChanged();
    prompts++;
    final r = next();
    if (r is QuickKeyChanged) await erase();
    if (r is! QuickOk) return r;
    return QuickOk(secret);
  }

  @override
  Future<void> erase() async {
    saved = null;
    secret = null;
  }
}

final quickSignInStoreProvider = Provider<QuickSignInStore>(
  (ref) => SecureQuickSignInStore(ref.read(biometricsProvider)),
);

/// The saved sign-in's profile, as the screens see it.
@immutable
class QuickSignInState {
  const QuickSignInState({this.loaded = false, this.profile});
  final bool loaded;
  final QuickProfile? profile;

  bool get saved => profile != null;
}

final quickSignInProvider =
    NotifierProvider<QuickSignInController, QuickSignInState>(
      QuickSignInController.new,
    );

class QuickSignInController extends Notifier<QuickSignInState> {
  QuickSignInStore get _store => ref.read(quickSignInStoreProvider);

  @override
  QuickSignInState build() {
    // Someone else signing in on this phone: the saved sign-in isn't theirs.
    ref.listen(sessionProvider, (before, now) {
      final p = state.profile;
      if (p != null && now is SignedIn && now.session.userId != p.userId) {
        erase();
      }
    });
    _load();
    return const QuickSignInState();
  }

  Future<void> _load() async {
    final p = await _store.profile();
    if (!state.loaded) state = QuickSignInState(loaded: true, profile: p);
  }

  /// "Asad", "Madina Electronics · Main shop".
  static QuickProfile profileOf(BrandSession s, {required String mainShop}) =>
      QuickProfile(
        userId: s.userId,
        firstName: s.firstName,
        isOwner: s.who.isOwner,
        shopLine: [
          if (s.brandName != null) s.brandName!,
          s.who.isOwner ? (s.outletName ?? mainShop) : s.outletName,
        ].whereType<String>().join(' · '),
      );

  Future<QuickResult> save(
    QuickProfile profile,
    QuickSecret secret,
    QuickPrompt prompt,
  ) async {
    final r = await _store.save(profile, secret, prompt);
    if (r is QuickOk) {
      state = QuickSignInState(loaded: true, profile: profile);
    } else if (r is QuickKeyChanged) {
      await erase();
    }
    return r;
  }

  Future<QuickResult> read(QuickPrompt prompt) async {
    final r = await _store.read(prompt);
    if (r is QuickKeyChanged) {
      state = const QuickSignInState(loaded: true);
    }
    return r;
  }

  Future<void> erase() async {
    state = const QuickSignInState(loaded: true);
    await _store.erase();
  }
}

/// The login and password typed at sign-in (or the agent's new one from
/// 2.3), in memory only, for 2.4's "Open with fingerprint". Cleared when
/// the PIN step ends or the person signs out.
final pendingSignInProvider = NotifierProvider<PendingSignIn, QuickSecret?>(
  PendingSignIn.new,
);

class PendingSignIn extends Notifier<QuickSecret?> {
  @override
  QuickSecret? build() {
    ref.listen(sessionProvider, (before, now) {
      if (now is SignedOut) state = null;
    });
    return null;
  }

  void keep(String login, String password) =>
      state = QuickSecret(login: login, password: password);

  /// The agent chose their own password (2.3).
  void newPassword(String password) {
    final s = state;
    if (s != null) state = QuickSecret(login: s.login, password: password);
  }

  void forget() => state = null;
}
