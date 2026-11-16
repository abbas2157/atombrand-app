import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';
import '../../notifications/data/notifications_repository.dart' show Notice;

/// The v2 Home, read from `GET dashboard` (`data.home`, plus the few v1
/// keys the first-day check needs). docs/BRAND_APP.md "GET dashboard".
///
/// A section the person's role can't see comes back `null` from the
/// server and stays null here, so the screen leaves it out.

/// The navy hero's counts. Each is null when the role can't see it.
@immutable
class HomeHero {
  const HomeHero({
    this.ordersToConfirm,
    this.atompayToHandOver,
    this.bulkWaiting,
    this.sellerWaiting,
  });

  final int? ordersToConfirm;
  final int? atompayToHandOver;

  /// Website buyers' new bulk requests.
  final int? bulkWaiting;

  /// Atomshop sellers' requests waiting for a quote.
  final int? sellerWaiting;

  /// Seller and bulk requests together ("Seller & bulk requests to quote").
  int? get requestsWaiting => bulkWaiting == null && sellerWaiting == null
      ? null
      : (bulkWaiting ?? 0) + (sellerWaiting ?? 0);

  /// "9 things need you today": every count the person can see.
  int get total =>
      (ordersToConfirm ?? 0) +
      (atompayToHandOver ?? 0) +
      (requestsWaiting ?? 0);

  factory HomeHero.fromJson(Object? raw) {
    final j = Json.map(raw);
    return HomeHero(
      ordersToConfirm: Json.integer(j['orders_to_confirm']),
      atompayToHandOver: Json.integer(j['atompay_to_hand_over']),
      bulkWaiting: Json.integer(j['bulk_requests_waiting']),
      sellerWaiting: Json.integer(j['seller_requests_waiting']),
    );
  }
}

/// One of today's tasks (`GET tasks`, also `home.tasks`), most urgent
/// first. The server writes the words; the app picks the screen from
/// [key] and [target].
@immutable
class HomeTask {
  const HomeTask({
    required this.key,
    required this.title,
    this.detail,
    this.count = 0,
    this.button,
    this.tone,
    this.deadline,
    this.urgent = false,
    this.target = const {},
  });

  /// `confirm`, `hand_over`, `sourcing_change`, `sourcing`, `quotes`,
  /// `record`, `bulk`, `on_hold` or `stock`.
  final String key;
  final String title;
  final String? detail;
  final int count;
  final String? button;

  /// `t-rose`, `t-amber`, `t-blue` or `t-green`.
  final String? tone;
  final String? deadline;
  final bool urgent;

  /// What to open: `{bulk_request_id}` or `{from: "sellers"}`; empty is
  /// the list for the key.
  final Map<String, dynamic> target;

  factory HomeTask.fromJson(Object? raw) {
    final j = Json.map(raw);
    return HomeTask(
      key: Json.str(j['key']) ?? '',
      title: Json.str(j['title']) ?? '',
      detail: Json.str(j['detail']),
      count: Json.integer(j['count']) ?? 0,
      button: Json.str(j['button']),
      tone: Json.str(j['tone']),
      deadline: Json.str(j['deadline']),
      urgent: Json.flag(j['urgent']),
      target: Json.map(j['target']),
    );
  }

  static List<HomeTask> listFromJson(Object? raw) => [
    for (final t in Json.list(raw)) HomeTask.fromJson(t),
  ];
}

/// "Your sales on Atomshop" for one period.
@immutable
class SalesFigures {
  const SalesFigures({
    required this.period,
    this.label,
    this.cashSales = 0,
    this.orders = 0,
    this.paymentsReceived = 0,
    this.stillDue = 0,
    this.unitsSold = 0,
    this.cancelled = 0,
    this.live = 0,
    this.catalogueTotal = 0,
  });

  /// `today`, `month`, `year` or `all`.
  final String period;

