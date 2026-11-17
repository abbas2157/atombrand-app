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
  int? _categoryId;

  /// The category choices last read, kept while another filter loads.
  List<({int id, String title})> _categories = const [];
  final _searchBox = TextEditingController();
  Timer? _debounce;

  /// Pages after the first, for the current filters.
  final _more = <StockOverview>[];
  bool _loadingMore = false;
  bool _moreFailed = false;

  StockQuery get _query => (
    show: _show,
    search: _search,
    outletId: _outletId,
    categoryId: _categoryId,
  );

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
          categoryId: q.categoryId,
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
    if (first != null && !first.fromCopy && first.categories.isNotEmpty) {
      _categories = first.categories;
    }
    final categoryName = _categoryId == null
        ? l.stockAll
        : _categories
                  .where((c) => c.id == _categoryId)
                  .map((c) => c.title)
                  .firstOrNull ??
              l.stockAll;

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
                Padding(
                  // with the header's 8: the 16px gutter
                  padding: const EdgeInsets.only(right: 8),
                  child: AtomButton.small(
                    label: l.stockIn,
                    kind: AtomButtonKind.primary,
                    onPressed: () => context.push(V2Routes.stockIn()),
                  ),
                ),
            ],
            fitTabs: true,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: l.stockFindStock,
                    child: AtomTextField(
                      label: '',
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
                ),
                const SizedBox(width: 8),
                // The board's `.scan`: a 46px square icon button.
                AtomPressable(
                  onTap: () => context.push(V2Routes.scanSerial),
                  semanticLabel: l.stockScan,
                  builder: (context, pressed) => Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: pressed ? AtomColors.head : AtomColors.paper,
                      borderRadius: AtomRadius.brControl,
                      border: Border.all(color: AtomColors.line2),
                    ),
                    child: const Icon(
                      LucideIcons.scanBarcode,
                      size: 22,
                      color: AtomColors.ink,
                    ),
                  ),
                ),
              ],
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
                          _setQuery(
                            () => _outletId = picked == 0 ? null : picked,
                          );
                        }
                      },
                    ),
                  if (_categories.isNotEmpty || _categoryId != null)
                    StockFilterChip(
                      label: l.stockCategoryFilter(categoryName),
                      active: _categoryId != null,
                      onTap: () async {
                        final picked = await showAtomSelect<int>(
                          context,
                          title: l.stockCategory,
                          selected: _categoryId ?? 0,
                          options: [
                            AtomOption(value: 0, label: l.stockAll),
                            for (final c in _categories)
                              AtomOption(value: c.id, label: c.title),
                          ],
                        );
                        if (picked != null) {
                          _setQuery(
                            () => _categoryId = picked == 0 ? null : picked,
                          );
                        }
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
    final listed = listedOnWebsite(product.websiteStatus) || v.onWebsite;
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
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
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
                  // One line, as on the board (`white-space: nowrap`,
                  // ellipsis): the code, then the listing tag inline.
                  Text.rich(
                    TextSpan(
                      children: [
                        if (code.isNotEmpty) TextSpan(text: '$code '),
                        // Listed on the website (live or out of stock
                        // there), as Products says; not whether units can
                        // sell now.
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          // The span already scales it with the text.
                          child: MediaQuery.withNoTextScaling(
                            child: StockTag(
                              label: listed
                                  ? l.stockOnAtomshop
                                  : l.stockNotLive,
                              tone: listed ? AtomTone.green : AtomTone.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtomText.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // At least 70 wide (`.qty`); at large text it gives way and
            // the state wraps rather than push the row off the screen.
            Flexible(
              flex: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${v.available}',
                      style: AtomText.amount.copyWith(
                        fontSize: 18,
                        color: stateInk(v.state),
                      ),
                    ),
                    Text(
                      stateLabel(l, v.state),
                      textAlign: TextAlign.end,
                      style: AtomText.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: stateTone(v.state).fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
