import 'package:atombrand_app/v2/core/services/local_storage_methods.dart';
import 'package:atombrand_app/v2/core/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Asking for notifications, once, after sign-in (16.8): the app explains
/// why before the phone shows its own prompt, which can't be shown again
/// once refused.
abstract interface class NotificationPrompt {
  /// True when the explainer should show: never shown on this phone, and
  /// notifications not already allowed.
  Future<bool> shouldShow();

  /// Remembers that it was shown, whatever the answer.
  Future<void> markShown();

  /// Shows the phone's own prompt. True when allowed.
  Future<bool> request();
}

class PhoneNotificationPrompt implements NotificationPrompt {
  const PhoneNotificationPrompt();

  static const _key = 'v2_notification_prompt_shown';

  @override
  Future<bool> shouldShow() async {
    if (await LocalStorageMethods.instance.readData(_key) == '1') return false;
    return !await FcmService.notificationsAllowed();
  }

  @override
  Future<void> markShown() => LocalStorageMethods.instance.writeData(_key, '1');

  @override
  Future<bool> request() => FcmService.requestPermission();
}

final notificationPromptProvider = Provider<NotificationPrompt>(
  (ref) => const PhoneNotificationPrompt(),
);

/// The explainer. Allow shows the phone's prompt; Not now just closes it.
class AllowNotificationsScreen extends ConsumerStatefulWidget {
  const AllowNotificationsScreen({super.key});

  @override
  ConsumerState<AllowNotificationsScreen> createState() =>
      _AllowNotificationsScreenState();
}

class _AllowNotificationsScreenState
    extends ConsumerState<AllowNotificationsScreen> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    ref.read(notificationPromptProvider).markShown();
  }

  Future<void> _allow() async {
    setState(() => _asking = true);
    await ref.read(notificationPromptProvider).request();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final padding = MediaQuery.paddingOf(context);

    Widget reason(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AtomColors.nav2,
              borderRadius: AtomRadius.brControl,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AtomText.body.copyWith(
                color: AtomColors.navSoftText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28, padding.top + 24, 28, 16),
                  child: Column(
                    children: [
                      const _BadgedTile(),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: Text(
                          l.notifTitle,
                          textAlign: TextAlign.center,
                          style: AtomText.successTitle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      reason(LucideIcons.fileText, l.notifWhyPayments),
                      reason(LucideIcons.funnel, l.notifWhyLeads),
                      reason(LucideIcons.messageCircle, l.notifWhyAtomshop),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 34 + padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AtomButton(
                    label: l.notifAllow,
                    kind: AtomButtonKind.light,
                    saving: _asking,
                    onPressed: _allow,
                  ),
                  const SizedBox(height: 10),
                  AtomButton(
                    label: l.notifNotNow,
                    kind: AtomButtonKind.ghostDark,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.notifFootnote,
                    textAlign: TextAlign.center,
                    style: AtomText.small.copyWith(color: AtomColors.navMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app tile with a red count on its corner (16.8 `.big-ico`): what a
/// notification looks like on the home screen.
class _BadgedTile extends StatelessWidget {
  const _BadgedTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            bottom: 0,
            child: AtomBrandTile(size: 88, shadow: true),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 26),
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AtomColors.alertBadge,
                  borderRadius: AtomRadius.brPill,
                  border: Border.all(color: AtomColors.nav, width: 3),
                ),
                child: Text(
                  '3',
                  style: AtomText.smallButton.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
