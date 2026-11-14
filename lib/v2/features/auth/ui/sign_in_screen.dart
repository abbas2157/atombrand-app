import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/ids.dart';
import '../../../core/lock/app_lock.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/auth_repository.dart';
import 'auth_parts.dart';

/// Atomshop's support line on WhatsApp.
const atomshopSupportPhone = atomshopWhatsApp;

/// Sign in (2.1) and its problems (2.2). Owners sign in with their email,
/// team members with their mobile number; both with a password.
///
/// When the app is locked and the person chose "Sign in with password",
/// this opens over the locked session: Back and "Sign in with fingerprint"
/// return to the lock, and the session is replaced only when a sign-in
/// succeeds.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Who { owner, agent }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  _Who _who = _Who.owner;
  bool _saving = false;
  String? _loginError;
  String? _passwordError;
  String? _formError;

  /// The last call couldn't reach the server.
  bool _callOffline = false;

  /// The server knows the seller, but Atomshop hasn't verified them yet.
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    // Changing what is typed starts again after "being checked".
    void edited() {
      if (_pending) setState(() => _pending = false);
    }

    _login.addListener(edited);
    _password.addListener(edited);
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();

    String? login;
    if (_who == _Who.owner) {
      // The owner's email, or the phone on the brand account.
      final typed = _login.text.trim();
      login = typed.contains('@')
          ? (RegExp(r'^\S+@\S+\.\S+$').hasMatch(typed) ? typed : null)
          : AtomIds.normaliseMobile(typed);
    } else {
      login = AtomIds.normaliseMobile(_login.text);
    }
    setState(() {
      _formError = null;
      _pending = false;
      _loginError = login == null
          ? (_who == _Who.owner ? l.signInEmailInvalid : l.signInMobileInvalid)
          : null;
      _passwordError = _password.text.isEmpty ? l.signInPasswordEmpty : null;
    });
    if (_loginError != null || _passwordError != null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(login: login!, password: _password.text);
    if (!mounted) return;

    switch (result) {
      case ApiOk(:final value):
        _callOffline = false;
        ref.read(quickNoticeProvider.notifier).clear();
        // In memory only, for 2.4's "Open with fingerprint".
        ref.read(pendingSignInProvider.notifier).keep(login, _password.text);
        if (value.who.mustChangePassword) {
          // 2.3 checks the new one isn't this temporary one.
          ref
              .read(lastSignInPasswordProvider.notifier)
              .remember(_password.text);
        }
        // The router takes it from here: the agent's password, the PIN, the
        // shop, the tour, then Home or the screen kept from before.
        await ref.read(sessionProvider.notifier).signIn(value);
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _callOffline = false;
          if (failure.body?['reason'] == unverifiedBrandReason) {
            _pending = true;
            return;
          }
          switch (failure.kind) {
            case ApiFailureKind.signedOut:
              _passwordError = _who == _Who.owner
                  ? l.auth2WrongOwner
                  : l.auth2WrongAgent;
            case ApiFailureKind.validation:
              _loginError =
                  failure.fieldErrors['login'] ?? failure.fieldErrors['email'];
              _passwordError = failure.fieldErrors['password'];
              if (_loginError == null && _passwordError == null) {
                _formError = failure.message ?? l.signInFailed;
              }
            case ApiFailureKind.offline || ApiFailureKind.timeout:
              _callOffline = true;
            case ApiFailureKind.notInRole || ApiFailureKind.ownerOnly:
              // A switched-off agent or a non-seller account: the server
              // says why.
              _formError = failure.message ?? l.signInFailed;
            default:
              _formError = l.signInFailed;
          }
        });
    }
  }

  Future<void> _tryAgain() async {
    ref.invalidate(onlineProvider);
    final online = await ref.read(networkStatusProvider).check();
    if (!mounted || !online) return;
    setState(() => _callOffline = false);
    if (_login.text.isNotEmpty && _password.text.isNotEmpty) await _submit();
  }

  void _back() {
    final lock = ref.read(appLockProvider);
    if (lock.locked && lock.passwordMode) {
      ref.read(appLockProvider.notifier).backToQuickUnlock();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(V2Routes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owner = _who == _Who.owner;
    final online = ref.watch(onlineProvider).value ?? true;
    // The network came back: whatever failed to connect can go again.
    ref.listen(onlineProvider, (before, now) {
      if (now.value == true && before?.value == false && _callOffline) {
        setState(() => _callOffline = false);
      }
    });
    final offline = !online || _callOffline;
    final lock = ref.watch(appLockProvider);
    // Locked, signing in with the password: back to the lock's fingerprint.
    final lockFingerprint =
        lock.locked && lock.passwordMode && lock.fingerprint;
    // Signed out, with a sign-in saved behind the fingerprint: 3.0.
    final quickFingerprint =
        !lockFingerprint &&
        ref.watch(sessionProvider) is SignedOut &&
        ref.watch(quickSignInProvider).saved;
    final fingerprint = lockFingerprint || quickFingerprint;
    final notice = ref.watch(quickNoticeProvider);

    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        children: [
          AtomFlowBar(
            leading: AtomFlowLeading.back,
            onLeading: _back,
            trailing: [
              // Expanded (the bar's title is empty), so the pill sits at
              // the end and scales down rather than run off at large text.
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AuthNetworkPill(offline: offline),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: AutofillGroup(
              child: AuthScrollBody(
                children: [
                  // The mark over the heading: the way in carries the
                  // brand from Welcome through to the tour.
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AtomBrandTile(size: 56, onLight: true),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(l.signInTitle, style: AuthText.h1),
                  ),
                  const SizedBox(height: 8),
                  Text(l.signInSubtitle, style: AuthText.sub),
                  const SizedBox(height: 22),
                  if (notice != null && !offline) ...[
                    AuthNote(
                      kind: AtomNoteKind.warning,
                      icon: LucideIcons.fingerprint,
                      text: switch (notice) {
                        QuickNotice.fingerprintsChanged =>
                          l.auth3FingerprintsChanged,
                        QuickNotice.passwordChanged => l.auth3PasswordChanged,
                      },
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (offline) ...[
                    AuthNote(
                      kind: AtomNoteKind.warning,
                      icon: LucideIcons.wifiOff,
                      lead: l.auth2OfflineTitle,
                      text: l.auth2OfflineBody,
                    ),
                    const SizedBox(height: 22),
                  ] else if (_pending) ...[
                    AuthNote(
                      kind: AtomNoteKind.info,
                      icon: LucideIcons.clock,
                      lead: l.auth2PendingTitle,
                      text: l.auth2PendingBody,
                    ),
                    const SizedBox(height: 22),
                  ],
                  AtomSegmented<_Who>(
                    segments: [
                      AtomSegment(
                        _Who.owner,
                        l.signInOwner,
                        icon: LucideIcons.store,
                      ),
                      AtomSegment(
                        _Who.agent,
                        l.signInAgent,
                        icon: LucideIcons.user,
                      ),
                    ],
                    selected: _who,
                    onChanged: (w) => setState(() {
                      _who = w;
                      _login.clear();
                      _loginError = null;
                      _passwordError = null;
                      _formError = null;
                      _pending = false;
                    }),
                  ),
                  const SizedBox(height: 22),
                  AtomTextField(
                    key: ValueKey(_who),
                    label: owner ? l.signInEmail : l.signInMobile,
                    controller: _login,
                    placeholder: owner ? null : '03XX XXXXXXX',
                    hint: owner ? null : l.signInMobileHint,
                    error: _loginError,
                    prefix: Icon(
                      owner ? LucideIcons.mail : LucideIcons.smartphone,
                    ),
                    keyboardType: owner
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    inputFormatters: owner ? null : [MobileInputFormatter()],
                    textInputAction: TextInputAction.next,
                    autofillHints: [
                      owner
                          ? AutofillHints.email
                          : AutofillHints.telephoneNumber,
                    ],
                  ),
                  const SizedBox(height: 14),
                  AtomPasswordField(
                    label: l.signInPassword,
                    controller: _password,
                    error: _passwordError,
                    labelTrailing: AtomPressable(
                      onTap: () => context.push(V2Routes.forgot),
                      semanticLabel: l.signInForgot,
                      scaleOnPress: false,
                      builder: (_, _) => Text(
                        l.signInForgot,
                        style: AtomText.secondary.copyWith(
                          color: AtomColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => offline ? null : _submit(),
                  ),
                  const SizedBox(height: 22),
                  if (_formError != null) ...[
                    AtomNote(kind: AtomNoteKind.problem, message: _formError!),
                    const SizedBox(height: AtomSpace.s3),
                  ],
                  if (offline) ...[
                    AtomButton(
                      label: l.auth2WaitingForInternet,
                      onPressed: null,
                    ),
                    const SizedBox(height: 10),
                    AtomButton(
                      label: l.commonTryAgain,
                      icon: LucideIcons.rotateCw,
                      kind: AtomButtonKind.outline,
                      onPressed: _tryAgain,
                    ),
                  ] else if (_pending)
                    AtomButton(
                      label: l.auth2AskOnWhatsApp,
                      icon: AtomBrandIcons.whatsapp,
                      kind: AtomButtonKind.whatsapp,
                      onPressed: openAtomshopWhatsApp,
                    )
                  else ...[
                    AtomButton(
                      label: l.signInButton,
                      saving: _saving,
                      savingLabel: l.signInSigningIn,
                      onPressed: _submit,
                    ),
                    if (fingerprint) ...[
                      const SizedBox(height: 12),
                      _OrDivider(label: l.auth2Or),
                      const SizedBox(height: 12),
                      AtomButton(
                        label: l.auth2SignInFingerprint,
                        icon: LucideIcons.fingerprint,
                        iconColor: AtomColors.primary,
                        kind: AtomButtonKind.outline,
                        onPressed: lockFingerprint
                            ? ref
                                  .read(appLockProvider.notifier)
                                  .backToQuickUnlock
                            : () => context.push(V2Routes.quickSignIn),
                      ),
                    ],
                    const SizedBox(height: 22),
                    AuthNote(
                      kind: AtomNoteKind.info,
                      icon: LucideIcons.shieldCheck,
                      text: l.auth2PasswordOnce(l.auth2PasswordOnceBold),
                      bold: l.auth2PasswordOnceBold,
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 16),
                  _Trouble(l: l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.divider`: a line, "or", a line.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(height: 1, color: AtomColors.line));
    return Row(
      children: [
        line,
        const SizedBox(width: 12),
        Text(
          label,
          style: AtomText.secondary.copyWith(color: AtomColors.faint),
        ),
        const SizedBox(width: 12),
        line,
      ],
    );
  }
}

/// "Trouble signing in? WhatsApp Atomshop" at the foot.
class _Trouble extends StatelessWidget {
  const _Trouble({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 2.1 "New brand? Apply to list your brand".
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l.signInNewBrand,
              style: AtomText.body.copyWith(color: AtomColors.muted),
            ),
            const SizedBox(width: 4),
            AuthLink(
              label: l.welcomeBecomeSeller,
              onTap: () => context.push(V2Routes.apply),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _troubleRow(context),
      ],
    );
  }

  Widget _troubleRow(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l.signInTrouble,
          style: AtomText.body.copyWith(color: AtomColors.muted),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            const Icon(
              AtomBrandIcons.whatsapp,
              size: 16,
              color: AtomColors.whatsapp,
            ),
            // Flexible: at 200% text on a 320dp phone the link is wider
            // than the screen, and wraps rather than running off it.
            Flexible(
              child: AuthLink(
                label: l.signInWhatsApp,
                onTap: openAtomshopWhatsApp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
