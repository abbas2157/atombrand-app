import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import 'auth_scaffold.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final t = Theme.of(context).textTheme;
    return AuthTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo.lockup(height: 150),
                  const SizedBox(height: 40),
                  if (session is SessionUnreachable) ...[
                    Text(session.message, textAlign: TextAlign.center, style: authSubtitleStyle(t)),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => ref.read(sessionProvider.notifier).bootstrap(),
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                      child: const Text('Sign out'),
                    ),
                  ] else
                    const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
