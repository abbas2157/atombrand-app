import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../atompay/data/atompay_repository.dart';
import '../../atompay/ui/atompay_list.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/order_rules.dart';
import '../data/orders_models.dart';
import '../data/orders_providers.dart';
import '../data/orders_repository.dart';
import 'order_dates.dart';
import 'order_detail_screen.dart';
import 'order_parts.dart';

/// The Orders tab (6.1, 6.8, 6b, 14.2): Cash orders and AtomPay orders
/// side by side, each with its own filters. A person who may see only one
/// kind gets that one, with no toggle.
class OrdersTabScreen extends ConsumerWidget {
  const OrdersTabScreen({
    super.key,
    this.atompay = false,
    this.status,
    this.payment,
  });

  /// `?tab=atompay`.
  final bool atompay;

  /// `?status=Pending`: one status on Cash orders (from a Home task).
  final String? status;

  /// `?payment=unpaid|part|paid`: the payment filter on Cash orders.
  final String? payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final canCash = who?.can(BrandPermission.ordersView) ?? false;
    final canAtompay = who?.can(BrandPermission.atompayView) ?? false;
    // A role without Bulk deals has AtomPay as its own third tab (5.2),
    // so Orders is Cash orders only, with no toggle.
    final ownTab = !(who?.can(BrandPermission.bulkView) ?? true);
    final toggle = canCash && canAtompay && !ownTab;
    final showAtompay = canAtompay && (atompay || !canCash);
    final askAtom = ref.watch(accessProvider).has(Addon.askAtom);

    int? cashCount;
    int? atompayCount;
    if (toggle) {
      const q = (
        status: null,
        q: '',
        outletId: null,
        payment: null,
        from: null,
        to: null,
      );
      cashCount = ref
          .watch(orderCountsProvider(q))
          .value
          ?.values
          .fold<int>(0, (a, b) => a + b);
      atompayCount = ref
          .watch(atompayPageProvider((step: null, q: '', outletId: null)))
          .value
          ?.counts
          .values
          .fold<int>(0, (a, b) => a + b);
    }

    final header = Container(
      color: AtomColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.ordersTitle,
            divider: !toggle,
            actions: [
              if (askAtom)
                AtomIconButton(
                  icon: LucideIcons.sparkles,
                  label: l.ordersAskAtom,
                  glyph: const AtomAiMark(size: 30, ring: true),
                  onTap: () => context.push(V2Routes.askAtom),
                ),
              AtomIconButton(
                icon: LucideIcons.search,
                label: l.ordersSearch,
                onTap: () => context.push(V2Routes.search),
              ),
            ],
          ),
          if (toggle)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AtomColors.line)),
              ),
              child: OrdersToggle(
                atompay: showAtompay,
                cashCount: cashCount,
                atompayCount: atompayCount,
                onChanged: (v) =>
                    context.go(v ? V2Routes.atompayOrders : V2Routes.orders),
              ),
            ),
          const OfflineBar(),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: !canCash && !canAtompay
          ? Column(
              children: [
                header,
                Expanded(
                  child: AtomMessageState(
                    icon: LucideIcons.lock,
                    title: l.ordersNoRoleTitle,
                    body: l.ordersNoRoleBody,
                  ),
                ),
              ],
            )
          : showAtompay
          ? AtompayListBody(header: header)
          : CashOrdersBody(
              header: header,
              initialStatus: status,
              initialPayment: payment,
            ),
    );
  }
}

/// The Cash orders list (6.1): status chips with counts, search, the
/// payment and outlet filters, and the orders with their one action. On a
/// wide tablet (14.2) the chosen order shows beside the list.
class CashOrdersBody extends ConsumerStatefulWidget {
  const CashOrdersBody({
    super.key,
    required this.header,
    this.initialStatus,
    this.initialPayment,
  });

  final Widget header;
  final String? initialStatus;

  /// `unpaid`, `part` or `paid` (`V2Routes.ordersWith(payment:)`).
  final String? initialPayment;

  @override
  ConsumerState<CashOrdersBody> createState() => _CashOrdersBodyState();
}

