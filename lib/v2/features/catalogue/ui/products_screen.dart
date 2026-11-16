import 'dart:async';

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
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../states/ui/state_screens.dart';
import '../data/catalogue_logic.dart';
import '../data/catalogue_models.dart';
import '../data/catalogue_repository.dart';
import 'catalogue_parts.dart';
import 'product_actions_sheet.dart';

/// Products (8.1), the fourth tab: the status tiles (Live, In review, Out
/// of stock, On hold) filter the list and carry the server's counts; the
/// On hold callout; search by name or PR number; sort; each row's price,
/// status and tags; the ⋯ sheet of actions the person's role allows.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key, this.initialStatus});

  /// One status tile on (`V2Routes.productsWith(status:)`), e.g. `On hold`
  /// from a Home task.
  final String? initialStatus;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

const _searchPause = Duration(milliseconds: 350);

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  late String? _status = widget.initialStatus;

  @override
  void didUpdateWidget(ProductsScreen old) {
    super.didUpdateWidget(old);
    if (old.initialStatus != widget.initialStatus) {
      setState(() => _status = widget.initialStatus);
    }
  }

  ProductSort _sort = ProductSort.newest;
  final _search = TextEditingController();
  String _term = '';
  Timer? _searchTimer;

  /// Pages after the first, for the query they were read for.
  final _more = <ProductRow>[];
  ProductsQuery? _moreFor;
  int _page = 1;
  bool _lastPage = false;
  bool _loadingMore = false;

  /// Rows changed here (featured, AtomPay) before the list reloads.
  final _patched = <int, ProductRow>{};

  /// The counts last read, kept while another filter loads.
  ProductsPage? _lastCounts;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  ProductsQuery get _query =>
      (search: _term, status: _status, sort: _sort.serverKey);

  void _searchNow() {
    _searchTimer?.cancel();
    final term = _search.text.trim();
    if (mounted && term != _term) setState(() => _term = term);
  }

  Future<void> _showMore(ProductsQuery q) async {
    setState(() => _loadingMore = true);
    final r = await ref
        .read(catalogueRepositoryProvider)
        .products(
          search: q.search,
          status: q.status,
          sort: q.sort,
          page: _page + 1,
        );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      switch (r) {
        case ApiOk(:final value):
          _more.addAll(value.rows);
          _page = value.page;
          _lastPage = !value.hasMore;
        case ApiErr(:final failure):
          showAtomToast(
            context,
            kind: AtomToastKind.bad,
            message: sayFailure(AppLocalizations.of(context), failure),
          );
      }
    });
  }

  /// Reads the list again from the first page (a status changed, a product
  /// went).
  void _reload() {
    setState(() {
      _moreFor = null;
      _patched.clear();
    });
    ref.invalidate(productsProvider);
  }

  Future<void> _pickSort() async {
    final l = AppLocalizations.of(context);
    final s = await showAtomSelect<ProductSort>(
      context,
      title: l.catSortTitle,
      selected: _sort,
      options: [
        for (final s in ProductSort.values)
          if (s != ProductSort.stock ||
              ref.read(accessProvider).has(Addon.inventory))
            AtomOption(value: s, label: sortLabel(s, l)),
      ],
    );
    if (s != null && mounted) setState(() => _sort = s);
  }

  Future<void> _openActions(ProductRow p, List<ProductAction> actions) async {
    final action = await showProductActions(
      context,
      product: p,
      actions: actions,
      onChanged: (changed) {
        if (mounted) setState(() => _patched[changed.id] = changed);
      },
    );
    if (action == null || !mounted) return;
    final current = _patched[p.id] ?? p;
    switch (action) {
      case ProductAction.edit:
        await context.push(V2Routes.productEditOf(p.id));
      case ProductAction.stock:
        final stockId = p.available?.stockProductId;
        await context.push(
          stockId == null
              ? V2Routes.stockList()
              : V2Routes.productStockOf(stockId),
        );
      case ProductAction.markOut:
        await _setAvailability(current, available: false);
      case ProductAction.backIn:
        final units = await askUnits(context);
        if (units != null && mounted) {
          await _setAvailability(current, available: true, stock: units);
        }
      case ProductAction.delete:
        await _delete(current);
      case ProductAction.feature || ProductAction.atompay:
        break;
    }
  }

  Future<void> _setAvailability(
    ProductRow p, {
    required bool available,
    int? stock,
  }) async {
    final r = await ref
        .read(catalogueRepositoryProvider)
        .setAvailability(p.id, available: available, stock: stock);
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: available ? l.catMarkedIn : l.catMarkedOut,
        );
        _reload();
      case ApiErr(:final failure):
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(AppLocalizations.of(context), failure),
        );
    }
  }

  Future<void> _delete(ProductRow p) async {
    final l = AppLocalizations.of(context);
    final yes = await showAtomConfirm(
      context,
      title: l.catDeleteConfirmTitle(p.title),
      body: l.catDeleteConfirmBody,
      confirmLabel: l.catDelete,
      destructive: true,
    );
    if (!yes || !mounted) return;
    final r = await ref.read(catalogueRepositoryProvider).delete(p.id);
    if (!mounted) return;
    switch (r) {
      case ApiOk():
        showAtomToast(context, kind: AtomToastKind.ok, message: l.catDeleted);
        _reload();
        ref.invalidate(brandPageProvider);
      case ApiErr(:final failure):
        // 409: it has been ordered; the server's words say so and suggest
        // marking it out of stock.
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(AppLocalizations.of(context), failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = _query;
    if (_moreFor != query) {
      _moreFor = query;
      _more.clear();
      _page = 1;
      _lastPage = false;
    }
    final data = ref.watch(productsProvider(query));
    if (data.value case final v? when !v.fromCopy || _lastCounts == null) {
      _lastCounts = v;
    }
    final counts = data.value ?? _lastCounts;

    final who = ref.watch(sessionProvider.notifier).current?.who;
    final canEdit = who?.can(BrandPermission.catalogueEdit) ?? false;
    final canStock = who?.can(BrandPermission.stockView) ?? false;
    final access = ref.watch(accessProvider);
    final inventoryOn = access.addons == null
        ? null
        : access.has(Addon.inventory);
    final askAtom = access.has(Addon.askAtom);

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.catProductsTitle,
            subtitle: counts == null
                ? null
                : l.catProductsSummary(
                    counts.total,
                    counts.countOf(ProductStatus.published),
                  ),
            actions: [
              if (askAtom)
                AtomIconButton(
                  icon: LucideIcons.sparkles,
                  label: l.catAskAtom,
                  glyph: const AtomAiMark(size: 30),
                  onTap: () => context.push(V2Routes.askAtom),
                ),
              // At large text on a narrow phone the label can't fit beside
              // the title: the + alone, with its name for screen readers.
              if (canEdit &&
                  (MediaQuery.textScalerOf(context).scale(10) <= 13 ||
                      MediaQuery.sizeOf(context).width >= 400))
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 8),
                  child: AtomButton.small(
                    label: l.catAddProduct,
                    icon: LucideIcons.plus,
                    kind: AtomButtonKind.primary,
                    onPressed: () => context.push(V2Routes.productNew),
                  ),
                )
              else if (canEdit)
                AtomIconButton(
                  icon: LucideIcons.plus,
                  label: l.catAddProduct,
                  onTap: () => context.push(V2Routes.productNew),
                ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                setState(() {
                  _moreFor = null;
                  _patched.clear();
                });
                return ref.refresh(productsProvider(query).future);
              },
              child: AtomSliverPage(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                slivers: [
                  SliverToBoxAdapter(
                    child: _StatusTiles(
                      counts: counts,
                      selected: _status,
                      onPick: (s) =>
                          setState(() => _status = _status == s ? null : s),
                    ),
                  ),
                  if (data.value?.fromCopy ?? false)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: AtomNote(
                          kind: AtomNoteKind.warning,
                          message: l.catOfflineList,
                          compact: true,
                        ),
                      ),
                    ),
                  if (_holdCallout(counts, data.value, canEdit)
                      case final callout?)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: callout,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SearchBox(
                              controller: _search,
                              onChanged: (_) {
                                _searchTimer?.cancel();
                                _searchTimer = Timer(_searchPause, _searchNow);
                              },
                              onSubmitted: (_) => _searchNow(),
                            ),
                          ),
                          const SizedBox(width: AtomSpace.s2),
                          AtomFilterChip(
                            label: sortLabel(_sort, l),
                            minHeight: 44,
                            onTap: _pickSort,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _status == null
                                  ? l.catAllProducts
                                  : '${ProductStatus.label(_status!, l)} · ${counts?.countOf(_status!) ?? 0}',
                              style: AtomText.fieldLabel.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AtomColors.ink,
                              ),
                            ),
                          ),
                          if (_status != null)
                            AtomTextLink(
                              label: l.catShowAll,
                              onTap: () => setState(() => _status = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ...data.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const [
                      SliverToBoxAdapter(child: AtomLoadingRows()),
                    ],
                    error: (e, _) => [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 360,
                          child:
                              e is ApiFailure &&
                                  (e.kind == ApiFailureKind.offline ||
                                      e.kind == ApiFailureKind.timeout)
                              ? NoInternetBody(
                                  onRetry: () =>
                                      ref.invalidate(productsProvider(query)),
                                )
                              : AtomErrorState(
                                  message: e is ApiFailure ? e.message : null,
                                  error: e,
                                  onRetry: () =>
                                      ref.invalidate(productsProvider(query)),
                                ),
                        ),
                      ),
                    ],
                    data: (page) => _rows(
                      page,
                      query,
                      canEdit: canEdit,
                      canStock: canStock,
                      inventoryOn: inventoryOn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The On hold callout: the one product and Atomshop's reason with Fix,
  /// or how many are held with See.
  Widget? _holdCallout(ProductsPage? counts, ProductsPage? page, bool canEdit) {
    final l = AppLocalizations.of(context);
    if (counts == null) return null;
    if (_status != null && _status != ProductStatus.onHold) return null;
    final held = counts.countOf(ProductStatus.onHold);
    if (held == 0) return null;
    ProductRow? one;
    if (held == 1) {
      for (final p in [...?page?.rows, ..._more]) {
        if (p.status == ProductStatus.onHold) {
          one = p;
          break;
        }
      }
    }
    if (held > 1 && _status == ProductStatus.onHold) return null;
    final (title, body, action, onAction) = one != null
        ? (
            l.catOnHoldOne(one.title),
            one.holdWhy,
            canEdit ? l.catFix : null,
            () => context.push(V2Routes.productEditOf(one!.id)),
          )
        : (
            l.catOnHoldMany(held),
            l.catOnHoldManyBody,
            l.catSee,
            () => setState(() => _status = ProductStatus.onHold),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AtomColors.roseSoft.withValues(alpha: 0.45),
        borderRadius: AtomRadius.brCard,
        border: Border.all(color: AtomColors.roseLine),
      ),
      child: Row(
        children: [
          const AtomIconTile(
            icon: LucideIcons.triangleAlert,
            tone: AtomTone.rose,
          ),
          const SizedBox(width: AtomSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AtomText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AtomColors.ink,
                  ),
                ),
                if (body != null)
                  Text(
                    body,
                    style: AtomText.secondary.copyWith(
                      color: AtomColors.noteRoseText,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AtomSpace.s2),
            AtomButton.small(label: action, onPressed: onAction),
          ],
        ],
      ),
    );
  }

  List<Widget> _rows(
    ProductsPage page,
    ProductsQuery query, {
    required bool canEdit,
    required bool canStock,
    required bool? inventoryOn,
  }) {
    final rows = sortProducts([
      for (final p in [...page.rows, ..._more]) _patched[p.id] ?? p,
    ], _sort);
    final more = !page.fromCopy && (_page == 1 ? page.hasMore : !_lastPage);
    final filtered = query.status != null || query.search.isNotEmpty;
    return [
      if (rows.isEmpty)
        SliverToBoxAdapter(
          child: filtered || page.total > 0
              ? Container(
                  decoration: AtomDecor.card,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 28,
                  ),
                  child: Text(
                    query.search.isNotEmpty
                        ? l.catNoProductsFound
                        : l.catNoProductsHere,
                    textAlign: TextAlign.center,
                    style: AtomText.body.copyWith(color: AtomColors.muted),
                  ),
                )
              : SizedBox(
                  height: 320,
                  child: AtomMessageState(
                    icon: LucideIcons.tag,
                    tone: AtomTone.blue,
                    title: l.catFirstProductTitle,
                    body: l.catFirstProductBody,
                    actionLabel: canEdit ? l.catAddProduct : null,
                    onAction: canEdit
                        ? () => context.push(V2Routes.productNew)
                        : null,
                  ),
                ),
        )
      else
        SliverAtomListCard(
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final p = rows[i];
            final actions = page.fromCopy
                ? const <ProductAction>[]
                : productActions(
                    p,
                    canEdit: canEdit,
                    canStock: canStock,
                    inventoryOn: inventoryOn,
                  );
            return ProductListRow(
              product: p,
              showAvailability: inventoryOn ?? page.inventory,
              // A role without catalogue edit can't open the form; it reads
              // the product's stock instead, when it may.
              onTap: page.fromCopy
                  ? null
                  : canEdit
                  ? () => context.push(V2Routes.productEditOf(p.id))
                  : canStock && inventoryOn == true
                  ? switch (p.available?.stockProductId) {
                      final id? => () => context.push(
                        V2Routes.productStockOf(id),
                      ),
                      null => null,
                    }
                  : null,
              onMore: actions.isEmpty ? null : () => _openActions(p, actions),
            );
          },
        ),
      SliverList.list(
        children: [
          if (more) ...[
            const SizedBox(height: 10),
            AtomButton(
              label: l.catShowMore,
              kind: AtomButtonKind.outline,
              small: true,
              saving: _loadingMore,
              onPressed: () => _showMore(query),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Tiny(l.catReviewFoot),
          ),
        ],
      ),
    ];
  }
}

