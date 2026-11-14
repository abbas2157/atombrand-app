import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/format/money.dart';
import '../../../core/net/network_status.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../team/ui/team_parts.dart' show teamFailure;
import '../data/outlet_models.dart';
import '../data/outlet_rules.dart';
import '../data/outlets_repository.dart';
import 'outlets_parts.dart';

/// Outlets (11.7, owner): all outlets' cash sales for This month / Last
/// month / This year with how many of the account's outlets are used, then
/// each outlet with its status and figures as the server counts them, and
/// its share of the sales. Add outlet while there is room; WhatsApp
/// Atomshop to ask for more, or to make a single-outlet account
/// multi-outlet.
class OutletsScreen extends ConsumerStatefulWidget {
  const OutletsScreen({super.key});

  @override
  ConsumerState<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends ConsumerState<OutletsScreen> {
  OutletPeriod _period = OutletPeriod.month;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(outletListProvider(_period));
    final online = ref.watch(onlineProvider).value ?? true;
    final list = data.value;
    final brand =
        ref.read(sessionProvider.notifier).current?.brandName ??
        l.outletsMyBrand;
    final canAdd = online && (list?.canAdd ?? false);

    final header = AtomNavyHeader(
      bottom: 16,
      top: Row(
        children: [
          AtomNavyIconButton(
            icon: LucideIcons.chevronLeft,
            label: l.commonBack,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l.outletsTitle,
                style: AtomText.heading.copyWith(color: Colors.white),
              ),
            ),
          ),
          if (canAdd)
            AtomNavyIconButton(
              icon: LucideIcons.plus,
              label: l.outletsAddOutlet,
              onTap: () => context.push(V2Routes.outletAdd),
            ),
        ],
      ),
      child: list == null ? null : _Hero(list: list, period: _period),
    );

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(outletListProvider(_period).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AtomSpace.s6),
          children: [
            header,
            OutletTabs<OutletPeriod>(
              tabs: [for (final p in OutletPeriod.values) (p, p.label(l))],
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
            AtomReadableWidth(
              maxWidth: 720,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AtomSpace.gutter,
                  AtomSpace.s4,
                  AtomSpace.gutter,
                  0,
                ),
                child: switch (data) {
                  AsyncValue(:final value?) => _Body(
                    list: value,
                    onAskMore: () => askAtomshop(
                      value.multi
                          ? l.outletsWaAskMore(brand)
                          : l.outletsWaAskMulti(brand),
                    ),
                  ),
                  AsyncValue(:final error?) => SizedBox(
                    height: 380,
                    child: teamFailure(
                      error,
                      () => ref.invalidate(outletListProvider(_period)),
                    ),
                  ),
                  _ => const AtomLoadingCard(count: 3),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The navy card (`.hero`): cash sales of all outlets for the period, how
/// many outlets are used, and delivered and payments.
class _Hero extends StatelessWidget {
  const _Hero({required this.list, required this.period});

  final OutletList list;
  final OutletPeriod period;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = outletTotals(list.outlets);
    return AtomHeroCard(
      label: l.outletsHeroLabel(period.label(l)),
      labelEnd: list.multi ? l.outletsUsedOf(list.used, list.limit) : null,
      amount: formatRs(t.sales),
      meta: TextSpan(
        text: l.outletsHeroMeta(
          t.delivered,
          formatRs(t.payments),
          list.outlets.length,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.list, required this.onAskMore});

  final OutletList list;
  final VoidCallback onAskMore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = outletTotals(list.outlets).sales;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.outlets.isEmpty)
          SizedBox(
            height: 240,
            child: AtomMessageState(
              icon: LucideIcons.store,
              title: l.outletsEmpty,
            ),
          ),
        for (final o in list.outlets) ...[
          _OutletCard(outlet: o, total: total),
          const SizedBox(height: 10),
        ],
        if (list.multi && !list.canAdd) ...[
          AtomNote(kind: AtomNoteKind.info, message: l.outletsFull(list.limit)),
          const SizedBox(height: 10),
        ],
        if (!list.multi) ...[
          AtomNote(kind: AtomNoteKind.info, message: l.outletsAskMulti),
          const SizedBox(height: 6),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AtomTextLink(
            label: list.multi
                ? l.outletsAskMore(list.limit)
                : l.outletsAskWhatsApp,
            onTap: onAskMore,
          ),
        ),
      ],
    );
  }
}

/// One outlet (`.shop`): its name and status, six figures, its share of
/// the sales and a line of who runs it.
class _OutletCard extends StatelessWidget {
  const _OutletCard({required this.outlet, required this.total});

  final BrandOutlet outlet;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = outlet;
    final f = o.figures ?? const OutletFigures();
    final share = sharePercent(f.sales, total);
    final line = outletCardLine(l, o);
    final figures = [
      (l.outletsCashSales, formatRs(f.sales)),
      (l.outletsOrders, '${f.orders}'),
      (l.outletsPayments, formatRs(f.payments)),
      if (f.bulkWon != null) (l.outletsBulkWon, formatRs(f.bulkWon!)),
      if (f.units != null) (l.outletsInStock, l.outletsUnits(f.units!)),
      (l.outletsAvgOrder, formatRs(f.avgOrder)),
    ];
    return AtomPressable(
      onTap: () => context.push(V2Routes.outletOf(o.id)),
      scaleOnPress: false,
      focusRadius: AtomRadius.brCard,
      semanticLabel: '${o.name}, ${o.status.label(l)}',
      builder: (context, pressed) => Opacity(
        opacity: o.status == OutletStatus.closed ? 0.7 : 1,
        child: Container(
          padding: const EdgeInsets.all(AtomSpace.inset),
          decoration: BoxDecoration(
            color: AtomColors.paper,
            borderRadius: AtomRadius.brCard,
            border: Border.all(
              color: pressed ? AtomColors.primaryLine : AtomColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AtomSpace.s2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(o.name, style: AtomText.listTitle),
                        if (o.isMain)
                          Text(
                            l.outletsMain,
                            style: AtomText.small.copyWith(
                              color: AtomColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AtomSpace.s2),
                  OutletStatusPill(status: o.status),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final cols =
                      c.maxWidth < 280 ||
                          MediaQuery.textScalerOf(context).scale(10) >= 15
                      ? 2
                      : 3;
                  final w = (c.maxWidth - (cols - 1) * AtomSpace.s2) / cols;
                  return Wrap(
                    spacing: AtomSpace.s2,
                    runSpacing: AtomSpace.s2,
                    children: [
                      for (final (label, value) in figures)
                        SizedBox(
                          width: w,
                          child: OutletFigure(label: label, value: value),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AtomProgressBar(
                      value: share / 100,
                      colour: AtomColors.primary,
                      semanticLabel: l.outletsOfSales(share),
                    ),
                  ),
                  const SizedBox(width: AtomSpace.s2),
                  Text(
                    l.outletsOfSales(share),
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ],
              ),
              if (line.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  line,
                  style: AtomText.small.copyWith(color: AtomColors.faint),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
