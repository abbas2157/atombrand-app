import 'account.dart';
import 'json.dart';
import 'order.dart';

class TopProduct {
  const TopProduct(this.id, this.title, this.picture, this.units);
  factory TopProduct.fromJson(Json j) =>
      TopProduct(asInt(j['id']), asStrOr(j['title']), asStr(j['picture']), asInt(j['units']));
  final int id;
  final String title;
  final String? picture;
  final int units;
}

/// One bar of the sales chart.
class SeriesPoint {
  const SeriesPoint(this.label, this.value);
  factory SeriesPoint.fromJson(Json j) => SeriesPoint(asStrOr(j['label']), asInt(j['value']));
  final String label;
  final int value;
}

/// Revenue and orders for one dashboard period (`today`, `7d`, `30d`), with
/// the change against the previous period of the same length.
class DashPeriod {
  const DashPeriod({
    required this.revenue,
    required this.orders,
    this.revenueChangePct,
    this.ordersChange,
    this.series = const [],
  });

  factory DashPeriod.fromJson(Json j) => DashPeriod(
        revenue: asInt(j['revenue']),
        orders: asInt(j['orders']),
        revenueChangePct: asIntOrNull(j['revenue_change_pct']),
        ordersChange: asIntOrNull(j['orders_change']),
        series: asList(j['series'], SeriesPoint.fromJson),
      );

  final int revenue;
  final int orders;
  final int? revenueChangePct;
  final int? ordersChange;
  final List<SeriesPoint> series;
}

/// Instalment recovery on the brand's financed orders.
class Recovery {
  const Recovery({required this.financed, required this.recovered, required this.overdue});

  factory Recovery.fromJson(Json j) => Recovery(
        financed: asInt(j['financed']),
        recovered: asInt(j['recovered']),
        overdue: asInt(j['overdue_instalments']),
      );

  final int financed;
  final int recovered;
  final int overdue;

  double get ratio => financed <= 0 ? 0 : (recovered / financed).clamp(0, 1).toDouble();
}

/// `GET dashboard`, §8.3. [periods], [ordersPending], [ordersVerification]
/// and [recovery] are newer, optional fields: the screen hides what the
/// server doesn't send yet.
class Dashboard {
  const Dashboard({
    required this.catalogueTotal,
    required this.cataloguePublished,
    required this.cataloguePending,
    required this.catalogueOutOfStock,
    required this.ordersTotal,
    required this.ordersLast30,
    required this.ordersValue,
    required this.sellerSourced,
    required this.openBulkRequests,
    required this.topProducts,
    required this.latestOrders,
    this.ordersPending,
    this.ordersVerification,
    this.periods = const {},
    this.recovery,
  });

  /// Period keys in display order.
  static const periodKeys = ['today', '7d', '30d'];

  factory Dashboard.fromJson(Json j) {
    final c = asMap(j['catalogue']);
    final o = asMap(j['orders']);
    final periods = asMap(j['periods']);
    final recovery = asMapOrNull(j['recovery']);
    return Dashboard(
      catalogueTotal: asInt(c['total']),
      cataloguePublished: asInt(c['published']),
      cataloguePending: asInt(c['pending']),
      catalogueOutOfStock: asInt(c['out_of_stock']),
      ordersTotal: asInt(o['total']),
      ordersLast30: asInt(o['last_30_days']),
      ordersValue: asInt(o['value']),
      sellerSourced: asInt(o['seller_sourced']),
      openBulkRequests: asInt(j['open_bulk_requests']),
      topProducts: asList(j['top_products'], TopProduct.fromJson),
      latestOrders: asList(j['latest_orders'], OrderSummary.fromJson),
      ordersPending: asIntOrNull(o['pending']),
      ordersVerification: asIntOrNull(o['verification']),
      periods: {
        for (final k in periodKeys)
          if (asMapOrNull(periods[k]) != null) k: DashPeriod.fromJson(asMap(periods[k])),
      },
      recovery: recovery == null ? null : Recovery.fromJson(recovery),
    );
  }

  final int? ordersPending;
  final int? ordersVerification;
  final Map<String, DashPeriod> periods;
  final Recovery? recovery;

  /// A brand that hasn't listed anything yet.
  bool get isNewSeller => catalogueTotal == 0 && ordersTotal == 0;

  final int catalogueTotal;
  final int cataloguePublished;
  final int cataloguePending;
  final int catalogueOutOfStock;
  final int ordersTotal;
  final int ordersLast30;
  final int ordersValue;
  final int sellerSourced;
  final int openBulkRequests;
  final List<TopProduct> topProducts;
  final List<OrderSummary> latestOrders;
}

class PageSlide {
  const PageSlide({this.tag = '', this.heading = '', this.text = ''});
  factory PageSlide.fromJson(Json j) =>
      PageSlide(tag: asStrOr(j['tag']), heading: asStrOr(j['heading']), text: asStrOr(j['text']));
  final String tag;
  final String heading;
  final String text;
}

class FeaturedProduct {
  const FeaturedProduct(this.id, this.title, this.status, this.picture);
  factory FeaturedProduct.fromJson(Json j) =>
      FeaturedProduct(asInt(j['id']), asStrOr(j['title']), asStrOr(j['status']), asStr(j['picture']));
  final int id;
  final String title;
  final String status;
  final String? picture;
}

/// `GET page`, §8.8. `heroIntro`/`slides` are the *effective* copy.
class BrandPage {
  const BrandPage({
    required this.brand,
    required this.heroIntro,
    required this.slides,
    required this.maxSlides,
    required this.featured,
    required this.publishedCount,
  });

  factory BrandPage.fromJson(Json j) {
    final content = asMap(j['content']);
    return BrandPage(
      brand: Brand.fromJson(asMap(j['brand'])),
      heroIntro: asStrOr(content['hero_intro']),
      slides: asList(content['slides'], PageSlide.fromJson),
      maxSlides: asInt(j['max_slides'], 2),
      featured: asList(j['featured'], FeaturedProduct.fromJson),
      publishedCount: asInt(j['published_count']),
    );
  }

  final Brand brand;
  final String heroIntro;
  final List<PageSlide> slides;
  final int maxSlides;
  final List<FeaturedProduct> featured;
  final int publishedCount;
}
