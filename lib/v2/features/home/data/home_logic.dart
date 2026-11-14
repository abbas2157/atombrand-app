import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../design/design.dart';
import 'home_models.dart';

/// Home's rules, kept apart from the widgets so they can be tested:
/// where a task leads, which banner shows, the first-day steps, the
/// offline counts read from the phone's copy, and the status colours.

// ───────────────────────────────────────────── tasks

/// Where a route goes: [tab] switches tabs (`context.go`), else it opens
/// over the tabs (`context.push`).
typedef HomeRoute = ({String path, bool tab});

/// The screen a task opens, from its `key` and `target`
/// (docs/BRAND_APP.md "GET tasks"). Null for a key this app doesn't know:
/// the task shows without a button.
HomeRoute? taskRoute(HomeTask t, {bool stockOn = true}) {
  final requestId = Json.integer(t.target['bulk_request_id']);
  final fromSellers = Json.str(t.target['from']) == 'sellers';
  return switch (t.key) {
    'confirm' => (path: V2Routes.ordersWith(status: 'Pending'), tab: true),
    'hand_over' => (path: V2Routes.atompayOrders, tab: true),
    'record' => (path: V2Routes.ordersWith(status: 'Delivered'), tab: true),
    'sourcing' || 'sourcing_change' when requestId != null => (
      path: V2Routes.sellerRequestOf(requestId),
      tab: false,
    ),
    'sourcing' ||
    'sourcing_change' => (path: V2Routes.bulkTab('sellers'), tab: true),
    'bulk' when requestId != null => (
      path: V2Routes.bulkRequestOf(requestId),
      tab: false,
    ),
    'bulk' => (
      path: V2Routes.bulkTab(fromSellers ? 'sellers' : 'website'),
      tab: true,
    ),
    'quotes' => (path: V2Routes.bulk, tab: true),
    'on_hold' => (path: V2Routes.productsWith(status: 'On hold'), tab: true),
    'stock' when stockOn => (path: V2Routes.stockList(show: 'out'), tab: false),
    _ => null,
  };
}

/// The task's tile colour, from the server's `t-rose` / `t-amber` / …
AtomTone taskTone(String? tone) => switch (tone) {
  't-rose' => AtomTone.rose,
  't-amber' => AtomTone.amber,
  't-green' => AtomTone.green,
  _ => AtomTone.blue,
};

// ───────────────────────────────────────────── greeting and figures

/// "Good morning" by the time of day.
String greetingFor(DateTime now, AppLocalizations l) => now.hour < 12
    ? l.homeGoodMorning
    : now.hour < 17
    ? l.homeGoodAfternoon
    : l.homeGoodEvening;

/// The period switch's names.
String periodName(String period, AppLocalizations l) => switch (period) {
  'today' => l.homeToday,
  'year' => l.homePeriodYear,
  'all' => l.homePeriodAll,
  _ => l.homePeriodMonth,
};

/// The chosen bar's tag: `4.6m`, `820k`, `950`.
String compactAmount(int amount) {
  final a = amount.abs();
  if (a >= 1000000) {
    final m = (a / 100000).round() / 10;
    return '${m == m.roundToDouble() ? m.toInt() : m}m';
  }
  if (a >= 1000) return '${(a / 1000).round()}k';
  return '$a';
}

/// Bar heights for the chart, 0 to 1, against the tallest bar of either
/// series (so the two can be compared).
List<(double, double)> chartHeights(List<ChartMonth> months) {
  final top = months.fold<int>(
    0,
    (m, x) => [m, x.sales, x.paid].reduce((a, b) => a > b ? a : b),
  );
  if (top <= 0) return [for (final _ in months) (0.0, 0.0)];
  return [for (final m in months) (m.sales / top, m.paid / top)];
}

// ───────────────────────────────────────────── status colours

/// An order's pill colour by the server's status.
AtomTone orderTone(String status) => switch (status) {
  'Pending' => AtomTone.grey,
  'Varification' || 'Confirming' => AtomTone.amber,
  'Processing' || 'Delivered' => AtomTone.blue,
  'Completed' || 'Paid' => AtomTone.green,
  'Cancelled' => AtomTone.rose,
  _ => AtomTone.grey,
};

/// A product's pill colour by the server's status.
AtomTone productTone(String status) => switch (status) {
  'Published' => AtomTone.green,
  'Out of Stock' => AtomTone.rose,
  'Pending' || 'On hold' => AtomTone.amber,
  _ => AtomTone.grey,
};