class _CashOrdersBodyState extends ConsumerState<CashOrdersBody> {
  late String? _status = _statusFrom(widget.initialStatus);
  final _search = TextEditingController();
  Timer? _searchTimer;
  String _searched = '';
  int? _outletId;
  String? _outletName;

  /// Payment filter: null is any.
  late PaymentState? _pay = _payFrom(widget.initialPayment);

  /// The Placed filter: any time, a preset or picked days.
  PlacedRange _placed = const PlacedRange();

  /// The order beside the list on a wide tablet.
  String? _picked;

  /// Pages after the first, read as the list scrolls.
  OrdersQuery? _moreFor;
  final _more = <CashOrder>[];
  int _page = 1;
  bool _loadingMore = false;

  static String? _statusFrom(String? key) =>
      key == null ? null : OrderStage.fromKey(key).key;

  static PaymentState? _payFrom(String? key) => switch (key) {
    'unpaid' => PaymentState.unpaid,
    'part' => PaymentState.part,
    'paid' => PaymentState.paid,
    _ => null,
  };

  @override
  void didUpdateWidget(CashOrdersBody old) {
    super.didUpdateWidget(old);
    if (old.initialStatus != widget.initialStatus ||
        old.initialPayment != widget.initialPayment) {
      setState(() {
        _status = _statusFrom(widget.initialStatus);
        _pay = _payFrom(widget.initialPayment);
      });
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  OrdersQuery get _query => (
    status: _status,
    q: _searched,
    outletId: _outletId,
    payment: _pay?.name,
    from: _placed.from,
    to: _placed.to,
  );

  Future<void> _pickPlaced() async {
    final v = await pickPlacedRange(context, _placed);
    if (v == null || !mounted) return;
    setState(() => _placed = v);
  }

  Future<void> _loadMore(OrdersQuery q, int lastPage) async {
    if (_loadingMore) return;
    final from = _moreFor == q ? _page : 1;
    if (from >= lastPage) return;
    setState(() => _loadingMore = true);
    final r = await ref.read(ordersRepositoryProvider).list(q, page: from + 1);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (r case ApiOk(:final value) when _query == q) {
        if (_moreFor != q) {
          _moreFor = q;
          _more.clear();
        }
        _more.addAll(value.items);
        _page = value.page;
      }
    });
  }

  Future<void> _pickPay() async {
    final l = AppLocalizations.of(context);
    final v = await showAtomSelect<String>(
      context,
      title: l.ordersPayment,
      selected: _pay?.name ?? '',
      options: [
        AtomOption(value: '', label: l.ordersAnyPayment),
        for (final p in const [
          PaymentState.unpaid,
          PaymentState.part,
          PaymentState.paid,
        ])
          AtomOption(value: p.name, label: p.label(l)),
      ],
    );
    if (v == null) return;
    setState(
      () => _pay = v.isEmpty
          ? null
          : PaymentState.values.firstWhere((p) => p.name == v),
    );
  }