  /// "1 Nov to 14 Nov 2026".
  final String? label;
  final int cashSales;
  final int orders;
  final int paymentsReceived;
  final int stillDue;
  final int unitsSold;
  final int cancelled;
  final int live;
  final int catalogueTotal;

  /// How much of the catalogue is live, 0 to 1.
  double get liveShare =>
      catalogueTotal <= 0 ? 0 : (live / catalogueTotal).clamp(0, 1).toDouble();

  factory SalesFigures.fromJson(Object? raw, {String? period}) {
    final j = Json.map(raw);
    return SalesFigures(
      period: Json.str(j['period']) ?? period ?? 'month',
      label: Json.str(j['label']),
      cashSales: Json.integer(j['cash_sales']) ?? 0,
      orders: Json.integer(j['orders']) ?? 0,
      paymentsReceived: Json.integer(j['payments_received']) ?? 0,
      stillDue: Json.integer(j['still_due']) ?? 0,
      unitsSold: Json.integer(j['units_sold']) ?? 0,
      cancelled: Json.integer(j['cancelled']) ?? 0,
      live: Json.integer(j['live']) ?? 0,
      catalogueTotal: Json.integer(j['catalogue_total']) ?? 0,
    );
  }
}

/// The periods on the switch, in its order.
const salesPeriods = ['today', 'month', 'year', 'all'];

/// One month on the six-month chart.
@immutable
class ChartMonth {
  const ChartMonth({required this.label, this.sales = 0, this.paid = 0});

  /// "Jun".
  final String label;
  final int sales;
  final int paid;

  factory ChartMonth.fromJson(Object? raw) {
    final j = Json.map(raw);
    return ChartMonth(
      label: Json.str(j['label']) ?? '',
      sales: Json.integer(j['sales']) ?? 0,
      paid: Json.integer(j['paid']) ?? 0,
    );
  }
}

/// One step of the order pipeline.
@immutable
class PipeCount {
  const PipeCount({required this.status, required this.label, this.count = 0});

  /// The server's status (`Varification` is its spelling of Confirming).
  final String status;
  final String label;
  final int count;

  factory PipeCount.fromJson(Object? raw) {
    final j = Json.map(raw);
    final status = Json.str(j['status']) ?? '';
    return PipeCount(
      status: status,
      label: Json.str(j['label']) ?? status,
      count: Json.integer(j['count']) ?? 0,
    );
  }
}

/// The Bulk deals tiles.
@immutable
class BulkTiles {
  const BulkTiles({
    this.newCount = 0,
    this.contacted = 0,
    this.quoted = 0,
    this.won = 0,
    this.lost = 0,
    this.delivering,
  });

  final int newCount;
  final int contacted;
  final int quoted;
  final int won;
  final int lost;

  /// Null until the deals tables exist on the server.
  final int? delivering;

  factory BulkTiles.fromJson(Object? raw) {
    final j = Json.map(raw);
    return BulkTiles(
      newCount: Json.integer(j['new']) ?? 0,
      contacted: Json.integer(j['contacted']) ?? 0,
      quoted: Json.integer(j['quoted']) ?? 0,
      won: Json.integer(j['won']) ?? 0,
      lost: Json.integer(j['lost']) ?? 0,
      delivering: Json.integer(j['delivering']),
    );
  }
}

/// An outlet's month on Home (owner of a multi-outlet brand, All outlets).
@immutable
class OutletMonth {
  const OutletMonth({
    required this.id,
    required this.name,
    this.main = false,
    this.status = 'open',
    this.sales = 0,
    this.orders = 0,
    this.toConfirm = 0,
  });

  final int id;
  final String name;
  final bool main;

  /// `open`, `paused` or `closed`.
  final String status;
  final int sales;
  final int orders;
  final int toConfirm;

  bool get open => status == 'open';

