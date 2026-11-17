import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../../core/format/ids.dart' show whatsAppUri;
import '../../help/data/help_repository.dart' show AtomshopContacts;
import '../../settings/ui/settings_parts.dart' show SettingsPane;
import '../data/notifications_repository.dart';

/// Where a notification leads (`data.screen`, docs/BRAND_APP.md §8.10).
/// Null when it has no screen of its own: the message itself is shown.
({String path, bool tab})? noticeTarget(
  Map<String, dynamic> data, {
  String? type,
}) {
  final orderUuid = Json.str(data['order_uuid']);
  final kind = type ?? Json.str(data['type']) ?? '';
  // An Atomshop seller's request (sourcing) opens 7.2, a website buyer's 7.3.
  final fromSeller =
      Json.str(data['from']) == 'seller' ||
      kind.startsWith('brand_quote_') ||
      kind == 'brand_sourcing_received';
  final bulkId = Json.integer(data['bulk_request_id']);
  final productId = Json.integer(data['product_id']);
  final dealId = Json.integer(data['deal_id']);
  final sourcingId = Json.integer(
    data['sourcing_request_id'] ?? data['request_id'],
  );
  return switch (Json.str(data['screen'])) {
    'order' when orderUuid != null => (
      path: Json.str(data['order_type']) == 'atompay'
          ? V2Routes.atompayOf(orderUuid)
          : V2Routes.orderOf(orderUuid),
      tab: false,
    ),
    'orders' when Json.str(data['status']) != null => (
      path: V2Routes.ordersWith(status: Json.str(data['status'])),
      tab: true,
    ),
    'order' || 'orders' => (path: V2Routes.orders, tab: true),
    'atompay' || 'atompay_order' when orderUuid != null => (
      path: V2Routes.atompayOf(orderUuid),
      tab: false,
    ),
    'bulk_request' when bulkId != null => (
      path: fromSeller
          ? V2Routes.sellerRequestOf(bulkId)
          : V2Routes.bulkRequestOf(bulkId),
      tab: false,
    ),
    'sourcing' when sourcingId != null => (
      path: V2Routes.sellerRequestOf(sourcingId),
      tab: false,
    ),
    'deal' when dealId != null => (path: V2Routes.dealOf(dealId), tab: false),
    'bulk_request' || 'sourcing' || 'deal' => (path: V2Routes.bulk, tab: true),
    'atompay' || 'atompay_order' => (path: V2Routes.atompayOrders, tab: true),
    'product' when productId != null => (
      path: V2Routes.productEditOf(productId),
      tab: false,
    ),
    'product' => (path: V2Routes.products, tab: true),
    'stock' || 'inventory' => (path: V2Routes.stock, tab: false),
    'billing' => (path: V2Routes.plan, tab: false),
    'reports' => (path: V2Routes.reports, tab: false),
    'support' => (path: V2Routes.support, tab: false),
    'dashboard' => (path: V2Routes.home, tab: true),
    'profile' => (path: V2Routes.profile, tab: false),
    _ => null,
  };
}

/// Opens what [n] is about: its screen, or the message.
void openNotice(BuildContext context, Notice n) {
  final t = n.fromAtomshop ? null : noticeTarget(n.data, type: n.type);
  if (t == null) {
    context.push(V2Routes.notificationMessage, extra: n);
  } else if (t.tab) {
    context.go(t.path);
  } else {
    context.push(t.path);
  }
}

/// The `.ico.grey` tile: muted icon on the surface grey.
const _greyTile = AtomTone(
  fg: AtomColors.muted,
  bg: AtomColors.surface,
  border: AtomColors.line,
);

/// The icon and tile colour of a notification (16.1's `I` paths).
(IconData, AtomTone) noticeLook(String type, Map<String, dynamic> data) {
  if (type == 'brand_admin_message' ||
      type == 'admin_message' ||
      type == 'support_reply' ||
      Json.str(data['from']) == 'atomshop') {
    return (LucideIcons.messageCircle, AtomTone.blue);
  }
  return switch (type) {
    'brand_new_order' => (LucideIcons.package, AtomTone.blue),
    'brand_orders_waiting' => (LucideIcons.triangleAlert, AtomTone.rose),
    'brand_quote_expiring' => (LucideIcons.clock, AtomTone.amber),
    'brand_weekly_summary' ||
    'brand_daily_summary' => (LucideIcons.chartColumn, AtomTone.blue),
    'brand_atompay_assigned' => (LucideIcons.creditCard, AtomTone.amber),
    'brand_new_bulk_request' => (LucideIcons.funnel, AtomTone.blue),
    'brand_quote_accepted' ||
    'brand_sourcing_received' => (LucideIcons.check, AtomTone.green),
    'brand_quote_declined' => (LucideIcons.x, AtomTone.rose),
    'brand_quote_change' => (LucideIcons.messageCircle, AtomTone.amber),
    'brand_product_reviewed'
        when Json.str(data['status']) == 'On hold' ||
            Json.str(data['status']) == 'Closed' =>
      (LucideIcons.triangleAlert, AtomTone.rose),
    'brand_product_reviewed' => (LucideIcons.tag, AtomTone.green),
    'brand_stock_low' ||
    'stock_low' => (LucideIcons.layoutGrid, AtomTone.amber),
    'brand_support_reply' => (LucideIcons.messageCircle, AtomTone.blue),
    'brand_billing' when Json.str(data['receipt']) != null => (
      LucideIcons.check,
      AtomTone.green,
    ),
    _ when type.startsWith('brand_billing') || type.startsWith('billing') => (
      LucideIcons.file,
      _greyTile,
    ),
    _ => (LucideIcons.bell, AtomTone.blue),
  };
}

