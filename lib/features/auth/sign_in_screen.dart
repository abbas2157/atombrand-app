import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/push.dart';
import '../../core/session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/feedback.dart';
import 'auth_field.dart';
import 'auth_scaffold.dart';
import 'google_sign_in_button.dart';

/// F1: email or phone + password. No code at login (§6.1).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  // Keeps the Sign In button in view above the keyboard while typing.
  static const _revealButton = EdgeInsets.fromLTRB(20, 20, 20, 140);

  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _submitted = false;
  ApiException? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fcm = await ref.read(pushServiceProvider).currentToken();
      final session = await ref.read(authRepositoryProvider).login(_login.text, _password.text, fcmToken: fcm);
      if (!mounted) return;
      await ref.read(sessionProvider.notifier).signIn(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty && e.statusCode != 401) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authError = _error?.statusCode == 401 ? _error!.message : null;
    return AuthScaffold(
      showLogo: true,
      title: 'Welcome back',
      subtitle: 'Sign in with the email or phone number linked to your brand.',
      footer: AuthFooterLink(
        prompt: "Don't have an account?",
        action: 'Sign up',
        // Swap rather than stack, so Back from either returns to Welcome.
        onPressed: () => context.pushReplacement('/sign-up'),
      ),
      children: [
        Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (authError != null) ...[
                  AuthBanner(authError),
                  const SizedBox(height: 16),
                ],
                AuthField(
                  label: 'Email or phone',
                  controller: _login,
                  icon: Icons.mail_outline_rounded,
                  hint: 'you@brand.pk or 0300 1234567',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username, AutofillHints.email, AutofillHints.telephoneNumber],
                  scrollPadding: _revealButton,
                  errorText: _error?.fieldError('login'),
                  validator: loginValidator,
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Password',
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  scrollPadding: _revealButton,
                  onSubmitted: (_) => _submit(),
                  errorText: _error?.fieldError('password'),
                  validator: (v) => v.isEmpty ? 'Enter your password.' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 6),
                AuthButton(label: 'Sign In', busyLabel: 'Signing in…', busy: _busy, onPressed: _submit),
                const SizedBox(height: 28),
                const OrDivider(text: 'or continue with'),
                const SizedBox(height: 20),
                const SocialLoginRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
