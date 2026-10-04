import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../data/models/account.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/feedback.dart';
import 'auth_field.dart';
import 'auth_illustrations.dart';
import 'auth_scaffold.dart';
import 'verify_code_screen.dart';

/// F2: forgot password. Asks for the login, sends a reset code (§6.2), then
/// confirms it was sent before moving on to the code.
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
  bool _submitted = false;
  ApiException? _error;

  /// Set once the code is sent; switches to the "check your messages" state.
  VerificationChallenge? _sent;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .forgotPassword(_login.text.trim(), channel: _channel == 'any' ? null : _channel);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() => _sent = challenge);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
      if (e.fieldErrors.isEmpty) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _sent == null ? _buildForm(context) : _buildSent(context, _sent!);

  Widget _buildForm(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password?',
      icon: Icons.key_rounded,
      subtitle: "Enter the email or phone linked to your account and we'll send you a code to reset your password.",
      bottom: AuthButton(label: 'Send Reset Code', busyLabel: 'Sending code…', busy: _busy, onPressed: _send),
      children: [
        Form(
          key: _form,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                label: 'Email or phone',
                controller: _login,
                icon: Icons.mail_outline_rounded,
                hint: 'you@brand.pk or 0300 1234567',
                autofocus: true,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.username],
                onSubmitted: (_) => _send(),
                errorText: _error?.fieldError('login'),
                validator: loginValidator,
              ),
              const SizedBox(height: 20),
              const AuthFieldLabel('Send the code by'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'any', label: Text('Both')),
                  ButtonSegment(value: 'whatsapp', label: Text('WhatsApp')),
                  ButtonSegment(value: 'email', label: Text('Email')),
                ],
                selected: {_channel},
                showSelectedIcon: false,
                onSelectionChanged: _busy ? null : (s) => setState(() => _channel = s.first),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSent(BuildContext context, VerificationChallenge challenge) {
    final login = _login.text.trim();
    return AuthScaffold(
      bottom: Builder(builder: (context) {
        final p = AppPalette.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthButton(
              label: 'Enter Code',
              onPressed: () => context.pushReplacement('/verify', extra: VerifyArgs.reset(login, challenge)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => context.pop(), child: const Text('Back to Sign In')),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text("Didn't get it? Check spam or", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted)),
                TextButton(
                  onPressed: () => setState(() => _sent = null),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                  child: const Text('send again'),
                ),
              ],
            ),
          ],
        );
      }),
      children: [
        const SizedBox(height: 12),
        const Center(child: InboxIllustration()),
        const SizedBox(height: 24),
        Builder(
          builder: (context) => Text('Check your messages', textAlign: TextAlign.center, style: authTitleStyle(context)),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (context) => Text(challengeSentText(challenge), textAlign: TextAlign.center, style: authSubtitleStyle(context)),
        ),
      ],
    );
  }
}