/// A notification's own button ("Pay"), and
/// where it goes.
({String label, VoidCallback onTap})? _action(
  BuildContext context,
  AppLocalizations l,
  Notice n, {
  required Who? who,
  required bool inventory,
}) {
  final owner = who?.isOwner ?? false;
  bool can(String p) => who != null && who.can(p);
  final target = noticeTarget(n.data, type: n.type);
  ({String label, VoidCallback onTap}) go(String label, String path) =>
      (label: label, onTap: () => context.push(path));
  ({String label, VoidCallback onTap})? open(String label) => target == null
      ? null
      : (
          label: label,
          onTap: () =>
              target.tab ? context.go(target.path) : context.push(target.path),
        );
  final orderUuid = Json.str(n.data['order_uuid']);
  final bulkId = Json.integer(n.data['bulk_request_id']);
  final productId = Json.integer(n.data['product_id']);
  final status = Json.str(n.data['status']);
  return switch (n.type) {
    'brand_billing' when owner && Json.str(n.data['invoice']) != null => (
      label: l.bannerPay,
      onTap: () =>
          context.push(V2Routes.paidOf(bill: Json.str(n.data['invoice']))),
    ),
    'brand_new_order' || 'brand_orders_waiting'
        when can(BrandPermission.ordersStatus) =>
      open(l.notifActConfirm),
    'brand_atompay_assigned'
        when orderUuid != null && can(BrandPermission.atompayView) =>
      go(l.notifActHandOver, V2Routes.atompayHandoverOf(orderUuid)),
    'brand_new_bulk_request'
        when bulkId != null &&
            Json.str(n.data['from']) == 'seller' &&
            can(BrandPermission.bulkQuote) =>
      go(l.notifActSendQuote, V2Routes.sellerRequestQuoteOf(bulkId)),
    'brand_new_bulk_request' when can(BrandPermission.bulkView) => open(
      l.notifActReply,
    ),
    'brand_quote_change' when can(BrandPermission.bulkQuote) => open(
      l.notifActAnswer,
    ),
    'brand_quote_expiring' when can(BrandPermission.bulkView) => open(
      l.notifActFollowUp,
    ),
    'brand_quote_accepted' when can(BrandPermission.bulkView) => open(
      l.notifActOpenDeal,
    ),
    'brand_stock_low' when inventory && can(BrandPermission.stockChange) => go(
      l.notifActStockIn,
      V2Routes.stockIn(),
    ),
    'brand_product_reviewed'
        when status == 'On hold' &&
            productId != null &&
            can(BrandPermission.catalogueEdit) =>
      go(l.notifActFix, V2Routes.productEditOf(productId)),
    _ => null,
  };
}

String _kindName(AppLocalizations l, NoticeKind k, {required bool agent}) =>
    switch (k) {
      NoticeKind.orders => l.noticesOrders,
      NoticeKind.atompay => 'AtomPay',
      NoticeKind.bulk => l.noticesBulk,
      NoticeKind.stock => l.noticesStock,
      NoticeKind.products => l.notifKindReviews,
      NoticeKind.account => agent ? l.dpDcMessages : l.dpDcAtomshop,
    };