  factory OutletMonth.fromJson(Object? raw) {
    final j = Json.map(raw);
    return OutletMonth(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      main: Json.flag(j['main'] ?? j['is_main']),
      status: Json.str(j['status']) ?? 'open',
      sales: Json.integer(j['sales']) ?? 0,
      orders: Json.integer(j['orders']) ?? 0,
      toConfirm: Json.integer(j['to_confirm']) ?? 0,
    );
  }
}

@immutable
class TopProduct {
  const TopProduct({
    required this.id,
    required this.title,
    this.units = 0,
    this.price,
  });

  final int id;
  final String title;
  final int units;

  /// The cash price (`price`), for the "Rs … cash price" line.
  final int? price;

  factory TopProduct.fromJson(Object? raw) {
    final j = Json.map(raw);
    return TopProduct(
      id: Json.integer(j['id']) ?? 0,
      title: Json.str(j['title']) ?? '',
      units: Json.integer(j['units']) ?? 0,
      price: Json.integer(j['price']),
    );
  }
}

/// A line of Latest orders, and an order found by search.
@immutable
class HomeOrder {
  const HomeOrder({
    required this.uuid,
    required this.id,
    this.atompay = false,
    this.status = '',
    this.statusLabel = '',
    this.total = 0,
    this.productTitle,
    this.customer,
    this.city,
    this.createdAt,
  });

  final String uuid;
  final int id;
  final bool atompay;
  final String status;
  final String statusLabel;
  final int total;
  final String? productTitle;
  final String? customer;
  final String? city;
  final DateTime? createdAt;

  factory HomeOrder.fromJson(Object? raw) {
    final j = Json.map(raw);
    final status = Json.str(j['status']) ?? '';
    return HomeOrder(
      uuid: Json.str(j['uuid']) ?? '',
      id: Json.integer(j['id']) ?? 0,
      atompay: Json.str(j['type']) == 'atompay',
      status: status,
      statusLabel: Json.str(j['status_label']) ?? status,
      total: Json.integer(j['total'] ?? j['total_deal_price']) ?? 0,
      productTitle: Json.str(Json.map(j['product'])['title']),
      customer: Json.str(j['customer']),
      city: Json.str(j['city']),
      createdAt: AtomDates.parse(j['created_at']),
    );
  }
}

/// A line of Recent activity: a notification (§8.10) as the inbox shows it.
@immutable
class HomeActivity {
  const HomeActivity({required this.notice, this.timeAgo});

  final Notice notice;

  /// The server's "2 minutes ago".
  final String? timeAgo;

  factory HomeActivity.fromJson(Object? raw) => HomeActivity(
    notice: Notice.fromJson(raw),
    timeAgo: Json.str(Json.map(raw)['time_ago']),
  );
}

/// The plan card (owner only).
@immutable
class PlanSummary {
  const PlanSummary({
    required this.packageName,
    this.paidUntil,
    this.addonsOn = const [],
  });

  /// "Brand Partner package".
  final String packageName;
  final DateTime? paidUntil;

  /// The names of the add-ons in trial, active or legacy.
  final List<String> addonsOn;

  factory PlanSummary.fromJson(Object? raw) {
    final j = Json.map(raw);
    final package = Json.map(j['package']);
    return PlanSummary(
      packageName: Json.str(package['name']) ?? 'Brand Partner package',
      paidUntil: AtomDates.parse(j['paid_until']),
      addonsOn: [
        for (final a in Json.list(j['addons']))
          if (const {
            'trial',
            'active',
            'legacy',
          }.contains(Json.str(Json.map(a)['state'])))
            ?Json.str(Json.map(a)['name']),
      ],
    );
  }
}

/// Everything Home shows from one `GET dashboard`.
@immutable
class HomeDashboard {
  const HomeDashboard({
    this.hero = const HomeHero(),
    this.tasks = const [],
    this.periods = const {},
    this.chart,
    this.pipeline,
    this.bulk,
    this.outlets = const [],
    this.topProducts = const [],
    this.latestOrders,
    this.activity = const [],
    this.plan,
    this.noticed,
    this.catalogueTotal = 0,
    this.cataloguePublished = 0,
    this.ordersTotal = 0,
    this.readAt,
  });

