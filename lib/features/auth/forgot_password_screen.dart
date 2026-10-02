import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';
import 'verify_code_screen.dart';

/// F2: forgot password. Asks for the login, then sends a reset code (§6.2).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  String _channel = 'any';
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final login = _login.text.trim();
      final challenge = await ref
          .read(authRepositoryProvider)
          .forgotPassword(login, channel: _channel == 'any' ? null : _channel);
      if (!mounted) return;
      context.push('/verify', extra: VerifyArgs.reset(login, challenge));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset your password',
      icon: Icons.lock_reset_rounded,
      subtitle: "Enter your email or phone. We'll send a 6-digit code to reset your password.",
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _login,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.username],
                onFieldSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  labelText: 'Email or phone',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  hintText: 'you@brand.pk or 0300 1234567',
                  errorText: _error?.fieldError('login'),
                ),
                validator: loginValidator,
              ),
              const SizedBox(height: 16),
              Text('Send the code by', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'any', label: Text('Both')),
                  ButtonSegment(value: 'whatsapp', label: Text('WhatsApp')),
                  ButtonSegment(value: 'email', label: Text('Email')),
                ],
                selected: {_channel},
                onSelectionChanged: (s) => setState(() => _channel = s.first),
              ),
              const SizedBox(height: 24),
              BusyButton(label: 'Send code', busy: _busy, onPressed: _send),
            ],
          ),
        ),
      ],
    );
  }
}
