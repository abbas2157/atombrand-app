import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/push.dart';
import '../../core/session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';
import 'google_sign_in_button.dart';

/// F1: email or phone + password. No code at login (§6.1).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  ApiException? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
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
      title: 'Welcome back',
      subtitle: 'Sign in with the email or phone number linked to your brand.',
      footer: const PartnerLink(),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (authError != null) ...[
                  InfoBanner(authError, icon: Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _login,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username, AutofillHints.email, AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: 'Email or phone',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    hintText: 'you@brand.pk or 0300 1234567',
                    errorText: _error?.fieldError('login'),
                  ),
                  validator: loginValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    errorText: _error?.fieldError('password'),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => requiredValidator(v, 'Password'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => context.push('/forgot'), child: const Text('Forgot password?')),
                ),
                const SizedBox(height: 8),
                BusyButton(label: 'Sign in', busy: _busy, onPressed: _submit),
                const OrDivider(),
                const GoogleSignInButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
