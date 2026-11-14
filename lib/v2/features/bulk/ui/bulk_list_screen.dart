import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/bulk_logic.dart';
import '../data/bulk_models.dart';
import '../data/bulk_repository.dart';
import 'bulk_parts.dart';
import 'deal_screens.dart' show DealScreen;
import 'request_screens.dart' show BulkRequestScreen;

/// 7.1 Bulk deals: Seller requests (default) · Website · Deals.
class BulkListScreen extends ConsumerStatefulWidget {
  const BulkListScreen({super.key, this.tab});

  /// `sellers`, `website` or `deals` (`?tab=`).
  final String? tab;

  @override
  ConsumerState<BulkListScreen> createState() => _BulkListScreenState();
}

enum _Tab { sellers, website, deals }

_Tab _tabOf(String? s) => switch (s) {
  'website' || 'buyers' => _Tab.website,
  'deals' => _Tab.deals,
  _ => _Tab.sellers,
};

/// Pages after the first, read as the list scrolls.
class _More<T> {
  Object? key;
  final items = <T>[];
  int page = 1;
  bool loading = false;

  void reset() {
    key = null;
    items.clear();
    page = 1;
  }
}

class _BulkListScreenState extends ConsumerState<BulkListScreen> {
  late _Tab _tab = _tabOf(widget.tab);
  RequestStatus _sellerStatus = RequestStatus.fresh;
  RequestStatus _webStatus = RequestStatus.fresh;
  DealStatus? _dealStatus;

  final _moreRequests = _More<BulkRequest>();
  final _moreDeals = _More<Deal>();

  /// The request or deal beside the list on a wide tablet; null shows the
  /// first row of the tab.
  BulkPick? _picked;

