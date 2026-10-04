import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/feedback.dart';
import 'auth_field.dart';
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
  bool _submitted = false;
  ApiException? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _confirmMatches => _confirm.text.isNotEmpty && _confirm.text == _password.text;

  /// Shown as soon as the confirmation is as long as the password.
  bool get _confirmMismatch =>
      _confirm.text.isNotEmpty && _confirm.text.length >= _password.text.length && _confirm.text != _password.text;

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
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
      bottom: AuthButton(label: 'Save password', busyLabel: 'Saving…', busy: _busy, onPressed: _save),
      children: [
        Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthField(
                  label: 'New password',
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 72), // keeps the meter in view
                  errorText: _error?.fieldError('password'),
                  validator: passwordValidator,
                  below: PasswordStrengthMeter(controller: _password),
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'Confirm new password',
                  controller: _confirm,
                  icon: Icons.lock_outline_rounded,
                  password: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                  errorText: _confirmMismatch ? "Passwords don't match." : null,
                  successText: _confirmMatches ? 'Passwords match' : null,
                  validator: (v) => v != _password.text ? "Passwords don't match." : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
