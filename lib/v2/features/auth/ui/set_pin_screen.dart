import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/lock/app_lock.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/getting_ready_due.dart';
import '../data/auth_repository.dart';
import 'auth_parts.dart';

/// Set PIN (2.4) on the way in, after a password sign-in on this phone.
/// Continue ends the step and the guards move on (Choose shop, terms, the
/// tour, Home).
///
/// Skip leaves the phone without a PIN: the step ends the same way, and
/// Home's first steps and Settings › Security keep offering it. Without a
/// PIN nothing locks the app, so the next sign-in asks again.
///
/// With "Open with fingerprint" on, Continue also saves the login and the
/// password typed at sign-in behind the fingerprint (one system prompt), so
/// the next sign-in after signing out can be the fingerprint.
class WayInSetPinScreen extends ConsumerStatefulWidget {
  const WayInSetPinScreen({super.key});

  @override
  ConsumerState<WayInSetPinScreen> createState() => _WayInSetPinScreenState();
}

class _WayInSetPinScreenState extends ConsumerState<WayInSetPinScreen> {
  /// Finishing or skipping is under way: the second tap waits for it.
  bool _finishing = false;

  /// Ends the way-in step. If the phone could not save it (the secure
  /// store, the copy's key), the step stays and can be tried again:
  /// [_finishing] was never put back before, so every later tap returned
  /// at once and the screen could not be left.
  Future<void> _end() async {
    // Getting ready (2.7) follows, for a brand with the Offline add-on.
    final ready = ref.read(gettingReadyDueProvider.notifier)..arm();
    try {
      await ref.read(appLockProvider.notifier).finishPinSetup();
    } catch (e) {
      debugPrint('[pin] could not finish the PIN step: $e');
      ready.done();
      _finishing = false;
      if (!mounted) return;
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: AppLocalizations.of(context).commonSomethingWrong,
      );
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final l = AppLocalizations.of(context);
    final pending = ref.read(pendingSignInProvider);
    final session = ref.read(sessionProvider.notifier).current;
    if (pending != null &&
        session != null &&
        ref.read(appLockProvider).prefs.biometric) {
      final r = await ref
          .read(quickSignInProvider.notifier)
          .save(
            QuickSignInController.profileOf(session, mainShop: l.auth2MainShop),
            pending,
            quickPrompt(l, save: true),
          );
      if (r is! QuickOk && mounted) {
        showAtomToast(
          context,
          kind: AtomToastKind.wait,
          message: l.auth3NotSaved,
        );
      }
    }
    ref.read(pendingSignInProvider.notifier).forget();
    await _end();
  }

  /// Skip: no PIN on this phone. The password typed at sign-in is dropped
  /// unsaved (it is only kept behind the fingerprint alongside a PIN), and
  /// the way-in step ends so the guards move on.
  Future<void> _skip() async {
    if (_finishing) return;
    _finishing = true;
    ref.read(pendingSignInProvider.notifier).forget();
    await _end();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: PinSetupScreen(
        stepLabel: l.pinStepOf(2),
        onFinished: _finish,
        onSkip: _skip,
      ),
    );
  }
}

/// A PIN that is easy to guess: one digit four times (0000) or a run up or
/// down (1234, 4321). The board says "Avoid 1234".
bool isEasyPin(String pin) {
  if (pin.length < 2) return false;
  final d = pin.codeUnits;
  bool step(int by) {
    for (var i = 1; i < d.length; i++) {
      if (d[i] - d[i - 1] != by) return false;
    }
    return true;
  }

  return step(0) || step(1) || step(-1);
}

