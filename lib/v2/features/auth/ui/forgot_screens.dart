import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/ids.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../../core/lock/app_lock.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../data/auth_repository.dart';
import 'auth_parts.dart';

/// Forgot password (4.1–4.4): the email or mobile number and a channel, the
/// 6-digit code, a new password, done. Needs internet throughout.

/// What the flow has gathered so far.
@immutable
class ForgotState {
  const ForgotState({
    this.login = '',
    this.channel = ResetChannel.whatsapp,
    this.codeMinutes = 10,
    this.resetToken,
  });

  final String login;
  final ResetChannel channel;
  final int codeMinutes;
  final String? resetToken;

  ForgotState copyWith({
    String? login,
    ResetChannel? channel,
    int? codeMinutes,
    String? Function()? resetToken,
  }) => ForgotState(
    login: login ?? this.login,
    channel: channel ?? this.channel,
    codeMinutes: codeMinutes ?? this.codeMinutes,
    resetToken: resetToken != null ? resetToken() : this.resetToken,
  );
}

final forgotProvider = NotifierProvider<ForgotFlow, ForgotState>(
  ForgotFlow.new,
);

class ForgotFlow extends Notifier<ForgotState> {
  @override
  ForgotState build() => const ForgotState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Sends (or re-sends) the code. Null on success.
  Future<ApiFailure?> send({String? login, ResetChannel? channel}) async {
    final next = state.copyWith(login: login, channel: channel);
    final result = await _repo.sendResetCode(
      login: next.login,
      channel: next.channel,
    );
    switch (result) {
      case ApiOk(:final value):
        state = next.copyWith(
          codeMinutes: (value / 60).ceil(),
          resetToken: () => null,
        );
        return null;
      case ApiErr(:final failure):
        return failure;
    }
  }

  Future<ApiFailure?> verify(String code) async {
    final result = await _repo.verifyResetCode(login: state.login, code: code);
    switch (result) {
      case ApiOk(:final value):
        state = state.copyWith(resetToken: () => value);
        return null;
      case ApiErr(:final failure):
        return failure;
    }
  }

  Future<ApiFailure?> reset(String password) async {
    final token = state.resetToken;
    if (token == null) return const ApiFailure(ApiFailureKind.validation);
    final result = await _repo.resetPassword(
      resetToken: token,
      password: password,
    );
    if (result case ApiErr(:final failure)) return failure;
    // The saved fingerprint sign-in has the old password: erase it.
    await ref.read(quickSignInProvider.notifier).erase();
    // The token is single use; drop it with the rest of the flow.
    state = const ForgotState();
    return null;
  }
}

/// A failure as one sentence for the person.
String _say(AppLocalizations l, ApiFailure f) => switch (f.kind) {
  ApiFailureKind.offline || ApiFailureKind.timeout => l.signInOffline,
  _ => f.message ?? l.commonSomethingWrong,
};

/// The frame shared by the four steps: a flow bar, a scrolling form, and
/// the buttons at the bottom.
class _Step extends StatelessWidget {
  const _Step({required this.children, required this.bottom, this.onLeading});