  @override
  void didUpdateWidget(BulkListScreen old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab && widget.tab != null) {
      setState(() => _tab = _tabOf(widget.tab));
    }
  }

  RequestsQuery get _requestsQuery => _tab == _Tab.sellers
      ? (from: 'sellers', status: _sellerStatus, search: '')
      : (from: 'buyers', status: _webStatus, search: '');

  DealsQuery get _dealsQuery => (status: _dealStatus, search: '');

  Future<void> _refresh() async {
    _moreRequests.reset();
    _moreDeals.reset();
    ref.invalidate(bulkCountsProvider);
    try {
      if (_tab == _Tab.deals) {
        ref.invalidate(dealsProvider(_dealsQuery));
        await ref.read(dealsProvider(_dealsQuery).future);
      } else {
        ref.invalidate(bulkRequestsProvider(_requestsQuery));
        await ref.read(bulkRequestsProvider(_requestsQuery).future);
      }
    } on Object {
      // the list shows the error with Try again
    }
  }

  Future<void> _loadMoreRequests(
    RequestsQuery q,
    BulkRequestsPage first,
  ) async {
    final m = _moreRequests;
    if (m.loading) return;
    final last = m.key == q ? m.page : first.page.page;
    if (last >= first.page.lastPage) return;
    setState(() => m.loading = true);
    final r = await ref
        .read(bulkRepositoryProvider)
        .requests(from: q.from, status: q.status, page: last + 1);
    if (!mounted) return;
    setState(() {
      m.loading = false;
      if (r case ApiOk(:final value) when _requestsQuery == q) {
        if (m.key != q) {
          m.reset();
          m.key = q;
        }
        m.items.addAll(value.items);
        m.page = value.page.page;
      }
    });
  }

  Future<void> _loadMoreDeals(DealsQuery q, DealsPage first) async {
    final m = _moreDeals;
    if (m.loading) return;
    final last = m.key == q ? m.page : first.page.page;
    if (last >= first.page.lastPage) return;
    setState(() => m.loading = true);
    final r = await ref
        .read(bulkRepositoryProvider)
        .deals(status: q.status, page: last + 1);
    if (!mounted) return;
    setState(() {
      m.loading = false;
      if (r case ApiOk(:final value) when _dealsQuery == q) {
        if (m.key != q) {
          m.reset();
          m.key = q;
        }
        m.items.addAll(value.items);
        m.page = value.page.page;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final access = ref.watch(accessProvider);
    final counts = ref.watch(bulkCountsProvider).value;
    final who = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.session.who : null),
    );
    final canQuote = who?.can(BrandPermission.bulkQuote) ?? false;
    final canDeal = who?.can(BrandPermission.bulkDeal) ?? false;

    final Widget body;
    bool hasMore = false;
    VoidCallback? more;
    // The rows on screen, for the pick beside the list on a tablet.
    var shownPicks = const <BulkPick>[];
    if (_tab == _Tab.deals) {
      final q = _dealsQuery;
      final page = ref.watch(dealsProvider(q));
      body = page.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const _Loading(),
        error: (e, _) =>
            _Error(onRetry: () => ref.invalidate(dealsProvider(q))),
        data: (p) {
          final rows = [
            ...p.items,
            if (_moreDeals.key == q) ..._moreDeals.items,
          ];
          hasMore =
              (_moreDeals.key == q ? _moreDeals.page : p.page.page) <
              p.page.lastPage;
          more = () => _loadMoreDeals(q, p);
          shownPicks = [
            for (final d in rows) (kind: BulkPickKind.deal, id: d.id),
          ];
          return _DealsTab(
            deals: rows,
            statuses: p.statuses,
            status: _dealStatus,
            canDeal: canDeal,
            onStatus: (s) => setState(() {
              _dealStatus = s;
              _moreDeals.reset();
            }),
          );
        },
      );
    } else {
      final q = _requestsQuery;
      final page = ref.watch(bulkRequestsProvider(q));
      body = page.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const _Loading(),
        error: (e, _) =>
            _Error(onRetry: () => ref.invalidate(bulkRequestsProvider(q))),
        data: (p) {
          final rows = [
            ...p.items,
            if (_moreRequests.key == q) ..._moreRequests.items,
          ];
          hasMore =
              (_moreRequests.key == q ? _moreRequests.page : p.page.page) <
              p.page.lastPage;
          more = () => _loadMoreRequests(q, p);
          final kind = _tab == _Tab.sellers
              ? BulkPickKind.sellerRequest
              : BulkPickKind.websiteRequest;
          shownPicks = [for (final r in rows) (kind: kind, id: r.id)];
          return _tab == _Tab.sellers
              ? _SellersTab(
                  requests: rows,
                  status: _sellerStatus,
                  total: p.page.total,
                  sellerCounts: counts?.seller ?? p.sellerCounts,
                  canQuote: canQuote,
                  onStatus: (s) => setState(() {
                    _sellerStatus = s;
                    _moreRequests.reset();
                  }),
                )
              : _WebsiteTab(
                  requests: rows,
                  status: _webStatus,
                  total: p.page.total,
                  canQuote: canQuote,
                  onStatus: (s) => setState(() {
                    _webStatus = s;
                    _moreRequests.reset();
                  }),
                );
        },
      );
    }

    // The money tiles come with any request list (when the server sends
    // them); on Deals, with the website list.
    final tilesPage = ref
        .watch(
          bulkRequestsProvider(
            _tab == _Tab.deals
                ? (from: 'buyers', status: RequestStatus.fresh, search: '')
                : _requestsQuery,
          ),
        )
        .value;

    final split = atomTwoPane(context);
    final picked = !split
        ? null
        : shownPicks.contains(_picked)
        ? _picked
        : shownPicks.firstOrNull;

    final listColumn = Column(
      children: [
        _Header(
          tab: _tab,
          sellerBadge: counts?.seller.badge ?? counts?.sellerRequests ?? 0,
          askAtom: access.has(Addon.askAtom),
          onTab: (t) => setState(() => _tab = t),
        ),
        const OfflineBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (hasMore && n.metrics.extentAfter < 400) more?.call();
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _KpiStrip(tiles: tilesPage?.tiles, counts: counts),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: body),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                      child: hasMore
                          ? const Center(child: AtomSpinner())
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    // A wide tablet (14.x, as TabletOrders): the list and the request or
    // deal side by side; rows pick instead of opening a page.
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: !split
          ? listColumn
          : AtomSplitView(
              listWidth: 420,
              list: BulkPicker(
                picked: picked,
                onPick: (p) => setState(() => _picked = p),
                child: listColumn,
              ),
              detail: picked == null
                  ? null
                  : BulkBeside(
                      key: ValueKey(picked),
                      child: switch (picked.kind) {
                        BulkPickKind.deal => DealScreen(id: picked.id),
                        BulkPickKind.sellerRequest => BulkRequestScreen(
                          id: picked.id,
                          seller: true,
                        ),
                        BulkPickKind.websiteRequest => BulkRequestScreen(
                          id: picked.id,
                        ),
                      },
                    ),
              empty: AtomMessageState(
                icon: LucideIcons.mousePointerClick,
                title: l.bulkPickHint,
              ),
            ),
    );
  }
}

