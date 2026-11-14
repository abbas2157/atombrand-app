import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/format/dates.dart';

/// Models for bulk requests, seller (sourcing) requests, quotes and deals,
/// read from the Brand App API (atomshop `BulkOrdersController`,
/// `BulkDealsController`; docs/BRAND_APP.md "Bulk deals").

double _dbl(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s.trim()) ?? 0,
  _ => 0,
};

int _int(Object? v) => Json.integer(v) ?? 0;

/// A request's status as the server spells it (`New Lead`, `Contacted`,
/// `Quoted`, `Won`, `Lost`). A missing status is a new lead.
enum RequestStatus {
  fresh('New Lead'),
  contacted('Contacted'),
  quoted('Quoted'),
  won('Won'),
  lost('Lost');

  const RequestStatus(this.key);
  final String key;

  static RequestStatus of(Object? raw) {
    final s = Json.str(raw);
    for (final v in values) {
      if (v.key == s) return v;
    }
    return fresh;
  }

  bool get open => this == fresh || this == contacted || this == quoted;
}

/// The Atomshop shop asking (a seller's sourcing request) or buying (a
/// seller's deal). The list carries `{id, name, branch, code, verified}`;
/// the detail adds how it has traded with this brand.
@immutable
class BulkSeller {
  const BulkSeller({
    required this.id,
    required this.name,
    this.branch,
    this.code,
    this.verified = false,
    this.city,
    this.since,
    this.dealsWithYou = 0,
    this.dealsAmount = 0,
    this.paidOnTime = 0,
    this.otherOpen = 0,
    this.otherRequests = const [],
  });

  final int id;
  final String name;
  final String? branch;
  final String? code;
  final bool verified;
  final String? city;
  final DateTime? since;
  final int dealsWithYou;
  final int dealsAmount;
  final int paidOnTime;
  final int otherOpen;
  final List<SellerOtherRequest> otherRequests;

  static BulkSeller? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    return BulkSeller(
      id: _int(j['id']),
      name: Json.str(j['name']) ?? '',
      branch: Json.str(j['branch']),
      code: Json.str(j['code']),
      verified: Json.flag(j['verified']),
      city: Json.str(j['city']),
      since: AtomDates.parse(j['on_atomshop_since']),
      dealsWithYou: _int(j['deals_with_you']),
      dealsAmount: _int(j['deals_amount']),
      paidOnTime: _int(j['paid_on_time']),
      otherOpen: _int(j['other_open_requests']),
      otherRequests: [
        for (final r in Json.list(j['other_requests']))
          SellerOtherRequest.fromJson(r),
      ],
    );
  }
}

@immutable
class SellerOtherRequest {
  const SellerOtherRequest({
    required this.id,
    required this.title,
    required this.quantity,
    required this.status,
  });

  final int id;
  final String title;
  final int quantity;
  final RequestStatus status;

  factory SellerOtherRequest.fromJson(Object? data) {
    final j = Json.map(data);
    return SellerOtherRequest(
      id: _int(j['id']),
      title: Json.str(j['product_title']) ?? '',
      quantity: _int(j['quantity']),
      status: RequestStatus.of(j['status']),
    );
  }
}

/// The seller's latest answer to the brand's quote.
@immutable
class SellerAnswer {
  const SellerAnswer({
    required this.action,
    this.label,
    this.message,
    this.reason,
    this.pending = false,
    this.at,
  });

  /// `accepted`, `change_asked`, `declined` or `cancelled`.
  final String action;
  final String? label;

  /// What they asked to change (change_asked).
  final String? message;

  /// Why they said no (declined, cancelled).
  final String? reason;

  /// A change asked that has no newer revision yet.
  final bool pending;
  final DateTime? at;

  static SellerAnswer? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    final action = Json.str(j['action']);
    if (action == null) return null;
    return SellerAnswer(
      action: action,
      label: Json.str(j['label']),
      message: Json.str(j['message']) ?? Json.str(j['details']),
      reason: Json.str(j['reason']),
      pending: Json.flag(j['pending']),
      at: AtomDates.parse(j['at']),
    );
  }
}

