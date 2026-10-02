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

/// `GET dashboard`, §8.3.
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
  });

  factory Dashboard.fromJson(Json j) {
    final c = asMap(j['catalogue']);
    final o = asMap(j['orders']);
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
    );
  }

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