/// The four status tiles (`.stiles`): the count in the status colour over
/// its name; the picked one outlined in blue. Two by two when large text
/// leaves them too narrow.
class _StatusTiles extends StatelessWidget {
  const _StatusTiles({
    required this.counts,
    required this.selected,
    required this.onPick,
  });

  final ProductsPage? counts;
  final String? selected;
  final ValueChanged<String> onPick;

  static Color _colour(String status) => switch (status) {
    ProductStatus.published => AtomColors.green,
    ProductStatus.pending => AtomColors.primary,
    ProductStatus.outOfStock => AtomColors.amberInk,
    _ => AtomColors.rose,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.catFilterByStatus,
      container: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
          final columns = (box.maxWidth - 24) / 4 >= 74 * scale ? 4 : 2;
          // Rows of equal tiles: a fractional width in a Wrap left them
          // uneven, and a label on two lines made one tile taller.
          const tiles = ProductStatus.tiles;
          return Column(
            children: [
              for (var r = 0; r < tiles.length; r += columns) ...[
                if (r > 0) const SizedBox(height: 8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = r; c < r + columns; c++) ...[
                        if (c > r) const SizedBox(width: 8),
                        Expanded(
                          child: c < tiles.length
                              ? _tile(tiles[c], l)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String status, AppLocalizations l) {
    final on = selected == status;
    final n = counts?.countOf(status);
    final label = ProductStatus.label(status, l);
    return AtomPressable(
      onTap: () => onPick(status),
      selected: on,
      semanticLabel: '$label, ${n ?? ''}',
      builder: (context, pressed) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: on
              ? AtomColors.unreadRow
              : pressed
              ? AtomColors.head
              : AtomColors.paper,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: on ? AtomColors.primary : AtomColors.line,
            width: on ? 2 : 1,
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                n == null ? '–' : '$n',
                style: AtomText.amount.copyWith(
                  fontSize: 22,
                  height: 1.1,
                  color: _colour(status),
                ),
              ),
              const SizedBox(height: 2),
              // One line in every tile, so all four stay the same height:
              // a long name ("Out of stock") shrinks a little to fit.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: AtomText.small.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The search box beside Sort: a magnifier and "Product name or PR number".
class _SearchBox extends StatefulWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: atomInputBox(
        focused: _focus.hasFocus,
        error: false,
        disabled: false,
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.search,
            size: AtomIcon.row,
            color: AtomColors.faint,
          ),
          const SizedBox(width: AtomSpace.s2),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: AtomText.input.copyWith(fontSize: 15),
              inputFormatters: [LengthLimitingTextInputFormatter(80)],
              decoration: InputDecoration(
                hintText: l.catSearchHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
                semanticCounterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of Products (`.prow`): the photo, "PR-10421 · Category", the
/// title, price and status pill, then the tags; ⋯ on the right.
class ProductListRow extends StatelessWidget {
  const ProductListRow({
    super.key,
    required this.product,
    required this.showAvailability,
    this.onTap,
    this.onMore,
  });

  final ProductRow product;
  final bool showAvailability;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = product;
    final avail = showAvailability ? availabilityTag(p.available, l) : null;
    final variants = variantsTag(p);
    final tags = <Widget>[
      if (avail != null) ProductTag(avail.$1, tone: tagTone(avail.$2)),
      if (p.atompayOn) ProductTag(l.catAtompayOnTag, tone: AtomTone.blue),
      if (p.featured) ProductTag(l.catFeaturedTag, tone: AtomTone.amber),
      if (variants != null) ProductTag(variants),
    ];
    final price = formatRs(p.price);
    return Container(
      color: AtomColors.paper,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AtomPressable(
              onTap: onTap,
              scaleOnPress: false,
              semanticLabel: [
                p.title,
                productCodeLine(p, l),
                price,
                p.statusLabel(l),
                ?avail?.$1,
                if (p.atompayOn) l.catAtompayOnTag,
                if (p.featured) l.catFeatured,
                ?variants,
              ].join(', '),
              builder: (context, pressed) => ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AtomThumb(url: p.picture, size: 56),
                    const SizedBox(width: AtomSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productCodeLine(p, l),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtomText.small.copyWith(
                              color: AtomColors.faint,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AtomText.listTitle.copyWith(
                              color: pressed
                                  ? AtomColors.primary
                                  : AtomColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                price,
                                style: AtomText.money.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              StatusPill(
                                label: p.statusLabel(l),
                                tone: statusTone(p.status),
                              ),
                            ],
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(spacing: 6, runSpacing: 6, children: tags),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onMore != null)
            AtomIconButton(
              icon: LucideIcons.ellipsisVertical,
              label: l.catMoreActionsFor(p.title),
              color: AtomColors.muted,
              onTap: onMore,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
