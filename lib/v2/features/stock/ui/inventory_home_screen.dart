import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'stock_parts.dart';

/// 9.1 Stock (and 9.2, the same screen for a brand with one outlet): what
/// can be sold, what is held, the actions, and three views — by product,
/// held for orders, find a serial.
class InventoryHomeScreen extends ConsumerStatefulWidget {
  const InventoryHomeScreen({super.key});

  @override
  ConsumerState<InventoryHomeScreen> createState() =>
      _InventoryHomeScreenState();
}

enum _View { products, held, serial }

class _InventoryHomeScreenState extends ConsumerState<InventoryHomeScreen> {
  _View _view = _View.products;
  String _level = 'all';
  int? _outletId;
  final _serial = TextEditingController();
  String? _looking;

  StockQuery get _query => (show: _level, search: '', outletId: _outletId);

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    refreshStock(ref);
    if (_looking != null) ref.invalidate(unitLookupProvider(_looking!));
    await ref.read(stockOverviewProvider(_query).future);
  }

  void _find(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _looking = s);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(stockOverviewProvider(_query));
    // The totals and the header don't follow the level filter: keep the
    // first answer on screen while a filtered one loads.
    final page = data.value;
    final session = stockSession(ref);
    final who = session?.who;
    final allOutlets =
        session?.outletId == null && (session?.multiOutlet ?? false);

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: page == null
          ? Column(
              children: [
                _Header(page: null, scope: ''),
                Expanded(
                  child: data.hasError
                      ? StockFailed(
                          error: data.error!,
                          onRetry: () =>
                              ref.invalidate(stockOverviewProvider(_query)),
                        )
                      : StockLoading(),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _Header(
                    page: page,
                    scope: _scope(page, allOutlets, session?.outletName),
                  ),
                  const OfflineBar(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        _Actions(
                          page: page,
                          canChange: who?.can('stock.change') ?? false,
                        ),
                        ..._notices(page, session?.who.isOwner ?? false),
                        if (page.totals.out > 0)
                          _OutAlert(page: page, who: who),
                        AtomSegmented<_View>(
                          segments: [
                            AtomSegment(_View.products, l.stockViewByProduct),
                            AtomSegment(
                              _View.held,
                              page.held.isEmpty
                                  ? l.stockHeld
                                  : l.stockViewHeldN(page.held.length),
                            ),
                            AtomSegment(_View.serial, l.stockViewSerial),
                          ],
                          selected: _view,
                          onChanged: (v) => setState(() => _view = v),
                        ),
                        switch (_view) {
                          _View.products => _products(
                            data.isLoading,
                            page,
                            allOutlets,
                          ),
                          _View.held => _HeldList(held: page.held),
                          _View.serial => _serialView(),
                        },
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _scope(StockOverview page, bool allOutlets, String? outletName) {
    final l = AppLocalizations.of(context);
    final whs = l.stockWarehousesN(page.warehouses.length);
    if (allOutlets) return l.stockScopeAll(whs);
    final name = outletName ?? page.warehouses.firstOrNull?.outlet;
    return name == null ? whs : l.stockScopeNamed(name, whs);
  }

  List<Widget> _notices(StockOverview page, bool owner) {
    final l = AppLocalizations.of(context);
    final a = page.access;
    return [
      if (a.trial && !a.readOnly)
        AtomNote(
          kind: AtomNoteKind.info,
          icon: LucideIcons.clock,
          title: a.daysLeft == null
              ? l.stockTrialTitle
              : l.stockTrialDaysLeft(a.daysLeft!),
          message: owner ? l.stockTrialOwner : l.stockTrialStaff,
        ),
      if (a.trial && !a.readOnly && owner)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AtomTextLink(
            label: l.stockPlanBilling,
            onTap: () => context.push(V2Routes.plan),
          ),
        ),
      if (a.readOnly) ...[
        AtomNote(
          kind: AtomNoteKind.warning,
          icon: LucideIcons.lock,
          title: l.stockReadOnlyTitle,
          message: l.stockReadOnlyBody,
        ),
        if (owner)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AtomTextLink(
              label: l.stockSwitchBackOn,
              onTap: () =>
                  context.push(V2Routes.addonSwitchOf(Addon.inventory)),
            ),
          ),
      ],
    ];
  }

  Widget _products(bool loading, StockOverview page, bool allOutlets) {
    final l = AppLocalizations.of(context);
    final session = stockSession(ref);
    final outlets = session?.outlets ?? const [];
    final rows = <(StockProduct, StockVariant)>[
      for (final p in page.items)
        for (final v in p.variants)
          if (_level != 'low' || v.state == 'low') (p, v),
    ];
    final widest = rows.fold<int>(
      1,
      (m, r) => r.$2.onHand > m ? r.$2.onHand : m,
    );
    final t = page.totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          children: [
            Expanded(
              child: AtomChips<String>(
                chips: [
                  AtomChip('all', l.stockChipAll(t.variants)),
                  AtomChip('low', l.stockChipLow(t.low)),
                  AtomChip('out', l.stockChipOut(t.out)),
                ],
                selected: _level,
                onChanged: (v) => setState(() => _level = v),
              ),
            ),
            if (allOutlets && outlets.length > 1)
              StockFilterChip(
                label: _outletId == null
                    ? l.stockAllOutlets
                    : outlets
                          .firstWhere(
                            (o) => o.id == _outletId,
                            orElse: () => outlets.first,
                          )
                          .name,
                active: _outletId != null,
                onTap: () async {
                  final picked = await showAtomSelect<int>(
                    context,
                    title: l.stockOutlet,
                    selected: _outletId ?? 0,
                    options: [
                      AtomOption(value: 0, label: l.stockAllOutlets),
                      for (final o in outlets)
                        AtomOption(value: o.id, label: o.name),
                    ],
                  );
                  if (picked != null) {
                    setState(() => _outletId = picked == 0 ? null : picked);
                  }
                },
              ),
          ],
        ),
        if (loading)
          const AtomLoadingCard()
        else if (rows.isEmpty)
          StockCard(
            child: AtomMessageState(
              icon: LucideIcons.package,
              title: _level == 'all' ? l.stockEmptyTitle : l.stockNothingHere,
              body: _level == 'all'
                  ? l.stockEmptyBody
                  : (_level == 'low' ? l.stockEmptyLow : l.stockEmptyOut),
              art: false,
            ),
          )
        else
          StockRows(
            children: [
              for (final (p, v) in rows)
                _VariantRow(
                  product: p,
                  variant: v,
                  widest: widest,
                  where: whereLine(
                    l,
                    v,
                    page.warehouses,
                    byOutlet: allOutlets && _outletId == null,
                  ),
                ),
            ],
          ),
        if (page.hasMore)
          AtomButton(
            label: l.stockSeeAll(page.total),
            kind: AtomButtonKind.outline,
            onPressed: () => context.push(V2Routes.stockList(show: _level)),
          ),
        Text(l.stockAvailableNote, style: AtomText.small),
      ],
    );
  }

  Widget _serialView() {
    final l = AppLocalizations.of(context);
    final looking = _looking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AtomTextField(
                label: l.stockSerialOrImei,
                controller: _serial,
                placeholder: l.stockTypeNumber,
                prefix: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AtomColors.muted,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _find,
              ),
            ),
            const SizedBox(width: 8),
            AtomButton(
              label: l.stockScan,
              icon: LucideIcons.scanLine,
              kind: AtomButtonKind.outline,
              expand: false,
              onPressed: () => context.push(V2Routes.scanSerial),
            ),
          ],
        ),
        AtomButton(label: l.stockLookUp, onPressed: () => _find(_serial.text)),
        if (looking != null)
          ref
              .watch(unitLookupProvider(looking))
              .when(
                loading: () => const AtomLoadingCard(count: 1),
                error: (e, _) => StockFailed(
                  error: e,
                  onRetry: () => ref.invalidate(unitLookupProvider(looking)),
                ),
                data: (found) => UnitFoundCard(found: found),
              ),
      ],
    );
  }
}