/// Set a 4-digit PIN, then type it again; then the fingerprint switch when
/// the phone has one, the small print and Continue (2.4).
///
/// With [askCurrent] (Change PIN in Settings) the PIN in use is asked for
/// first, in the 3.1 look on the light page. Wrong ones count with the
/// lock's own ([maxPinTries] start the wait and it leaves through
/// [onClose]; [pinTriesBeforeSignOut] sign the phone out).
///
/// Back starts the entry again (as on the board); [onClose], when given,
/// leaves instead once nothing is typed.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({
    super.key,
    required this.onFinished,
    this.stepLabel,
    this.onClose,
    this.onSkip,
    this.askCurrent = false,
  });

  /// "Step 2 of 2" at the end of the bar.
  final String? stepLabel;

  /// Continue on the done state.
  final VoidCallback onFinished;
  final VoidCallback? onClose;

  /// Leaves without a PIN, under the pad. Only the way-in step offers it:
  /// Change PIN in Settings has Back instead.
  final VoidCallback? onSkip;

  /// Ask for the PIN in use before a new one is set.
  final bool askCurrent;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String? _first;
  late bool _checkingCurrent = widget.askCurrent;

  /// The current PIN is being checked: no digits until it answers.
  bool _asking = false;

  /// The line under the dots, in rose; the dots turn rose with it.
  String? _error;
  bool _done = false;

  void _reset() => setState(() {
    _pin = '';
    _first = null;
    _error = null;
  });

  void _leave() => widget.onClose != null
      ? widget.onClose!()
      : Navigator.of(context).maybePop();

  Future<void> _current(String pin) async {
    final l = AppLocalizations.of(context);
    final lock = ref.read(appLockProvider.notifier);
    _asking = true;
    final result = await lock.checkCurrent(pin);
    _asking = false;
    if (!mounted) return;
    switch (result) {
      case PinCheck.ok:
        setState(() {
          _checkingCurrent = false;
          _pin = '';
          _error = null;
        });
      case PinCheck.wrong:
        HapticFeedback.heavyImpact();
        final wrong = ref.read(appLockProvider).wrongTries;
        setState(() {
          _pin = '';
          _error = wrong < maxPinTries
              ? l.qa3PinCurrentWrong(maxPinTries - wrong)
              : l.auth2WrongPinPassword(pinTriesBeforeSignOut - wrong);
        });
      case PinCheck.waiting:
        // The fifth wrong one, or the lock's wait was already on: the
        // same five minutes as the lock screen.
        HapticFeedback.heavyImpact();
        final minutes = (lock.waitLeft().inSeconds / 60).ceil();
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: minutes > 0
              ? l.qa3PinCurrentWait(minutes)
              : l.qa3PinCurrentTooMany,
        );
        _leave();
      case PinCheck.tooMany:
        // The tenth: as on the lock screen, the password is needed, the
        // saved fingerprint sign-in is erased, and the token goes while
        // it still works.
        await ref.read(quickSignInProvider.notifier).erase();
        await ref.read(authRepositoryProvider).signOut();
        await ref.read(sessionProvider.notifier).signOut();
    }
  }

  Future<void> _digit(String d) async {
    if (_done || _asking || _pin.length >= 4) return;
    final l = AppLocalizations.of(context);
    final pin = _pin + d;
    if (pin.length < 4) {
      return setState(() {
        _pin = pin;
        _error = null;
      });
    }
    if (_checkingCurrent) return _current(pin);
    if (_first == null) {
      if (isEasyPin(pin)) {
        return setState(() {
          _pin = '';
          _error = l.qa3PinTooEasy;
        });
      }
      return setState(() {
        _first = pin;
        _pin = '';
      });
    }
    if (pin != _first) {
      return setState(() {
        _pin = '';
        _first = null;
        _error = l.pinMismatch;
      });
    }
    setState(() => _pin = pin);
    final lock = ref.read(appLockProvider.notifier);
    await lock.setPin(pin);
    // Fingerprint is the seller's choice: the switch on the next step
    // starts off, and turning it on is what asks for a finger.
    if (mounted) setState(() => _done = true);
  }

  void _delete() => setState(
    () => _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = _done
        ? l.pinDoneTitle
        : _checkingCurrent
        ? l.qa3PinCurrentTitle
        : _first == null
        ? l.pinCreateTitle
        : l.pinConfirmTitle;
    final body = _done
        ? l.pinDoneBody
        : _checkingCurrent
        ? l.qa3PinCurrentBody
        : l.pinCreateBody;
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(
            leading: AtomFlowLeading.back,
            onLeading: () {
              if (widget.onClose != null && _pin.isEmpty && _first == null) {
                widget.onClose!();
              } else if (!_done) {
                // Back clears what is typed; the current PIN, once
                // checked, isn't asked again.
                _reset();
              }
            },
            trailing: [
              if (widget.stepLabel != null) AuthStepLabel(widget.stepLabel!),
            ],
          ),
          Expanded(
            child: AuthScrollBody(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
              children: [
                _Header(title: title, body: body),
                if (!_done)
                  Expanded(child: _entry())
                else
                  Expanded(child: _DoneBody(onContinue: widget.onFinished)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entry() {
    final l = AppLocalizations.of(context);
    final error = _error;
    // The PIN in use is asked for first: Skip belongs to the new one.
    final skip = _checkingCurrent ? null : widget.onSkip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 30),
      child: Column(
        children: [
          AtomPinDots(filled: _pin.length, error: error != null),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 18),
            child: error != null
                ? Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Flexible(child: AtomFieldError(error))],
                      ),
                    ),
                  )
                : null,
          ),
          const Spacer(),
          const SizedBox(height: 16),
          AtomPinPad(onDigit: _digit, onDelete: _delete),
          if (skip != null) ...[
            const SizedBox(height: 8),
            AuthLink(label: l.pinSkip, onTap: skip),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AtomColors.primarySoft,
              borderRadius: BorderRadius.all(Radius.circular(AtomRadius.sheet)),
            ),
            child: const ShieldKeyholeIcon(color: AtomColors.primary),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: AuthText.h1),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(body, textAlign: TextAlign.center, style: AuthText.sub),
          ),
        ],
      ),
    );
  }
}

class _DoneBody extends ConsumerWidget {
  const _DoneBody({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final canCheck = ref.watch(biometricsCanCheckProvider).value ?? false;
    final bio = ref.watch(appLockProvider.select((s) => s.prefs.biometric));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthNote(
            kind: AtomNoteKind.success,
            icon: LucideIcons.check,
            lead: l.auth2PinSavedBold,
            text: l.auth2PinSavedRest,
          ),
          if (canCheck) ...[
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(AtomSpace.inset),
              decoration: AtomDecor.card,
              child: Row(
                children: [
                  const AtomIconTile(icon: LucideIcons.fingerprint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.auth2BioRowTitle, style: AtomText.listTitle),
                        const SizedBox(height: 2),
                        Text(l.auth2BioRowSub, style: AuthText.small),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AtomSwitch(
                    value: bio,
                    semanticLabel: l.auth2BioRowTitle,
                    onChanged: (on) async {
                      final lock = ref.read(appLockProvider.notifier);
                      if (!on) return lock.setBiometric(false);
                      // One prompt, now: the finger is asked for when the
                      // seller turns it on, and a cancel leaves it off.
                      if (!await lock.turnOnFingerprint(
                            copyPrompt(l, keep: true),
                          ) &&
                          context.mounted) {
                        showAtomToast(
                          context,
                          kind: AtomToastKind.wait,
                          message: l.auth3NotSaved,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(l.auth2PinSmallPrint, style: AuthText.small),
          const Spacer(),
          const SizedBox(height: 14),
          AtomButton(label: l.auth2Continue, onPressed: onContinue),
        ],
      ),
    );
  }
}
