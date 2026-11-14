import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../notifications/ui/notifications_screens.dart' show openNotice;
import '../data/home_logic.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'home_parts.dart';

/// The banner above Home's tasks (13.8, 13.4): one at a time, the most
/// urgent first. Read-only and a late bill in the strong colours of 13.4;
/// a trial ending in amber, a bill due in blue, Atomshop's message navy.
class HomeBannerSlot extends ConsumerWidget {
  const HomeBannerSlot({super.key, this.activity = const []});

  /// Recent activity, where Atomshop's messages are found.
  final List<HomeActivity> activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider.notifier).current;
    ref.watch(sessionProvider);
    final banner = pickBanner(
      owner: session?.who.isOwner ?? false,
      access: ref.watch(accessProvider),
      billing: ref.watch(homeBillingProvider).value,
      activity: activity,
      hidden: ref.watch(hiddenBannersProvider),
      today: ref.watch(homeClockProvider)(),
      l: AppLocalizations.of(context),
    );
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: HomeBannerCard(
        banner: banner,
        onHide: banner.dismissable
            ? () => ref.read(hiddenBannersProvider.notifier).hide(banner.key)
            : null,
      ),
    );
  }
}

/// One banner, drawn by its kind.
class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({super.key, required this.banner, this.onHide});

  final HomeBanner banner;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = banner;
    final (bg, line, fg) = switch (b.kind) {
      HomeBannerKind.readOnly || HomeBannerKind.restricted => (
        AtomColors.roseSoft,
        AtomColors.roseLine,
        AtomColors.noteRoseText,
      ),
      HomeBannerKind.late || HomeBannerKind.trial => (
        AtomColors.amberSoft,
        AtomColors.amberLine,
        AtomColors.confirmText,
      ),
      HomeBannerKind.billDue => (
        AtomColors.primarySoft,
        AtomColors.primaryLine,
        AtomColors.noteBlueText,
      ),
      HomeBannerKind.message => (
        AtomColors.nav,
        AtomColors.navLine,
        AtomColors.navText,
      ),
    };
    final dark = b.kind == HomeBannerKind.message;
    final (IconData icon, AtomTone tone) = switch (b.kind) {
      HomeBannerKind.readOnly => (LucideIcons.lock, AtomTone.rose),
      HomeBannerKind.restricted => (LucideIcons.circleAlert, AtomTone.rose),
      HomeBannerKind.late => (LucideIcons.clock, AtomTone.amber),
      HomeBannerKind.trial => (LucideIcons.clock, AtomTone.amber),
      HomeBannerKind.billDue => (LucideIcons.receipt, AtomTone.blue),
      HomeBannerKind.message => (LucideIcons.messageCircle, AtomTone.blue),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dark
                ? const AtomAiMark(size: 36, radius: AtomRadius.brControl)
                : HomeIconTile(
                    icon: icon,
                    tone: tone,
                    size: 36,
                    iconSize: 18,
                    background: Colors.white,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    style: AtomText.listTitle.copyWith(
                      color: dark ? Colors.white : fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.body,
                    style: AtomText.secondary.copyWith(color: fg, height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: _actions(context)),
                ],
              ),
            ),
            if (onHide != null)
              AtomPressable(
                onTap: onHide,
                semanticLabel: l.homeHide,
                builder: (_, _) => SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: (dark ? Colors.white : fg).withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = banner;
    void pay() => context.push(V2Routes.paidOf(bill: b.bill));
    void plan() => context.push(V2Routes.plan);
    final amount = b.amount;
    return switch (b.kind) {
      HomeBannerKind.readOnly || HomeBannerKind.late => [
        MiniButton(
          label: amount != null && amount > 0
              ? l.homePayNow(formatRs(amount))
              : l.homePay,
          primary: true,
          onTap: pay,
        ),
        MiniButton(label: l.homeSeeBill, onTap: plan),
      ],
      HomeBannerKind.restricted => [
        MiniButton(
          label: l.homeReadMore,
          onTap: () => context.push(V2Routes.restricted),
        ),
      ],
      HomeBannerKind.trial => [
        MiniButton(label: l.homeKeepIt, primary: true, onTap: plan),
        MiniButton(
          label: l.homeSwitchOff,
          onTap: () => context.push(
            b.addon == null ? V2Routes.plan : V2Routes.addonSwitchOf(b.addon!),
          ),
        ),
      ],
      HomeBannerKind.billDue => [
        MiniButton(label: l.homePay, primary: true, onTap: pay),
        MiniButton(label: l.homeSeeBill, onTap: plan),
      ],
      HomeBannerKind.message => [
        MiniButton(
          label: l.homeRead,
          onDark: true,
          onTap: () => openNotice(context, b.message!.notice),
        ),
      ],
    };
  }
}