/// A filter chip (`.chips button`): a pill, 36 tall.
class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      selected: on,
      semanticLabel: label,
      focusRadius: AtomRadius.brPill,
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: AtomSize.small),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: on
              ? AtomColors.primarySoft
              : pressed
              ? AtomColors.surface
              : AtomColors.paper,
          borderRadius: AtomRadius.brPill,
          border: Border.all(
            color: on ? AtomColors.primary : AtomColors.line2,
            width: on ? 2 : 1,
          ),
        ),
        // In a Wrap: hug the label (a plain `alignment` fills the row).
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: AtomText.smallButton.copyWith(
              color: on ? AtomColors.primary : AtomColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// The notifications header (16.1, 16.7): ‹, the title, Mark all read and
/// the settings button.
class _NoticesHeader extends StatelessWidget {
  const _NoticesHeader({this.onReadAll, this.title});

  final VoidCallback? onReadAll;

  /// "Recommendations" when only Atomshop's messages are shown.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomPageHeader(
      title: title ?? l.noticesTitle,
      leading: AtomIconButton(
        icon: LucideIcons.chevronLeft,
        label: l.commonBack,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        // From 150% text the words don't fit beside the title: the ✓✓ icon.
        if (onReadAll != null &&
            MediaQuery.textScalerOf(context).scale(10) >= 15)
          AtomIconButton(
            icon: LucideIcons.checkCheck,
            label: l.noticesReadAll,
            onTap: onReadAll!,
          )
        else if (onReadAll != null)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AtomButton.small(
              label: l.noticesReadAll,
              onPressed: onReadAll,
            ),
          ),
        AtomIconButton(
          icon: LucideIcons.slidersHorizontal,
          glyph: const _KnobsGlyph(),
          label: l.noticeSettingsTitle,
          onTap: () => context.push(V2Routes.notificationSettings),
        ),
      ],
    );
  }
}