  Future<void> _pickOutlet(List<Outlet> outlets) async {
    final l = AppLocalizations.of(context);
    final v = await showAtomSelect<int>(
      context,
      title: l.ordersOutlet,
      selected: _outletId ?? 0,
      options: [
        AtomOption(value: 0, label: l.ordersAllOutlets),
        for (final o in outlets)
          AtomOption(value: o.id, label: o.name, subtitle: o.city),
      ],
    );
    if (v == null) return;
    setState(() {
      _outletId = v == 0 ? null : v;
      _outletName = v == 0 ? null : outlets.firstWhere((o) => o.id == v).name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider.notifier).current;
    // The outlet filter only when the brand has several and the person is
    // looking at all of them (an outlet chosen already scopes every call).
    final outlets = session?.outlets ?? const <Outlet>[];
    final multi = (session?.multiOutlet ?? false) && session?.outletId == null;
    final query = _query;
    final data = ref.watch(ordersPageProvider(query));
    final counts = ref.watch(orderCountsProvider(anyStatus(query))).value;
    final split = atomTwoPane(context);

    List<CashOrder> rowsOf(List<CashOrder> first) => [
      ...first,
      if (_moreFor == query) ..._more,
    ].where((o) => _pay == null || o.payState == _pay).toList();

    final shown = rowsOf(data.value?.items ?? const []);
    final selected = !split
        ? null
        : shown.any((o) => o.uuid == _picked)
        ? _picked
        : shown.firstOrNull?.uuid;

    final chips = CountChips<String?>(
      selected: _status,
      onPick: (s) => setState(() => _status = s),
      chips: [
        (null, l.ordersAll, counts?.values.fold<int>(0, (a, b) => a + b)),
        for (final s in OrderStage.values) (s.key, s.label(l), counts?[s.key]),
      ],
    );

    final filters = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          AtomFilterChip(
            minHeight: 36,
            label: l.ordersPaymentFilter(_pay?.label(l) ?? l.ordersAnyPayment),
            active: _pay != null,
            onTap: _pickPay,
          ),
          const SizedBox(width: 8),
          AtomFilterChip(
            minHeight: 36,
            label: l.ordersPlacedFilter(_placed.label(l)),
            active: !_placed.any,
            onTap: _pickPlaced,
          ),
          if (multi) ...[
            const SizedBox(width: 8),
            AtomFilterChip(
              minHeight: 36,
              label: l.ordersOutletFilter(_outletName ?? l.ordersAll),
              active: _outletId != null,
              onTap: () => _pickOutlet(outlets),
            ),
          ],
        ],
      ),
    );

    final search = OrdersSearchBox(
      controller: _search,
      placeholder: l.ordersSearchPlaceholder,
      onChanged: (_) {
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _searched = _search.text.trim());
        });
      },
    );

    Widget list(int lastPage, List<CashOrder> first) {
      final rows = rowsOf(first);
      final hasMore = (_moreFor == query ? _page : 1) < lastPage;
      final filtered =
          _status != null ||
          _pay != null ||
          !_placed.any ||
          _outletId != null ||
          _searched.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () {
          _moreFor = null;
          _more.clear();
          ref.invalidate(orderCountsProvider);
          return ref.refresh(ordersPageProvider(query).future);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (hasMore && n.metrics.extentAfter < 400) {
              _loadMore(query, lastPage);
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (rows.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: filtered
                        ? AtomMessageState(
                            icon: LucideIcons.searchX,
                            title: l.ordersNoMatch,
                            actionLabel: l.ordersClearFilters,
                            onAction: () => setState(() {
                              _status = null;
                              _pay = null;
                              _placed = const PlacedRange();
                              _outletId = null;
                              _outletName = null;
                              _search.clear();
                              _searched = '';
                            }),
                          )
                        : AtomMessageState(
                            icon: LucideIcons.shoppingBag,
                            title: l.ordersEmptyTitle,
                            body: l.ordersEmptyBody,
                          ),
                  ),
                )
              else if (split)
                // 14.2: the tablet's compact rows beside the order.
                SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) => CashOrderRow(
                    order: rows[i],
                    selected: rows[i].uuid == selected,
                    onTap: () => setState(() => _picked = rows[i].uuid),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => CashOrderCard(
                      order: rows[i],
                      multiOutlet: session?.multiOutlet ?? false,
                      selected: split && rows[i].uuid == selected,
                      onOpen: split
                          ? () => setState(() => _picked = rows[i].uuid)
                          : null,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: hasMore
                      ? const Center(child: AtomSpinner())
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final listColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.header,
        chips,
        search,
        filters,
        Expanded(
          child: data.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: AtomLoadingRows(),
            ),
            error: (e, _) => OrdersLoadError(
              error: e,
              onRetry: () => ref.invalidate(ordersPageProvider(query)),
            ),
            data: (page) => list(page.lastPage, page.items),
          ),
        ),
      ],
    );

    return AtomSplitView(
      listWidth: 400,
      list: listColumn,
      detail: selected == null
          ? null
          : OrderView(key: ValueKey(selected), uuid: selected, embedded: true),
      empty: AtomMessageState(
        icon: LucideIcons.mousePointerClick,
        title: l.ordersPickOne,
      ),
    );
  }
}

