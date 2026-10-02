import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/images.dart';
import '../models/json.dart';
import '../models/product.dart';

/// Everything the product form sends (§8.4). Variant lists are replaced on
/// every save, so the full set is always sent.
class ProductInput {
  ProductInput({
    required this.title,
    required this.categoryId,
    required this.brandId,
    required this.price,
    required this.minAdvancePrice,
    required this.short,
    this.detailPageTitle,
    this.long,
    this.picture,
    this.gallery = const [],
    this.colors = const [],
    this.memories = const {},
    this.sizes = const {},
  });

  final String title;
  final String? detailPageTitle;
  final int categoryId;
  final int brandId;
  final int price;
  final int minAdvancePrice;
  final String short;
  final String? long;
  final PickedImage? picture;
  final List<PickedImage> gallery;
  final List<int> colors;

  /// variant id → price
  final Map<int, int> memories;
  final Map<int, int> sizes;

  FormData toFormData() {
    final form = FormData();
    void field(String k, Object? v) {
      if (v != null) form.fields.add(MapEntry(k, v.toString()));
    }

    field('title', title);
    field('detail_page_title', detailPageTitle ?? '');
    field('category_id', categoryId);
    field('brand_id', brandId);
    field('price', price);
    field('min_advance_price', minAdvancePrice);
    field('short', short);
    field('long', long ?? '');
    for (final c in colors) {
      field('colors[]', c);
    }
    memories.forEach((id, p) {
      field('memories[name][]', id);
      field('memories[price_$id]', p);
    });
    sizes.forEach((id, p) {
      field('sizes[name][]', id);
      field('sizes[price_$id]', p);
    });
    if (picture != null) form.files.add(MapEntry('picture', picture!.toMultipart()));
    for (final g in gallery) {
      form.files.add(MapEntry('gallery_images[]', g.toMultipart()));
    }
    return form;
  }
}

class InventoryPage {
  const InventoryPage(this.page, this.inStock, this.outOfStock);
  final Paged<ProductSummary> page;
  final int inStock;
  final int outOfStock;
}

class CatalogueRepository {
  CatalogueRepository(this._api);
  final ApiClient _api;

  Future<Paged<ProductSummary>> products({String? q, String? status, int page = 1}) async {
    final res = await _api.get('products', query: {'q': q, 'status': status, 'page': page});
    return Paged.fromJson(res.map, ProductSummary.fromJson);
  }

  Future<ProductFormOptions> formOptions() async =>
      ProductFormOptions.fromJson((await _api.get('products/form-options')).map);

  Future<ProductDetail> product(int id) async =>
      ProductDetail.fromJson((await _api.get('products/$id')).map);

  Future<ProductDetail> create(ProductInput input) async =>
      ProductDetail.fromJson((await _api.post('products', data: input.toFormData())).map);

  Future<ProductDetail> update(int id, ProductInput input) async =>
      ProductDetail.fromJson((await _api.post('products/$id/update', data: input.toFormData())).map);

  Future<bool> toggleFeatured(int id) async =>
      asBool((await _api.post('products/$id/feature')).map['brand_featured']);

  Future<void> deleteGalleryImage(int productId, int imageId) =>
      _api.delete('products/$productId/gallery/$imageId');

  /// `409` if the product has ever been ordered.
  Future<void> delete(int id) => _api.delete('products/$id');

  Future<InventoryPage> inventory({String? q, String? availability, int page = 1}) async {
    final res = await _api.get('inventory', query: {'q': q, 'availability': availability, 'page': page});
    final summary = asMap(res.map['summary']);
    return InventoryPage(
      Paged.fromJson(res.map, ProductSummary.fromJson),
      asInt(summary['in_stock']),
      asInt(summary['out_of_stock']),
    );
  }

  /// Applies immediately. Returns the new `{status, stock}`.
  Future<(String, int)> setStock(int id, {required bool available, int? stock}) async {
    final res = await _api.post('inventory/$id', data: {
      'available': available ? 1 : 0,
      if (available) 'stock': stock,
    });
    return (asStrOr(res.map['status']), asInt(res.map['stock']));
  }
}

final catalogueRepositoryProvider = Provider((ref) => CatalogueRepository(ref.watch(apiClientProvider)));
