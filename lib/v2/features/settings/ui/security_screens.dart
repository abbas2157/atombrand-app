import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/lock/app_lock.dart';
import '../../../core/lock/quick_sign_in.dart';
import '../../../core/lock/screen_guard.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../auth/ui/auth_parts.dart' show copyPrompt, quickPrompt;
import '../../auth/ui/set_pin_screen.dart' show PinSetupScreen;
import '../../notifications/data/notifications_repository.dart';
import 'settings_parts.dart';
import 'settings_screens.dart' show openPasswordScreen;

/// The lock delays offered (19.2), in seconds.
const _lockAfter = [0, 30, 60, 300, 900];

String _lockLabel(AppLocalizations l, int s) => switch (s) {
  0 => l.lockImmediately,
  < 60 => l.lockAfterSeconds(s),
  _ => l.lockAfterMinutes(s ~/ 60),
};

/// Whether this phone can check a fingerprint or face.
final biometricsAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(biometricsProvider).available(),
);

/// Account security (19.2): password (everyone), the quick-unlock PIN, the
/// fingerprint, when the app locks, and signing out other phones.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lock = ref.watch(appLockProvider);
    final p = lock.prefs;
    final bio = ref.watch(biometricsAvailableProvider).value ?? false;
    final ctl = ref.read(appLockProvider.notifier);
    final shots = ref.watch(blockScreenshotsProvider);

    Future<void> flipBio(bool on) async {
      if (!on) {
        // Off also erases the saved sign-in.
        await ctl.setBiometric(false);
        return;
      }
      // On asks for the password, to save it behind the fingerprint.
      if (await showQuickPasswordSheet(context) && context.mounted) {
        await ctl.setBiometric(true);
        // And the key to what is saved on the phone, so a fingerprint
        // unlock opens the offline copy too (§5).
        await ctl.keepFingerprintKey(copyPrompt(l, keep: true));
      }
    }

    Future<void> pickLock() async {
      final s = await showAtomSelect<int>(
        context,
        title: l.lockAfterTitle,
        load: () async => [
          for (final s in _lockAfter)
            AtomOption(value: s, label: _lockLabel(l, s)),
        ],
      );
      if (s != null) await ctl.setLockAfter(s);
    }

    // The board's groups (19.2): Sign in (password, PIN, fingerprint), On
    // this phone (when the app locks), Everywhere (sign out the others),
    // then the small print.
    return SetPage(
      title: l.securityTitle,
      children: [
        AtomSectionLabel(l.securitySignIn),
        AtomRowGroup(
          children: [
            SetItem(
              icon: LucideIcons.lock,
              tone: AtomTone.blue,
              title: l.passwordTitle,
              subtitle: l.passwordSub,
              chevron: true,
              onTap: () => openPasswordScreen(context, ref),
            ),
            SetItem(
              icon: LucideIcons.rectangleEllipsis,
              tone: AtomTone.blue,
              title: p.hasPin ? l.pinChange : l.pinSet,
              subtitle: l.pinSub,
              chevron: true,
              onTap: () => context.push(V2Routes.settingsStep('pin')),
            ),
            if (p.hasPin && bio)
              SetItem(
                icon: LucideIcons.fingerprint,
                tone: AtomTone.blue,
                title: l.bioTitle,
                subtitle: l.auth3BioSub,
                subWraps: true,
                trailing: AtomSwitch(
                  value: p.biometric,
                  semanticLabel: l.bioTitle,
                  onChanged: flipBio,
                ),
                onTap: () => flipBio(!p.biometric),
              ),
            // Last in the group and red (RULES §4): the PIN is optional,
            // so it can be taken off again.
            if (p.hasPin)
              SetItem(
                icon: LucideIcons.trash2,
                title: l.pinRemove,
                subtitle: l.pinRemoveSub,
                subWraps: true,
                danger: true,
                onTap: () async {
                  final yes = await showAtomConfirm(
                    context,
                    title: l.pinRemoveTitle,
                    body: l.pinRemoveBody,
                    confirmLabel: l.pinRemove,
                    destructive: true,
                    sideBySide: true,
                  );
                  if (yes) await ctl.removePin();
                },
              ),
          ],
        ),
        AtomSectionLabel(l.securityThisPhone),
        AtomRowGroup(
          children: [
            if (p.hasPin)
              SetItem(
                icon: LucideIcons.clock,
                title: l.lockAfterTitle,
                subtitle: l.lockAfterSub,
                subWraps: true,
                value: _lockLabel(l, p.lockAfterSeconds),
                chevron: true,
                onTap: pickLock,
              ),
            if (ref.watch(noticeSettingsProvider).value?.hideAmountsKept ??
                false)
              const _HideAmountsItem(),
            SetItem(
              icon: LucideIcons.image,
              title: l.secBlockShots,
              subtitle: l.secBlockShotsSub,
              subWraps: true,
              trailing: AtomSwitch(
                value: shots,
                semanticLabel: l.secBlockShots,
                onChanged: ref.read(blockScreenshotsProvider.notifier).set,
              ),
              onTap: () =>
                  ref.read(blockScreenshotsProvider.notifier).set(!shots),
            ),
          ],
        ),
        AtomSectionLabel(l.securityEverywhere),
        AtomRowGroup(
          children: [
            SetItem(
              icon: LucideIcons.logIn,
              title: l.devicesSignOutOthers,
              subtitle: l.securitySignOutOthersSub,
              danger: true,
              chevron: true,
              onTap: () => context.push(V2Routes.settingsStep('devices')),
            ),
          ],
        ),
        SetTiny(l.securityNote, top: 12),
      ],
    );
  }
}

