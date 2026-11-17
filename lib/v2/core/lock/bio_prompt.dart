import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// How a read or write behind the fingerprint ended, when it did not work.
enum BioFailure {
  /// Cancel, Back, the negative button, or the prompt timing out.
  cancelled,

  /// The key behind it is gone: new fingerprints, none enrolled any more,
  /// or the entry was never there. Asking again will not help.
  keyChanged,

  /// Anything else.
  failed,
}

/// The one place behind the fingerprint: the saved sign-in and the copy's
/// key both live in it. Android's secure storage asks for the fingerprint
/// once per place and run, so one place means one prompt when security is
/// set up, where two places asked twice in a row (seen on a OnePlus, 9 Nov).
///
/// The name is quick sign-in's, already on phones; the copy's key moved in.
abstract final class FingerprintVault {
  static const namespace = 'quick_sign_in';

  /// Opened in this run: the plugin will not ask again, so whoever reads
  /// next must check the fingerprint itself first.
  static bool unlocked = false;
}

/// [call], or a cancel when the fingerprint prompt has closed and [call]
/// still has not answered a moment later.
///
/// On some phones the secure storage plugin never answers a prompt closed
/// with Cancel or Back, which would leave whatever was waiting on it
/// waiting for good. Shared by quick sign-in and the copy's key, so the
/// two cannot drift apart on a phone that behaves this way.
Future<T> untilPromptCloses<T>(Future<T> call) {
  final done = Completer<T>();
  var away = false;
  Timer? grace;
  late final AppLifecycleListener listener;
  void finish() {
    grace?.cancel();
    listener.dispose();
  }

  listener = AppLifecycleListener(
    onInactive: () => away = true,
    onResume: () {
      if (!away || done.isCompleted) return;
      grace?.cancel();
      grace = Timer(const Duration(seconds: 3), () {
        if (done.isCompleted) return;
        finish();
        done.completeError(
          PlatformException(code: 'cancel', message: 'Prompt closed'),
        );
      });
    },
  );
  call.then(
    (v) {
      if (done.isCompleted) return;
      finish();
      done.complete(v);
    },
    onError: (Object e, StackTrace st) {
      if (done.isCompleted) return;
      finish();
      done.completeError(e, st);
    },
  );
  return done.future;
}

/// The plugin's errors: `Biometric authentication error [code]: …` from
/// Android's BiometricPrompt, `BIOMETRIC_UNAVAILABLE` / none enrolled, or
/// the Keychain's.
BioFailure classifyBio(PlatformException e) {
  final text = '${e.code} ${e.message}';
  final code = RegExp(r'error \[(\d+)\]').firstMatch(text)?.group(1);
  switch (code) {
    // Canceled, user canceled, negative button, timeout.
    case '5' || '10' || '13' || '3':
      return BioFailure.cancelled;
    // No fingerprints enrolled any more.
    case '11':
      return BioFailure.keyChanged;
  }
  if (RegExp(
    'UNAVAILABLE|NONE_ENROLLED|KeyPermanentlyInvalidated|-25293|errSecItemNotFound',
    caseSensitive: false,
  ).hasMatch(text)) {
    return BioFailure.keyChanged;
  }
  if (RegExp('cancel|-128', caseSensitive: false).hasMatch(text)) {
    return BioFailure.cancelled;
  }
  debugPrint('[biometric] ${e.code}');
  return BioFailure.failed;
}