/// One bulk request in a list (`GET bulk-orders` items).
@immutable
class BulkRequest {
  const BulkRequest({
    required this.id,
    required this.status,
    required this.fullName,
    this.uuid,
    this.phone,
    this.quantity = 0,
    this.productTitle,
    this.productId,
    this.productPicture,
    this.productPrice,
    this.city,
    this.area,
    this.fromSeller = false,
    this.targetPrice,
    this.neededBy,
    this.seller,
    this.createdAt,
    this.commentsCount = 0,
    this.answer,
    this.quote,
  });

  final int id;
  final String? uuid;
  final RequestStatus status;
  final String fullName;
  final String? phone;
  final int quantity;
  final String? productTitle;
  final int? productId;
  final String? productPicture;

  /// The catalogue price, when the server sends it with the product.
  final int? productPrice;
  final String? city;
  final String? area;

  /// An Atomshop seller sourcing stock, not a website buyer.
  final bool fromSeller;
  final int? targetPrice;
  final DateTime? neededBy;
  final BulkSeller? seller;
  final DateTime? createdAt;
  final int commentsCount;

  /// The seller's latest answer, when the list sends it.
  final SellerAnswer? answer;

  /// The latest quote, when the list sends it.
  final Quote? quote;

  /// Who to show: the shop for a seller's request, else the person.
  String get who => seller?.name ?? fullName;

  String get title => productTitle ?? '';

  factory BulkRequest.fromJson(Object? data) {
    final j = Json.map(data);
    final product = Json.map(j['product']);
    return BulkRequest(
      id: _int(j['id']),
      uuid: Json.str(j['uuid']),
      status: RequestStatus.of(j['status']),
      fullName: Json.str(j['full_name']) ?? '',
      phone: Json.str(j['phone']),
      quantity: _int(j['quantity']),
      productTitle: Json.str(j['product_title']) ?? Json.str(product['title']),
      productId: Json.integer(product['id']),
      productPicture: Json.str(product['picture']),
      productPrice: Json.integer(product['price']),
      city: Json.str(j['city']),
      area: Json.str(j['area']),
      fromSeller: Json.str(j['from']) == 'seller',
      targetPrice: Json.integer(j['target_price']),
      neededBy: AtomDates.parse(j['needed_by']),
      seller: BulkSeller.fromJson(j['seller']),
      createdAt: AtomDates.parse(j['created_at']),
      commentsCount: _int(j['comments_count']),
      answer: SellerAnswer.fromJson(j['answer']),
      quote: j['quote'] is Map ? Quote.fromJson(j['quote']) : null,
    );
  }
}

/// The seller's request counts (`seller_counts`).
@immutable
class SellerCounts {
  const SellerCounts({
    this.waiting = 0,
    this.changeAsked = 0,
    this.open = 0,
    this.total = 0,
  });

  final int waiting;
  final int changeAsked;
  final int open;
  final int total;

  /// The Seller requests tab badge.
  int get badge => waiting + changeAsked;

  factory SellerCounts.fromJson(Object? data) {
    final j = Json.map(data);
    return SellerCounts(
      waiting: _int(j['waiting']),
      changeAsked: _int(j['change_asked']),
      open: _int(j['open']),
      total: _int(j['total']),
    );
  }
}

/// `GET bulk-orders/count`.
@immutable
class BulkCounts {
  const BulkCounts({
    this.count = 0,
    this.sellerRequests = 0,
    this.seller = const SellerCounts(),
  });

  /// New requests, buyers and sellers.
  final int count;
  final int sellerRequests;
  final SellerCounts seller;

  factory BulkCounts.fromJson(Object? data) {
    final j = Json.map(data);
    return BulkCounts(
      count: _int(j['count']),
      sellerRequests: _int(j['seller_requests']),
      seller: SellerCounts.fromJson(j['seller_counts']),
    );
  }
}

/// The money tiles over the list (7.1), when the server sends them
/// (`tiles`, the portal's figures).
@immutable
class BulkTiles {
  const BulkTiles({
    this.fresh = 0,
    this.outValue = 0,
    this.outCount = 0,
    this.outSoon = 0,
    this.wonValue = 0,
    this.wonCount = 0,
    this.winRate,
    this.toCollect = 0,
    this.openDeals = 0,
  });

