import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/lock/app_lock.dart';
import '../../../core/db/copy_key.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../settings/data/settings_repository.dart' show myProfileProvider;
import '../data/auth_repository.dart';
import 'auth_parts.dart';

/// Opening the app while signed in (3.0–3.2). Covers the app whenever it is
/// locked: on a cold start with a PIN, and after the lock delay in the
/// background.
///
/// - 3.2 while the 5-minute wait after five wrong PINs is on;
/// - 3.0 when the fingerprint is on (until "Use PIN instead");
/// - 3.1 otherwise.
class UnlockGate extends ConsumerStatefulWidget {
  const UnlockGate({super.key});

  @override
  ConsumerState<UnlockGate> createState() => _UnlockGateState();
}

class _UnlockGateState extends ConsumerState<UnlockGate> {
  bool _usePin = false;

  /// Why the fingerprint sent the seller to the PIN pad, if it did: it
  /// could not open what is saved on the phone, or the PIN is needed once
  /// to lock it. The pad says which.
  CopyBioResult? _pinBecause;

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    // Rebuilds on the minute tick of 3.2 come from its own timer; this
    // reads the wait once per lock change.
    final waiting =
        ref.read(appLockProvider.notifier).waitLeft() > Duration.zero;
    final Widget screen;
    if (waiting) {
      screen = const PinWaitScreen();
    } else if (lock.fingerprint && !_usePin) {
      screen = FingerprintUnlockScreen(
        onUsePin: () => setState(() => _usePin = true),
        onPinNeeded: (why) => setState(() {
          _usePin = true;
          _pinBecause = why;
        }),
      );
    } else {
      screen = PinUnlockScreen(
        onFingerprint: lock.fingerprint
            ? () => setState(() => _usePin = false)
            : null,
        pinBecause: _pinBecause,
      );
    }
    return Material(color: AtomColors.nav, child: screen);
  }
}

/// "{business} · {shop}" under the welcome.
String _shopLine(AppLocalizations l, BrandSession? s) {
  if (s == null) return '';
  return [
    if (s.brandName != null) s.brandName!,
    s.who.isOwner ? (s.outletName ?? l.auth2MainShop) : s.outletName,
  ].whereType<String>().join(' · ');
}

/// Sign in with the password instead: the lock steps aside for Sign in.
void _usePassword(WidgetRef ref) =>
    ref.read(appLockProvider.notifier).usePassword();

/// The navy frame shared by 3.0–3.2: the status bar, the "Online" pill.
class _DarkFrame extends StatelessWidget {
  const _DarkFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: AuthNetworkPill(dark: true)),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The scrolling body: the top part, then the bottom part pushed down.
class _Fill extends StatelessWidget {
  const _Fill({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ],
  );
}

TextStyle get _welcomeStyle =>
    AtomText.successTitle.copyWith(color: Colors.white, height: 1.2);

TextStyle get _shopStyle => AtomText.body.copyWith(color: AtomColors.navText);

enum _Scan { ready, failed, ok }

/// Fingerprint sign-in (3.0) from Sign in, after signing out: the same
/// screen, reading the sign-in saved behind the fingerprint and signing in
/// with it. No "Use PIN instead": a PIN can't release the password.
class QuickSignInScreen extends StatelessWidget {
  const QuickSignInScreen({super.key});

  @override
  Widget build(BuildContext context) => const Material(
    color: AtomColors.nav,
    child: FingerprintUnlockScreen(quick: true),
  );
}

/// Fingerprint sign-in (3.0): asks the phone once by itself; the circle
/// asks again.
///
/// Locked, it unlocks the app. With [quick] (signed out), it reads the
/// saved sign-in, then signs in with it and the way in carries on.
class FingerprintUnlockScreen extends ConsumerStatefulWidget {
  const FingerprintUnlockScreen({
    super.key,
    this.onUsePin,
    this.onPinNeeded,
    this.quick = false,
  }) : assert(quick || onUsePin != null);

  final VoidCallback? onUsePin;

  /// The PIN is needed for what is saved on the phone — the fingerprint
  /// could not open it, or it has never been locked behind the PIN. Falls
  /// back to [onUsePin] when not given.
  final void Function(CopyBioResult why)? onPinNeeded;
  final bool quick;

  @override
  ConsumerState<FingerprintUnlockScreen> createState() =>
      _FingerprintUnlockScreenState();
}

