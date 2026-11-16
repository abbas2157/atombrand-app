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
import '../data/home_logic.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'home_parts.dart';

enum _Tab { all, orders, products, bulk }

/// Search (5.8): orders, products and bulk requests from `GET search`,
/// grouped, with what matched marked. Sections the role can't see don't
/// show. With no signal and the Offline add-on, from the phone's copy.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  final _text = TextEditingController();
  Timer? _wait;
  _Tab _tab = _Tab.all;
  String _query = '';
  SearchResults? _results;
  bool _loading = false;
  Object? _failure;

  /// Answers to an older query are dropped.
  int _asked = 0;

  @override
  void dispose() {
    _wait?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _asked++;
    _wait?.cancel();
    _wait = Timer(const Duration(milliseconds: 350), () => _search(value));
    setState(() {});
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    if (q.length < 2) {
      _asked++;
      setState(() {
        _query = q;
        _results = null;
        _loading = false;
        _failure = null;
      });
      return;
    }
    final ask = ++_asked;
    setState(() {
      _query = q;
      _loading = true;
      _failure = null;
    });
    final who =
        ref.read(sessionProvider.notifier).current?.who ?? const Who.owner();
    final r = await ref
        .read(homeRepositoryProvider)
        .search(q.length > 100 ? q.substring(0, 100) : q, who: who);
    if (!mounted || ask != _asked) return;
    setState(() {
      _loading = false;
      switch (r) {
        case ApiOk(:final value):
          _results = value;
        case ApiErr(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    final who =
        ref.watch(sessionProvider.notifier).current?.who ?? const Who.owner();
    final access = ref.watch(accessProvider);
    final canScan =
        access.has(Addon.inventory) && who.can(BrandPermission.stockView);
    final offline = access.has(Addon.offline);
    final r = _results;

    String n(Found<Object?>? f) =>
        f == null ? '0' : '${f.items.length}${f.more ? '+' : ''}';
    final seesOrders = r?.orders != null || who.can(BrandPermission.ordersView);
    final seesProducts =
        r?.products != null || who.can(BrandPermission.catalogueView);
    final seesBulk = r?.requests != null || who.can(BrandPermission.bulkView);
    final tabs = [
      (_Tab.all, l.homeAllCount(r?.total ?? 0)),
      if (seesOrders) (_Tab.orders, l.homeOrdersCount(n(r?.orders))),
      if (seesProducts) (_Tab.products, l.homeProductsCount(n(r?.products))),
      if (seesBulk) (_Tab.bulk, l.homeBulkCount(n(r?.requests))),
    ];
    bool shows(_Tab t) => _tab == _Tab.all || _tab == t;

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              6,
              MediaQuery.paddingOf(context).top,
              16,
              3,
            ),
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      AtomIconButton(
                        icon: LucideIcons.chevronLeft,
                        label: l.commonBack,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: _field(canScan)),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      for (final (t, label) in tabs) ...[
                        if (t != _Tab.all) const SizedBox(width: 8),
                        HomeChip(
                          label: label,
                          on: _tab == t,
                          onTap: () => setState(() => _tab = t),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (_loading && r == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: AtomLoadingRows(count: 3),
                  )
                else if (_failure != null && r == null)
                  SizedBox(
                    height: 300,
                    child: AtomErrorState(
                      message: noSignal(_failure) ? l.homeSearchOffline : null,
                      onRetry: () => _search(_query),
                    ),
                  )
                else if (r != null) ...[
                  if (r.fromCopy)
                    Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: AtomNote(
                        kind: AtomNoteKind.warning,
                        message: l.homeFromCopyNote,
                        compact: true,
                      ),
                    ),
                  if (r.total == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Text(
                        l.homeNoneFound(r.query),
                        style: AtomText.secondary,
                      ),
                    ),
                  if (shows(_Tab.orders) &&
                      (r.orders?.items.isNotEmpty ?? false))
                    ..._group(l.homeOrdersCount(n(r.orders)), [
                      for (final o in r.orders!.items) _order(o, who),
                    ], r.orders!.more),
                  if (shows(_Tab.products) &&
                      (r.products?.items.isNotEmpty ?? false))
                    ..._group(l.homeProductsCount(n(r.products)), [
                      for (final p in r.products!.items)
                        _product(p, who, canScan),
                    ], r.products!.more),
                  if (shows(_Tab.bulk) &&
                      (r.requests?.items.isNotEmpty ?? false))
                    ..._group(l.homeRequestsCount(n(r.requests)), [
                      for (final q in r.requests!.items) _request(q),
                    ], r.requests!.more),
                ] else if (_query.isNotEmpty && _query.length < 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(l.homeTypeMore, style: AtomText.secondary),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 14,
                        color: AtomColors.faint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offline ? l.homeSearchTipOffline : l.homeSearchTip,
                          style: AtomText.small.copyWith(
                            color: AtomColors.faint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _group(String title, List<Widget> rows, bool more) => [
    Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: AtomText.small.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AtomColors.muted,
          ),
        ),
      ),
    ),
    HomeCard(children: rows),
    if (more)
      Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Text(
          l.homeFirstFive,
          style: AtomText.small.copyWith(color: AtomColors.faint),
        ),
      ),
  ];

  Widget _field(bool canScan) {
    final l = AppLocalizations.of(context);
    return Container(
      height: AtomSize.sheetSearch,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.primary),
        boxShadow: const [
          BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 20, color: AtomColors.faint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _text,
              autofocus: true,
              onChanged: _changed,
              onSubmitted: _search,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              style: AtomText.input.copyWith(color: AtomColors.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                // The whole hint fits beside the scan key: it scales down
                // rather than end in "…" (5.8).
                hint: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l.homeSearchHint,
                    maxLines: 1,
                    style: AtomText.input.copyWith(
                      color: AtomColors.placeholder,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_text.text.isNotEmpty)
            AtomPressable(
              onTap: () {
                _text.clear();
                _changed('');
              },
              semanticLabel: l.commonClear,
              builder: (_, _) => const SizedBox(
                width: 40,
                height: 40,
                child: Icon(LucideIcons.x, size: 18, color: AtomColors.faint),
              ),
            )
          else if (canScan)
            AtomPressable(
              onTap: () => context.push(V2Routes.scanSerial),
              semanticLabel: l.homeScan,
              builder: (_, _) => const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  LucideIcons.scanBarcode,
                  size: 20,
                  color: AtomColors.faint,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// [text] with the query marked.
  InlineSpan _marked(String text, TextStyle base) {
    final q = _query.toLowerCase();
    final at = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (at < 0) return TextSpan(text: text, style: base);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: text.substring(0, at)),
        TextSpan(
          text: text.substring(at, at + q.length),
          style: const TextStyle(backgroundColor: AtomColors.searchMark),
        ),
        TextSpan(text: text.substring(at + q.length)),
      ],
    );
  }

  Widget _hit({
    required IconData icon,
    required AtomTone tone,
    required String title,
    required String sub,
    Widget? pill,
    VoidCallback? onTap,
  }) => AtomPressable(
    onTap: onTap,
    scaleOnPress: false,
    semanticLabel: '$title, $sub',
    builder: (_, pressed) => ExcludeSemantics(
      child: Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            HomeIconTile(icon: icon, tone: tone, iconSize: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(_marked(title, AtomText.listTitle)),
                  const SizedBox(height: 1),
                  Text.rich(_marked(sub, AtomText.secondary)),
                ],
              ),
            ),
            if (pill != null) ...[const SizedBox(width: 12), pill],
          ],
        ),
      ),
    ),
  );

  Widget _order(HomeOrder o, Who who) => _hit(
    icon: o.atompay ? LucideIcons.creditCard : LucideIcons.fileText,
    tone: AtomTone.blue,
    title: ['#${o.id}', ?o.productTitle].join(' · '),
    sub: [
      o.atompay ? l.homeAtompay : l.homeCash,
      ?o.customer,
      formatRs(o.total),
    ].join(' · '),
    pill: AtomPill(label: o.statusLabel, tone: orderTone(o.status)),
    onTap: o.uuid.isEmpty
        ? null
        : () => context.push(
            o.atompay ? V2Routes.atompayOf(o.uuid) : V2Routes.orderOf(o.uuid),
          ),
  );

  Widget _product(FoundProduct p, Who who, bool stock) => _hit(
    icon: LucideIcons.tag,
    tone: AtomTone.green,
    title: p.title,
    sub: [?p.prNumber, if (p.price > 0) formatRs(p.price)].join(' · '),
    pill: AtomPill(
      label: productLabel(p.status, p.statusLabel, l),
      tone: productTone(p.status),
    ),
    onTap: stock
        ? () => context.push(V2Routes.productStockOf(p.id))
        : who.can(BrandPermission.catalogueEdit)
        ? () => context.push(V2Routes.productEditOf(p.id))
        : null,
  );

  Widget _request(FoundRequest q) {
    final (label, tone) = requestPill(q.status, l);
    return _hit(
      icon: LucideIcons.funnel,
      tone: AtomTone.amber,
      title: [
        if (q.quantity > 0) '${q.quantity} ×',
        q.productTitle ?? '',
      ].join(' ').trim(),
      sub: [
        ?q.name,
        q.fromSeller ? l.homeSellerRequest : l.homeWebsite,
      ].join(' · '),
      pill: AtomPill(label: label, tone: tone),
      onTap: () => context.push(
        q.fromSeller
            ? V2Routes.sellerRequestOf(q.id)
            : V2Routes.bulkRequestOf(q.id),
      ),
    );
  }
}
