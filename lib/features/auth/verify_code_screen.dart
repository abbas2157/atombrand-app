import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../data/models/account.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/code_input.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';

/// Where the code went, from the challenge's masked destinations.
String challengeSentText(VerificationChallenge c) {
  final d = c.destinations;
  final parts = [
    if (d['whatsapp'] != null) 'WhatsApp ${d['whatsapp']}',
    if (d['email'] != null) 'email ${d['email']}',
  ];
  if (parts.isEmpty) return "If this account exists, we've sent a 6-digit code. It's valid for 10 minutes.";
  return 'We sent a 6-digit code to ${parts.join(' and ')}. It\'s valid for 10 minutes.';
}

/// Codes exist only where there's no password to check (§6).
enum VerifyMode { reset, apply }

class VerifyArgs {
  VerifyArgs._(this.mode, this.login, this.challenge, {this.applyForm});

  factory VerifyArgs.reset(String login, VerificationChallenge c) => VerifyArgs._(VerifyMode.reset, login, c);
  factory VerifyArgs.apply(Map<String, dynamic> form, VerificationChallenge c) =>
      VerifyArgs._(VerifyMode.apply, form['phone'] as String, c, applyForm: form);

  final VerifyMode mode;

  /// The login (email/phone), or the applicant's phone for [VerifyMode.apply].
  final String login;
  final VerificationChallenge challenge;
  final Map<String, dynamic>? applyForm;
}

/// 6-box code entry with resend cooldown and channel switch (§3.2).
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key, required this.args});

  final VerifyArgs args;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  static const _cooldown = 60;

  final _code = TextEditingController();
  late VerificationChallenge _challenge = widget.args.challenge;
  Timer? _timer;
  int _wait = _cooldown;
  bool _busy = false;
  bool _resending = false;
  String? _error;

  VerifyArgs get _args => widget.args;
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _wait = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _verify(String code) async {
    if (_busy || code.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      switch (_args.mode) {
        case VerifyMode.reset:
          final token = await _repo.verifyResetCode(_args.login, code);
          if (mounted) context.pushReplacement('/new-password', extra: token);
        case VerifyMode.apply:
          final message = await _repo.apply(_args.applyForm!, code);
          if (mounted) context.go('/apply/submitted', extra: message);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _code.clear();
      if (e.isValidation && _args.mode == VerifyMode.apply && e.fieldErrors.keys.any((k) => k != 'otp' && k != 'code')) {
        // A form field was refused: go back so the user can fix it.
        context.pop(e);
        return;
      }
      if (e.isConflict) {
        await showApiError(context, e);
        if (mounted && _args.mode == VerifyMode.apply) context.pop();
        return;
      }
      setState(() => _error = e.fieldError('code') ?? e.fieldError('otp') ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend([String? channel]) async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final c = switch (_args.mode) {
        VerifyMode.reset => await _repo.forgotPassword(_args.login, channel: channel),
        VerifyMode.apply => await _repo.sendApplyCode(
            phone: _args.login,
            email: _args.applyForm?['email'] as String?,
            name: _args.applyForm?['name'] as String?,
            channel: channel,
          ),
      };
      if (!mounted) return;
      // password/forgot never reveals channels; keep what we knew.
      if (c.channels.isNotEmpty) setState(() => _challenge = c);
      _code.clear();
      _startCooldown();
      showToast(context, channel == null ? 'A new code is on its way.' : 'A new code was sent by ${_channelName(channel)}.');
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _channelName(String c) => c == 'whatsapp' ? 'WhatsApp' : 'email';

  @override
  Widget build(BuildContext context) {
    final channels = _challenge.channels;
    return AuthScaffold(
      title: switch (_args.mode) {
        VerifyMode.reset => 'Enter your code',
        VerifyMode.apply => 'Verify your phone',
      },
      icon: _args.mode == VerifyMode.apply ? Icons.verified_user_outlined : Icons.mark_email_unread_outlined,
      subtitle: challengeSentText(_challenge),
      bottom: AuthButton(
        label: _args.mode == VerifyMode.apply ? 'Submit application' : 'Verify',
        busyLabel: 'Verifying…',
        busy: _busy,
        onPressed: () => _verify(_code.text),
      ),
      children: [
        CodeInput(controller: _code, onCompleted: _verify, errorText: _error, enabled: !_busy),
        if (kDebugMode && _challenge.debugCode != null) ...[
          const SizedBox(height: 8),
          Builder(
            builder: (context) => Text(
              'Test server code: ${_challenge.debugCode}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppPalette.of(context).accentInk),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _ResendRow(wait: _wait, onResend: _resending ? null : () => _resend()),
        if (channels.length > 1 && _wait <= 0)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final c in channels)
                TextButton(
                  onPressed: _resending ? null : () => _resend(c),
                  child: Text('Send by ${_channelName(c)} only'),
                ),
            ],
          ),
      ],
    );
  }
}

/// "Didn't get a code? ⏱ Resend in 0:42", then a Resend button.
class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.wait, required this.onResend});
  final int wait;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme.bodyMedium;
    final clock = '${wait ~/ 60}:${(wait % 60).toString().padLeft(2, '0')}';
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text("Didn't get a code?", style: t?.copyWith(color: p.muted)),
        if (wait > 0)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: p.accentInk),
                const SizedBox(width: 5),
                Text(
                  'Resend in $clock',
                  style: t?.copyWith(color: p.text, fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                ),
              ],
            ),
          )
        else
          TextButton(
            onPressed: onResend,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
            child: const Text('Resend code'),
          ),
      ],
    );
  }
}