  final int fresh;
  final int outValue;
  final int outCount;
  final int outSoon;
  final int wonValue;
  final int wonCount;
  final int? winRate;
  final int toCollect;
  final int openDeals;

  static BulkTiles? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    return BulkTiles(
      fresh: _int(j['new']),
      outValue: _int(j['out_value']),
      outCount: _int(j['out_count']),
      outSoon: _int(j['out_soon']),
      wonValue: _int(j['won_value']),
      wonCount: _int(j['won_count']),
      winRate: Json.integer(j['win_rate']),
      toCollect: _int(j['to_collect']),
      openDeals: _int(j['open_deals']),
    );
  }
}

/// One page of `GET bulk-orders`, with its siblings.
@immutable
class BulkRequestsPage {
  const BulkRequestsPage({
    required this.page,
    this.counts = const {},
    this.allCount,
    this.sellerCounts = const SellerCounts(),
    this.tiles,
  });

  final ApiPage<BulkRequest> page;

  /// Requests by status (`counts`), under the list's `from`.
  final Map<RequestStatus, int> counts;

  /// Every status together (`all_count`), for an All chip; the sum of
  /// [counts] when the server sent none.
  final int? allCount;

  int get all => allCount ?? counts.values.fold(0, (a, b) => a + b);
  final SellerCounts sellerCounts;
  final BulkTiles? tiles;

  List<BulkRequest> get items => page.items;

  factory BulkRequestsPage.fromJson(Object? data) {
    final page = ApiPage.fromJson(data, BulkRequest.fromJson);
    final counts = Json.map(page.extra['counts']);
    return BulkRequestsPage(
      page: page,
      counts: {for (final s in RequestStatus.values) s: _int(counts[s.key])},
      allCount: Json.integer(page.extra['all_count']),
      sellerCounts: SellerCounts.fromJson(page.extra['seller_counts']),
      tiles: BulkTiles.fromJson(page.extra['tiles']),
    );
  }
}

/// A note on a request (`request.comments`).
@immutable
class BulkComment {
  const BulkComment({required this.text, this.status, this.byName, this.at});

  final String text;
  final String? status;
  final String? byName;
  final DateTime? at;

  factory BulkComment.fromJson(Object? data) {
    final j = Json.map(data);
    return BulkComment(
      text: Json.str(j['comments']) ?? '',
      status: Json.str(j['status']),
      byName: Json.str(Json.map(j['by'])['name']),
      at: AtomDates.parse(j['created_at']),
    );
  }
}

/// The person who asked on the website, when they have an account.
@immutable
class Requester {
  const Requester({
    this.name,
    this.phone,
    this.email,
    this.since,
    this.verified = false,
    this.city,
    this.area,
    this.address,
  });

  final String? name;
  final String? phone;
  final String? email;
  final DateTime? since;
  final bool verified;
  final String? city;
  final String? area;
  final String? address;

  static Requester? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    return Requester(
      name: Json.str(j['name']),
      phone: Json.str(j['phone']),
      email: Json.str(j['email']),
      since: AtomDates.parse(j['customer_since']),
      verified: Json.flag(j['verified']),
      city: Json.str(j['city']),
      area: Json.str(j['area']),
      address: Json.str(j['address']),
    );
  }
}

/// One line of a seller request's timeline.
@immutable
class HistoryEntry {
  const HistoryEntry({
    required this.label,
    this.action,
    this.actor,
    this.details,
    this.by,
    this.at,
  });

  final String label;
  final String? action;

  /// `seller`, `brand` or `atomshop`.
  final String? actor;
  final String? details;

  /// The brand's own staff member, when it was them.
  final String? by;
  final DateTime? at;

  factory HistoryEntry.fromJson(Object? data) {
    final j = Json.map(data);
    return HistoryEntry(
      label: Json.str(j['label']) ?? '',
      action: Json.str(j['action']),
      actor: Json.str(j['actor']),
      details: Json.str(j['details']),
      by: Json.str(j['by']),
      at: AtomDates.parse(j['at']),
    );
  }
}

@immutable
class DealRef {
  const DealRef({required this.id, required this.number, this.status});

