import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/stock_models.dart';
import '../data/stock_repository.dart';
import '../data/stock_rules.dart';
import 'product_stock_screen.dart' show MoveRow;
import 'stock_parts.dart';

/// 9.9 Stock history: every stock in, delivery, move and adjustment, by
/// day, newest first. Paged.
class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key, this.productId});

  /// One stock product's history (from 9.4).
  final int? productId;

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

const _types = <String?>[null, 'stock_in', 'sale', 'moved', 'adjusted'];
Map<String, String> _periods(AppLocalizations l) => {
  '30': l.stockPeriod30,
  'month': l.stockPeriodMonth,
  '90': l.stockPeriod90,
  'all': l.stockPeriodAll,
};

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  String? _type;
  String _period = '30';
  String _search = '';
  int? _outletId;
  final _searchBox = TextEditingController();
  Timer? _debounce;
  final _more = <ApiPage<StockMove>>[];
  bool _loadingMore = false;
  bool _moreFailed = false;

  HistoryQuery get _query => (
    type: _type,
    period: _period,
    search: _search,
    outletId: _outletId,
    productId: widget.productId,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _searchBox.dispose();
    super.dispose();
  }

  void _setQuery(void Function() change) => setState(() {
    change();
    _more.clear();
    _moreFailed = false;
  });

  Future<void> _loadMore(ApiPage<StockMove> first) async {
    final last = _more.isEmpty ? first : _more.last;
    if (_loadingMore || !last.hasMore) return;
    setState(() => _loadingMore = true);
    final q = _query;
    final r = await ref
        .read(stockRepositoryProvider)
        .history(
          type: q.type,
          period: q.period,
          query: q.search,
          outletId: q.outletId,
          productId: q.productId,
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
    final periods = _periods(l);
    final data = ref.watch(stockHistoryProvider(_query));
    final session = stockSession(ref);
    final outlets = session?.outlets ?? const [];
    final multi = session?.outletId == null && outlets.length > 1;

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          AtomPageHeader(
            title: l.stockHistoryTitle,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: l.commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            tabs: [
              AtomHeaderTab(l.stockAll),
              AtomHeaderTab(l.stockIn),
              AtomHeaderTab(l.stockMoveDelivered),
              AtomHeaderTab(l.stockMoveMoved),
              AtomHeaderTab(l.stockMoveAdjusted),
            ],
            selectedTab: _types.indexOf(_type),
            onTab: (i) => _setQuery(() => _type = _types[i]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            // No label above the box (the board's search has its
            // placeholder only); the label is read out.
            child: Semantics(
              label: l.stockSearchHistory,
              child: AtomTextField(
                label: '',
                controller: _searchBox,
                placeholder: l.stockHistoryHint,
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (multi)
                    StockFilterChip(
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
                        final id = await showAtomSelect<int>(
                          context,
                          title: l.stockOutlet,
                          selected: _outletId ?? 0,
                          options: [
                            AtomOption(value: 0, label: l.stockAllOutlets),
                            for (final o in outlets)
                              AtomOption(value: o.id, label: o.name),
                          ],
                        );
                        if (id != null) {
                          _setQuery(() => _outletId = id == 0 ? null : id);
                        }
                      },
                    ),
                  StockFilterChip(
                    label: l.stockWhenFilter(periods[_period] ?? ''),
                    active: _period != '30',
                    onTap: () async {
                      final p = await showAtomSelect<String>(
                        context,
                        title: l.stockWhen,
                        selected: _period,
                        options: [
                          for (final e in periods.entries)
                            AtomOption(value: e.key, label: e.value),
                        ],
                      );
                      if (p != null) _setQuery(() => _period = p);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: data.when(
              skipLoadingOnRefresh: true,
              loading: () => StockLoading(count: 5),
              error: (e, _) => StockFailed(
                error: e,
                onRetry: () => ref.invalidate(stockHistoryProvider(_query)),
              ),
              data: _list,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(ApiPage<StockMove> first) {
    final rows = [
      for (final p in [first, ..._more]) ...p.items,
    ];
    final l = AppLocalizations.of(context);
    final groups = groupByDay(l, rows, DateTime.now());
    final hasMore = (_more.isEmpty ? first : _more.last).hasMore;
    return RefreshIndicator(
      onRefresh: () {
        _setQuery(() {});
        return ref.refresh(stockHistoryProvider(_query).future);
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                // The board's plain card: one bold line, centred.
                child: StockCard(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _search.isEmpty
                        ? l.stockNothingPeriod
                        : l.stockNoMatch(_search),
                    textAlign: TextAlign.center,
                    style: AtomText.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
                child: Text(g.day.toUpperCase(), style: AtomText.section),
              ),
              StockRows(children: [for (final m in g.rows) MoveRow(move: m)]),
            ],
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
          ],
        ),
      ),
    );
  }
}