  final List<Widget> children;
  final List<Widget> bottom;
  final VoidCallback? onLeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        children: [
          AtomFlowBar(onLeading: onLeading),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AtomSize.formMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AtomSize.formMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < bottom.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      bottom[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _heading(
  String title,
  String body, {
  Widget? icon,
  String? bold,
  double gap = 22,
}) => [
  if (icon != null) ...[icon, const SizedBox(height: 16)],
  Semantics(header: true, child: Text(title, style: AuthText.h1)),
  const SizedBox(height: AtomSpace.s2),
  Text.rich(
    TextSpan(
      style: AuthText.sub,
      children: boldSpans(
        body,
        bold,
        const TextStyle(color: AtomColors.ink, fontWeight: FontWeight.w600),
      ),
    ),
  ),
  SizedBox(height: gap),
];

/// 4.1: email or mobile number, and WhatsApp or email.
class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen> {
  late final _login = TextEditingController(
    text: ref.read(forgotProvider).login,
  );
  ResetChannel _channel = ResetChannel.whatsapp;
  bool _sending = false;
  String? _loginError;
  String? _formError;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  /// An email as typed, or a mobile number as the server stores it.
  static String? _normalise(String input) {
    final s = input.trim();
    if (s.contains('@')) {
      return RegExp(r'^\S+@\S+\.\S+$').hasMatch(s) ? s : null;
    }
    return AtomIds.normaliseMobile(s);
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final login = _normalise(_login.text);
    setState(() {
      _formError = null;
      _loginError = login == null ? l.forgotLoginInvalid : null;
    });
    if (login == null) return;

    setState(() => _sending = true);
    final failure = await ref
        .read(forgotProvider.notifier)
        .send(login: login, channel: _channel);
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure == null) {
      context.push(V2Routes.forgotCode);
      return;
    }
    setState(() {
      _loginError = failure.fieldErrors['login'];
      if (_loginError == null) _formError = _say(l, failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Step(
      onLeading: () =>
          context.canPop() ? context.pop() : context.go(V2Routes.signIn),
      bottom: [
        if (_formError != null)
          AtomNote(kind: AtomNoteKind.problem, message: _formError!),
        AtomButton(label: l.forgotSend, saving: _sending, onPressed: _send),
        Text(
          l.forgotNote,
          textAlign: TextAlign.center,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ],
      children: [
        ..._heading(
          l.forgotTitle,
          l.forgotBody,
          icon: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox.square(
              dimension: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AtomTone.blue.bg,
                  borderRadius: AtomRadius.brCard,
                ),
                child: Center(child: BoardKeyIcon(color: AtomTone.blue.fg)),
              ),
            ),
          ),
        ),
        AtomTextField(
          label: l.forgotLogin,
          controller: _login,
          error: _loginError,
          prefix: const Icon(LucideIcons.user),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 22),
        Text(l.forgotSendBy, style: AtomText.fieldLabel),
        const SizedBox(height: 10),
        AtomOptionCard(
          leading: const AtomIconTile(
            icon: AtomBrandIcons.whatsapp,
            tone: AtomTone.green,
          ),
          title: l.forgotWhatsApp,
          subtitle: l.forgotWhatsAppSub,
          selected: _channel == ResetChannel.whatsapp,
          onTap: () => setState(() => _channel = ResetChannel.whatsapp),
        ),
        const SizedBox(height: 10),
        AtomOptionCard(
          leading: const AtomIconTile(icon: LucideIcons.mail),
          title: l.forgotEmail,
          subtitle: l.forgotEmailSub,
          selected: _channel == ResetChannel.email,
          onTap: () => setState(() => _channel = ResetChannel.email),
        ),
      ],
    );
  }
}

/// 4.2: the 6-digit code, with a resend after a short wait.
class ForgotCodeScreen extends ConsumerStatefulWidget {
  const ForgotCodeScreen({super.key});

  /// How long before "Send it again" opens. The server allows three sends
  /// in ten minutes, so this keeps a person from using them up by accident.
  static const resendAfter = Duration(seconds: 60);

  @override
  ConsumerState<ForgotCodeScreen> createState() => _ForgotCodeScreenState();
}

class _ForgotCodeScreenState extends ConsumerState<ForgotCodeScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _wait = ForgotCodeScreen.resendAfter.inSeconds;

  /// Verify and another code never run together: a code sent while one
  /// is being checked would replace it under the check.
  _CodeBusy _busy = _CodeBusy.idle;
  bool get _verifying => _busy == _CodeBusy.verifying;
  bool get _resending => _busy == _CodeBusy.resending;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _wait = ForgotCodeScreen.resendAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy != _CodeBusy.idle) return;
    final l = AppLocalizations.of(context);
    if (_code.text.length != 6) {
      setState(() => _error = l.codeIncomplete);
      return;
    }
    setState(() {
      _error = null;
      _busy = _CodeBusy.verifying;
    });
    final failure = await ref.read(forgotProvider.notifier).verify(_code.text);
    if (!mounted) return;
    setState(() => _busy = _CodeBusy.idle);
    if (failure == null) {
      context.pushReplacement(V2Routes.forgotNew);
    } else {
      setState(() => _error = failure.fieldErrors['code'] ?? _say(l, failure));
    }
  }

  Future<void> _resend({ResetChannel? channel}) async {
    if (_busy != _CodeBusy.idle) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = _CodeBusy.resending;
      _error = null;
    });
    final failure = await ref
        .read(forgotProvider.notifier)
        .send(channel: channel);
    if (!mounted) return;
    setState(() => _busy = _CodeBusy.idle);
    if (failure != null) {
      setState(() => _error = _say(l, failure));
      return;
    }
    _code.clear();
    _startTimer();
    showAtomToast(context, kind: AtomToastKind.ok, message: l.codeSentAgain);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final flow = ref.watch(forgotProvider);
    final byWhatsApp = flow.channel == ResetChannel.whatsapp;
    final wait = '${_wait ~/ 60}:${(_wait % 60).toString().padLeft(2, '0')}';

    return _Step(
      bottom: [
        AtomButton(label: l.codeVerify, saving: _verifying, onPressed: _verify),
        AtomButton(
          label: byWhatsApp ? l.codeByEmail : l.codeByWhatsApp,
          icon: byWhatsApp ? null : AtomBrandIcons.whatsapp,
          kind: AtomButtonKind.outline,
          // Another code, so the same wait as Resend: the server sends three
          // a person in ten minutes, whichever way, and switching back and
          // forth used them up and locked the person out.
          onPressed: _busy != _CodeBusy.idle || _wait > 0
              ? null
              : () => _resend(
                  channel: byWhatsApp
                      ? ResetChannel.email
                      : ResetChannel.whatsapp,
                ),
        ),
      ],
      children: [
        ..._heading(
          l.codeTitle,
          byWhatsApp ? l.codeSentWhatsApp : l.codeSentEmail,
          gap: 24,
          icon: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AtomIconTile(
              icon: byWhatsApp ? AtomBrandIcons.whatsapp : LucideIcons.mail,
              tone: byWhatsApp ? AtomTone.green : AtomTone.blue,
              size: 52,
            ),
          ),
        ),
        AtomCodeInput(
          controller: _code,
          error: _error != null,
          semanticLabel: l.codeLabel,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Semantics(liveRegion: true, child: AtomFieldError(_error!)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                l.codeDidntGet,
                style: AtomText.body.copyWith(color: AtomColors.muted),
              ),
            ),
            if (_wait > 0)
              Text(
                l.codeResendIn(wait),
                style: AtomText.body.copyWith(
                  color: AtomColors.faint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              AtomButton.small(
                label: l.codeResend,
                saving: _resending,
                onPressed: () => _resend(),
              ),
          ],
        ),
        const SizedBox(height: 20),
        AtomNote(
          kind: AtomNoteKind.info,
          message: l.codeNote(flow.codeMinutes),
        ),
      ],
    );
  }
}

