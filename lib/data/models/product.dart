import 'json.dart';

class IdTitle {
  const IdTitle(this.id, this.title);
  factory IdTitle.fromJson(Json j) => IdTitle(asInt(j['id']), asStrOr(j['title'], asStrOr(j['name'])));
  final int id;
  final String title;
}

/// Product summary (list item), §8.4.
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.title,
    required this.status,
    this.uuid,
    this.prNumber,
    this.picture,
    this.price = 0,
    this.minAdvancePrice = 0,
    this.stock = 0,
    this.brandFeatured = false,
    this.category,
    this.displayBrand,
    this.publicUrl,
    this.createdAt,
    this.updatedAt,
    this.canManageStock = false,
  });

  factory ProductSummary.fromJson(Json j) => ProductSummary(
        id: asInt(j['id']),
        uuid: asStr(j['uuid']),
        prNumber: asStr(j['pr_number']),
        title: asStrOr(j['title']),
        picture: asStr(j['picture']),
        price: asInt(j['price']),
        minAdvancePrice: asInt(j['min_advance_price']),
        status: asStrOr(j['status'], 'Pending'),
        stock: asInt(j['stock']),
        brandFeatured: asBool(j['brand_featured']),
        category: asMapOrNull(j['category']) == null ? null : IdTitle.fromJson(asMap(j['category'])),
        displayBrand: asMapOrNull(j['display_brand']) == null ? null : IdTitle.fromJson(asMap(j['display_brand'])),
        publicUrl: asStr(j['public_url']),
        createdAt: asStr(j['created_at']),
        updatedAt: asStr(j['updated_at']),
        canManageStock: asBool(j['can_manage_stock']),
      );

  final int id;
  final String? uuid;
  final String? prNumber;
  final String title;
  final String? picture;
  final int price;
  final int minAdvancePrice;
  final String status;
  final int stock;
  final bool brandFeatured;
  final IdTitle? category;
  final IdTitle? displayBrand;
  final String? publicUrl;
  final String? createdAt;
  final String? updatedAt;
  final bool canManageStock;

  bool get isLive => status == 'Published';
  bool get isOutOfStock => status == 'Out of Stock';
}

class VariantPrice {
  const VariantPrice(this.id, this.price);
  factory VariantPrice.fromJson(Json j) => VariantPrice(asInt(j['id']), asInt(j['price']));
  final int id;
  final int price;
}

class GalleryImage {
  const GalleryImage(this.id, this.url);
  factory GalleryImage.fromJson(Json j) => GalleryImage(asInt(j['id']), asStrOr(j['url']));
  final int id;
  final String url;
}

/// `GET products/{id}`: summary plus the editable detail.
class ProductDetail {
  const ProductDetail({
    required this.summary,
    this.detailPageTitle,
    this.categoryId,
    this.brandId,
    this.short,
    this.long,
    this.colors = const [],
    this.memories = const [],
    this.sizes = const [],
    this.gallery = const [],
  });

  factory ProductDetail.fromJson(Json j) => ProductDetail(
        summary: ProductSummary.fromJson(j),
        detailPageTitle: asStr(j['detail_page_title']),
        categoryId: asIntOrNull(j['category_id']),
        brandId: asIntOrNull(j['brand_id']),
        short: asStr(j['short']),
        long: asStr(j['long']),
        colors: asIntList(j['colors']),
        memories: asList(j['memories'], VariantPrice.fromJson),
        sizes: asList(j['sizes'], VariantPrice.fromJson),
        gallery: asList(j['gallery'], GalleryImage.fromJson),
      );

  final ProductSummary summary;
  final String? detailPageTitle;
  final int? categoryId;
  final int? brandId;
  final String? short;
  final String? long;
  final List<int> colors;
  final List<VariantPrice> memories;
  final List<VariantPrice> sizes;
  final List<GalleryImage> gallery;
}

class FormBrand {
  const FormBrand(this.id, this.title, this.categoryIds);
  factory FormBrand.fromJson(Json j) =>
      FormBrand(asInt(j['id']), asStrOr(j['title']), asIntList(j['category_ids']));
  final int id;
  final String title;
  final List<int> categoryIds;
}

class VariantOption {
  const VariantOption(this.id, this.name, {this.unit});
  factory VariantOption.fromJson(Json j) => VariantOption(
        asInt(j['id']),
        asStrOr(j['title'], asStrOr(j['name'], asStrOr(j['value']))),
        unit: asStr(j['unit']),
      );
  final int id;
  final String name;
  final String? unit;

  String get label => unit == null || name.endsWith(unit!) ? name : '$name $unit';
}

/// `GET products/form-options`.
class ProductFormOptions {
  const ProductFormOptions({
    required this.categories,
    required this.brands,
    required this.colors,
    required this.memories,
    required this.sizes,
    required this.colorCategories,
    required this.memoryCategories,
    required this.sizeCategories,
  });

  factory ProductFormOptions.fromJson(Json j) {
    final vc = asMap(j['variant_categories']);
    return ProductFormOptions(
      categories: asList(j['categories'], IdTitle.fromJson),
      brands: asList(j['brands'], FormBrand.fromJson),
      colors: asList(j['colors'], VariantOption.fromJson),
      memories: asList(j['memories'], VariantOption.fromJson),
      sizes: asList(j['sizes'], VariantOption.fromJson),
      colorCategories: vc.containsKey('colors') ? asIntList(vc['colors']) : const [1, 2, 3],
      memoryCategories: vc.containsKey('memories') ? asIntList(vc['memories']) : const [1, 2],
      sizeCategories: vc.containsKey('sizes') ? asIntList(vc['sizes']) : const [4],
    );
  }

  final List<IdTitle> categories;
  final List<FormBrand> brands;
  final List<VariantOption> colors;
  final List<VariantOption> memories;
  final List<VariantOption> sizes;
  final List<int> colorCategories;
  final List<int> memoryCategories;
  final List<int> sizeCategories;
}