/// The navy header: Available to sell, and Held / Live / Low or out.
class _Header extends StatelessWidget {
  const _Header({required this.page, required this.scope});

  final StockOverview? page;
  final String scope;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = page?.totals;
    final products = page?.total ?? 0;
    return AtomNavyHeader(
      bottom: 16,
      top: Row(
        children: [
          AtomNavyIconButton(
            icon: LucideIcons.chevronLeft,
            label: l.commonBack,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l.stockTitle,
                    style: AtomText.heading.copyWith(color: Colors.white),
                  ),
                ),
                if (scope.isNotEmpty)
                  Text(
                    scope,
                    style: AtomText.small.copyWith(color: AtomColors.navText),
                  ),
              ],
            ),
          ),
          AtomNavyIconButton(
            icon: LucideIcons.scanLine,
            label: l.stockScanSerial,
            onTap: () => context.push(V2Routes.scanSerial),
          ),
          const SizedBox(width: 6),
          AtomNavyIconButton(
            icon: LucideIcons.warehouse,
            label: l.stockWarehouses,
            onTap: () => context.push(V2Routes.warehouses),
          ),
        ],
      ),
      child: t == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.stockAvailableToSell,
                            style: AtomText.secondary.copyWith(
                              color: AtomColors.navText,
                            ),
                          ),
                          Text(
                            '${t.available}',
                            style: AtomText.amountLg.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            l.stockOfUnits(t.units, products),
                            style: AtomText.secondary.copyWith(
                              color: AtomColors.navText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AtomPressable(
                      onTap: () => context.push(V2Routes.stockList()),
                      semanticLabel: l.stockFullList,
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          l.stockFullList,
                          style: AtomText.smallButton.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    _Box(label: l.stockHeldForOrders, value: '${t.held}'),
                    _Box(
                      label: l.stockLiveOn,
                      value: page!.fromCopy
                          ? '–'
                          : l.stockLiveOf(t.live, t.listed),
                    ),
                    _Box(
                      label: l.stockLowOrOut,
                      value: l.stockLowOutValue(t.low + t.out, t.out),
                      warn: t.low + t.out > 0,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AtomColors.navLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AtomText.small.copyWith(color: AtomColors.navText),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AtomText.listTitle.copyWith(
              fontSize: 18,
              color: warn ? AtomColors.darkAmber : Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.page, required this.canChange});

  final StockOverview page;
  final bool canChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = !page.access.readOnly;
    void go(String r) => context.push(r);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (canChange) ...[
          Expanded(
            child: StockActionTile(
              icon: LucideIcons.arrowDownToLine,
              tone: AtomTone.green,
              label: l.stockIn,
              onTap: on ? () => go(V2Routes.stockIn()) : null,
            ),
          ),
          Expanded(
            child: StockActionTile(
              icon: LucideIcons.arrowLeftRight,
              tone: AtomTone.amber,
              label: l.stockMove,
              onTap: on ? () => go(V2Routes.stockMove) : null,
            ),
          ),
          Expanded(
            child: StockActionTile(
              icon: LucideIcons.slidersHorizontal,
              tone: AtomTone.rose,
              label: l.stockAdjust,
              onTap: on ? () => go(V2Routes.stockAdjust) : null,
            ),
          ),
        ],
        Expanded(
          child: StockActionTile(
            icon: LucideIcons.clock,
            tone: AtomTone.grey,
            label: l.stockHistory,
            onTap: () => go(V2Routes.stockHistory),
          ),
        ),
      ],
    );
  }
}