  final int id;
  final String number;
  final String? status;

  static DealRef? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    final id = Json.integer(j['id']);
    if (id == null) return null;
    return DealRef(
      id: id,
      number: Json.str(j['number']) ?? '',
      status: Json.str(j['status']),
    );
  }
}

/// What Atomshop charges the brand on a seller deal.
@immutable
class Commission {
  const Commission({required this.amount, this.label, this.onTotal});

  final int amount;
  final String? label;
  final int? onTotal;

  static Commission? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    return Commission(
      amount: _int(j['amount']),
      label: Json.str(j['label']),
      onTotal: Json.integer(j['on_total']),
    );
  }
}

/// The `sourcing` block of a seller's request.
@immutable
class Sourcing {
  const Sourcing({
    required this.title,
    required this.quantity,
    this.seller,
    this.typed = false,
    this.productId,
    this.picture,
    this.targetPrice,
    this.neededBy,
    this.note,
    this.deliverAddress,
    this.deliverCity,
    this.deliverArea,
    this.liveQuote,
    this.answer,
    this.history = const [],
    this.deal,
    this.commission,
  });

  final BulkSeller? seller;
  final String title;
  final int quantity;

  /// The seller typed what they need: not in the brand's catalogue.
  final bool typed;
  final int? productId;
  final String? picture;
  final int? targetPrice;
  final DateTime? neededBy;
  final String? note;
  final String? deliverAddress;
  final String? deliverCity;
  final String? deliverArea;
  final Quote? liveQuote;
  final SellerAnswer? answer;
  final List<HistoryEntry> history;
  final DealRef? deal;
  final Commission? commission;

  String get deliverTo => [
    ?deliverAddress,
    ?deliverArea,
    ?deliverCity,
  ].where((s) => s.isNotEmpty).join(', ');

  static Sourcing? fromJson(Object? data) {
    if (data is! Map) return null;
    final j = Json.map(data);
    final item = Json.map(j['item']);
    final to = Json.map(j['deliver_to']);
    return Sourcing(
      seller: BulkSeller.fromJson(j['seller']),
      title: Json.str(item['title']) ?? '',
      quantity: _int(item['quantity']),
      typed: Json.flag(item['typed']),
      productId: Json.integer(item['product_id']),
      picture: Json.str(item['picture']) ?? Json.str(item['photo']),
      targetPrice: Json.integer(j['target_price']),
      neededBy: AtomDates.parse(j['needed_by']),
      note: Json.str(j['note']),
      deliverAddress: Json.str(to['address']),
      deliverCity: Json.str(to['city']),
      deliverArea: Json.str(to['area']),
      liveQuote: j['live_quote'] is Map
          ? Quote.fromJson(j['live_quote'])
          : null,
      answer: SellerAnswer.fromJson(j['answer']),
      history: [
        for (final h in Json.list(j['history'])) HistoryEntry.fromJson(h),
      ],
      deal: DealRef.fromJson(j['deal']),
      commission: Commission.fromJson(j['commission']),
    );
  }
}

/// `GET bulk-orders/{id}`: the request, who asked and how they have dealt
/// with the brand; `sourcing` for a seller's request.
@immutable
class BulkDossier {
  const BulkDossier({
    required this.request,
    this.address,
    this.reason,
    this.whatsapp,
    this.comments = const [],
    this.requester,
    this.otherRequests = const [],
    this.ordersCount = 0,
    this.lifetimeValue = 0,
    this.sourcing,
  });

  final BulkRequest request;
  final String? address;

  /// Why it was lost.
  final String? reason;
  final String? whatsapp;
  final List<BulkComment> comments;
  final Requester? requester;
  final List<BulkRequest> otherRequests;
  final int ordersCount;
  final int lifetimeValue;
  final Sourcing? sourcing;

  bool get isSeller => sourcing != null || request.fromSeller;