/// Hide amounts on the lock screen (19.2): the server then sends pushes
/// without the money in them ("tap to see"). Kept on the account
/// (`settings/notifications` hide_amounts).
class _HideAmountsItem extends ConsumerStatefulWidget {
  const _HideAmountsItem();

  @override
  ConsumerState<_HideAmountsItem> createState() => _HideAmountsItemState();
}

class _HideAmountsItemState extends ConsumerState<_HideAmountsItem> {
  /// Switched here, before the server answers.
  bool? _on;
  bool _saving = false;

  Future<void> _flip(bool on) async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _on = on;
      _saving = true;
    });
    final r = await ref
        .read(notificationsRepositoryProvider)
        .saveSettings(hideAmounts: on);
    if (!mounted) return;
    setState(() => _saving = false);
    if (r case ApiErr(:final failure)) {
      setState(() => _on = !on);
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayFailure(l, failure),
      );
      return;
    }
    ref.invalidate(noticeSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final saved = ref.watch(noticeSettingsProvider);
    final on = _on ?? saved.value?.hideAmounts ?? false;
    final ready = saved.hasValue;
    return SetItem(
      icon: LucideIcons.eye,
      title: l.secHideAmounts,
      subtitle: l.secHideAmountsSub,
      subWraps: true,
      loading: !ready && saved.isLoading,
      trailing: ready
          ? AtomSwitch(
              value: on,
              semanticLabel: l.secHideAmounts,
              onChanged: _flip,
            )
          : null,
      onTap: ready ? () => _flip(!on) : null,
    );
  }
}

/// Change PIN from Settings (19.2): the same screen as the first sign-in
/// (2.4), without the step count; done goes back to Security. With a PIN
/// already set, that PIN is asked for first.
class SetPinScreen extends ConsumerWidget {
  const SetPinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PinSetupScreen(
    askCurrent: ref.read(appLockProvider).prefs.hasPin,
    onFinished: () => Navigator.of(context).pop(),
    onClose: () => Navigator.of(context).pop(),
  );
}

/// "Type your password to sign in with your fingerprint": turning the
/// fingerprint on in Settings saves the login and this password behind it
/// (one system prompt). True when it was saved.
Future<bool> showQuickPasswordSheet(BuildContext context) async =>
    await showAtomSheet<bool>(
      context,
      builder: (_) => const QuickPasswordSheet(),
    ) ??
    false;

class QuickPasswordSheet extends ConsumerStatefulWidget {
  const QuickPasswordSheet({super.key});

  @override
  ConsumerState<QuickPasswordSheet> createState() => _QuickPasswordSheetState();
}

class _QuickPasswordSheetState extends ConsumerState<QuickPasswordSheet> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  /// The owner signs in with the email, an agent with the mobile number.
  String? get _knownLogin {
    final s = ref.read(sessionProvider.notifier).current;
    if (s == null) return null;
    return s.who.isOwner ? s.email : s.phone;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final session = ref.read(sessionProvider.notifier).current;
    final login = _knownLogin ?? _login.text.trim();
    if (session == null || login.isEmpty || _password.text.isEmpty) {
      setState(() => _error = l.signInPasswordEmpty);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(quickSignInProvider.notifier)
        .save(
          QuickSignInController.profileOf(session, mainShop: l.auth2MainShop),
          QuickSecret(login: login, password: _password.text),
          quickPrompt(l, save: true),
        );
    if (!mounted) return;
    switch (r) {
      case QuickOk():
        Navigator.of(context).pop(true);
      case QuickKeyChanged():
        setState(() {
          _saving = false;
          _error = l.auth3FingerprintsChanged;
        });
      case QuickCancelled() || QuickFailed():
        setState(() {
          _saving = false;
          _error = l.auth3FpFailed;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final askLogin = _knownLogin == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l.auth3SheetTitle, style: AtomText.heading),
            ),
            const SizedBox(height: 8),
            Text(l.auth3SheetBody, style: AtomText.secondary),
            const SizedBox(height: 16),
            if (askLogin) ...[
              AtomTextField(
                label: l.forgotLogin,
                controller: _login,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 14),
            ],
            AtomPasswordField(
              label: l.signInPassword,
              controller: _password,
              error: _error,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            AtomButton(
              label: l.auth3SheetSave,
              icon: LucideIcons.fingerprint,
              saving: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            AtomButton(
              label: l.commonCancel,
              kind: AtomButtonKind.outline,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