/// A row of the Cash orders list (`.ocard`): number, time and city with
/// the step; the customer, the product and the outlet; then the value, the
/// payment and the one action.
class CashOrderCard extends ConsumerWidget {
  const CashOrderCard({
    super.key,
    required this.order,
    required this.multiOutlet,
    this.selected = false,
    this.onOpen,
  });

  final CashOrder order;
  final bool multiOutlet;
  final bool selected;

  /// Replaces opening the order page (the tablet picks instead).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final o = order;
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final writes = !ref.watch(accessProvider).account.blocksWrites;
    final act = rowActionFor(
      o.stage,
      o.payState,
      canStatus: writes && (who?.can(BrandPermission.ordersStatus) ?? false),
      canPay: writes && (who?.can(BrandPermission.ordersPayment) ?? false),
    );
    final top = [o.number, whenRow(o.createdAt, l), ?o.city].join(' · ');
    final name = o.customerName ?? o.productTitle;
    final open = onOpen ?? () => context.push(V2Routes.orderOf(o.uuid));

    final (String label, bool primary, VoidCallback onTap)? button =
        switch (act) {
          RowAction.confirm => (l.ordersConfirm, true, open),
          RowAction.deliver => (
            l.ordersMarkDelivered,
            true,
            () => context.push(V2Routes.orderDeliverOf(o.uuid)),
          ),
          RowAction.takePayment => (
            l.ordersTakePayment,
            true,
            () => context.push(V2Routes.orderPaymentOf(o.uuid)),
          ),
          RowAction.complete => (l.ordersComplete, true, open),
          RowAction.receipt => (
            l.ordersReceipt,
            false,
            () => context.push(V2Routes.orderReceiptOf(o.uuid)),
          ),
          null => null,
        };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brCard,
        border: Border.all(
          color: selected ? AtomColors.primary : AtomColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPressable(
            onTap: open,
            scaleOnPress: false,
            focusRadius: BorderRadius.zero,
            semanticLabel: [
              name,
              top,
              o.productLine(l),
              o.stageName(l),
            ].join(', '),
            builder: (_, pressed) => Container(
              color: pressed ? AtomColors.head : null,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            top,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtomText.small.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StageTag(
                          label: o.stageName(l),
                          tone: stageTone(o.stage),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: AtomText.listTitle),
                    if (o.customerName != null)
                      Text(o.productLine(l), style: AtomText.secondary)
                    else if (o.variant != null)
                      Text(
                        [o.variant!, l.ordersQty(o.quantity)].join(' · '),
                        style: AtomText.secondary,
                      ),
                    if (multiOutlet && o.outlet != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(o.outlet!.name, style: AtomText.small),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AtomColors.line)),
            ),
            // The value and payment wrap under each other and the button
            // narrows (its label wraps) before anything overflows.
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(formatRs(o.total), style: AtomText.money),
                      StageTag(
                        label: o.payState.label(l),
                        tone: payTone(o.payState),
                      ),
                    ],
                  ),
                ),
                if (button != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: AtomButton.small(
                      label: button.$1,
                      kind: button.$2
                          ? AtomButtonKind.primary
                          : AtomButtonKind.outline,
                      onPressed: button.$3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tablet row of the Cash orders list (14.2 `.orow`): the customer, the
/// number and product, then the value over the step. The chosen one is
/// blue-soft with a blue bar on its left.
class CashOrderRow extends StatelessWidget {
  const CashOrderRow({
    super.key,
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final CashOrder order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final o = order;
    final name = o.customerName ?? o.productTitle;
    final line = '${o.number} · ${o.productLine(l)}';
    return AtomPressable(
      onTap: onTap,
      selected: selected,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [name, line, formatRs(o.total), o.stageName(l)].join(', '),
      builder: (_, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AtomColors.primarySoft
              : pressed
              ? AtomColors.head
              : AtomColors.paper,
          border: Border(
            top: const BorderSide(color: AtomColors.line),
            left: BorderSide(
              color: selected ? AtomColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AtomText.listTitle),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtomText.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRs(o.total),
                    style: AtomText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AtomColors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  StageTag(label: o.stageName(l), tone: stageTone(o.stage)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