  factory BulkDossier.fromJson(Object? data) {
    final j = Json.map(data);
    final r = Json.map(j['request']);
    return BulkDossier(
      request: BulkRequest.fromJson(r),
      address: Json.str(r['address']),
      reason: Json.str(r['reason']),
      whatsapp: Json.str(r['whatsapp']),
      comments: [
        for (final c in Json.list(r['comments'])) BulkComment.fromJson(c),
      ],
      requester: Requester.fromJson(j['requester']),
      otherRequests: [
        for (final o in Json.list(j['other_requests'])) BulkRequest.fromJson(o),
      ],
      ordersCount: Json.list(j['orders']).length,
      lifetimeValue: _int(j['lifetime_value']),
      sourcing: Sourcing.fromJson(j['sourcing']),
    );
  }
}

// ───────────────────────────────────────────────────────────── quotes

@immutable
class QuoteLine {
  const QuoteLine({
    required this.productId,
    required this.title,
    required this.qty,
    required this.unitPrice,
    this.memoryId,
    this.colorId,
    this.discountPct = 0,
    this.lineTotal = 0,
  });

  final int? productId;
  final int? memoryId;
  final int? colorId;
  final String title;
  final int qty;
  final int unitPrice;
  final double discountPct;
  final int lineTotal;

  factory QuoteLine.fromJson(Object? data) {
    final j = Json.map(data);
    return QuoteLine(
      productId: Json.integer(j['product_id']),
      memoryId: Json.integer(j['memory_id']),
      colorId: Json.integer(j['color_id']),
      title: Json.str(j['title']) ?? '',
      qty: _int(j['qty']),
      unitPrice: _int(j['unit_price']),
      discountPct: _dbl(j['discount_pct']),
      lineTotal: _int(j['line_total']),
    );
  }
}

/// A quote (`QT-0007`, revision 2).
@immutable
class Quote {
  const Quote({
    required this.id,
    required this.number,
    required this.revision,
    required this.status,
    this.bulkOrderId,
    this.label,
    this.items = const [],
    this.subtotal = 0,
    this.discountTotal = 0,
    this.deliveryCharge = 0,
    this.total = 0,
    this.advancePct = 0,
    this.advance = 0,
    this.balanceTerms = 'before_last',
    this.validUntil,
    this.notes,
    this.sentAt,
    this.createdBy,
    this.whatsappLink,
    this.expired = false,
  });

  final int id;
  final int? bulkOrderId;
  final String number;
  final int revision;
  final String? label;

  /// `draft`, `sent`, `accepted`, `superseded` or `expired`.
  final String status;
  final List<QuoteLine> items;

  /// The lines after their discounts (the server's `subtotal`).
  final int subtotal;
  final int discountTotal;
  final int deliveryCharge;
  final int total;
  final int advancePct;
  final int advance;

  /// `before_each` or `before_last`.
  final String balanceTerms;
  final DateTime? validUntil;
  final String? notes;
  final DateTime? sentAt;
  final String? createdBy;
  final String? whatsappLink;
  final bool expired;

  String get name => label ?? '$number rev $revision';

  bool get isDraft => status == 'draft';

  int get units => items.fold(0, (s, l) => s + l.qty);

  factory Quote.fromJson(Object? data) {
    final j = Json.map(data);
    final status = Json.str(j['status']) ?? 'draft';
    return Quote(
      id: _int(j['id']),
      bulkOrderId: Json.integer(j['bulk_order_id']),
      number: Json.str(j['number']) ?? '',
      revision: Json.integer(j['revision']) ?? 1,
      label: Json.str(j['label']),
      status: status,
      items: [for (final i in Json.list(j['items'])) QuoteLine.fromJson(i)],
      subtotal: _int(j['subtotal']),
      discountTotal: _int(j['discount_total']),
      deliveryCharge: _int(j['delivery_charge']),
      total: _int(j['total']),
      advancePct: _int(j['advance_pct']),
      advance: _int(j['advance']),
      balanceTerms: Json.str(j['balance_terms']) ?? 'before_last',
      validUntil: AtomDates.parse(j['valid_until']),
      notes: Json.str(j['notes']),
      sentAt: AtomDates.parse(j['sent_at']),
      createdBy: Json.str(j['created_by']),
      whatsappLink: Json.str(j['whatsapp_link']),
      expired: Json.flag(j['expired']) || status == 'expired',
    );
  }
}