class _OutAlert extends StatelessWidget {
  const _OutAlert({required this.page, required this.who});

  final StockOverview page;
  final Who? who;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = page.totals.out;
    final canIn = canChangeStock(who, page.access);
    return StockCard(
      tone: AtomTone.rose,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const AtomIconTile(
            icon: LucideIcons.ban,
            tone: AtomTone.rose,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.stockOutAlert(n),
                  style: AtomText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  l.stockOutAlertBody,
                  style: AtomText.secondary.copyWith(
                    color: AtomColors.noteRoseText,
                  ),
                ),
              ],
            ),
          ),
          if (canIn)
            AtomButton.small(
              label: l.stockIn,
              onPressed: () => context.push(V2Routes.stockIn()),
            ),
        ],
      ),
    );
  }
}

/// A variant's row: thumb, title, level bar, where, available and held.
class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.product,
    required this.variant,
    required this.widest,
    required this.where,
  });

  final StockProduct product;
  final StockVariant variant;
  final int widest;
  final String where;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = variant;
    final bar = levelBar(v.available, v.held, widest);
    final code = product.prNumber ?? v.sku;
    final sub = [
      if (v.name.isNotEmpty && v.name != 'Standard') v.name,
      ?code,
    ].join(' · ');
    return AtomPressable(
      onTap: () => context.push(V2Routes.productStockOf(product.id)),
      semanticLabel: l.stockVariantSemantics(product.title, v.available),
      scaleOnPress: false,
      builder: (context, pressed) => Container(
        color: pressed ? AtomColors.head : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtomIconTile(
              icon: LucideIcons.package,
              tone: AtomTone.blue,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    product.title,
                    style: AtomText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AtomColors.ink,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: AtomText.small.copyWith(color: AtomColors.faint),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: StockLevelBar(
                      available: bar.available,
                      held: bar.held,
                      state: v.state,
                      semanticLabel: l.stockLevelSemantics(
                        v.available,
                        v.held,
                        v.onHand,
                      ),
                    ),
                  ),
                  Text(where, style: AtomText.small),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                Text(
                  '${v.available}',
                  style: AtomText.amount.copyWith(
                    fontSize: 24,
                    color: stateInk(v.state),
                  ),
                ),
                Text(
                  l.stockAvailableWord,
                  style: AtomText.tag.copyWith(
                    color: AtomColors.faint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (v.held > 0)
                  Text(
                    l.stockHeldN(v.held),
                    style: AtomText.tag.copyWith(
                      color: AtomColors.pipe4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                StockTag(
                  label: stateLabel(l, v.state),
                  tone: stateTone(v.state),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Units held for cash orders and bulk deals.
class _HeldList extends StatelessWidget {
  const _HeldList({required this.held});

  final List<StockHold> held;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (held.isEmpty) {
      return StockCard(
        child: AtomMessageState(
          icon: LucideIcons.package,
          title: l.stockHeldEmptyTitle,
          body: l.stockHeldEmptyBody,
          art: false,
        ),
      );
    }
    return StockRows(
      children: [
        for (final h in held)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AtomIconTile(
                  icon: h.forDeal ? LucideIcons.funnel : LucideIcons.package,
                  tone: h.forDeal ? AtomTone.amber : AtomTone.blue,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.qty} × ${variantTitle(h.product ?? '', h.variant ?? '')}',
                        style: AtomText.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          h.forDeal
                              ? l.stockBulkDealN('${h.orderId}')
                              : l.stockCashOrderN('${h.orderId}'),
                          if (h.warehouse != null) l.stockFromWh(h.warehouse!),
                          if (h.since != null)
                            l.stockSince(_since(l, h.since!)),
                        ].join(' · '),
                        style: AtomText.small.copyWith(color: AtomColors.faint),
                      ),
                    ],
                  ),
                ),
                if (h.orderId != null)
                  AtomButton.small(
                    label: l.stockOpen,
                    onPressed: () => h.forDeal
                        ? context.push(V2Routes.dealOf(h.orderId!))
                        : h.orderUuid != null
                        ? context.push(V2Routes.orderOf(h.orderUuid!))
                        // An older server sent no uuid: the Orders tab.
                        : context.go(V2Routes.orders),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _since(AppLocalizations l, DateTime d) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days == 0) return l.stockSinceToday;
    if (days == 1) return l.stockSinceYesterday;
    return AtomDates.short(d);
  }
}

/// What a looked-up serial is, and what can be done with it.
class UnitFoundCard extends ConsumerWidget {
  const UnitFoundCard({super.key, required this.found, this.actions = true});

  final UnitLookup found;
  final bool actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who = stockWho(ref);
    final canChange = who?.can('stock.change') ?? false;
    final u = found.unit;
    final (label, tone) = switch (found.found) {
      UnitFound.inStock => (l.stockStateIn, AtomTone.green),
      UnitFound.delivered => (l.stockMoveDelivered, AtomTone.grey),
      UnitFound.removed => (l.stockRemoved, AtomTone.rose),
      UnitFound.notFound => (l.stockNotFoundTitle, AtomTone.grey),
    };
    final title =
        u?.title ??
        (found.last == null
            ? null
            : variantTitle(
                found.last!.product ?? '',
                found.last!.variant ?? '',
              ));
    final came = found.cameIn;
    final last = found.last;
    return StockCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Row(
            children: [
              Expanded(child: Text(found.serial, style: AtomText.listTitle)),
              StockTag(label: label, tone: tone),
            ],
          ),
          if (title != null && title.isNotEmpty)
            Text(title, style: AtomText.body),
          if (found.found == UnitFound.notFound)
            Text(l.stockNotInYourStock, style: AtomText.secondary),
          if (u?.warehouse != null)
            StockLine(label: l.stockWhere, value: stockValue(u!.warehouse!)),
          if (came != null)
            StockLine(
              label: l.stockCameIn,
              value: stockValue(
                [
                  if (came.date != null) AtomDates.short(came.date!),
                  ?came.by,
                ].join(' · '),
              ),
            ),
          if (found.heldFor case final h?)
            StockLine(
              label: l.stockHeldFor,
              value: stockValue(
                h.forType == 'bulk_deal'
                    ? l.stockBulkDealN('${h.orderId ?? ''}')
                    : l.stockCashOrderN('${h.orderId ?? ''}'),
              ),
            ),
          if (found.found == UnitFound.delivered && last != null)
            StockLine(
              label: l.stockMoveDelivered,
              value: stockValue(last.why ?? ''),
            ),
          if (found.found == UnitFound.removed && last != null)
            StockLine(label: l.stockWhy, value: stockValue(last.why ?? '')),
          if (actions) ...[
            const SizedBox(height: 6),
            ..._actions(context, canChange),
          ],
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, bool canChange) {
    final l = AppLocalizations.of(context);
    final last = found.last;
    switch (found.found) {
      case UnitFound.inStock:
        final serial = found.serial;
        final held = found.heldFor;
        return [
          if (held?.orderUuid case final uuid?) ...[
            AtomButton(
              label: l.stockOpenOrder,
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: () => context.push(V2Routes.orderOf(uuid)),
            ),
            const SizedBox(height: 8),
          ] else if (held != null &&
              held.forType == 'bulk_deal' &&
              held.orderId != null) ...[
            AtomButton(
              label: l.stockOpenDeal,
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: () => context.push(V2Routes.dealOf(held.orderId!)),
            ),
            const SizedBox(height: 8),
          ],
          if (found.productId != null)
            AtomButton(
              label: l.stockOpenProduct,
              compact: true,
              onPressed: () =>
                  context.push(V2Routes.productStockOf(found.productId!)),
            ),
          if (canChange) ...[
            const SizedBox(height: 8),
            AtomButtonPair(
              first: AtomButton(
                label: l.stockMove,
                kind: AtomButtonKind.outline,
                compact: true,
                onPressed: () =>
                    context.push(V2Routes.moveStock(serial: serial)),
              ),
              second: AtomButton(
                label: l.stockRemove,
                kind: AtomButtonKind.outline,
                compact: true,
                onPressed: () =>
                    context.push(V2Routes.adjustStock(serial: serial)),
              ),
            ),
          ],
        ];
      case UnitFound.delivered:
        return [
          if (last?.refType == 'bulk_deal' && last?.refId != null)
            AtomButton(
              label: l.stockOpenDeal,
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: () => context.push(V2Routes.dealOf(last!.refId!)),
            ),
        ];
      case UnitFound.removed:
        return [
          if (canChange)
            AtomButton(
              label: l.stockFoundAddBack,
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: () => context.push(
                V2Routes.adjustStock(serial: found.serial, found: true),
              ),
            ),
        ];
      case UnitFound.notFound:
        return [
          if (canChange) ...[
            AtomButton(
              label: l.stockStockItIn,
              compact: true,
              onPressed: () =>
                  context.push(V2Routes.stockIn(serial: found.serial)),
            ),
            const SizedBox(height: 8),
            AtomButton(
              label: l.stockFoundUnit,
              kind: AtomButtonKind.outline,
              compact: true,
              onPressed: () => context.push(
                V2Routes.adjustStock(serial: found.serial, found: true),
              ),
            ),
          ],
        ];
    }
  }
}
