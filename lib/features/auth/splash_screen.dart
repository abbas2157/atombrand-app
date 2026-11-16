import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import 'auth_scaffold.dart';

/// Shown while the stored token is validated (§5.4).
///
/// The lockup is anchored to the exact centre of the screen so it lands on
/// the same pixels as the native launch screen (`flutter_native_splash`,
/// same white, same 150 px lockup). The status area sits below it without
/// moving it, so the handover from native splash to Flutter is invisible.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  /// Matches the lockup height baked into the native launch screen.
  static const _lockupHeight = 150.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return AuthTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            const Center(child: BrandLogo.lockup(height: _lockupHeight)),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 56),
                  child: _Status(session),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spinner while loading; message + recovery actions when the server can't
/// be reached with a token in hand.
class _Status extends ConsumerWidget {
  const _Status(this.session);

  final SessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = session;
    if (s is! SessionUnreachable) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.message, textAlign: TextAlign.center, style: authSubtitleStyle(t)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => ref.read(sessionProvider.notifier).bootstrap(),
            child: const Text('Try again'),
          ),
        ),
        TextButton(
          onPressed: () => ref.read(sessionProvider.notifier).signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