  final HomeHero hero;
  final List<HomeTask> tasks;

  /// "Your sales on Atomshop" by period; empty without `home.totals`.
  final Map<String, SalesFigures> periods;

  /// Six months, oldest first; null without `home.totals`.
  final List<ChartMonth>? chart;
  final List<PipeCount>? pipeline;
  final BulkTiles? bulk;
  final List<OutletMonth> outlets;
  final List<TopProduct> topProducts;
  final List<HomeOrder>? latestOrders;
  final List<HomeActivity> activity;
  final PlanSummary? plan;

  /// "Atom noticed" (5.1): one insight, or null when nothing stands out.
  final HomeNoticed? noticed;

  /// The v1 figures, always sent: the first-day check reads them.
  final int catalogueTotal;
  final int cataloguePublished;
  final int ordersTotal;

  /// When this phone read it ("Updated 9:42 am").
  final DateTime? readAt;

  /// The person may see the business totals (`home.totals`).
  bool get hasTotals => periods.isNotEmpty;

  factory HomeDashboard.fromJson(Object? data, {DateTime? readAt}) {
    final d = Json.map(data);
    final h = Json.map(d['home']);
    final periods = <String, SalesFigures>{};
    final rawPeriods = Json.map(h['periods']);
    for (final p in salesPeriods) {
      if (rawPeriods[p] is Map) {
        periods[p] = SalesFigures.fromJson(rawPeriods[p], period: p);
      }
    }
    // A server that sends only the chosen period still fills its slot.
    if (periods.isEmpty && h['sales'] is Map) {
      final s = SalesFigures.fromJson(h['sales']);
      periods[s.period] = s;
    }
    List<T>? listOrNull<T>(Object? v, T Function(Object?) f) =>
        v is List ? [for (final x in v) f(x)] : null;
    final catalogue = Json.map(d['catalogue']);
    final orders = Json.map(d['orders']);
    return HomeDashboard(
      hero: HomeHero.fromJson(h['hero']),
      tasks: HomeTask.listFromJson(h['tasks']),
      periods: periods,
      chart: Json.map(h['chart'])['months'] is List
          ? [
              for (final m in Json.list(Json.map(h['chart'])['months']))
                ChartMonth.fromJson(m),
            ]
          : null,
      pipeline: listOrNull(h['pipeline'], PipeCount.fromJson),
      bulk: h['bulk'] is Map ? BulkTiles.fromJson(h['bulk']) : null,
      outlets: listOrNull(h['outlets'], OutletMonth.fromJson) ?? const [],
      topProducts:
          listOrNull(h['top_products'], TopProduct.fromJson) ?? const [],
      latestOrders: listOrNull(h['latest_orders'], HomeOrder.fromJson),
      activity: listOrNull(h['activity'], HomeActivity.fromJson) ?? const [],
      plan: h['plan'] is Map ? PlanSummary.fromJson(h['plan']) : null,
      noticed: HomeNoticed.tryParse(h['noticed']),
      catalogueTotal: Json.integer(catalogue['total']) ?? 0,
      cataloguePublished: Json.integer(catalogue['published']) ?? 0,
      ordersTotal: Json.integer(orders['total']) ?? 0,
      readAt: readAt,
    );
  }
}

// ───────────────────────────────────────────── outlet switcher (5.7)

/// An outlet with this month's figures (`GET outlets?p=month`, owner).
@immutable
class OutletFigures {
  const OutletFigures({
    required this.id,
    required this.name,
    this.main = false,
    this.status = 'open',
    this.sales = 0,
    this.toConfirm = 0,
  });

  final int id;
  final String name;
  final bool main;
  final String status;
  final int sales;
  final int toConfirm;

  bool get paused => status == 'paused';
  bool get closed => status == 'closed';

