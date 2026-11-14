import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/ui/offline_bar.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'stock_parts.dart';

/// 9.3 Stock list: every variant with what can be sold now, by level,
/// searched by product, PR number or SKU, filtered by outlet. Paged.
class StockListScreen extends ConsumerStatefulWidget {
  const StockListScreen({super.key, this.show = 'all'});

  /// `all`, `in`, `low` or `out`.
  final String show;

  @override
  ConsumerState<StockListScreen> createState() => _StockListScreenState();
}

const _tabs = ['all', 'in', 'low', 'out'];

class _StockListScreenState extends ConsumerState<StockListScreen> {
  late String _show = _tabs.contains(widget.show) ? widget.show : 'all';
  String _search = '';
  int? _outletId;
  final _searchBox = TextEditingController();
  Timer? _debounce;

  /// Pages after the first, for the current filters.
  final _more = <StockOverview>[];
  bool _loadingMore = false;
  bool _moreFailed = false;

  StockQuery get _query => (show: _show, search: _search, outletId: _outletId);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchBox.dispose();
    super.dispose();
  }

  void _setQuery(void Function() change) {
    setState(() {
      change();
      _more.clear();
      _moreFailed = false;
    });
  }

  Future<void> _loadMore(StockOverview first) async {
    final last = _more.isEmpty ? first : _more.last;
    if (_loadingMore || !last.hasMore) return;
    setState(() => _loadingMore = true);
    final q = _query;
    final r = await ref
        .read(stockRepositoryProvider)
        .overview(
          show: q.show,
          query: q.search,
          outletId: q.outletId,
          page: last.page + 1,
        );
    if (!mounted || q != _query) return;
    setState(() {
      _loadingMore = false;
      switch (r) {
        case ApiOk(:final value):
          _more.add(value);
        case ApiErr():
          _moreFailed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(stockOverviewProvider(_query));
    final first = data.value;
    final t = first?.totals;
    final session = stockSession(ref);
    final outlets = session?.outlets ?? const [];
    final multi = session?.outletId == null && outlets.length > 1;
    final canIn = first != null && canChangeStock(session?.who, first.access);

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          AtomPageHeader(
            title: l.stockListTitle,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: l.commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (canIn)
                AtomButton.small(
                  label: l.stockIn,
                  kind: AtomButtonKind.primary,
                  onPressed: () => context.push(V2Routes.stockIn()),
                ),
            ],
            tabs: [
              AtomHeaderTab(l.stockAll, count: t?.variants),
              AtomHeaderTab(
                l.stockStateIn,
                count: t == null
                    ? null
                    : (t.variants - t.low - t.out).clamp(0, t.variants),
              ),
              AtomHeaderTab(l.stockRunningLow, count: t?.low),
              AtomHeaderTab(l.stockStateOut, count: t?.out),
            ],
            selectedTab: _tabs.indexOf(_show),
            onTab: (i) => _setQuery(() => _show = _tabs[i]),
          ),
          const OfflineBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AtomTextField(
                    label: l.stockFindStock,
                    controller: _searchBox,
                    placeholder: l.stockFindHint,
                    prefix: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AtomColors.muted,
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (v) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 400),
                        () => _setQuery(() => _search = v.trim()),
                      );
                    },
                    onSubmitted: (v) => _setQuery(() => _search = v.trim()),
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
          ),
          if (multi)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: StockFilterChip(
                  label: l.stockOutletFilter(
                    _outletId == null
                        ? l.stockAll
                        : outlets
                              .firstWhere(
                                (o) => o.id == _outletId,
                                orElse: () => outlets.first,
                              )
                              .name,
                  ),
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
                      _setQuery(() => _outletId = picked == 0 ? null : picked);
                    }
                  },
                ),
              ),
            ),
          Expanded(
            child: data.when(
              skipLoadingOnRefresh: true,
              loading: () => StockLoading(count: 5),
              error: (e, _) => StockFailed(
                error: e,
                onRetry: () => ref.invalidate(stockOverviewProvider(_query)),
              ),
              data: (first) => _list(first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(StockOverview first) {
    final l = AppLocalizations.of(context);
    final pages = [first, ..._more];
    final rows = <(StockProduct, StockVariant)>[
      for (final p in pages)
        for (final product in p.items)
          for (final v in product.variants)
            if (_show != 'low' || v.state == 'low') (product, v),
    ];
    final hasMore = (_more.isEmpty ? first : _more.last).hasMore;
    return RefreshIndicator(
      onRefresh: () {
        _setQuery(() {});
        return ref.refresh(stockOverviewProvider(_query).future);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400 && hasMore && !_moreFailed) {
            _loadMore(first);
          }
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            if (rows.isEmpty)
              StockCard(
                child: AtomMessageState(
                  icon: LucideIcons.package,
                  title: _search.isNotEmpty
                      ? l.stockNoMatch(_search)
                      : l.stockNothingHere,
                  body: _search.isNotEmpty
                      ? l.stockNoMatchBody
                      : l.stockNoVariant,
                  art: false,
                ),
              )
            else
              StockRows(
                children: [
                  for (final (p, v) in rows) _ListRow(product: p, variant: v),
                ],
              ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: AtomSpinner(size: 22)),
              ),
            if (_moreFailed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AtomButton(
                  label: l.commonTryAgain,
                  kind: AtomButtonKind.outline,
                  onPressed: () {
                    setState(() => _moreFailed = false);
                    _loadMore(first);
                  },
                ),
              ),
            const SizedBox(height: 10),
            Text(l.stockListNote, style: AtomText.small),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.product, required this.variant});

  final StockProduct product;
  final StockVariant variant;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = variant;
    final code = [?product.prNumber, ?v.sku].join(' · ');
    return AtomPressable(
      onTap: () => context.push(V2Routes.productStockOf(product.id)),
      semanticLabel: l.stockVariantSemantics(
        variantTitle(product.title, v.name),
        v.available,
      ),
      scaleOnPress: false,
      builder: (context, pressed) => Container(
        color: pressed ? AtomColors.head : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const AtomIconTile(
              icon: LucideIcons.package,
              tone: AtomTone.grey,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    variantTitle(product.title, v.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtomText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AtomColors.ink,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (code.isNotEmpty) Text(code, style: AtomText.small),
                      StockTag(
                        label: v.onWebsite ? l.stockOnAtomshop : l.stockNotLive,
                        tone: v.onWebsite ? AtomTone.green : AtomTone.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${v.available}',
                  style: AtomText.amount.copyWith(
                    fontSize: 22,
                    color: stateInk(v.state),
                  ),
                ),
                Text(
                  stateLabel(l, v.state),
                  style: AtomText.tag.copyWith(color: stateTone(v.state).fg),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
