import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../core/access/access.dart';
import '../core/access/access_controller.dart';
import '../core/session/session.dart';
import '../core/session/session_controller.dart';
import '../design/design.dart';
import '../features/menu/data/menu_counts.dart';
import '../widgets/widgets.dart';
import 'routes.dart';

/// One row of a tab's sheet.
class TabChoice {
  const TabChoice({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.open,
    this.badge,
  });

  final IconData icon;
  final AtomTone tone;
  final String title;
  final String subtitle;
  final int? badge;

  /// What choosing it does, once the sheet is closed.
  final VoidCallback open;
}

/// Business (the bar's 2nd place): Orders, AtomPay orders, Bulk deals,
/// Products, Stock and Warehouses. Each shows only when the person's role
/// works it and its add-on is on (the Menu's rules); the rest close up.
List<TabChoice> businessChoices(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback openOrders,
  required VoidCallback openBulk,
  required VoidCallback openProducts,
}) {
  final l = AppLocalizations.of(context);
  final who = ref.read(sessionProvider.notifier).current?.who;
  bool can(String p) => who?.can(p) ?? false;
  final access = ref.read(accessProvider);
  final counts = ref.read(menuCountsProvider).value;
  final router = GoRouter.of(context);
  return [
    if (can(BrandPermission.ordersView))
      TabChoice(
        icon: LucideIcons.fileText,
        tone: AtomTone.blue,
        title: l.tabOrders,
        subtitle: l.bizOrdersSub,
        badge: counts?.ordersToConfirm,
        open: openOrders,
      ),
    if (can(BrandPermission.atompayView))
      TabChoice(
        icon: LucideIcons.handCoins,
        tone: AtomTone.green,
        title: l.menuAtompay,
        subtitle: l.bizAtompaySub,
        badge: counts?.atompayToHandOver,
        open: () => router.go(V2Routes.atompayOrders),
      ),
    if (can(BrandPermission.bulkView))
      TabChoice(
        icon: LucideIcons.funnel,
        tone: AtomTone.amber,
        title: l.tabBulk,
        subtitle: l.bizBulkSub,
        badge: counts?.requestsWaiting,
        open: openBulk,
      ),
    if (can(BrandPermission.catalogueView))
      TabChoice(
        icon: LucideIcons.tag,
        tone: AtomTone.purple,
        title: l.tabProducts,
        subtitle: l.bizProductsSub,
        badge: counts?.productsToCheck,
        open: openProducts,
      ),
    // Lapsed, Inventory still opens read-only (as in the Menu).
    if (access.canRead(Addon.inventory) && can(BrandPermission.stockView))
      TabChoice(
        icon: LucideIcons.layoutGrid,
        tone: AtomTone.green,
        title: l.menuStock,
        subtitle: l.bizStockSub,
        badge: counts?.outOfStock,
        open: () => router.push(V2Routes.stock),
      ),
    if (access.canRead(Addon.inventory) && can(BrandPermission.stockManage))
      TabChoice(
        icon: LucideIcons.building,
        tone: AtomTone.grey,
        title: l.menuWarehouses,
        subtitle: l.bizWarehousesSub,
        open: () => router.push(V2Routes.warehouses),
      ),
  ];
}

/// Insights (the bar's 4th place): Reports (the role's reports right) and
/// Ask Atom (its add-on).
List<TabChoice> insightsChoices(BuildContext context, WidgetRef ref) {
  final l = AppLocalizations.of(context);
  final who = ref.read(sessionProvider.notifier).current?.who;
  final access = ref.read(accessProvider);
  final router = GoRouter.of(context);
  return [
    if (who?.can(BrandPermission.moneyReports) ?? false)
      TabChoice(
        icon: LucideIcons.chartColumn,
        tone: AtomTone.blue,
        title: l.menuReports,
        subtitle: l.insReportsSub,
        open: () => router.push(V2Routes.reports),
      ),
    if (access.has(Addon.askAtom))
      TabChoice(
        icon: LucideIcons.sparkle,
        tone: AtomTone.purple,
        title: l.atomTitle,
        subtitle: l.insAskAtomSub,
        open: () => router.push(V2Routes.askAtom),
      ),
  ];
}

/// Opens [build]'s choices: straight away when there is only one,
/// otherwise as a sheet with a title, a line under it and one row each.
/// The sheet builds the rows again as the counts it shows ([watch]) arrive.
Future<void> openTabChoices(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String subtitle,
  required List<TabChoice> Function(BuildContext, WidgetRef) build,
  List<ProviderListenable<Object?>> watch = const [],
}) async {
  final choices = build(context, ref);
  if (choices.isEmpty) return;
  if (choices.length == 1) {
    choices.single.open();
    return;
  }
  await showAtomSheet<void>(
    context,
    useRootNavigator: true,
    builder: (_) => Consumer(
      builder: (sheet, r, _) {
        for (final w in watch) {
          r.watch(w);
        }
        return _ChoiceSheet(
          title: title,
          subtitle: subtitle,
          choices: build(sheet, r),
        );
      },
    ),
  );
}

class _ChoiceSheet extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.subtitle,
    required this.choices,
  });

  final String title;
  final String subtitle;
  final List<TabChoice> choices;

  @override
  Widget build(BuildContext sheet) => Padding(
    // The row group brings its own 16 at the sides; the header takes 16.
    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: AtomText.heading),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AtomText.secondary),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(10, 0),
                child: AtomIconButton(
                  icon: LucideIcons.x,
                  label: AppLocalizations.of(sheet).commonClose,
                  onTap: () => Navigator.of(sheet).maybePop(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AtomRowGroup(
          children: [
            for (final c in choices)
              AtomNavRow(
                icon: c.icon,
                tone: c.tone,
                title: c.title,
                subtitle: c.subtitle,
                badge: c.badge == null || c.badge == 0 ? null : c.badge,
                onTap: () {
                  Navigator.of(sheet).pop();
                  c.open();
                },
              ),
          ],
        ),
      ],
    ),
  );
}