/// Notifications (16.1, 16.2, 16.7): newest first by day, filters for the
/// kinds that are there, a message from Atomshop pinned on top.
///
/// [recommendations]: only Atomshop's messages (what buyers in the seller's
/// areas search for, what is in demand), as "Recommendations".
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.recommendations = false});

  final bool recommendations;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NoticeKind? _kind;

  /// The Unread chip: only notifications not read yet.
  bool _unread = false;

  /// The server's page: the first comes with [noticesProvider], "Show
  /// older" brings the next. Without it, nothing past the newest 20 could
  /// ever be seen (audit, 9 Nov).
  static const _perPage = 20;
  final _older = <Notice>[];
  int _nextPage = 2;
  bool? _more;
  bool _loadingOlder = false;
  bool _readingAll = false;

  /// Bumped each time the older pages are let go. A "Show older" still on
  /// its way when the list was refreshed belonged to the old list: landed
  /// on the new one, it added a page out of turn and skipped the next.
  int _olderRound = 0;

  void _forgetOlder() {
    _olderRound++;
    _older.clear();
    _nextPage = 2;
    _more = null;
    _loadingOlder = false;
  }

  Future<void> _showOlder() async {
    if (_loadingOlder) return;
    final round = _olderRound;
    setState(() => _loadingOlder = true);
    final r = await ref.read(notificationsRepositoryProvider).page(_nextPage);
    if (!mounted || round != _olderRound) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _loadingOlder = false;
      if (r case ApiOk(value: (final list, final more))) {
        _older.addAll(list);
        _nextPage++;
        _more = more;
      }
    });
    if (r case ApiErr(:final failure)) {
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayFailure(l, failure),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Home's bell keeps the list alive, so without this it stayed as it
    // was at the first load: new alerts (and "all caught up") were stale.
    Future.microtask(() {
      if (!mounted) return;
      _forgetOlder();
      ref.invalidate(noticesProvider);
    });
  }

  Future<void> _open(Notice n) async {
    _markRead(n);
    openNotice(context, n);
  }

  void _markRead(Notice n) =>
      unawaited(ref.read(noticesReadHereProvider.notifier).markRead(n));

  Future<void> _readAll() async {
    if (_readingAll) return;
    final l = AppLocalizations.of(context);
    setState(() => _readingAll = true);
    final r = await ref.read(notificationsRepositoryProvider).markAllRead();
    if (!mounted) return;
    setState(() => _readingAll = false);
    if (r case ApiErr(:final failure)) {
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayFailure(l, failure),
      );
      return;
    }
    _forgetOlder();
    ref.invalidate(noticesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(noticesProvider);
    final readHere = ref.watch(noticesReadHereProvider);
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final agent = who != null && !who.isOwner;
    final inventory = ref.watch(accessProvider).has(Addon.inventory);
    final empty = data.value?.$1.isEmpty ?? false;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NoticesHeader(
            title: widget.recommendations ? l.recoTitle : null,
            onReadAll:
                data.hasValue &&
                    !empty &&
                    !widget.recommendations &&
                    !_readingAll
                ? _readAll
                : null,
          ),
          Expanded(
            child: data.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 16),
                child: AtomLoadingRows(),
              ),
              error: (e, _) => AtomErrorState(
                message: e is ApiFailure ? sayFailure(l, e) : null,
                error: e,
                onRetry: () => ref.invalidate(noticesProvider),
              ),
              data: (d) {
                final firstIds = {for (final n in d.$1) n.id};
                final all = [
                  for (final n in [
                    ...d.$1,
                    // A notice that moved onto page one since is shown once.
                    ..._older.where((n) => !firstIds.contains(n.id)),
                  ])
                    if (!widget.recommendations || n.fromAtomshop)
                      readHere.contains(n.id) ? n.markedRead() : n,
                ];
                final more = _more ?? d.$1.length >= _perPage;
                if (all.isEmpty) {
                  return widget.recommendations
                      ? AtomMessageState(
                          icon: LucideIcons.lightbulb,
                          title: l.recoEmptyTitle,
                          body: l.recoEmptyBody,
                        )
                      : const NoticesEmpty();
                }
                final kinds = <NoticeKind>[
                  if (who == null || who.can(BrandPermission.ordersView))
                    NoticeKind.orders,
                  if (who == null || who.can(BrandPermission.atompayView))
                    NoticeKind.atompay,
                  if (who == null || who.can(BrandPermission.bulkView))
                    NoticeKind.bulk,
                  if (inventory &&
                      (who == null || who.can(BrandPermission.stockView)))
                    NoticeKind.stock,
                  if (who == null || who.can(BrandPermission.catalogueView))
                    NoticeKind.products,
                ];
                final shown = all
                    .where((n) => _kind == null || n.kind == _kind)
                    .where((n) => !_unread || !n.read)
                    .toList();
                final pinned =
                    !widget.recommendations &&
                        (_kind == null || _kind == NoticeKind.account)
                    ? all.where((n) => n.fromAtomshop && !n.read).firstOrNull
                    : null;
                final today = AtomDates.now();
                String dayOf(Notice n) {
                  if (n.at == null) return l.noticesEarlier;
                  final days = AtomDates.daysFrom(n.at!, today: today);
                  return days == 0
                      ? l.noticesToday
                      : days == -1
                      ? l.noticesYesterday
                      : l.noticesEarlier;
                }

                final groups = <String, List<Notice>>{};
                for (final n in shown) {
                  if (n == pinned) continue;
                  groups.putIfAbsent(dayOf(n), () => []).add(n);
                }
                return RefreshIndicator(
                  onRefresh: () {
                    setState(_forgetOlder);
                    return ref.refresh(noticesProvider.future);
                  },
                  // Slivers, so a long history builds only the rows on
                  // screen.
                  child: AtomSliverPage(
                    padding: const EdgeInsets.only(bottom: 24),
                    slivers: [
                      SliverList.list(
                        children: [
                          if (!widget.recommendations)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _KindChip(
                                    label: l.noticesAll,
                                    on: _kind == null && !_unread,
                                    onTap: () => setState(() {
                                      _kind = null;
                                      _unread = false;
                                    }),
                                  ),
                                  _KindChip(
                                    label: l.dpDcUnread,
                                    on: _unread,
                                    onTap: () => setState(() {
                                      _unread = !_unread;
                                    }),
                                  ),
                                  for (final k in kinds)
                                    _KindChip(
                                      label: _kindName(l, k, agent: agent),
                                      on: _kind == k,
                                      onTap: () => setState(
                                        () => _kind = _kind == k ? null : k,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (pinned != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: _PinnedMessage(
                                notice: pinned,
                                onTap: () => _open(pinned),
                              ),
                            ),
                        ],
                      ),
                      for (final MapEntry(key: day, value: list)
                          in groups.entries) ...[
                        SliverToBoxAdapter(child: AtomSectionLabel(day)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverAtomListCard(
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final n = list[i];
                              final act = _action(
                                context,
                                l,
                                n,
                                who: who,
                                inventory: inventory,
                              );
                              return NoticeRow(
                                notice: n,
                                actionLabel: act?.label,
                                onAction: act == null
                                    ? null
                                    : () {
                                        _markRead(n);
                                        act.onTap();
                                      },
                                onTap: () => _open(n),
                              );
                            },
                          ),
                        ),
                      ],
                      if (more)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: AtomButton(
                              label: l.noticesShowOlder,
                              kind: AtomButtonKind.outline,
                              saving: _loadingOlder,
                              onPressed: _showOlder,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The newest unread message from Atomshop, on navy above the list.
class _PinnedMessage extends StatelessWidget {
  const _PinnedMessage({required this.notice, required this.onTap});

  final Notice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = notice.title.isEmpty ? notice.body : notice.title;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: '${l.noticesFromAtomshopNew}. $text',
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AtomColors.nav,
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: AtomColors.navLine),
        ),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LogoTile(size: 38, logo: 30, radius: AtomRadius.control),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.noticesFromAtomshopNew,
                      style: AtomText.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      text,
                      style: AtomText.secondary.copyWith(
                        color: AtomColors.navText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Atomshop mark on a white tile (`.pin .av`, `.from .av`).
class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.size,
    required this.logo,
    required this.radius,
  });

  final double size;
  final double logo;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Image.asset(
      'assets/brand/eco_atomshop.png',
      width: logo,
      height: logo,
    ),
  );
}

/// One notification (`.nt`): its icon, title, text and time, a button when
/// it has one, and a blue dot while unread.
class NoticeRow extends StatelessWidget {
  const NoticeRow({
    super.key,
    required this.notice,
    required this.onTap,
    this.actionLabel,
    this.onAction,
  });

  final Notice notice;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = notice;
    final (icon, tone) = noticeLook(n.type, n.data);
    final title = n.title.isEmpty ? n.body : n.title;
    final body = n.title.isEmpty ? '' : n.body;
    // Under Earlier a time alone can't say which day: "3 Nov, 9:02 AM"
    final at = n.at;
    final time = at == null
        ? null
        : AtomDates.daysFrom(at, today: AtomDates.now()) < -1
        ? '${AtomDates.short(at)}, ${AtomDates.time(at)}'
        : AtomDates.time(at);
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [
        title,
        if (body.isNotEmpty) body,
        ?time,
        if (!n.read) l.dpDcUnread,
      ].join(', '),
      builder: (context, pressed) => Container(
        color: pressed
            ? AtomColors.head
            : n.read
            ? AtomColors.paper
            : AtomColors.unreadRow,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: AtomIconTile(icon: icon, tone: tone, size: 38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AtomText.body.copyWith(
                            color: AtomColors.ink,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        if (body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              body,
                              style: AtomText.secondary.copyWith(height: 1.4),
                            ),
                          ),
                        if (time != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              time,
                              style: AtomText.small.copyWith(
                                color: AtomColors.faint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      // Its own width, not the row's.
                      child: IntrinsicWidth(
                        child: AtomButton.small(
                          label: actionLabel!,
                          kind: AtomButtonKind.primary,
                          onPressed: onAction,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!n.read) ...[
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AtomColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// All caught up (16.7).
class NoticesEmpty extends ConsumerWidget {
  const NoticesEmpty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final who = ref.watch(sessionProvider.notifier).current?.who;
    final orders = who == null || who.can(BrandPermission.ordersView);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 120,
                height: 126,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AtomColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: AtomColors.line),
                      ),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AtomColors.greenSoft,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 30,
                          color: AtomColors.green,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      child: AtomStepsStripe(width: 64),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                l.noticesEmptyTitle,
                textAlign: TextAlign.center,
                style: AtomText.heading,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.noticesEmptyBody,
              textAlign: TextAlign.center,
              style: AtomText.body.copyWith(
                color: AtomColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicWidth(
              child: AtomButton(
                label: orders ? l.noticesEmptyAction : l.notifEmptyHome,
                expand: false,
                onPressed: () =>
                    context.go(orders ? V2Routes.orders : V2Routes.home),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A message from Atomshop (16.3), as it was sent: the title, its
/// paragraphs, then Ask Atom about it or reply to Atomshop.
class NoticeMessageScreen extends ConsumerWidget {
  const NoticeMessageScreen({super.key, required this.notice});
  final Notice? notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = notice;
    if (n == null) {
      return Scaffold(
        body: Column(
          children: [
            const AtomFlowBar(),
            Expanded(
              child: AtomMessageState(
                icon: LucideIcons.bell,
                title: l.noticeOpenFromList,
              ),
            ),
          ],
        ),
      );
    }
    final askAtom = ref.watch(accessProvider).has(Addon.askAtom);
    final title = n.title.isEmpty ? n.body : n.title;
    final paragraphs = n.title.isEmpty
        ? const <String>[]
        : [
            for (final p in n.body.split(RegExp(r'\n\s*\n')))
              if (p.trim().isNotEmpty) p.trim(),
          ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget half(String label, VoidCallback onTap) => Expanded(
      child: _BarButton(label: label, onTap: onTap),
    );
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.light,
                  child: Container(
                    color: AtomColors.nav,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.paddingOf(context).top,
                      16,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 52,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Transform.translate(
                              offset: const Offset(-8, 0),
                              child: AtomIconButton(
                                icon: LucideIcons.chevronLeft,
                                label: l.commonBack,
                                color: Colors.white,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const _LogoTile(size: 44, logo: 34, radius: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.fromAtomshop
                                        ? l.dpDcAtomshop
                                        : l.noticesTitle,
                                    style: AtomText.listTitle.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (n.at != null)
                                    Text(
                                      '${AtomDates.short(n.at!)}, '
                                      '${AtomDates.time(n.at!)}',
                                      style: AtomText.secondary.copyWith(
                                        color: AtomColors.navMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _FullStripe(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: AtomText.pageTitle),
                      ),
                      for (final p in paragraphs) ...[
                        const SizedBox(height: 14),
                        Text(
                          p,
                          style: AtomText.body.copyWith(
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AtomColors.paper,
              border: Border(top: BorderSide(color: AtomColors.line)),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 26 + bottom),
            child: Row(
              children: [
                if (askAtom) ...[
                  half(
                    l.dpDcAskAtomAbout,
                    () => context.push(V2Routes.askAtom),
                  ),
                  const SizedBox(width: 8),
                ],
                half(
                  l.dpDcReplyAtomshop,
                  () => launchUrl(
                    whatsAppUri(
                      AtomshopContacts.whatsapp,
                      text: l.dpDcReplyText(title),
                    ),
                    mode: LaunchMode.externalApplication,
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

/// A 44-tall outline button for a bottom bar's pair (16.3).
class _BarButton extends StatelessWidget {
  const _BarButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = AtomText.listTitle.copyWith(color: AtomColors.ink);
    // One line as on the board; on a 360dp phone "Ask Atom about this"
    // shrinks a little rather than breaking. Large text still wraps.
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (_, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: large ? 8 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed ? AtomColors.head : AtomColors.paper,
          borderRadius: AtomRadius.brControl,
          border: Border.all(color: AtomColors.line2),
        ),
        child: large
            ? Text(label, textAlign: TextAlign.center, style: style)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, softWrap: false, style: style),
              ),
      ),
    );
  }
}

/// The logo colours across the full width (`.steps`).
class _FullStripe extends StatelessWidget {
  const _FullStripe();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => AtomStepsStripe(width: c.maxWidth),
  );
}

/// Notification settings (16.4): the switches the server offers this
/// person (by add-on and role), grouped; what is always on; how they
/// arrive.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  /// What the server answered to the last change.
  NoticeSettings? _now;

  /// A switch flipped and waiting for the server: shown in its new place.
  final _pending = <String, bool>{};

  /// Saves still to answer, per switch: its pending place is kept until
  /// the last one has.
  final _inFlight = <String, int>{};

  /// Saves go one at a time, in the order they were made. Sent together,
  /// a quick on-then-off reached the server in either order and whichever
  /// answer came back last was shown, so the switch could show the
  /// opposite of what the server kept.
  Future<void> _queue = Future.value();

  Future<void> _save({
    Map<String, bool>? switches,
    (String, String)? quiet,
    bool clearQuiet = false,
  }) {
    if (switches != null) {
      setState(() => _pending.addAll(switches));
      for (final k in switches.keys) {
        _inFlight[k] = (_inFlight[k] ?? 0) + 1;
      }
    }
    return _queue = _queue.then(
      (_) => _send(switches: switches, quiet: quiet, clearQuiet: clearQuiet),
    );
  }

  Future<void> _send({
    Map<String, bool>? switches,
    (String, String)? quiet,
    bool clearQuiet = false,
  }) async {
    final repo = ref.read(notificationsRepositoryProvider);
    final r =
        switches != null && switches.length == 1 && quiet == null && !clearQuiet
        ? await repo.toggle(switches.keys.first, switches.values.first)
        : await repo.saveSettings(
            switches: switches,
            quiet: quiet,
            clearQuiet: clearQuiet,
          );
    if (!mounted) return;
    setState(() {
      for (final k in switches?.keys ?? const <String>[]) {
        final left = (_inFlight[k] ?? 1) - 1;
        if (left > 0) {
          _inFlight[k] = left;
        } else {
          _inFlight.remove(k);
          _pending.remove(k);
        }
      }
      if (r case ApiOk(:final value)) _now = value;
    });
    if (r case ApiErr(:final failure)) {
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: sayFailure(AppLocalizations.of(context), failure),
      );
    }
  }

  Future<void> _quiet(NoticeSettings s) async {
    final l = AppLocalizations.of(context);
    if (s.quietFrom != null) {
      final off = await showAtomSheet<bool>(
        context,
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The header has its own 16 at the side; the rest lines up
            // under its title.
            AtomSheetHeader(title: l.quietTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.dpDcQuietSub,
                    style: AtomText.body.copyWith(color: AtomColors.muted),
                  ),
                  const SizedBox(height: 16),
                  AtomButton(
                    label: l.dpDcQuietChange,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(height: 10),
                  AtomButton(
                    label: l.dpDcQuietOff,
                    kind: AtomButtonKind.outline,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      if (off == null || !mounted) return;
      if (off) return _save(clearQuiet: true);
    }
    TimeOfDay parse(String? v, TimeOfDay or) {
      final p = v?.split(':');
      if (p == null || p.length < 2) return or;
      return TimeOfDay(
        hour: int.tryParse(p[0]) ?? or.hour,
        minute: int.tryParse(p[1]) ?? 0,
      );
    }

    final from = await showTimePicker(
      context: context,
      helpText: l.quietFrom,
      initialTime: parse(s.quietFrom, const TimeOfDay(hour: 22, minute: 0)),
    );
    if (from == null || !mounted) return;
    final to = await showTimePicker(
      context: context,
      helpText: l.quietTo,
      initialTime: parse(s.quietTo, const TimeOfDay(hour: 8, minute: 0)),
    );
    if (to == null || !mounted) return;
    String hm(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (hm(from) == hm(to)) return;
    await _save(quiet: (hm(from), hm(to)));
  }

  /// "22:00" → "10 pm", "08:30" → "8:30 am" (the board's way).
  static String _clock(String hm) {
    final p = hm.split(':');
    final h = int.tryParse(p.first) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final half = h < 12 ? 'am' : 'pm';
    return m == 0 ? '$h12 $half' : '$h12:${m.toString().padLeft(2, '0')} $half';
  }

  Future<void> _phoneSettings() async {
    try {
      await const MethodChannel('atombrand/settings')
          .invokeMethod<void>('openNotificationSettings');
    } on Object {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loaded = ref.watch(noticeSettingsProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.noticesTitle,
            leading: SettingsPane.of(context)
                ? null
                : AtomIconButton(
                    icon: LucideIcons.chevronLeft,
                    label: l.commonBack,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
          ),
          Expanded(
            child: loaded.when(
              loading: () => const AtomLoadingRows(),
              error: (e, _) => AtomErrorState(
                message: e is ApiFailure ? sayFailure(l, e) : null,
                error: e,
                onRetry: () => ref.invalidate(noticeSettingsProvider),
              ),
              data: (first) {
                final s = _now ?? first;
                final groups = <String, List<NoticeSwitch>>{};
                for (final w in s.switches) {
                  groups.putIfAbsent(w.group, () => []).add(w);
                }
                final owner =
                    ref.watch(sessionProvider.notifier).current?.who.isOwner ??
                    false;
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (!s.pushOn)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: AtomNote(
                          kind: AtomNoteKind.info,
                          title: l.notifLiveOffTitle,
                          message: owner
                              ? l.notifLiveOffOwner
                              : l.notifLiveOffAgent,
                        ),
                      ),
                    for (final MapEntry(key: group, value: list)
                        in groups.entries) ...[
                      AtomSectionLabel(group),
                      _Box(
                        children: [
                          for (final w in list)
                            _SettingRow(
                              title: w.label,
                              sub: w.description,
                              trailing: AtomSwitch(
                                value: _pending[w.type] ?? w.on,
                                semanticLabel: w.label,
                                onChanged: (v) => _save(switches: {w.type: v}),
                              ),
                              onTap: () => _save(
                                switches: {w.type: !(_pending[w.type] ?? w.on)},
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (s.alwaysOnItems.isNotEmpty) ...[
                      AtomSectionLabel(l.noticesFromAtomshop),
                      _Box(
                        children: [
                          for (final a in s.alwaysOnItems)
                            _SettingRow(
                              title: a.label,
                              sub: a.description,
                              trailing: Text(
                                l.noticeAlwaysOn,
                                style: AtomText.small.copyWith(
                                  color: AtomColors.faint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    AtomSectionLabel(l.noticeHow),
                    _Box(
                      children: [
                        _SettingRow(
                          title: l.quietTitle,
                          sub: l.dpDcQuietSub,
                          trailing: _Value(
                            s.quietFrom == null
                                ? l.dpDcOff
                                : '${_clock(s.quietFrom!)} – '
                                      '${_clock(s.quietTo ?? '')}',
                          ),
                          onTap: () => _quiet(s),
                        ),
                        if (owner)
                          _SettingRow(
                            title: l.notifMorningTitle,
                            sub: l.notifMorningSub,
                            trailing: _Value(switch (ref.watch(
                              morningSummaryOnProvider,
                            )) {
                              AsyncData(value: false) => l.dpDcOff,
                              _ => l.notifMorningAt,
                            }),
                            onTap: () => context.push(V2Routes.dailySummary),
                          ),
                        _SettingRow(
                          title: l.dpDcSound,
                          sub: l.dpDcPhoneSettings,
                          trailing: _Value(l.dpDcOpen),
                          onTap: _phoneSettings,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Text(
                        l.noticeSettingsFoot,
                        style: AtomText.small.copyWith(color: AtomColors.faint),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// `.box`: a white card 16 in from the sides.
class _Box extends StatelessWidget {
  const _Box({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: AtomListCard(children: children),
  );
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AtomText.body.copyWith(
      color: AtomColors.muted,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// `.st`: a title and a second line, with a switch, a value or "Always on"
/// at the end.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.trailing,
    this.sub,
    this.onTap,
  });

  final String title;
  final String? sub;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [
        title,
        if (sub != null && sub!.isNotEmpty) sub!,
      ].join(', '),
      builder: (_, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AtomText.listTitle.copyWith(height: 1.3),
                    ),
                    if (sub != null && sub!.isNotEmpty)
                      Text(sub!, style: AtomText.secondary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // A switch drawn in its own size: its 48 tap area made the row
            // taller than the board's `.st` (the row takes the tap).
            if (trailing is AtomSwitch)
              SizedBox(
                width: AtomSize.switchWidth,
                height: AtomSize.switchHeight,
                child: OverflowBox(
                  maxWidth: AtomSize.tapTarget,
                  maxHeight: AtomSize.tapTarget,
                  child: trailing,
                ),
              )
            else
              trailing,
          ],
        ),
      ),
    );
  }
}

/// What a push is about, for the banner inside the app (16.6): its icon,
/// tile and button.
({IconData icon, AtomTone tone, String cta}) bannerLook(
  AppLocalizations l,
  Map<String, dynamic> data,
) {
  final type = Json.str(data['type']) ?? '';
  if (type == 'brand_admin_message' ||
      type == 'admin_message' ||
      Json.str(data['from']) == 'atomshop') {
    return (
      icon: LucideIcons.messageCircle,
      tone: AtomTone.blue,
      cta: l.dpDcRead,
    );
  }
  final (icon, tone) = noticeLook(type, data);
  final cta = switch (type) {
    'brand_new_order' || 'brand_orders_waiting' => l.notifActConfirm,
    'brand_new_bulk_request' => l.notifActReply,
    'brand_atompay_assigned' => l.notifActHandOver,
    'brand_quote_expiring' => l.notifActFollowUp,
    _ => l.bannerOpen,
  };
  return (icon: icon, tone: tone, cta: cta);
}

/// A push that arrives while the app is open (16.6): it drops from the top
/// for a few seconds, then waits in Notifications. Swipe up to hide.
class InAppBanner extends StatefulWidget {
  const InAppBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onOpen,
    required this.onClose,
    this.data = const {},
  });

  final String title;
  final String body;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  /// The push's data, for its icon and button.
  final Map<String, dynamic> data;

  @override
  State<InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<InAppBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 6), widget.onClose);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final look = bannerLook(l, widget.data);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Dismissible(
          key: const ValueKey('banner'),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onClose(),
          child: Semantics(
            liveRegion: true,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: AtomColors.paper,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: AtomColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x38101828),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AtomIconTile(icon: look.icon, tone: look.tone, size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AtomText.body.copyWith(
                              color: AtomColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.body.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.body,
                                style: AtomText.secondary,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              IntrinsicWidth(
                                child: AtomButton.small(
                                  label: look.cta,
                                  kind: AtomButtonKind.primary,
                                  onPressed: widget.onOpen,
                                ),
                              ),
                              IntrinsicWidth(
                                child: AtomButton.small(
                                  label: l.bannerLater,
                                  onPressed: widget.onClose,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: AtomIconButton(
                        icon: LucideIcons.x,
                        label: l.commonClose,
                        onTap: widget.onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The boards' notification-settings glyph: three lines with round knobs
/// (`M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0` and three r2 circles),
/// which Lucide's sliders don't draw.
class _KnobsGlyph extends StatelessWidget {
  const _KnobsGlyph();

  @override
  Widget build(BuildContext context) => const CustomPaint(
    size: Size.square(AtomIcon.bar),
    painter: _Knobs(AtomColors.ink),
  );
}

class _Knobs extends CustomPainter {
  const _Knobs(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    void line(double x1, double y, double x2) =>
        canvas.drawLine(Offset(x1 * s, y * s), Offset(x2 * s, y * s), paint);
    line(4, 6, 14);
    line(18, 6, 20);
    line(4, 12, 8);
    line(12, 12, 20);
    line(4, 18, 16);
    line(20, 18, 20);
    for (final (x, y) in const [(16.0, 6.0), (10.0, 12.0), (18.0, 18.0)]) {
      canvas.drawCircle(Offset(x * s, y * s), 2 * s, paint);
    }
  }

  @override
  bool shouldRepaint(_Knobs old) => old.color != color;
}