/// A product's status as the app says it.
String productLabel(String status, String label, AppLocalizations l) =>
    switch (status) {
      'Published' => l.catStatusLive,
      'Out of Stock' => l.catStatusOutOfStock,
      'Pending' => l.catStatusInReview,
      _ => label.isEmpty ? status : label,
    };

/// A bulk request's pill: its name and colour.
(String, AtomTone) requestPill(String status, AppLocalizations l) =>
    switch (status) {
      'New Lead' || '' => (l.homeBulkNew, AtomTone.blue),
      'Contacted' => (l.homeBulkContacted, AtomTone.grey),
      'Quoted' => (l.homeBulkQuoted, AtomTone.amber),
      'Won' => (l.homeBulkWon, AtomTone.green),
      'Lost' => (l.homeBulkLost, AtomTone.rose),
      _ => (status, AtomTone.grey),
    };

// ───────────────────────────────────────────── banners (13.8)

enum HomeBannerKind { restricted, readOnly, late, message, trial, billDue }

/// One banner above the tasks. Only the most urgent shows.
@immutable
class HomeBanner {
  const HomeBanner({
    required this.kind,
    required this.key,
    required this.title,
    required this.body,
    this.dismissable = false,
    this.amount,
    this.bill,
    this.addon,
    this.message,
  });

  final HomeBannerKind kind;

  /// Names this banner for Hide (a hidden one stays hidden this session).
  final String key;
  final String title;
  final String body;
  final bool dismissable;

  /// Rupees to pay (read-only, late, bill due).
  final int? amount;

  /// The bill to pay.
  final String? bill;

  /// The add-on whose trial ends.
  final Addon? addon;

  /// Atomshop's message.
  final HomeActivity? message;
}

/// How many days before a trial ends its banner shows.
const trialWarnDays = 7;

/// The banner to show now, or null. The most urgent first: restricted,
/// read-only, a late bill, a message from Atomshop, a trial ending, a
/// bill due. Team members see none of the billing ones.
HomeBanner? pickBanner({
  required bool owner,
  required AccessState access,
  BillingGlance? billing,
  List<HomeActivity> activity = const [],
  Set<String> hidden = const {},
  required DateTime today,
  required AppLocalizations l,
}) {
  final bill = billing?.openBills.isEmpty ?? true
      ? null
      : billing!.openBills.first;
  final amount = access.due ?? bill?.due;
  final days = access.daysLate;
  final candidates = <HomeBanner>[
    if (access.account == AccountStatus.restricted)
      HomeBanner(
        kind: HomeBannerKind.restricted,
        key: 'restricted',
        title: l.homeBannerRestrictedTitle,
        body: access.message ?? l.homeBannerRestrictedBody,
      ),
    if (owner && access.account == AccountStatus.readOnly)
      HomeBanner(
        kind: HomeBannerKind.readOnly,
        key: 'read-only',
        title: l.homeBannerReadOnlyTitle,
        body: days != null && days > 0
            ? l.homeBannerReadOnlyLate(days)
            : l.homeBannerReadOnlyBody,
        amount: amount,
        bill: bill?.number,
      ),
    if (owner &&
        (access.account == AccountStatus.late ||
            access.account == AccountStatus.overdue))
      HomeBanner(
        kind: HomeBannerKind.late,
        key: 'late',
        title: days != null && days > 0
            ? l.homeBannerLateDays(days)
            : l.homeBannerLate,
        body: access.message ?? l.homeBannerLateBody,
        amount: amount,
        bill: bill?.number,
      ),
    if (_atomshopMessage(activity) case final m?)
      HomeBanner(
        kind: HomeBannerKind.message,
        key: 'msg:${m.notice.id}',
        title: l.homeBannerMessage,
        body: m.notice.body.isNotEmpty ? m.notice.body : m.notice.title,
        dismissable: true,
        message: m,
      ),
    if (owner) ?_trialBanner(billing, today, l),
    if (owner &&
        (access.account == AccountStatus.due ||
            (bill != null &&
                !bill.overdue &&
                access.account == AccountStatus.ok)))
      HomeBanner(
        kind: HomeBannerKind.billDue,
        key: 'bill:${bill?.number ?? 'due'}',
        title: bill?.coversFrom == null
            ? l.homeBannerBillReady
            : l.homeBannerMonthBill(
                DateFormat('MMMM').format(bill!.coversFrom!),
              ),
        body: [
          ?bill?.number,
          if (amount != null && amount > 0) formatRs(amount),
          if (bill?.dueOn != null)
            l.homeBannerDue(AtomDates.short(bill!.dueOn!)),
        ].join(' · '),
        amount: amount,
        bill: bill?.number,
      ),
  ];
  for (final b in candidates) {
    if (!hidden.contains(b.key)) return b;
  }
  return null;
}

