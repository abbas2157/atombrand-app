import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';

/// Switch outlet (5.7): All outlets, then each outlet with this month's
/// sales and orders to confirm. Choosing one sets the session's outlet;
/// every call after it carries `X-Outlet`, and Home reads itself again.
class OutletSwitcherSheet extends ConsumerWidget {
  const OutletSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    final session = ref.watch(sessionProvider.notifier).current;
    final list = ref.watch(homeOutletsProvider);
    final brand = session?.brandName ?? l.homeBrandPartner;
    final current = session?.outletId;

    // Until the figures come, the session's own outlets are listed.
    final data = list.value;
    final outlets =
        data?.outlets ??
        [
          for (final o in session?.outlets ?? const <Outlet>[])
            OutletFigures(
              id: o.id,
              name: o.name,
              main: o.isMain,
              status: o.active ? 'open' : 'paused',
            ),
        ];

    void pick(int? id, String? name) {
      ref.read(sessionProvider.notifier).selectOutlet(id, name);
      showAtomToast(
        context,
        kind: AtomToastKind.ok,
        message: l.homeSwitched(name ?? l.homeAllOutlets),
      );
      Navigator.of(context).pop();
    }

    Widget figures(int sales, int toConfirm) => Wrap(
      spacing: 14,
      children: [
        for (final (label, value) in [
          (l.homeSales, data == null ? '…' : formatRs(sales)),
          (l.homeToConfirm, data == null ? '…' : '$toConfirm'),
        ])
          Text.rich(
            TextSpan(
              style: AtomText.small,
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: value,
                  style: AtomText.small.copyWith(
                    color: AtomColors.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    Widget tile(IconData icon, AtomTone tone) => Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: AtomRadius.brControl,
      ),
      child: Icon(icon, size: AtomIcon.row, color: tone.fg),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AtomSpace.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 5.7 has no close X: the grab handle and the backdrop close it.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(l.homeSwitchOutlet, style: AtomText.heading),
                ),
                const SizedBox(height: 2),
                Text(
                  l.homeOutletsSub(brand, outlets.length),
                  style: AtomText.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (list.hasError && data == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AtomNote(
                kind: AtomNoteKind.warning,
                message: l.homeOutletsLoadError,
                compact: true,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AtomOptionCard(
              leading: tile(LucideIcons.layoutGrid, AtomTone.grey),
              title: l.homeAllOutlets,
              selected: current == null,
              onTap: () => pick(null, null),
              subtitleWidget: figures(
                data?.totalSales ?? 0,
                data?.totalToConfirm ?? 0,
              ),
            ),
          ),
          for (final o in outlets)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AtomOptionCard(
                leading: tile(
                  LucideIcons.store,
                  o.paused ? AtomTone.amber : AtomTone.blue,
                ),
                title: o.name,
                titleTag: o.main
                    ? AtomPill(label: l.homeMain, tone: AtomTone.blue)
                    : o.paused
                    ? AtomPill(label: l.homePausedPill, tone: AtomTone.amber)
                    : null,
                selected: current == o.id,
                onTap: () => pick(o.id, o.name),
                subtitleWidget: figures(o.sales, o.toConfirm),
              ),
            ),
          // `.btn-outline`, 46 tall: "+ Add an outlet … 3 of 5 used".
          if (data != null && data.canAdd)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: AtomPressable(
                semanticLabel: l.homeAddOutlet,
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push(V2Routes.outletAdd);
                },
                builder: (_, pressed) => Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pressed ? AtomColors.surface : AtomColors.paper,
                    borderRadius: AtomRadius.brControl,
                    border: Border.all(color: AtomColors.line2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.plus,
                        size: 18,
                        color: AtomColors.ink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.homeAddOutlet,
                          style: AtomText.button.copyWith(fontSize: 15),
                        ),
                      ),
                      if (data.limit != null && data.used != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          l.homeUsed(data.used!, data.limit!),
                          style: AtomText.secondary.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: TextButton(
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                router.push(V2Routes.outlets);
              },
              child: Text(
                l.homeManageOutlets,
                style: AtomText.body.copyWith(
                  color: AtomColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
