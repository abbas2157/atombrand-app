import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';

/// F3, last step: set a new password with the 15-minute reset token.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  ApiException? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(widget.resetToken, _password.text, _confirm.text);
      if (!mounted) return;
      showToast(context, 'Password updated. All devices were signed out. Sign in with your new password.');
      context.go('/welcome');
      context.push('/sign-in');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty || e.fieldError('reset_token') != null) {
        await showApiError(context, e.fieldError('reset_token') != null
            ? ApiException('This reset link has expired. Please request a new code.', statusCode: 422)
            : e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a new password',
      icon: Icons.password_rounded,
      subtitle: 'Saving signs you out on every device.',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    helperText: 'At least 8 characters',
                    errorText: _error?.fieldError('password'),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: passwordValidator,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v != _password.text ? "Passwords don't match." : null,
                ),
                const SizedBox(height: 24),
                BusyButton(label: 'Save password', busy: _busy, onPressed: _save),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