/// A row's tap: pick it beside the list on a wide tablet, else open its
/// page. Selected rows get the leading bar.
VoidCallback _openOrPick(BuildContext context, BulkPick pick, String path) {
  final picker = BulkPicker.maybeOf(context);
  return picker == null ? () => context.push(path) : () => picker.onPick(pick);
}

Widget _selectable(BuildContext context, BulkPick pick, Widget child) {
  final picker = BulkPicker.maybeOf(context);
  return picker == null
      ? child
      : AtomSelectedRow(selected: picker.picked == pick, child: child);
}

// ───────────────────────────────────────────────────────────── header

class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    required this.sellerBadge,
    required this.askAtom,
    required this.onTab,
  });

  final _Tab tab;
  final int sellerBadge;
  final bool askAtom;
  final ValueChanged<_Tab> onTab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: const BoxDecoration(
          color: AtomColors.paper,
          border: Border(bottom: BorderSide(color: AtomColors.line)),
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AtomSpace.gutter,
                  right: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l.bulkTitle, style: AtomText.pageTitle),
                      ),
                    ),
                    if (askAtom)
                      AtomIconButton(
                        icon: LucideIcons.sparkles,
                        label: l.bulkAskAtom,
                        glyph: const AtomAiMark(size: 28),
                        onTap: () => context.push(V2Routes.askAtom),
                      ),
                    AtomIconButton(
                      icon: LucideIcons.search,
                      label: l.bulkSearch,
                      onTap: () => context.push(V2Routes.search),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _TabSeg(tab: tab, sellerBadge: sellerBadge, onTab: onTab),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.seg` with three tabs; Seller requests carries the red badge.
class _TabSeg extends StatelessWidget {
  const _TabSeg({
    required this.tab,
    required this.sellerBadge,
    required this.onTab,
  });

  final _Tab tab;
  final int sellerBadge;
  final ValueChanged<_Tab> onTab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget seg(_Tab t, String label, {int flex = 100, int? badge}) {
      final on = t == tab;
      final colour = on ? AtomColors.ink : AtomColors.muted;
      return Expanded(
        flex: flex,
        child: AtomPressable(
          onTap: () => onTab(t),
          selected: on,
          scaleOnPress: false,
          semanticLabel: badge != null && badge > 0
              ? l.bulkTabBadge(label, badge)
              : label,
          builder: (context, _) => Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AtomColors.paper : Colors.transparent,
              borderRadius: AtomRadius.brControl,
              boxShadow: on
                  ? const [
                      BoxShadow(
                        color: Color(0x14101828),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                      BoxShadow(color: AtomColors.line, spreadRadius: 1),
                    ]
                  : null,
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtomText.smallButton.copyWith(color: colour),
                    ),
                  ),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AtomColors.alertBadge,
                        borderRadius: AtomRadius.brPill,
                      ),
                      child: Text(
                        '$badge',
                        style: AtomText.tag.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: AtomColors.surface,
        borderRadius: AtomRadius.brControl,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.line),
      ),
      child: Row(
        children: [
          seg(_Tab.sellers, l.bulkTabSellers, flex: 135, badge: sellerBadge),
          seg(_Tab.website, l.bulkTabWebsite),
          seg(_Tab.deals, l.bulkTabDeals),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── KPIs

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.tiles, required this.counts});

  final BulkTiles? tiles;
  final BulkCounts? counts;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = tiles;
    final c = counts;
    final kpis = <AtomKpi>[
      if (t != null) ...[
        AtomKpi(
          label: l.bulkKpiNew,
          value: '${t.fresh}',
          note: l.bulkKpiNewNote,
        ),
        AtomKpi(
          label: l.bulkKpiQuotesOut,
          value: formatRs(t.outValue),
          note: [
            l.bulkKpiQuotes(t.outCount),
            if (t.outSoon > 0) l.bulkKpiExpireSoon(t.outSoon),
          ].join(', '),
        ),
        AtomKpi(
          label: l.bulkKpiWon,
          value: formatRs(t.wonValue),
          note: [
            l.bulkKpiDeals(t.wonCount),
            if (t.winRate != null) l.bulkKpiWinRate('${t.winRate}'),
          ].join(' · '),
        ),
        AtomKpi(
          label: l.bulkKpiCollect,
          value: formatRs(t.toCollect),
          note: l.bulkKpiOpenDeals(t.openDeals),
        ),
      ] else if (c != null) ...[
        AtomKpi(
          label: l.bulkKpiNew,
          value: '${c.count}',
          note: l.bulkKpiNewNote,
        ),
        AtomKpi(
          label: l.bulkTabSellers,
          value: '${c.seller.open}',
          note: c.seller.changeAsked > 0
              ? l.bulkKpiChangeAsked(c.seller.changeAsked)
              : l.bulkKpiOpenNow,
        ),
      ],
    ];
    if (kpis.isEmpty) return const SizedBox(height: 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AtomKpiGrid(kpis: kpis),
    );
  }
}

// ───────────────────────────────────────────────────────────── states

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const AtomLoadingCard(count: 4);
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 360, child: AtomErrorState(onRetry: onRetry));
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, this.body});

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: AtomMessageState(icon: icon, title: title, body: body),
  );
}

/// `.chips` over a list: one status at a time, scrolling sideways.
class _StatusChips extends StatelessWidget {
  const _StatusChips({
    required this.chips,
    required this.selected,
    required this.onChanged,
  });

  final List<(RequestStatus, String)> chips;
  final RequestStatus selected;
  final ValueChanged<RequestStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (s, label) in chips) ...[
            if (s != chips.first.$1) const SizedBox(width: 8),
            AtomPressable(
              onTap: () => onChanged(s),
              selected: s == selected,
              semanticLabel: label,
              focusRadius: AtomRadius.brPill,
              builder: (_, _) {
                final on = s == selected;
                return Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? AtomColors.primarySoft : AtomColors.paper,
                    borderRadius: AtomRadius.brPill,
                    border: Border.all(
                      color: on ? AtomColors.primary : AtomColors.line2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: AtomText.smallButton.copyWith(
                      color: on ? AtomColors.primary : AtomColors.text,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// A chip with its count beside the label when known.
String _chipLabel(String label, int? n) => n == null ? label : '$label  $n';

// ───────────────────────────────────────────────────── seller requests

class _SellersTab extends StatelessWidget {
  const _SellersTab({
    required this.requests,
    required this.status,
    required this.total,
    required this.sellerCounts,
    required this.canQuote,
    required this.onStatus,
  });

  final List<BulkRequest> requests;
  final RequestStatus status;
  final int total;
  final SellerCounts sellerCounts;
  final bool canQuote;
  final ValueChanged<RequestStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chips = [
      (RequestStatus.fresh, l.bulkStatusNew),
      (RequestStatus.contacted, l.bulkStatusContacted),
      (RequestStatus.quoted, l.bulkStatusQuoted),
      (RequestStatus.won, l.bulkStatusAccepted),
      (RequestStatus.lost, l.bulkStatusDeclined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtomNote(
          kind: AtomNoteKind.info,
          icon: LucideIcons.store,
          message: l.bulkSellersNote,
          bold: [l.bulkSellersNoteBold],
        ),
        const SizedBox(height: 10),
        _StatusChips(
          chips: [
            for (final (s, label) in chips)
              (s, _chipLabel(label, s == status ? total : null)),
          ],
          selected: status,
          onChanged: onStatus,
        ),
        if (sellerCounts.changeAsked > 0 && status != RequestStatus.quoted) ...[
          const SizedBox(height: 10),
          AtomPressable(
            onTap: () => onStatus(RequestStatus.quoted),
            builder: (_, _) => AtomNote(
              kind: AtomNoteKind.warning,
              icon: LucideIcons.messageSquareWarning,
              message: l.bulkChangeAskedNote(sellerCounts.changeAsked),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (requests.isEmpty)
          _Empty(
            icon: LucideIcons.store,
            title: switch (status) {
              RequestStatus.fresh => l.bulkEmptySellersNew,
              RequestStatus.won => l.bulkEmptyAccepted,
              RequestStatus.lost => l.bulkEmptyDeclined,
              _ => l.bulkEmptyHere,
            },
            body: status == RequestStatus.fresh ? l.bulkEmptySellersBody : null,
          )
        else
          for (final r in requests) ...[
            _SellerCard(request: r, canQuote: canQuote),
            const SizedBox(height: 10),
          ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            l.bulkSellersFooter,
            style: AtomText.small.copyWith(color: AtomColors.faint),
          ),
        ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.request, required this.canQuote});

  final BulkRequest request;
  final bool canQuote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = request;
    final state = sourcingStateOfRow(r);
    final seller = r.seller;
    final need = needByText(l, r.neededBy);
    final typed = r.productId == null;
    final price = [
      // A saved draft shows on the card, so it isn't forgotten.
      if (r.quote case final q? when q.status == 'draft')
        l.bulkDraftLine(q.name, formatRs(q.total))
      else if (r.quote case final q?)
        l.bulkQuoteLine(q.name, formatRs(q.total)) +
            (q.validUntil == null
                ? ''
                : ' · ${l.bulkValidUntil(AtomDates.short(q.validUntil!))}')
      else if (r.targetPrice != null)
        l.bulkHopingFor(formatRs(r.targetPrice!)),
      if (r.quote == null && r.productPrice != null)
        l.bulkYourPrice(formatRs(r.productPrice!)),
    ].join(' · ');
    final note = switch (r.answer) {
      SellerAnswer(action: 'change_asked', :final message?) => '“$message”',
      SellerAnswer(action: 'declined' || 'cancelled', :final reason?) =>
        l.bulkSellerSaid(reason),
      _ => null,
    };
    final (String act, bool primary, String path) = switch (state) {
      SourcingState.fresh when canQuote => (
        r.quote?.status == 'draft' ? l.bulkActFinishQuote : l.bulkActSendQuote,
        true,
        V2Routes.sellerRequestQuoteOf(r.id),
      ),
      SourcingState.changeAsked when canQuote => (
        l.bulkActSendNewQuote,
        true,
        V2Routes.sellerRequestQuoteOf(r.id),
      ),
      SourcingState.accepted => (
        l.bulkOpen,
        false,
        V2Routes.sellerRequestOf(r.id),
      ),
      SourcingState.declined || SourcingState.closed => (
        l.bulkActView,
        false,
        V2Routes.sellerRequestOf(r.id),
      ),
      _ => (l.bulkOpen, false, V2Routes.sellerRequestOf(r.id)),
    };

    final pick = (kind: BulkPickKind.sellerRequest, id: r.id);
    return _selectable(
      context,
      pick,
      BulkCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtomPressable(
              onTap: _openOrPick(context, pick, V2Routes.sellerRequestOf(r.id)),
              scaleOnPress: false,
              builder: (_, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtomInitials(name: r.who, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                r.who,
                                style: AtomText.listTitle.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (seller?.verified ?? false) ...[
                              const SizedBox(width: 6),
                              const VerifiedMark(),
                            ],
                          ],
                        ),
                        Text(
                          [
                            ?seller?.branch,
                            ?r.city,
                            bulkAgo(l, r.createdAt),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: AtomText.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AtomPill(label: state.label(l), tone: sourcingTone(state)),
                ],
              ),
            ),
            // The product lines open the request too, like the head.
            AtomPressable(
              onTap: _openOrPick(context, pick, V2Routes.sellerRequestOf(r.id)),
              scaleOnPress: false,
              builder: (_, _) => Padding(
                padding: const EdgeInsets.only(left: 52, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${r.quantity} × ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: r.title),
                        ],
                      ),
                      style: AtomText.body.copyWith(color: AtomColors.ink),
                    ),
                    if (typed) ...[
                      const SizedBox(height: 4),
                      BulkTag(l.bulkTypedTag, tone: AtomTone.purple),
                    ],
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(price, style: AtomText.small),
                    ],
                  ],
                ),
              ),
            ),
            if (note != null)
              Container(
                margin: const EdgeInsets.only(left: 52, top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AtomColors.amberSoft,
                  borderRadius: AtomRadius.brControl,
                ),
                child: Text(
                  note,
                  style: AtomText.secondary.copyWith(
                    color: AtomColors.amberInk,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: need == null
                          ? const SizedBox.shrink()
                          : NeedByChip(
                              text: need.text,
                              urgency: state.canQuote ? need.urgency : 0,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AtomButton(
                    label: act,
                    small: true,
                    expand: false,
                    kind: primary
                        ? AtomButtonKind.primary
                        : AtomButtonKind.outline,
                    onPressed: () => context.push(path),
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

// ───────────────────────────────────────────────────── website requests

class _WebsiteTab extends StatelessWidget {
  const _WebsiteTab({
    required this.requests,
    required this.status,
    required this.total,
    required this.canQuote,
    required this.onStatus,
  });

  final List<BulkRequest> requests;
  final RequestStatus status;
  final int total;
  final bool canQuote;
  final ValueChanged<RequestStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusChips(
          chips: [
            for (final s in RequestStatus.values)
              (s, _chipLabel(requestLabel(l, s), s == status ? total : null)),
          ],
          selected: status,
          onChanged: onStatus,
        ),
        const SizedBox(height: 10),
        if (requests.isEmpty)
          _Empty(
            icon: LucideIcons.funnel,
            title: status == RequestStatus.fresh
                ? l.bulkEmptyWebNew
                : l.bulkEmptyHere,
            body: status == RequestStatus.fresh ? l.bulkEmptyWebBody : null,
          )
        else
          BulkCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < requests.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AtomColors.line),
                  _WebsiteRow(request: requests[i], canQuote: canQuote),
                ],
              ],
            ),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            l.bulkWebFooter,
            style: AtomText.small.copyWith(color: AtomColors.faint),
          ),
        ),
      ],
    );
  }
}

class _WebsiteRow extends StatelessWidget {
  const _WebsiteRow({required this.request, required this.canQuote});

  final BulkRequest request;
  final bool canQuote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = request;
    final action = requestActionOf(r.status, canQuote: canQuote);
    final path = action == RequestAction.sendQuote
        ? V2Routes.bulkQuoteOf(r.id)
        : V2Routes.bulkRequestOf(r.id);
    final pick = (kind: BulkPickKind.websiteRequest, id: r.id);
    return _selectable(
      context,
      pick,
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtomPressable(
              onTap: _openOrPick(context, pick, V2Routes.bulkRequestOf(r.id)),
              scaleOnPress: false,
              builder: (_, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AtomInitials(name: r.who, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.who,
                          style: AtomText.listTitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            ?r.phone,
                            ?r.city,
                            bulkAgo(l, r.createdAt),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: AtomText.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AtomPill(
                    label: requestLabel(l, r.status),
                    tone: requestTone(r.status),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${r.quantity} × ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: r.title),
                      ],
                    ),
                    style: AtomText.body.copyWith(color: AtomColors.ink),
                  ),
                  if (r.targetPrice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.bulkHopingFor(formatRs(r.targetPrice!)),
                      style: AtomText.small,
                    ),
                  ],
                  if (r.quote case final q?) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.bulkQuoteLineColon(q.name, formatRs(q.total)) +
                          (q.validUntil == null
                              ? ''
                              : ' · ${l.bulkValidUntil(AtomDates.short(q.validUntil!))}'),
                      style: AtomText.small,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 10),
              child: Row(
                children: [
                  AtomButton(
                    label: action.label(l),
                    small: true,
                    expand: false,
                    kind: action.primary
                        ? AtomButtonKind.primary
                        : AtomButtonKind.outline,
                    onPressed: () => context.push(path),
                  ),
                  if ((r.phone ?? '').isNotEmpty) ...[
                    const SizedBox(width: 8),
                    AtomButton(
                      label: l.bulkCall,
                      icon: LucideIcons.phone,
                      small: true,
                      expand: false,
                      kind: AtomButtonKind.outline,
                      onPressed: () => callPhone(r.phone),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── deals

class _DealsTab extends StatelessWidget {
  const _DealsTab({
    required this.deals,
    required this.statuses,
    required this.status,
    required this.canDeal,
    required this.onStatus,
  });

  final List<Deal> deals;
  final List<KeyLabel> statuses;
  final DealStatus? status;
  final bool canDeal;
  final ValueChanged<DealStatus?> onStatus;

  Future<void> _pick(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final options = statuses.isEmpty
        ? [for (final s in DealStatus.values) (key: s.key, label: s.label(l))]
        : statuses;
    final v = await showAtomSelect<String>(
      context,
      title: l.bulkDealStatus,
      selected: status?.key ?? '',
      options: [
        AtomOption(value: '', label: l.bulkAny),
        for (final o in options) AtomOption(value: o.key, label: o.label),
      ],
    );
    if (v == null) return;
    onStatus(v.isEmpty ? null : DealStatus.of(v));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AtomFilterChip(
            label: l.bulkStatusFilter(status?.label(l) ?? l.bulkAny),
            active: status != null,
            onTap: () => _pick(context),
          ),
        ),
        const SizedBox(height: 10),
        if (deals.isEmpty)
          _Empty(
            icon: LucideIcons.handshake,
            title: status == null ? l.bulkEmptyDeals : l.bulkEmptyDealsHere,
            body: status == null ? l.bulkEmptyDealsBody : null,
          )
        else
          for (final d in deals) ...[
            _DealCard(deal: d, canDeal: canDeal),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal, required this.canDeal});

  final Deal deal;
  final bool canDeal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = deal;
    final action = dealActionOf(d, canDeal: canDeal);
    final pct = (d.paidShare * 100).round();
    final pick = (kind: BulkPickKind.deal, id: d.id);
    return _selectable(
      context,
      pick,
      BulkCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtomPressable(
              onTap: _openOrPick(context, pick, V2Routes.dealOf(d.id)),
              scaleOnPress: false,
              builder: (_, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: d.number,
                                style: AtomText.listTitle.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (d.createdAt != null)
                                TextSpan(
                                  text:
                                      '  ${l.bulkWonOn(AtomDates.short(d.createdAt!))}',
                                  style: AtomText.small,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                d.who,
                                style: AtomText.body.copyWith(
                                  color: AtomColors.ink,
                                ),
                              ),
                            ),
                            if (d.fromSeller) ...[
                              const SizedBox(width: 6),
                              BulkTag(l.bulkSellerTag),
                            ],
                          ],
                        ),
                        if (d.outletName != null)
                          Text(d.outletName!, style: AtomText.secondary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AtomPill(
                    label: d.statusLabel ?? d.status.label(l),
                    tone: dealTone(d.status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.bulkUnits(d.units),
                    style: AtomText.body.copyWith(color: AtomColors.muted),
                  ),
                ),
                Text(
                  formatRs(d.total),
                  style: AtomText.money.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.bulkDeliveredOf(d.deliveredUnits, d.units),
                    style: AtomText.secondary,
                  ),
                ),
                Text(
                  l.bulkPaidAmount(formatRs(d.paid)),
                  style: AtomText.secondary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            AtomProgressBar(
              value: d.paidShare,
              semanticLabel: l.bulkPercentPaid(pct),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.balance > 0
                        ? l.bulkAmountDue(formatRs(d.balance))
                        : d.status == DealStatus.lost
                        ? l.bulkStatusLost
                        : l.bulkPaidInFull,
                    style: AtomText.smallButton.copyWith(
                      color: d.balance > 0
                          ? AtomColors.amberInk
                          : AtomColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (action != null)
                  AtomButton(
                    label: action == DealAction.deliver
                        ? l.bulkDeliver
                        : l.bulkRecordPayment,
                    small: true,
                    expand: false,
                    onPressed: () => context.push(
                      action == DealAction.deliver
                          ? V2Routes.dealDeliverOf(d.id)
                          : V2Routes.dealPaymentOf(d.id),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