/// The newest unread message written by Atomshop.
HomeActivity? _atomshopMessage(List<HomeActivity> activity) {
  for (final a in activity) {
    if (a.notice.fromAtomshop && !a.notice.read) return a;
  }
  return null;
}

/// The add-on trial ending soonest, within [trialWarnDays].
HomeBanner? _trialBanner(
  BillingGlance? billing,
  DateTime today,
  AppLocalizations l,
) {
  AddonEnd? soonest;
  for (final a in billing?.addons ?? const <AddonEnd>[]) {
    final end = a.endsOn;
    if (a.state != 'trial' || end == null) continue;
    final left = AtomDates.daysFrom(end, today: today);
    if (left < 0 || left > trialWarnDays) continue;
    if (soonest == null || end.isBefore(soonest.endsOn!)) soonest = a;
  }
  final a = soonest;
  if (a == null) return null;
  final left = AtomDates.daysFrom(a.endsOn!, today: today);
  final day = AtomDates.short(a.endsOn!);
  return HomeBanner(
    kind: HomeBannerKind.trial,
    key: 'trial:${a.key}:${AtomDates.api(a.endsOn!)}',
    title: switch (left) {
      0 => l.homeTrialEndsToday(a.name),
      1 => l.homeTrialEndsTomorrow(a.name),
      _ => l.homeTrialEndsIn(a.name, left),
    },
    body: a.renew ? l.homeTrialRenew(day) : l.homeTrialOff(day),
    dismissable: true,
    addon: Addon.fromKey(a.key),
  );
}

// ───────────────────────────────────────────── first day (5.4)

/// A brand with nothing live and no orders yet sees its first steps
/// instead of the full Home. Only the owner sets the brand up.
bool isFirstDay({required bool owner, required HomeDashboard home}) =>
    owner && home.ordersTotal == 0 && home.cataloguePublished == 0;

/// The products a brand adds before the step counts as done.
const firstProducts = 3;

@immutable
class FirstStep {
  const FirstStep({
    required this.id,
    required this.title,
    required this.sub,
    required this.done,
    required this.path,
  });

  final String id;
  final String title;
  final String sub;
  final bool done;

  /// Where tapping it goes (pushed).
  final String path;
}

/// The first steps (5.4). The team step shows only with the Roles
/// management add-on.
List<FirstStep> firstSteps({
  required bool hasPin,
  required int products,
  required bool hasLogo,
  required bool paymentsChosen,
  required bool teamOn,
  required int teamMembers,
  required AppLocalizations l,
}) => [
  FirstStep(
    id: 'pin',
    title: l.homeStepPinTitle,
    sub: l.homeStepPinSub,
    done: hasPin,
    path: V2Routes.settingsStep('pin'),
  ),
  FirstStep(
    id: 'products',
    title: l.homeStepProductsTitle,
    sub: l.homeStepProductsSub(firstProducts),
    done: products >= firstProducts,
    path: V2Routes.productNew,
  ),
  FirstStep(
    id: 'page',
    title: l.homeStepPageTitle,
    sub: l.homeStepPageSub,
    done: hasLogo,
    path: V2Routes.brandPage,
  ),
  FirstStep(
    id: 'pay',
    title: l.homeStepPayTitle,
    sub: l.homeStepPaySub,
    done: paymentsChosen,
    path: V2Routes.shopSettings,
  ),
  if (teamOn)
    FirstStep(
      id: 'team',
      title: l.homeStepTeamTitle,
      sub: l.homeStepTeamSub,
      done: teamMembers > 0,
      path: V2Routes.teamAdd,
    ),
];

/// Shop settings (`GET settings`) say the brand chose how it is paid:
/// a bank account or a wallet besides cash on delivery.
bool paymentsChosenFrom(Object? data) {
  final d = Json.map(data);
  final s = Json.map(d['settings']);
  if (Json.flag(s['pay_bank']) || Json.flag(s['pay_wallet'])) return true;
  return Json.list(d['payment_methods']).any((m) => Json.str(m) != 'cod');
}

// ───────────────────────────────────────────── offline (5.3)

/// What Home can count from the phone's copy with no signal.
@immutable
class OfflineHome {
  const OfflineHome({
    this.toConfirm = 0,
    this.toHandOver = 0,
    this.toDeliver = 0,
    this.unpaidOrders = 0,
    this.unpaidAmount = 0,
    this.newRequests = 0,
  });