/// `GET bulk-orders/{id}/quotes`.
@immutable
class RequestQuotes {
  const RequestQuotes({this.quotes = const [], this.deal});

  /// Newest revision first.
  final List<Quote> quotes;
  final DealRef? deal;

  factory RequestQuotes.fromJson(Object? data) {
    final j = Json.map(data);
    return RequestQuotes(
      quotes: [for (final q in Json.list(j['quotes'])) Quote.fromJson(q)],
      deal: DealRef.fromJson(j['deal']),
    );
  }
}

@immutable
class QuoteVariant {
  const QuoteVariant({required this.id, required this.title, this.price});
  final int id;
  final String title;
  final int? price;
}

@immutable
class QuoteProduct {
  const QuoteProduct({
    required this.id,
    required this.title,
    required this.price,
    this.memories = const [],
    this.colors = const [],
  });

  final int id;
  final String title;
  final int price;
  final List<QuoteVariant> memories;
  final List<QuoteVariant> colors;

  factory QuoteProduct.fromJson(Object? data) {
    final j = Json.map(data);
    QuoteVariant v(Object? o) {
      final m = Json.map(o);
      return QuoteVariant(
        id: _int(m['id']),
        title: Json.str(m['title']) ?? '',
        price: Json.integer(m['price']),
      );
    }

    return QuoteProduct(
      id: _int(j['id']),
      title: Json.str(j['title']) ?? '',
      price: _int(j['price']),
      memories: [for (final m in Json.list(j['memories'])) v(m)],
      colors: [for (final c in Json.list(j['colors'])) v(c)],
    );
  }
}

typedef KeyLabel = ({String key, String label});

/// `GET bulk-orders/quote-options`.
@immutable
class QuoteOptions {
  const QuoteOptions({
    this.products = const [],
    this.balanceTerms = const [],
    this.paymentMethods = const [],
    this.lostReasons = const [],
  });

  final List<QuoteProduct> products;
  final List<KeyLabel> balanceTerms;
  final List<KeyLabel> paymentMethods;
  final List<String> lostReasons;

  QuoteProduct? product(int? id) {
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  factory QuoteOptions.fromJson(Object? data) {
    final j = Json.map(data);
    List<KeyLabel> pairs(Object? v) => [
      for (final o in Json.list(v))
        (
          key: Json.str(Json.map(o)['key']) ?? '',
          label: Json.str(Json.map(o)['label']) ?? '',
        ),
    ];
    return QuoteOptions(
      products: [
        for (final p in Json.list(j['products'])) QuoteProduct.fromJson(p),
      ],
      balanceTerms: pairs(j['balance_terms']),
      paymentMethods: pairs(j['payment_methods']),
      lostReasons: [for (final r in Json.list(j['lost_reasons'])) ?Json.str(r)],
    );
  }
}

// ───────────────────────────────────────────────────────────── deals

/// A deal's status key: `open`, `delivering`, `delivered`, `paid`,
/// `closed` or `lost`.
enum DealStatus {
  open('open'),
  delivering('delivering'),
  delivered('delivered'),
  paid('paid'),
  closed('closed'),
  lost('lost');

  const DealStatus(this.key);
  final String key;

  String label(AppLocalizations l) => switch (this) {
    open => l.bulkDealOpen,
    delivering => l.bulkDealDelivering,
    delivered => l.bulkDealDelivered,
    paid => l.bulkDealPaid,
    closed => l.bulkDealClosed,
    lost => l.bulkStatusLost,
  };

  static DealStatus of(Object? raw) {
    final s = Json.str(raw);
    for (final v in values) {
      if (v.key == s) return v;
    }
    return open;
  }

  bool get finished => this == closed || this == lost;
}

@immutable
class DealItem {
  const DealItem({
    required this.id,
    required this.title,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.productId,
    this.deliveredQty = 0,
    this.remainingQty,
  });

  final int id;
  final int? productId;
  final String title;
  final int qty;
  final int unitPrice;
  final int lineTotal;
  final int deliveredQty;

  /// The server's figure; worked out when it is missing (the copy).
  final int? remainingQty;

  int get remaining => remainingQty ?? (qty - deliveredQty).clamp(0, qty);

