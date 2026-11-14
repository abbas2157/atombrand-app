import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_client.dart';

/// A product's `status` as the server stores it. The brand never sets it:
/// Atomshop publishes, puts on hold or closes; the brand only moves a live
/// product between [published] and [outOfStock].
abstract final class ProductStatus {
  static const published = 'Published';
  static const pending = 'Pending';
  static const outOfStock = 'Out of Stock';
  static const onHold = 'On hold';
  static const closed = 'Closed';

  /// The four filter tiles on Products (8.1), in board order.
  static const tiles = [published, pending, outOfStock, onHold];

  /// Live on atomshop.pk (orderable or not): stock can be set, it can be
  /// featured.
  static bool isLive(String status) =>
      status == published || status == outOfStock;

  /// The words the app shows when the server sent no `status_label`.
  static String label(String status, AppLocalizations l) => switch (status) {
    published => l.catStatusLive,
    pending => l.catStatusInReview,
    outOfStock => l.catStatusOutOfStock,
    onHold => l.catStatusOnHold,
    closed => l.catStatusClosed,
    _ => status,
  };
}

/// Units the brand's inventory has for a live product (Inventory add-on).
@immutable
class Availability {
  const Availability({
    required this.units,
    this.warehouses = 0,
    this.level = 'ok',
    this.stockProductId,
  });

  final int units;
  final int warehouses;

  /// `out` (0), `low` (at or under the shop's low-stock level) or `ok`.
  final String level;

  /// The inventory's own product id, for Stock and serials (9.4), when the
  /// server sends it.
  final int? stockProductId;

  static Availability? fromJson(Object? v) {
    if (v is! Map) return null;
    final m = Json.map(v);
    final units = Json.integer(m['units']);
    if (units == null) return null;
    return Availability(
      units: units,
      warehouses: Json.integer(m['warehouses']) ?? 0,
      level: Json.str(m['level']) ?? 'ok',
      stockProductId: Json.integer(m['stock_product_id']),
    );
  }
}

/// A row of Products (8.1): the product summary plus what the list shows.
@immutable
class ProductRow {
  const ProductRow({
    required this.id,
    required this.title,
    required this.status,
    this.uuid,
    this.prNumber,
    this.picture,
    this.price = 0,
    this.minAdvance = 0,
    this.serverLabel,
    this.statusNote,
    this.holdReason,
    this.stock = 0,
    this.featured = false,
    this.atompay = false,
    this.atompayBrandWide = false,
    this.categoryId,
    this.categoryTitle,
    this.displayBrand,
    this.publicUrl,
    this.createdAt,
    this.variantsSummary,
    this.available,
  });

  final int id;
  final String? uuid;
  final String? prNumber;
  final String title;
  final String? picture;
  final int price;
  final int minAdvance;
  final String status;

  /// The server's words for the status (`status_label`).
  final String? serverLabel;
  final String? statusNote;
  final String? holdReason;
  final int stock;
  final bool featured;
  final bool atompay;
  final bool atompayBrandWide;
  final int? categoryId;
  final String? categoryTitle;
  final String? displayBrand;
  final String? publicUrl;
  final DateTime? createdAt;

  /// "2 colours, 3 storage"; "One version" when there are none.
  final String? variantsSummary;

  /// Inventory add-on only; null when it is off or the product isn't
  /// stocked.
  final Availability? available;

  String statusLabel(AppLocalizations l) =>
      serverLabel ?? ProductStatus.label(status, l);

  bool get isLive => ProductStatus.isLive(status);

  /// AtomPay is on for customers: the product's switch or the whole brand.
  bool get atompayOn => atompay || atompayBrandWide;

  /// Why Atomshop is holding it: their reason once they record one, else
  /// the status note.
  String? get holdWhy => holdReason ?? statusNote;

  factory ProductRow.fromJson(Object? data) {
    final m = Json.map(data);
    final variants = Json.map(m['variants']);
    final category = Json.map(m['category']);
    final brand = Json.map(m['display_brand']);
    return ProductRow(
      id: Json.integer(m['id']) ?? 0,
      uuid: Json.str(m['uuid']),
      prNumber: Json.str(m['pr_number']),
      title: Json.str(m['title']) ?? '',
      picture: Json.str(m['picture']),
      price: Json.integer(m['price']) ?? 0,
      minAdvance: Json.integer(m['min_advance_price']) ?? 0,
      status: Json.str(m['status']) ?? ProductStatus.pending,
      serverLabel: Json.str(m['status_label']),
      statusNote: Json.str(m['status_note']),
      holdReason: Json.str(m['hold_reason']),
      stock: Json.integer(m['stock']) ?? 0,
      featured: Json.flag(m['brand_featured']),
      atompay: Json.flag(m['atompay_eligible']),
      atompayBrandWide: Json.flag(m['atompay_brand_wide']),
      categoryId:
          Json.integer(category['id']) ?? Json.integer(m['category_id']),
      categoryTitle: Json.str(category['title']),
      displayBrand: Json.str(brand['title']),
      publicUrl: Json.str(m['public_url']),
      createdAt: DateTime.tryParse(Json.str(m['created_at']) ?? ''),
      variantsSummary: Json.str(variants['summary']),
      available: Availability.fromJson(m['available']),
    );
  }