  final int toConfirm;
  final int toHandOver;
  final int toDeliver;
  final int unpaidOrders;
  final int unpaidAmount;
  final int newRequests;
}

/// Counts from the copy's tables (docs/brand-app-sync.md §4): cash
/// `orders`, `atompay_orders`, `order_payments` and `bulk_requests`.
OfflineHome offlineHomeFrom({
  List<Map<String, dynamic>> orders = const [],
  List<Map<String, dynamic>> atompay = const [],
  List<Map<String, dynamic>> payments = const [],
  List<Map<String, dynamic>> requests = const [],
}) {
  final paid = <int, int>{};
  for (final p in payments) {
    final id = Json.integer(p['order_id']);
    if (id == null) continue;
    paid[id] = (paid[id] ?? 0) + (Json.integer(p['amount']) ?? 0);
  }
  var toConfirm = 0, toDeliver = 0, unpaid = 0, unpaidAmount = 0;
  for (final o in orders) {
    switch (Json.str(o['status'])) {
      case 'Pending':
        toConfirm++;
      case 'Processing':
        toDeliver++;
      case 'Delivered':
        final id = Json.integer(o['id']);
        final left =
            (Json.integer(o['total_deal_price']) ?? 0) - (paid[id] ?? 0);
        if (left > 0) {
          unpaid++;
          unpaidAmount += left;
        }
    }
  }
  return OfflineHome(
    toConfirm: toConfirm,
    toDeliver: toDeliver,
    unpaidOrders: unpaid,
    unpaidAmount: unpaidAmount,
    toHandOver: atompay.where((o) => Json.str(o['step']) == 'handover').length,
    newRequests: requests.where((r) {
      final s = Json.str(r['status']);
      return s == null || s == 'New Lead';
    }).length,
  );
}

/// Search the phone's copy (no signal): the same three sections as
/// `GET search`, up to five each, those the role sees.
SearchResults searchCopy(
  String query, {
  required Who who,
  List<Map<String, dynamic>> orders = const [],
  List<Map<String, dynamic>> atompay = const [],
  List<Map<String, dynamic>> products = const [],
  List<Map<String, dynamic>> requests = const [],
}) {
  final q = query.trim().toLowerCase();
  final digits = q.startsWith('#') ? q.substring(1) : q;
  bool has(Object? v) => (Json.str(v) ?? '').toLowerCase().contains(q);
  bool orderHit(Map<String, dynamic> o) =>
      '${Json.integer(o['id'])}' == digits ||
      (Json.str(o['uuid']) ?? '').toLowerCase().startsWith(q) ||
      has(o['product_title']) ||
      has(o['pr_number']) ||
      has(o['customer_name']) ||
      has(o['customer_phone']);
  Found<T> found<T>(Iterable<T> all) {
    final list = all.take(6).toList();
    return Found(list.take(5).toList(), more: list.length > 5);
  }

  HomeOrder order(Map<String, dynamic> o, {required bool atompay}) {
    final status = Json.str(o['status']) ?? '';
    return HomeOrder(
      uuid: Json.str(o['uuid']) ?? '',
      id: Json.integer(o['id']) ?? 0,
      atompay: atompay,
      status: status,
      statusLabel:
          Json.str(atompay ? o['step_label'] : o['status_label']) ?? status,
      total: Json.integer(o['total_deal_price']) ?? 0,
      productTitle: Json.str(o['product_title']),
      customer: Json.str(o['customer_name']),
      createdAt: AtomDates.parse(o['created_at']),
    );
  }

  return SearchResults(
    query: query.trim(),
    fromCopy: true,
    orders: who.can(BrandPermission.ordersView)
        ? found([
            for (final o in orders)
              if (orderHit(o)) order(o, atompay: false),
            if (who.can(BrandPermission.atompayView))
              for (final o in atompay)
                if (orderHit(o)) order(o, atompay: true),
          ])
        : null,
    products: who.can(BrandPermission.catalogueView)
        ? found([
            for (final p in products)
              if (has(p['title']) || has(p['pr_number']))
                FoundProduct.fromJson(p),
          ])
        : null,
    requests: who.can(BrandPermission.bulkView)
        ? found([
            for (final r in requests)
              if (has(r['full_name']) ||
                  has(r['phone']) ||
                  has(r['product_title']))
                FoundRequest.fromJson(r),
          ])
        : null,
  );
}
