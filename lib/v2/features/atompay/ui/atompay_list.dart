import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../orders/ui/order_parts.dart';
import '../data/atompay_models.dart';
import '../data/atompay_repository.dart';
import 'atompay_detail_screen.dart';
import 'atompay_parts.dart';

/// AtomPay orders (6.8): what AtomPay is, the steps with counts, search,
/// the outlet filter, and the orders with Hand over when it is the brand's
/// turn. On a wide tablet the chosen order shows beside the list.
class AtompayListBody extends ConsumerStatefulWidget {
  const AtompayListBody({super.key, required this.header});
  final Widget header;

  @override
  ConsumerState<AtompayListBody> createState() => _AtompayListBodyState();
}

class _AtompayListBodyState extends ConsumerState<AtompayListBody> {
  String? _step;
  final _search = TextEditingController();
  Timer? _searchTimer;
  String _searched = '';
  int? _outletId;
  String? _outletName;
  String? _picked;

  AtompayQuery? _moreFor;
  final _more = <AtompayOrder>[];
  int _page = 1;
  bool _loadingMore = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  AtompayQuery get _query => (step: _step, q: _searched, outletId: _outletId);

  Future<void> _loadMore(AtompayQuery q, int lastPage) async {
    if (_loadingMore) return;
    final from = _moreFor == q ? _page : 1;
    if (from >= lastPage) return;
    setState(() => _loadingMore = true);
    final r = await ref.read(atompayRepositoryProvider).list(q, page: from + 1);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (r case ApiOk(:final value) when _query == q) {
        if (_moreFor != q) {
          _moreFor = q;
          _more.clear();
        }
        _more.addAll(value.page.items);
        _page = value.page.page;
      }
    });
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
    final outlets = session?.outlets ?? const <Outlet>[];
    final multi = (session?.multiOutlet ?? false) && session?.outletId == null;
    final query = _query;
    final data = ref.watch(atompayPageProvider(query));
    // The counts stay on the chips while another step loads.
    final counts = data.value?.counts;
    final split = atomTwoPane(context);

    List<AtompayOrder> rowsOf(List<AtompayOrder> first) => [
      ...first,
      if (_moreFor == query) ..._more,
    ].where((o) => _outletId == null || o.outlet?.id == _outletId).toList();

    final shown = rowsOf(data.value?.page.items ?? const []);
    final selected = !split
        ? null
        : shown.any((o) => o.uuid == _picked)
        ? _picked
        : shown.firstOrNull?.uuid;

    Widget list(int lastPage, List<AtompayOrder> first) {
      final rows = rowsOf(first);
      final hasMore = (_moreFor == query ? _page : 1) < lastPage;
      final filtered =
          _step != null || _outletId != null || _searched.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () {
          _moreFor = null;
          _more.clear();
          return ref.refresh(atompayPageProvider(query).future);
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
                            title: l.atompayNoMatch,
                            actionLabel: l.ordersClearFilters,
                            onAction: () => setState(() {
                              _step = null;
                              _outletId = null;
                              _outletName = null;
                              _search.clear();
                              _searched = '';
                            }),
                          )
                        : AtomMessageState(
                            icon: LucideIcons.wallet,
                            title: l.atompayEmptyTitle,
                            body: l.atompayEmptyBody,
                          ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => AtompayOrderCard(
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AtomNote(
            kind: AtomNoteKind.info,
            compact: true,
            message: l.atompayIntro,
            bold: [l.atompayIntroBold],
          ),
        ),
        CountChips<String?>(
          selected: _step,
          onPick: (s) => setState(() => _step = s),
          chips: [
            (null, l.ordersAll, counts?.values.fold<int>(0, (a, b) => a + b)),
            for (final s in AtompayStep.values)
              (s.key, s.label(l), counts?[s.key]),
          ],
        ),
        OrdersSearchBox(
          controller: _search,
          placeholder: l.atompaySearchPlaceholder,
          onChanged: (_) {
            _searchTimer?.cancel();
            _searchTimer = Timer(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _searched = _search.text.trim());
            });
          },
        ),
        if (multi)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AtomFilterChip(
                minHeight: 36,
                label: l.ordersOutletFilter(_outletName ?? l.ordersAll),
                active: _outletId != null,
                onTap: () => _pickOutlet(outlets),
              ),
            ),
          ),
        Expanded(
          child: data.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 16),
              child: AtomLoadingRows(),
            ),
            error: (e, _) => OrdersLoadError(
              error: e,
              onRetry: () => ref.invalidate(atompayPageProvider(query)),
            ),
            data: (p) => list(p.page.lastPage, p.page.items),
          ),
        ),
      ],
    );

    return AtomSplitView(
      listWidth: 400,
      list: listColumn,
      detail: selected == null
          ? null
          : AtompayView(
              key: ValueKey(selected),
              uuid: selected,
              embedded: true,
            ),
      empty: AtomMessageState(
        icon: LucideIcons.mousePointerClick,
        title: l.ordersPickOne,
      ),
    );
  }
}

/// A row of the AtomPay list (`.ocard`).
class AtompayOrderCard extends ConsumerWidget {
  const AtompayOrderCard({
    super.key,
    required this.order,
    required this.multiOutlet,
    this.selected = false,
    this.onOpen,
  });

  final AtompayOrder order;
  final bool multiOutlet;
  final bool selected;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final o = order;
    final writes = !ref.watch(accessProvider).account.blocksWrites;
    final canHand = writes && o.step == AtompayStep.handover;
    final top = [
      o.number,
      whenShort(o.createdAt, l),
      if (multiOutlet && o.outlet != null) o.outlet!.name,
    ].join(' · ');
    final open = onOpen ?? () => context.push(V2Routes.atompayOf(o.uuid));
    final sellerLine = o.seller == null
        ? l.atompayNotGiven
        : [
            o.seller!.name,
            if (o.seller!.place.isNotEmpty) o.seller!.place,
          ].join(' · ');
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
              o.productLine,
              top,
              sellerLine,
              o.stepName(l),
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
                            style: AtomText.small,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StageTag(
                          label: o.stepName(l),
                          tone: atompayTone(o.step),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [o.productLine, l.ordersQty(o.quantity)].join(' · '),
                      style: AtomText.listTitle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SellerInitials(seller: o.seller),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sellerLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtomText.secondary,
                          ),
                        ),
                      ],
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
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l.ordersCashPrice, style: AtomText.small),
                      Text(formatRs(o.cashPrice), style: AtomText.money),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AtomButton.small(
                    label: canHand ? l.atompayHandOver : l.atompayView,
                    kind: canHand
                        ? AtomButtonKind.primary
                        : AtomButtonKind.outline,
                    onPressed: canHand
                        ? () => context.push(V2Routes.atompayHandoverOf(o.uuid))
                        : open,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
