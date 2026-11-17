import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../team/ui/team_parts.dart' show teamFailure;
import '../data/outlet_models.dart';
import '../data/outlet_rules.dart';
import '../data/outlets_repository.dart';
import 'outlet_form_screen.dart';
import 'outlets_parts.dart';

/// An outlet (11.9): where it is, when it opened and who runs it; this
/// month's cash sales, orders, payments and open orders; its latest
/// orders; the cities it serves, staff, stock and contact; and its status:
/// open, pause or close, with what each does. The main outlet can't be
/// paused or closed, and closing waits until it has no open orders and no
/// stock.
class OutletScreen extends ConsumerStatefulWidget {
  const OutletScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<OutletScreen> createState() => _OutletScreenState();
}

class _OutletScreenState extends ConsumerState<OutletScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  OutletStatus? _chosen;
  bool _saving = false;

  Future<void> _setStatus(BrandOutlet o, OutletStatus to) async {
    final l = AppLocalizations.of(context);
    final ok = await switch (to) {
      OutletStatus.paused => showAtomConfirm(
        context,
        title: l.outletsPauseTitle(o.name),
        body: l.outletsPauseBody,
        confirmLabel: l.outletsPause,
      ),
      OutletStatus.closed => showAtomConfirm(
        context,
        title: l.outletsCloseTitle(o.name),
        body: l.outletsCloseBody,
        confirmLabel: l.outletsCloseOutlet,
        destructive: true,
      ),
      OutletStatus.open => showAtomConfirm(
        context,
        title: l.outletsOpenTitle(o.name),
        body: l.outletsOpenBody,
        confirmLabel: l.outletsOpenIt,
      ),
    };
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    final r = await ref.read(outletsRepositoryProvider).setStatus(o.id, to);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk(:final value):
        setState(() => _chosen = null);
        refreshOutlets(ref);
        ref.read(accessProvider.notifier).refresh();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.outletsStatusDone(
            value.name,
            value.status.label(l).toLowerCase(),
          ),
        );
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(l, failure),
        );
    }
  }

  void _edit(BrandOutlet o) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => OutletFormScreen(outlet: o)));

  Widget _head(BrandOutlet o, {required bool canEdit}) => Container(
    padding: const EdgeInsets.only(bottom: 14),
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(bottom: BorderSide(color: AtomColors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomFlowBar(
          trailing: [
            if (canEdit)
              AtomIconButton(
                icon: LucideIcons.pencil,
                label: l.outletsEdit,
                onTap: _saving ? null : () => _edit(o),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(o.name, style: AtomText.pageTitle),
                    ),
                  ),
                  OutletStatusPill(status: o.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  [?o.address, ?o.city?.title].join(', '),
                  if (o.openedOn case final opened?)
                    l.outletsOpenedDay(AtomDates.day(opened)),
                  if (o.runBy ?? o.managerName case final runner?)
                    l.outletsRunBy(runner),
                ].where((s) => s.isNotEmpty).join(' · '),
                style: AtomText.secondary,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(outletProvider(widget.id));
    final online = ref.watch(onlineProvider).value ?? true;
    final o = data.value;

    if (o == null) {
      final e = data.error;
      return Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          children: [
            const AtomFlowBar(),
            Expanded(
              child: e == null
                  ? const Padding(
                      padding: EdgeInsets.all(AtomSpace.gutter),
                      child: AtomLoadingCard(),
                    )
                  : (e is ApiFailure && e.kind == ApiFailureKind.notFound)
                  ? AtomMessageState(
                      icon: LucideIcons.store,
                      title: l.outletsOutletGone,
                    )
                  : teamFailure(
                      e,
                      () => ref.invalidate(outletProvider(widget.id)),
                    ),
            ),
          ],
        ),
      );
    }

    final f = o.figures ?? const OutletFigures();
    final chosen = _chosen ?? o.status;
    final cityNames = [for (final c in o.cities) c.title];
    final plan = statusPlan(
      l,
      current: o.status,
      chosen: chosen,
      isMain: o.isMain,
      cities: cityNames,
      openOrders: o.openOrders ?? 0,
      units: f.units,
    );
    final due = f.sales - f.payments;
    final orders = ref.watch(outletOrdersProvider(o.id));

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(outletOrdersProvider(o.id));
                return ref.refresh(outletProvider(widget.id).future);
              },
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _head(o, canEdit: online && o.status != OutletStatus.closed),
                  AtomReadableWidth(
                    maxWidth: 720,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AtomSpace.gutter,
                        AtomSpace.s3,
                        AtomSpace.gutter,
                        AtomSpace.s6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AtomKpiGrid(
                            kpis: [
                              AtomKpi(
                                label: l.outletsKpiSales,
                                value: formatRs(f.sales),
                                note: l.outletsKpiSalesNote(f.delivered),
                              ),
                              AtomKpi(
                                label: l.outletsKpiOrders,
                                value: '${f.orders}',
                                note: l.outletsKpiOrdersNote(f.toConfirm),
                              ),
                              AtomKpi(
                                label: l.outletsKpiPayments,
                                value: formatRs(f.payments),
                                note: due > 0
                                    ? l.outletsKpiDue(formatRs(due))
                                    : null,
                              ),
                              AtomKpi(
                                label: l.outletsKpiOpen,
                                value: '${o.openOrders ?? 0}',
                                note: l.outletsKpiOpenNote,
                              ),
                            ],
                          ),
                          const SizedBox(height: AtomSpace.s3),
                          AtomSectionLabel(
                            l.outletsOrdersThisMonth,
                            page: false,
                          ),
                          _Orders(orders: orders),
                          const SizedBox(height: AtomSpace.s3),
                          AtomInfoCard(
                            lines: [
                              AtomInfoLine(
                                label: l.outletsCitiesServes,
                                // none picked: it serves the city it is in
                                value: cityNames.isNotEmpty
                                    ? cityNames.join(', ')
                                    : o.city?.title ?? '–',
                              ),
                              AtomInfoLine(
                                label: l.outletsStaff,
                                value: switch (o.staffNames) {
                                  final names? when names.isNotEmpty =>
                                    names.join(', '),
                                  _ =>
                                    f.staffAll > 0
                                        ? l.outletsStaffAll(f.staff, f.staffAll)
                                        : l.outletsStaffHere(f.staff),
                                },
                              ),
                              if (f.units != null)
                                AtomInfoLine(
                                  label: l.outletsStock,
                                  value: l.outletsUnits(f.units!),
                                ),
                              if (f.bulkDeals != null)
                                AtomInfoLine(
                                  label: l.outletsBulkDeals,
                                  value:
                                      '${f.bulkDeals}${f.bulkWon == null ? '' : ' · ${formatRs(f.bulkWon!)}'}',
                                ),
                              if (o.phone != null)
                                AtomInfoLine(
                                  label: l.outletsContact,
                                  value: o.phone!,
                                ),
                            ],
                          ),
                          if (!o.isMain) ...[
                            const SizedBox(height: AtomSpace.s3),
                            Text(l.outletsStatus, style: AtomText.fieldLabel),
                            const SizedBox(height: 6),
                            AtomSegmented<OutletStatus>(
                              segments: [
                                for (final s in OutletStatus.values)
                                  AtomSegment(s, s.label(l)),
                              ],
                              selected: chosen,
                              onChanged: _saving
                                  ? (_) {}
                                  : (s) => setState(() => _chosen = s),
                            ),
                          ],
                          const SizedBox(height: AtomSpace.s3),
                          AtomNote(
                            kind: noteKindOf(plan.tone),
                            message: plan.note,
                            iconless: true,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!o.isMain && chosen != o.status)
            OutletBottomBar(
              children: [
                AtomButton(
                  label: online ? plan.button : l.outletsNeedsInternet,
                  saving: _saving,
                  kind: chosen == OutletStatus.closed
                      ? AtomButtonKind.danger
                      : AtomButtonKind.primary,
                  onPressed: online && plan.canSave
                      ? () => _setStatus(o, chosen)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The outlet's latest orders (`.or` rows): number, product · city and
/// status. Each opens the order.
class _Orders extends StatelessWidget {
  const _Orders({required this.orders});

  final AsyncValue<List<OutletOrder>> orders;

  static (String, AtomTone) _status(AppLocalizations l, String s) =>
      switch (s) {
        'Pending' => (l.outletsOrderPending, AtomTone.amber),
        'Varification' => (l.outletsOrderConfirming, AtomTone.amber),
        'Processing' => (l.outletsOrderProcessing, AtomTone.blue),
        'Delivered' => (l.outletsOrderDelivered, AtomTone.green),
        'Completed' => (l.outletsOrderCompleted, AtomTone.green),
        'Instalments' => (l.outletsOrderInstalments, AtomTone.blue),
        'Cancelled' => (l.outletsOrderCancelled, AtomTone.rose),
        _ => (s, AtomTone.grey),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = orders.value;
    if (list == null) {
      return orders.hasError
          ? const SizedBox.shrink()
          : const AtomLoadingRows(count: 2);
    }
    if (list.isEmpty) {
      return Text(l.outletsNoOrders, style: AtomText.secondary);
    }
    return AtomListCard(
      children: [
        for (final order in list.take(3))
          Builder(
            builder: (context) {
              final (label, tone) = _status(l, order.status);
              final what = [?order.product, ?order.city].join(' · ');
              return AtomPressable(
                onTap: order.uuid.isEmpty
                    ? null
                    : () => context.push(V2Routes.orderOf(order.uuid)),
                scaleOnPress: false,
                focusRadius: BorderRadius.zero,
                semanticLabel: '#${order.id}, $what, $label',
                builder: (_, pressed) => Container(
                  color: pressed ? AtomColors.head : AtomColors.paper,
                  constraints: const BoxConstraints(
                    minHeight: AtomSize.tapTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AtomSpace.inset,
                    vertical: 10,
                  ),
                  child: ExcludeSemantics(
                    child: Builder(
                      builder: (context) {
                        final id = Text(
                          '#${order.id}',
                          style: AtomText.smallButton.copyWith(
                            color: AtomColors.ink,
                          ),
                        );
                        final text = Text(
                          what,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtomText.secondary,
                        );
                        final pill = AtomPill(
                          label: label,
                          tone: tone,
                          compact: true,
                        );
                        // Large text: number and status above, the
                        // product under them.
                        if (MediaQuery.textScalerOf(context).scale(10) >= 15) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: AtomSpace.s2,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [id, pill],
                              ),
                              text,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            id,
                            const SizedBox(width: 10),
                            Expanded(child: text),
                            const SizedBox(width: AtomSpace.s2),
                            pill,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