  factory DealItem.fromJson(Object? data) {
    final j = Json.map(data);
    return DealItem(
      id: _int(j['id']),
      productId: Json.integer(j['product_id']),
      title: Json.str(j['title']) ?? '',
      qty: _int(j['qty']),
      unitPrice: _int(j['unit_price']),
      lineTotal: _int(j['line_total']),
      deliveredQty: _int(j['delivered_qty']),
      remainingQty: Json.integer(j['remaining']),
    );
  }
}

@immutable
class DeliveryLine {
  const DeliveryLine({
    required this.dealItemId,
    required this.qty,
    this.serials = const [],
  });

  final int dealItemId;
  final int qty;
  final List<String> serials;

  factory DeliveryLine.fromJson(Object? data) {
    final j = Json.map(data);
    return DeliveryLine(
      dealItemId: _int(j['deal_item_id']),
      qty: _int(j['qty']),
      serials: [for (final s in Json.list(j['serials'])) ?Json.str(s)],
    );
  }
}

/// A delivery note (`DN-0001`).
@immutable
class Delivery {
  const Delivery({
    required this.id,
    required this.number,
    this.deliveredOn,
    this.receivedBy,
    this.note,
    this.photo,
    this.sellerConfirmedAt,
    this.items = const [],
  });

  final int id;
  final String number;
  final DateTime? deliveredOn;
  final String? receivedBy;
  final String? note;
  final String? photo;
  final DateTime? sellerConfirmedAt;
  final List<DeliveryLine> items;

  int get units => items.fold(0, (s, i) => s + i.qty);

  List<String> get serials => [for (final i in items) ...i.serials];

  factory Delivery.fromJson(Object? data) {
    final j = Json.map(data);
    return Delivery(
      id: _int(j['id']),
      number: Json.str(j['number']) ?? '',
      deliveredOn: AtomDates.parse(j['delivered_on']),
      receivedBy: Json.str(j['received_by']),
      note: Json.str(j['note']),
      photo: Json.str(j['photo']),
      sellerConfirmedAt: AtomDates.parse(j['seller_confirmed_at']),
      items: [for (final i in Json.list(j['items'])) DeliveryLine.fromJson(i)],
    );
  }
}

@immutable
class DealPayment {
  const DealPayment({
    required this.id,
    required this.amount,
    this.method,
    this.methodLabel,
    this.reference,
    this.receipt,
    this.paidOn,
    this.recordedBy,
  });

  final int id;
  final int amount;
  final String? method;
  final String? methodLabel;
  final String? reference;
  final String? receipt;
  final DateTime? paidOn;
  final String? recordedBy;

  factory DealPayment.fromJson(Object? data) {
    final j = Json.map(data);
    return DealPayment(
      id: _int(j['id']),
      amount: _int(j['amount']),
      method: Json.str(j['method']),
      methodLabel: Json.str(j['method_label']),
      reference: Json.str(j['reference']),
      receipt: Json.str(j['receipt']),
      paidOn: AtomDates.parse(j['paid_on']),
      recordedBy: Json.str(j['recorded_by']) ?? Json.str(j['recorded_by_name']),
    );
  }
}

/// A deal (`BD-0001`): the summary in a list, everything in the detail.
@immutable
class Deal {
  const Deal({
    required this.id,
    required this.number,
    required this.status,
    this.statusLabel,
    this.buyerName,
    this.buyerPhone,
    this.outletId,
    this.outletName,
    this.units = 0,
    this.deliveredUnits = 0,
    this.total = 0,
    this.paid = 0,
    this.balance = 0,
    this.fromSeller = false,
    this.seller,
    this.commission,
    this.sellerConfirmedAt,
    this.createdAt,
    this.bulkOrderId,
    this.quoteId,
    this.quoteLabel,
    this.deliveryCharge = 0,
    this.advancePct = 0,
    this.advance = 0,
    this.balanceTerms = 'before_last',
    this.closedAt,
    this.items = const [],
    this.deliveries = const [],
    this.payments = const [],
    this.stockWarning = const [],
  });