  factory OutletFigures.fromJson(Object? raw) {
    final j = Json.map(raw);
    final f = Json.map(j['figures']);
    return OutletFigures(
      id: Json.integer(j['id']) ?? 0,
      name: Json.str(j['name']) ?? '',
      main: Json.flag(j['is_main'] ?? j['main']),
      status: Json.str(j['status']) ?? 'open',
      sales: Json.integer(f['sales']) ?? 0,
      toConfirm: Json.integer(f['to_confirm']) ?? 0,
    );
  }
}

/// The switcher's list: the outlets (closed ones left out), how many the
/// plan allows and how many are used.
@immutable
class OutletList {
  const OutletList({required this.outlets, this.limit, this.used});

  final List<OutletFigures> outlets;
  final int? limit;
  final int? used;

  int get totalSales => outlets.fold(0, (s, o) => s + o.sales);
  int get totalToConfirm => outlets.fold(0, (s, o) => s + o.toConfirm);

  /// Room for another outlet on the plan.
  bool get canAdd => limit == null || used == null || used! < limit!;

  factory OutletList.fromJson(Object? data) {
    final d = Json.map(data);
    return OutletList(
      outlets: [
        for (final o in Json.list(d['outlets']))
          if (OutletFigures.fromJson(o) case final f when !f.closed) f,
      ],
      limit: Json.integer(d['outlet_limit']),
      used: Json.integer(d['used']),
    );
  }
}

// ───────────────────────────────────────────── search (5.8)

@immutable
class FoundProduct {
  const FoundProduct({
    required this.id,
    required this.title,
    this.prNumber,
    this.status = '',
    this.statusLabel = '',
    this.price = 0,
  });

  final int id;
  final String title;
  final String? prNumber;
  final String status;
  final String statusLabel;
  final int price;

  factory FoundProduct.fromJson(Object? raw) {
    final j = Json.map(raw);
    final status = Json.str(j['status']) ?? '';
    return FoundProduct(
      id: Json.integer(j['id']) ?? 0,
      title: Json.str(j['title']) ?? '',
      prNumber: Json.str(j['pr_number']),
      status: status,
      statusLabel: Json.str(j['status_label']) ?? status,
      price: Json.integer(j['price']) ?? 0,
    );
  }
}

@immutable
class FoundRequest {
  const FoundRequest({
    required this.id,
    this.status = 'New Lead',
    this.name,
    this.productTitle,
    this.quantity = 0,
    this.fromSeller = false,
  });

  final int id;
  final String status;
  final String? name;
  final String? productTitle;
  final int quantity;
  final bool fromSeller;

  factory FoundRequest.fromJson(Object? raw) {
    final j = Json.map(raw);
    final from = Json.str(j['from']);
    return FoundRequest(
      id: Json.integer(j['id']) ?? 0,
      status: Json.str(j['status']) ?? 'New Lead',
      name: Json.str(j['full_name']),
      productTitle: Json.str(j['product_title']),
      quantity: Json.integer(j['quantity']) ?? 0,
      fromSeller: from == 'seller' || from == 'sellers',
    );
  }
}

/// A section of results: up to five, and whether there are more. Null
/// sections are ones the role can't see.
@immutable
class Found<T> {
  const Found(this.items, {this.more = false});
  final List<T> items;
  final bool more;

  static Found<T>? fromJson<T>(Object? raw, T Function(Object?) parse) {
    if (raw is! Map) return null;
    final j = Json.map(raw);
    return Found([
      for (final x in Json.list(j['items'])) parse(x),
    ], more: Json.flag(j['more']));
  }
}

@immutable
class SearchResults {
  const SearchResults({
    required this.query,
    this.orders,
    this.products,
    this.requests,
    this.fromCopy = false,
  });

  final String query;
  final Found<HomeOrder>? orders;
  final Found<FoundProduct>? products;
  final Found<FoundRequest>? requests;

  /// Read from this phone's copy, with no signal.
  final bool fromCopy;