class _FingerprintUnlockScreenState
    extends ConsumerState<FingerprintUnlockScreen> {
  _Scan _scan = _Scan.ready;
  bool _asking = false;
  Timer? _open;

  /// A problem in words (no internet, the server's message).
  String? _problem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
  }

  @override
  void dispose() {
    _open?.cancel();
    super.dispose();
  }

  Future<void> _ask() async {
    if (widget.quick) return _quickSignIn();
    if (_asking || _scan == _Scan.ok || !mounted) return;
    _asking = true;
    final l = AppLocalizations.of(context);
    final result = await ref
        .read(appLockProvider.notifier)
        .checkBiometrics(l.lockBioReason, copyPrompt(l));
    _asking = false;
    if (!mounted) return;
    if (result == CopyBioResult.usePin ||
        result == CopyBioResult.pinToProtect) {
      final needed = widget.onPinNeeded;
      needed != null ? needed(result) : widget.onUsePin?.call();
      return;
    }
    final ok = result == CopyBioResult.opened;
    // The phone's own prompt says "not recognised" while it is up; it
    // answers no only when it was closed (Cancel, Back) or locked out, so
    // the circle waits for another try rather than saying it failed.
    setState(() => _scan = ok ? _Scan.ok : _Scan.ready);
    if (ok) {
      // "Signed in" in green for a moment, then the app.
      _open = Timer(const Duration(milliseconds: 500), () {
        ref.read(appLockProvider.notifier).unlockedByBiometrics();
      });
    }
  }

  /// Back to the form, saying why the saved sign-in is gone.
  void _toForm(QuickNotice notice) {
    ref.read(quickNoticeProvider.notifier).show(notice);
    context.canPop() ? context.pop() : context.go(V2Routes.signIn);
  }

  /// Done once the app is in front (resumed), or after 3 s at most, so a
  /// phone that never reports it can't leave the sign-in waiting.
  Future<void> _untilResumed() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    final resumed = Completer<void>();
    final listener = AppLifecycleListener(
      onResume: () {
        if (!resumed.isCompleted) resumed.complete();
      },
    );
    await resumed.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    listener.dispose();
    // A moment for the phone to give the network back.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _quickSignIn() async {
    if (_asking || _scan == _Scan.ok || !mounted) return;
    _asking = true;
    final l = AppLocalizations.of(context);
    final quick = ref.read(quickSignInProvider.notifier);
    final read = await quick.read(quickPrompt(l));
    if (!mounted) return;
    switch (read) {
      case QuickOk(:final secret?):
        // The phone's fingerprint prompt pauses the app. Some phones (OPPO)
        // cut a paused app's network, so a sign-in sent behind the prompt
        // reached the server but its answer was lost ("No internet"). Wait
        // until the app is in front again, and try once more if the
        // connection still dropped.
        await _untilResumed();
        Future<ApiResult<BrandSession>> signIn() => ref
            .read(authRepositoryProvider)
            .signIn(login: secret.login, password: secret.password);
        var result = await signIn();
        if (result case ApiErr(:final failure)
            when failure.kind == ApiFailureKind.offline ||
                failure.kind == ApiFailureKind.timeout) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          if (!mounted) return;
          result = await signIn();
        }
        _asking = false;
        if (!mounted) return;
        switch (result) {
          case ApiOk(:final value):
            setState(() => _scan = _Scan.ok);
            // The router takes it from here: the way in, then Home.
            await ref.read(sessionProvider.notifier).signIn(value);
          case ApiErr(:final failure)
              when failure.kind == ApiFailureKind.signedOut ||
                  failure.fieldErrors.containsKey('password'):
            // A wrong password: it was changed somewhere else.
            await quick.erase();
            if (mounted) _toForm(QuickNotice.passwordChanged);
          case ApiErr(:final failure):
            setState(() {
              _scan = _Scan.failed;
              _problem = switch (failure.kind) {
                ApiFailureKind.offline ||
                ApiFailureKind.timeout => l.signInOffline,
                _ => failure.message ?? l.signInFailed,
              };
            });
        }
      case QuickKeyChanged():
        _asking = false;
        _toForm(QuickNotice.fingerprintsChanged);
      case QuickCancelled():
        _asking = false;
        setState(() {
          _scan = _Scan.ready;
          _problem = null;
        });
      case QuickOk() || QuickFailed():
        _asking = false;
        setState(() {
          _scan = _Scan.failed;
          _problem = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final profile = widget.quick
        ? ref.watch(quickSignInProvider).profile
        : null;
    final firstName = profile?.firstName ?? session?.firstName ?? '';
    final shopLine = profile?.shopLine ?? _shopLine(l, session);
    final shop =
        session?.outletName ??
        (session?.who.isOwner ?? false ? l.auth2MainShop : null);
    final ok = _scan == _Scan.ok;
    final (
      Color fill,
      Color ink,
      String msg,
      Color msgColour,
    ) = switch (_scan) {
      _Scan.ready => (
        AtomColors.primarySoft,
        AtomColors.primary,
        l.auth2FpTap,
        AtomColors.faint,
      ),
      _Scan.failed => (
        AtomColors.roseSoft,
        AtomColors.rose,
        _problem ?? (widget.quick ? l.auth3FpFailed : l.auth2FpFailed),
        AtomColors.rose,
      ),
      _Scan.ok => (
        AtomColors.greenSoft,
        AtomColors.green,
        l.auth2FpOk,
        AtomColors.green,
      ),
    };

    return _DarkFrame(
      child: _Fill(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
            child: Column(
              children: [
                const AtomBrandTile(size: AtomSize.lockTile, shadow: true),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    l.lockTitle(firstName),
                    textAlign: TextAlign.center,
                    style: _welcomeStyle,
                  ),
                ),
                const SizedBox(height: 10),
                Text(shopLine, textAlign: TextAlign.center, style: _shopStyle),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 24),
          Container(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              borderRadius: AtomRadius.brSheetTop,
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AtomColors.line2,
                    borderRadius: AtomRadius.brTag,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  ok ? l.auth2FpOkTitle : l.auth2SignInFingerprint,
                  textAlign: TextAlign.center,
                  style: AtomText.heading,
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 290),
                  child: Text(
                    ok && shop != null && !widget.quick
                        ? l.auth2FpOpening(shop)
                        : l.auth2FpBody,
                    textAlign: TextAlign.center,
                    style: AuthText.small,
                  ),
                ),
                const SizedBox(height: 14),
                AtomPressable(
                  onTap: ok ? null : _ask,
                  semanticLabel: l.auth2FpButton,
                  builder: (_, _) => Container(
                    width: AtomSize.fingerprintCircle,
                    height: AtomSize.fingerprintCircle,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ok ? LucideIcons.check : LucideIcons.fingerprint,
                      size: ok ? 54 : 60,
                      color: ink,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 18),
                    child: Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: AtomText.secondary.copyWith(
                        color: msgColour,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.onUsePin != null) ...[
                  AtomButton(
                    label: l.auth2UsePin,
                    kind: AtomButtonKind.outline,
                    onPressed: ok ? null : widget.onUsePin,
                  ),
                  const SizedBox(height: 10),
                ],
                AuthLink(
                  label: l.auth2SignInPassword,
                  onTap: widget.quick
                      ? () => context.canPop()
                            ? context.pop()
                            : context.go(V2Routes.signIn)
                      : () => _usePassword(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// PIN unlock (3.1). The bottom-left key is the fingerprint when it is on.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key, this.onFingerprint, this.pinBecause});

  /// Back to 3.0; null when the fingerprint is off.
  final VoidCallback? onFingerprint;

  /// Why the fingerprint sent the seller here, if it did. Said once, above
  /// the pad.
  final CopyBioResult? pinBecause;

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  String _pin = '';
  bool _wrong = false;
  bool _checking = false;
  late CopyBioResult? _because = widget.pinBecause;

  Future<void> _digit(String d) async {
    if (_checking || _pin.length >= 4) return;
    final pin = _pin + d;
    setState(() {
      _pin = pin;
      _wrong = false;
    });
    if (pin.length < 4) return;
    _checking = true;
    final result = await ref.read(appLockProvider.notifier).check(pin);
    _checking = false;
    if (!mounted) return;
    switch (result) {
      case PinCheck.ok:
        // The PIN opened the copy. If the fingerprint is on but no longer
        // holds this key, give it the key again, so the next unlock by
        // fingerprint opens the copy too.
        unawaited(
          ref
              .read(appLockProvider.notifier)
              .keepFingerprintKey(
                copyPrompt(AppLocalizations.of(context), keep: true),
              ),
        );
      case PinCheck.wrong || PinCheck.waiting:
        HapticFeedback.heavyImpact();
        setState(() {
          _pin = '';
          _wrong = true;
        });
      case PinCheck.tooMany:
        // Ten wrong PINs: the password is needed, the saved fingerprint
        // sign-in is erased, and the token goes while it still works.
        await ref.read(quickSignInProvider.notifier).erase();
        await ref.read(authRepositoryProvider).signOut();
        await ref.read(sessionProvider.notifier).signOut();
    }
  }

  Future<void> _fingerprint() async {
    final l = AppLocalizations.of(context);
    final result = await ref
        .read(appLockProvider.notifier)
        .checkBiometrics(l.lockBioReason, copyPrompt(l));
    if (!mounted) return;
    switch (result) {
      case CopyBioResult.opened:
        await ref.read(appLockProvider.notifier).unlockedByBiometrics();
      case CopyBioResult.usePin || CopyBioResult.pinToProtect:
        setState(() => _because = result);
      case CopyBioResult.cancelled:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    final picture = ref.watch(myProfileProvider).value?.pictureUrl;
    final wrongTries = ref.watch(appLockProvider.select((s) => s.wrongTries));
    final String? msg = _wrong && wrongTries > 0
        ? (wrongTries < maxPinTries
              ? l.auth2WrongPinWait(maxPinTries - wrongTries)
              : l.auth2WrongPinPassword(pinTriesBeforeSignOut - wrongTries))
        // Not an error: the fingerprint can't open the saved copy, and
        // this one PIN puts that right.
        : switch (_because) {
            CopyBioResult.usePin => l.lockBioUsePin,
            CopyBioResult.pinToProtect => l.lockPinOnceToProtect,
            _ => null,
          };
    final linkStyle = AtomText.body.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return _DarkFrame(
      child: _Fill(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            child: Column(
              children: [
                Container(
                  width: AtomSize.lockAvatar,
                  height: AtomSize.lockAvatar,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AtomColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AtomColors.nav2, spreadRadius: 4),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  // The person's photo over the initials (owner: photos
                  // where the server has one); offline, the initials.
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          session?.initials ?? '',
                          style: AtomText.successTitle.copyWith(
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                      if (picture != null && picture.isNotEmpty)
                        AtomPhoto(
                          picture,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    l.lockTitle(session?.firstName ?? ''),
                    textAlign: TextAlign.center,
                    style: _welcomeStyle,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _shopLine(l, session),
                  textAlign: TextAlign.center,
                  style: _shopStyle,
                ),
                const SizedBox(height: 34),
                Text(l.auth2EnterPin, style: _shopStyle),
                const SizedBox(height: 12),
                AtomPinDots(filled: _pin.length, error: _wrong, onDark: true),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 18),
                    child: msg == null
                        ? null
                        : Text(
                            msg,
                            textAlign: TextAlign.center,
                            style: AtomText.secondary.copyWith(
                              color: AtomColors.darkRose,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          AtomPinPad(
            onDark: true,
            onDigit: _digit,
            onDelete: () => setState(
              () =>
                  _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1),
            ),
            onBiometric: widget.onFingerprint == null ? null : _fingerprint,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              30,
              8,
              30,
              8 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: AuthLink(
                    label: l.auth2ForgotPin,
                    style: linkStyle,
                    onTap: () => ref
                        .read(appLockProvider.notifier)
                        .usePassword(forgotPin: true),
                  ),
                ),
                Flexible(
                  child: AuthLink(
                    label: l.auth2SwitchAccount,
                    style: linkStyle,
                    onTap: () {
                      // Someone else: the saved sign-in isn't theirs.
                      ref.read(quickSignInProvider.notifier).erase();
                      _usePassword(ref);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Too many wrong PINs (3.2): a 5-minute wait with a live countdown that
/// survives closing the app, or the password instead.
class PinWaitScreen extends ConsumerStatefulWidget {
  const PinWaitScreen({super.key});

  @override
  ConsumerState<PinWaitScreen> createState() => _PinWaitScreenState();
}

class _PinWaitScreenState extends ConsumerState<PinWaitScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = ref.read(appLockProvider.notifier).waitLeft();
      if (left == Duration.zero) {
        _tick?.cancel();
        // The gate shows the PIN again.
        ref.read(appLockProvider.notifier).waitOver();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final left = ref.read(appLockProvider.notifier).waitLeft();
    final secs = (left.inMilliseconds / 1000).ceil();
    final time = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

    return _DarkFrame(
      child: _Fill(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AtomColors.darkRoseFill,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AtomRadius.sheet),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.lockKeyhole,
                      size: 36,
                      color: AtomColors.darkRose,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      l.auth2TooManyTitle,
                      textAlign: TextAlign.center,
                      style: _welcomeStyle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      l.auth2TooManyBody,
                      textAlign: TextAlign.center,
                      style: AuthText.sub.copyWith(color: AtomColors.navText),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    label: '${l.auth2TryAgainIn} $time',
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AtomColors.nav2,
                          borderRadius: AtomRadius.brCard,
                          border: Border.all(color: AtomColors.navLine),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l.auth2TryAgainIn,
                              style: AtomText.secondary.copyWith(
                                color: AtomColors.navMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: AtomText.amountLg.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AtomColors.nav2,
                    borderRadius: AtomRadius.brControl,
                    border: Border.all(color: AtomColors.navLine),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          LucideIcons.circleAlert,
                          size: 18,
                          color: AtomColors.darkAmber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: AtomText.body.copyWith(
                              color: AtomColors.navText,
                            ),
                            children: boldSpans(
                              l.auth2TenPins(l.auth2TenPinsBold),
                              l.auth2TenPinsBold,
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AtomButton(
                  label: l.auth2PasswordInstead,
                  kind: AtomButtonKind.ghostDark,
                  onPressed: () => _usePassword(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