  final int id;
  final String number;
  final DealStatus status;
  final String? statusLabel;
  final String? buyerName;
  final String? buyerPhone;
  final int? outletId;
  final String? outletName;
  final int units;
  final int deliveredUnits;
  final int total;
  final int paid;
  final int balance;
  final bool fromSeller;
  final BulkSeller? seller;
  final Commission? commission;
  final DateTime? sellerConfirmedAt;
  final DateTime? createdAt;

  // detail
  final int? bulkOrderId;
  final int? quoteId;
  final String? quoteLabel;
  final int deliveryCharge;
  final int advancePct;
  final int advance;
  final String balanceTerms;
  final DateTime? closedAt;
  final List<DealItem> items;
  final List<Delivery> deliveries;
  final List<DealPayment> payments;

  /// What is short in stock, right after the deal is made.
  final List<String> stockWarning;

  String get who => seller?.name ?? buyerName ?? '';

  int get leftUnits => (units - deliveredUnits).clamp(0, units);

  /// 0–1 of the total paid.
  double get paidShare => total <= 0 ? 0 : (paid / total).clamp(0, 1);

  factory Deal.fromJson(Object? data) {
    final j = Json.map(data);
    final outlet = Json.map(j['outlet']);
    final quote = Json.map(j['quote']);
    final total = _int(j['total']);
    final paid = _int(j['paid']);
    final items = [for (final i in Json.list(j['items'])) DealItem.fromJson(i)];
    return Deal(
      id: _int(j['id']),
      number: Json.str(j['number']) ?? '',
      status: DealStatus.of(j['status']),
      statusLabel: Json.str(j['status_label']),
      buyerName: Json.str(j['buyer_name']),
      buyerPhone: Json.str(j['buyer_phone']),
      outletId: Json.integer(outlet['id']),
      outletName: Json.str(outlet['name']),
      units:
          Json.integer(j['units']) ?? items.fold<int>(0, (s, i) => s + i.qty),
      deliveredUnits:
          Json.integer(j['delivered_units']) ??
          items.fold<int>(0, (s, i) => s + i.deliveredQty),
      total: total,
      paid: paid,
      balance: Json.integer(j['balance']) ?? (total - paid).clamp(0, total),
      fromSeller: Json.str(j['from']) == 'seller' || j['seller_id'] != null,
      seller: BulkSeller.fromJson(j['seller']),
      commission: Commission.fromJson(j['commission']),
      sellerConfirmedAt: AtomDates.parse(j['seller_confirmed_at']),
      createdAt: AtomDates.parse(j['created_at']),
      bulkOrderId: Json.integer(j['bulk_order_id']),
      quoteId: Json.integer(quote['id']) ?? Json.integer(j['quote_id']),
      quoteLabel: Json.str(quote['label']),
      deliveryCharge: _int(j['delivery_charge']),
      advancePct: _int(j['advance_pct']),
      advance:
          Json.integer(j['advance']) ??
          (total * _int(j['advance_pct']) / 100).round(),
      balanceTerms: Json.str(j['balance_terms']) ?? 'before_last',
      closedAt: AtomDates.parse(j['closed_at']),
      items: items,
      deliveries: [
        for (final d in Json.list(j['deliveries'])) Delivery.fromJson(d),
      ],
      payments: [
        for (final p in Json.list(j['payments'])) DealPayment.fromJson(p),
      ],
      stockWarning: [
        for (final w in Json.list(j['stock_warning']))
          if (w is Map)
            ?Json.str(w['title'] ?? w['product'] ?? w['message'])
          else
            ?Json.str(w),
      ],
    );
  }
}

/// One page of `GET deals`.
@immutable
class DealsPage {
  const DealsPage({required this.page, this.statuses = const []});

  final ApiPage<Deal> page;
  final List<KeyLabel> statuses;

  List<Deal> get items => page.items;

  factory DealsPage.fromJson(Object? data) {
    final page = ApiPage.fromJson(data, Deal.fromJson);
    return DealsPage(
      page: page,
      statuses: [
        for (final o in Json.list(page.extra['statuses']))
          (
            key: Json.str(Json.map(o)['key']) ?? '',
            label: Json.str(Json.map(o)['label']) ?? '',
          ),
      ],
    );
  }
}