/// 4.3: the new password, twice.
class ForgotNewPasswordScreen extends ConsumerStatefulWidget {
  const ForgotNewPasswordScreen({super.key});

  @override
  ConsumerState<ForgotNewPasswordScreen> createState() =>
      _ForgotNewPasswordScreenState();
}

class _ForgotNewPasswordScreenState
    extends ConsumerState<ForgotNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    // A mismatch is checked on Save; retyping clears the old one.
    _confirm.addListener(() {
      if (_confirmError != null) setState(() => _confirmError = null);
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    // The keyboard goes, so an error under the second box isn't hidden
    // behind the button.
    FocusScope.of(context).unfocus();
    setState(() {
      _formError = null;
      _passwordError = _password.text.length < 8
          ? l.agentPasswordTooShort
          : null;
      _confirmError = _passwordError == null && _confirm.text != _password.text
          ? l.agentPasswordMismatch
          : null;
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _saving = true);
    final failure = await ref
        .read(forgotProvider.notifier)
        .reset(_password.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure == null) {
      context.go(V2Routes.forgotDone);
      return;
    }
    setState(() {
      _passwordError = failure.fieldErrors['password'];
      // An expired reset says so in the server's words ("request a new
      // code"); Back returns to the code step for that.
      if (_passwordError == null) _formError = _say(l, failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final login = ref.watch(forgotProvider).login;
    return AutofillGroup(
      child: _Step(
        bottom: [
          if (_formError != null)
            AtomNote(kind: AtomNoteKind.problem, message: _formError!),
          AtomButton(
            label: l.newPasswordSave,
            saving: _saving,
            onPressed: _save,
          ),
        ],
        children: [
          ..._heading(l.newPasswordTitle, l.newPasswordFor(login), bold: login),
          AtomPasswordField(
            label: l.agentPasswordNew,
            controller: _password,
            error: _passwordError,
            hint: l.agentPasswordHint,
            showStrength: true,
            newPassword: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          AtomPasswordField(
            label: l.agentPasswordConfirm,
            controller: _confirm,
            error: _confirmError,
            newPassword: true,
            reveal: false,
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    );
  }
}

/// 4.4: done; sign in with the new password. The server signs out every
/// phone with the reset but doesn't say how many, so the card doesn't
/// either.
class ForgotDoneScreen extends ConsumerWidget {
  const ForgotDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Reset from the lock ("Forgot PIN?", then Forgot password): the PIN on
    // this phone stays for the same person.
    final lock = ref.watch(appLockProvider);
    final pinKept = lock.passwordMode;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(V2Routes.signIn);
      },
      child: Scaffold(
        backgroundColor: AtomColors.paper,
        body: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: AuthScrollBody(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const SizedBox(height: 24),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AtomColors.greenSoft,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AtomColors.greenHalo, spreadRadius: 10),
                  ],
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 40,
                  color: AtomColors.green,
                ),
              ),
              const SizedBox(height: 30),
              Semantics(
                header: true,
                child: Text(
                  l.passwordDoneTitle,
                  textAlign: TextAlign.center,
                  style: AuthText.h1,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: Text(
                  pinKept
                      ? '${l.passwordDoneBody} ${l.auth2DonePinKept}'
                      : l.passwordDoneBody,
                  textAlign: TextAlign.center,
                  style: AuthText.sub,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(AtomSpace.inset),
                decoration: AtomDecor.card,
                child: Row(
                  children: [
                    const AtomIconTile(
                      icon: LucideIcons.smartphone,
                      tone: AtomTone.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.auth2DoneOthersTitle,
                            style: AtomText.listTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(l.auth2DoneOthersSub, style: AuthText.small),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AtomButton(
                  label: l.signInButton,
                  onPressed: () => context.go(V2Routes.signIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CodeBusy { idle, verifying, resending }