  int get total =>
      (orders?.items.length ?? 0) +
      (products?.items.length ?? 0) +
      (requests?.items.length ?? 0);

  factory SearchResults.fromJson(Object? data) {
    final d = Json.map(data);
    return SearchResults(
      query: Json.str(d['q']) ?? '',
      orders: Found.fromJson(d['orders'], HomeOrder.fromJson),
      products: Found.fromJson(d['products'], FoundProduct.fromJson),
      requests: Found.fromJson(d['bulk_requests'], FoundRequest.fromJson),
    );
  }
}

// ───────────────────────────────────────────── banners (13.8)

/// What Home's banners need from `GET billing` (owner): the open bills and
/// the add-ons' end dates.
@immutable
class BillingGlance {
  const BillingGlance({this.openBills = const [], this.addons = const []});

  final List<OpenBill> openBills;
  final List<AddonEnd> addons;

  factory BillingGlance.fromJson(Object? data) {
    final d = Json.map(data);
    return BillingGlance(
      openBills: [
        for (final b in Json.list(d['open_invoices'])) OpenBill.fromJson(b),
      ],
      addons: [for (final a in Json.list(d['addons'])) AddonEnd.fromJson(a)],
    );
  }
}

@immutable
class OpenBill {
  const OpenBill({
    required this.number,
    this.due = 0,
    this.dueOn,
    this.coversFrom,
    this.overdue = false,
  });

  final String number;
  final int due;
  final DateTime? dueOn;
  final DateTime? coversFrom;
  final bool overdue;

  factory OpenBill.fromJson(Object? raw) {
    final j = Json.map(raw);
    return OpenBill(
      number: Json.str(j['number']) ?? '',
      due: Json.integer(j['due'] ?? j['total']) ?? 0,
      dueOn: AtomDates.parse(j['due_on']),
      coversFrom: AtomDates.parse(j['covers_from']),
      overdue: Json.flag(j['overdue']),
    );
  }
}

@immutable
class AddonEnd {
  const AddonEnd({
    required this.key,
    required this.name,
    required this.state,
    this.endsOn,
    this.renew = true,
  });

  final String key;
  final String name;
  final String state;
  final DateTime? endsOn;

  /// It carries on into the next bill unless switched off.
  final bool renew;

  factory AddonEnd.fromJson(Object? raw) {
    final j = Json.map(raw);
    return AddonEnd(
      key: Json.str(j['key']) ?? '',
      name: Json.str(j['name']) ?? '',
      state: Json.str(j['state']) ?? 'off',
      endsOn: AtomDates.parse(j['ends_on']),
      renew: j['renew'] == null || Json.flag(j['renew']),
    );
  }
}

/// "Atom noticed" on Home (5.1, Ask Atom add-on): the server's one short
/// insight from the dashboard's own numbers (`home.noticed`): `{key, tone,
/// title, text, action: {screen, params}}`.
@immutable
class HomeNoticed {
  const HomeNoticed({
    required this.key,
    required this.title,
    required this.text,
    this.warning = false,
    this.screen,
    this.params = const {},
  });

  /// `low_stock`, `orders_waiting`, `slow_outlet` or `quotes_expiring`.
  final String key;
  final String title;
  final String text;
  final bool warning;

  /// Where its button goes (`stock_product`, `orders`, `outlets`,
  /// `bulk_orders`); null for none.
  final String? screen;
  final Map<String, dynamic> params;

  static HomeNoticed? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final j = Json.map(raw);
    final text = Json.str(j['text']) ?? '';
    final title = Json.str(j['title']) ?? '';
    if (text.isEmpty && title.isEmpty) return null;
    final action = Json.map(j['action']);
    return HomeNoticed(
      key: Json.str(j['key']) ?? '',
      title: title,
      text: text,
      warning: j['tone'] == 'warning',
      screen: Json.str(action['screen']),
      params: Json.map(action['params']),
    );
  }
}