  ProductRow copyWith({
    bool? featured,
    bool? atompay,
    bool? atompayBrandWide,
    String? status,
    String? statusLabel,
    int? stock,
  }) => ProductRow(
    id: id,
    uuid: uuid,
    prNumber: prNumber,
    title: title,
    picture: picture,
    price: price,
    minAdvance: minAdvance,
    status: status ?? this.status,
    // A new status drops the server's label for it, so the app's words show.
    serverLabel: status == null ? serverLabel : statusLabel,
    statusNote: status == null ? statusNote : null,
    holdReason: holdReason,
    stock: stock ?? this.stock,
    featured: featured ?? this.featured,
    atompay: atompay ?? this.atompay,
    atompayBrandWide: atompayBrandWide ?? this.atompayBrandWide,
    categoryId: categoryId,
    categoryTitle: categoryTitle,
    displayBrand: displayBrand,
    publicUrl: publicUrl,
    createdAt: createdAt,
    variantsSummary: variantsSummary,
    available: available,
  );
}

/// One page of Products with the status counts beside it.
@immutable
class ProductsPage {
  const ProductsPage({
    required this.rows,
    this.page = 1,
    this.hasMore = false,
    this.counts = const {},
    this.total = 0,
    this.inventory = false,
    this.fromCopy = false,
  });

  final List<ProductRow> rows;
  final int page;
  final bool hasMore;

  /// `status → count`, for the tiles.
  final Map<String, int> counts;

  /// Every product the brand has, whatever its status.
  final int total;

  /// The server says the Inventory add-on is on (available units shown).
  final bool inventory;

  /// Read from the phone's offline copy, not the server.
  final bool fromCopy;

  int countOf(String status) => counts[status] ?? 0;
}

/// An id and a name from the form's dropdowns.
@immutable
class NamedOption {
  const NamedOption(this.id, this.title, {this.categoryIds = const []});

  final int id;
  final String title;

  /// For a brand: the categories it already sells in.
  final List<int> categoryIds;

  factory NamedOption.fromJson(Object? data) {
    final m = Json.map(data);
    final unit = Json.str(m['unit']);
    final title = Json.str(m['title']) ?? '';
    return NamedOption(
      Json.integer(m['id']) ?? 0,
      // Sizes carry their unit: 55 + " → 55".
      unit == null ? title : '$title$unit'.trim(),
      categoryIds: [
        for (final c in Json.list(m['category_ids'])) ?Json.integer(c),
      ],
    );
  }
}

/// `GET products/form-options`.
@immutable
class FormOptions {
  const FormOptions({
    this.categories = const [],
    this.brands = const [],
    this.colors = const [],
    this.memories = const [],
    this.sizes = const [],
    this.colorCategories = const [1, 2, 3],
    this.memoryCategories = const [1, 2],
    this.sizeCategories = const [4],
  });

  final List<NamedOption> categories;
  final List<NamedOption> brands;
  final List<NamedOption> colors;
  final List<NamedOption> memories;
  final List<NamedOption> sizes;
  final List<int> colorCategories;
  final List<int> memoryCategories;
  final List<int> sizeCategories;

  factory FormOptions.fromJson(Object? data) {
    final m = Json.map(data);
    List<NamedOption> opts(String key) => [
      for (final o in Json.list(m[key])) NamedOption.fromJson(o),
    ];
    final gates = Json.map(m['variant_categories']);
    List<int>? ids(String key) => gates.containsKey(key)
        ? [for (final c in Json.list(gates[key])) ?Json.integer(c)]
        : null;
    return FormOptions(
      categories: opts('categories'),
      brands: opts('brands'),
      colors: opts('colors'),
      memories: opts('memories'),
      sizes: opts('sizes'),
      colorCategories: ids('colors') ?? const [1, 2, 3],
      memoryCategories: ids('memories') ?? const [1, 2],
      sizeCategories: ids('sizes') ?? const [4],
    );
  }

  String? nameOf(List<NamedOption> list, int? id) {
    if (id == null) return null;
    for (final o in list) {
      if (o.id == id) return o.title;
    }
    return null;
  }
}

/// A storage or size the product comes in, with its own price.
@immutable
class VariantPrice {
  const VariantPrice(this.id, this.price);

  final int id;
  final int price;

  static VariantPrice? fromJson(Object? data) {
    final m = Json.map(data);
    final id = Json.integer(m['id']);
    return id == null ? null : VariantPrice(id, Json.integer(m['price']) ?? 0);
  }
}

/// A gallery photo already on the server.
@immutable
class GalleryImage {
  const GalleryImage(this.id, this.url);

