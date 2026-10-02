import 'package:google_sign_in/google_sign_in.dart';

import 'env.dart';

/// Thrown when Google sign-in can't run on this build or device.
class GoogleAuthUnavailable implements Exception {
  const GoogleAuthUnavailable(this.message);
  final String message;
}

/// Shows Google's account picker and returns an ID token for the server, or
/// null when the user backs out.
class GoogleAuth {
  GoogleAuth._();

  static bool get isConfigured => Env.googleServerClientId.isNotEmpty;

  static Future<void>? _init;

  static Future<String?> idToken() async {
    if (!isConfigured) {
      throw const GoogleAuthUnavailable("Google sign-in isn't set up in this version of the app yet.");
    }
    final google = GoogleSignIn.instance;
    await (_init ??= google.initialize(serverClientId: Env.googleServerClientId));
    if (!google.supportsAuthenticate()) {
      throw const GoogleAuthUnavailable("Google sign-in isn't supported on this device.");
    }
    try {
      // Always ask which account, so a partner with two Google accounts can pick.
      await google.signOut();
      final account = await google.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const GoogleAuthUnavailable("Google sign-in isn't set up correctly. Please sign in with your password.");
      }
      throw const GoogleAuthUnavailable("Couldn't reach Google. Please try again.");
    }
  }
}