  final int id;
  final String url;
}

/// `GET products/{id}`: everything the form edits.
@immutable
class ProductDetail {
  const ProductDetail({
    required this.row,
    this.detailTitle,
    this.categoryId,
    this.brandId,
    this.short,
    this.long,
    this.colors = const [],
    this.memories = const [],
    this.sizes = const [],
    this.gallery = const [],
    this.canManageStock = false,
  });

  final ProductRow row;
  final String? detailTitle;
  final int? categoryId;
  final int? brandId;
  final String? short;
  final String? long;
  final List<int> colors;
  final List<VariantPrice> memories;
  final List<VariantPrice> sizes;
  final List<GalleryImage> gallery;
  final bool canManageStock;

  factory ProductDetail.fromJson(Object? data) {
    final m = Json.map(data);
    return ProductDetail(
      row: ProductRow.fromJson(m),
      detailTitle: Json.str(m['detail_page_title']),
      categoryId: Json.integer(m['category_id']),
      brandId: Json.integer(m['brand_id']),
      short: Json.str(m['short']),
      long: Json.str(m['long']),
      colors: [for (final c in Json.list(m['colors'])) ?Json.integer(c)],
      memories: [
        for (final v in Json.list(m['memories'])) ?VariantPrice.fromJson(v),
      ],
      sizes: [for (final v in Json.list(m['sizes'])) ?VariantPrice.fromJson(v)],
      gallery: [
        for (final g in Json.list(m['gallery']))
          if (Json.integer(Json.map(g)['id']) case final id?)
            GalleryImage(id, Json.str(Json.map(g)['url']) ?? ''),
      ],
      canManageStock: Json.flag(m['can_manage_stock']),
    );
  }
}

/// One cover slide on the brand page.
@immutable
class PageSlide {
  const PageSlide({this.tag = '', this.heading = '', this.text = ''});

  final String tag;
  final String heading;
  final String text;

  factory PageSlide.fromJson(Object? data) {
    final m = Json.map(data);
    return PageSlide(
      tag: Json.str(m['tag']) ?? '',
      heading: Json.str(m['heading']) ?? '',
      text: Json.str(m['text']) ?? '',
    );
  }
}

/// A product featured on the brand page.
@immutable
class FeaturedProduct {
  const FeaturedProduct({
    required this.id,
    required this.title,
    required this.status,
    this.picture,
  });

  final int id;
  final String title;
  final String status;
  final String? picture;

  factory FeaturedProduct.fromJson(Object? data) {
    final m = Json.map(data);
    return FeaturedProduct(
      id: Json.integer(m['id']) ?? 0,
      title: Json.str(m['title']) ?? '',
      status: Json.str(m['status']) ?? '',
      picture: Json.str(m['picture']),
    );
  }
}

/// `GET page`: the brand's public page.
@immutable
class BrandPageData {
  const BrandPageData({
    required this.title,
    this.slug,
    this.tagline,
    this.logo,
    this.banner,
    this.publicUrl,
    this.supportEmail,
    this.supportPhone,
    this.description,
    this.website,
    this.heroIntro,
    this.slides = const [],
    this.maxSlides = 2,
    this.featured = const [],
    this.featuredShown = 5,
    this.featuredCount = 0,
    this.publishedCount = 0,
  });

  final String title;
  final String? slug;
  final String? tagline;
  final String? logo;
  final String? banner;
  final String? publicUrl;
  final String? supportEmail;
  final String? supportPhone;
  final String? description;
  final String? website;
  final String? heroIntro;
  final List<PageSlide> slides;
  final int maxSlides;
  final List<FeaturedProduct> featured;
  final int featuredShown;
  final int featuredCount;
  final int publishedCount;

  factory BrandPageData.fromJson(Object? data) {
    final m = Json.map(data);
    final b = Json.map(m['brand']);
    final c = Json.map(m['content']);
    return BrandPageData(
      title: Json.str(b['title']) ?? '',
      slug: Json.str(b['slug']),
      tagline: Json.str(b['tagline']),
      logo: Json.str(b['logo']),
      banner: Json.str(b['banner']),
      publicUrl: Json.str(b['public_url']),
      supportEmail: Json.str(b['support_email']),
      supportPhone: Json.str(b['support_phone']),
      description: Json.str(b['description']),
      website: Json.str(b['website']),
      heroIntro: Json.str(c['hero_intro']),
      slides: [for (final s in Json.list(c['slides'])) PageSlide.fromJson(s)],
      maxSlides: Json.integer(m['max_slides']) ?? 2,
      featured: [
        for (final f in Json.list(m['featured'])) FeaturedProduct.fromJson(f),
      ],
      featuredShown: Json.integer(m['featured_shown']) ?? 5,
      featuredCount: Json.integer(m['featured_count']) ?? 0,
      publishedCount: Json.integer(m['published_count']) ?? 0,
    );
  }
}
