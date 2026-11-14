import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/session/session_controller.dart';
import '../../sync/data/sync_providers.dart';
import 'catalogue_logic.dart';
import 'catalogue_models.dart';

/// The brand's catalogue and public page (`/api/brand-app`, BRAND_APP.md
/// 8.4 and 8.8). Catalogue writes are never saved offline (`product.save`
/// is on the sync contract's "never" list); with no signal the list is read
/// from the phone's copy.
class CatalogueRepository {
  CatalogueRepository(this._api, {this.copy, this.store});

  final ApiClient _api;

  /// The offline copy, when the Offline add-on is on and the copy is open.
  final OfflineCopy? copy;
  final SyncStore? store;

  /// `GET products?q=&status=&sort=&page=`, or the copy's products with no
  /// signal. [sort] is a `ProductSort.serverKey`.
  Future<ApiResult<ProductsPage>> products({
    String search = '',
    String? status,
    String? sort,
    int page = 1,
  }) async {
    Future<ProductsPage?> fromCopy() async {
      final c = copy;
      final s = store;
      if (c == null || s == null || page != 1) return null;
      final rows = await s.rows('products', shopId: c.shopId);
      if (rows.isEmpty) return null;
      return pageFromCopy(
        [for (final r in rows) ProductRow.fromJson(r)],
        search: search,
        status: status,
      );
    }

    final c = copy;
    if (c != null && !c.isOnline()) {
      if (await fromCopy() case final here?) return ApiOk(here);
    }
    final answer = await _api.get(
      'products',
      query: {
        if (search.trim().isNotEmpty) 'q': search.trim(),
        'status': ?status,
        'sort': ?sort,
        if (page > 1) 'page': page,
      },
      parse: (d) {
        final p = ApiPage.fromJson(d, ProductRow.fromJson);
        return ProductsPage(
          rows: p.items,
          page: p.page,
          hasMore: p.hasMore,
          counts: {
            for (final c in Json.list(p.extra['counts']))
              ?Json.str(Json.map(c)['status']):
                  Json.integer(Json.map(c)['count']) ?? 0,
          },
          total: Json.integer(p.extra['total']) ?? p.total,
          inventory: Json.flag(p.extra['inventory']),
        );
      },
    );
    if (answer case ApiErr(:final failure)
        when failure.kind == ApiFailureKind.offline ||
            failure.kind == ApiFailureKind.timeout) {
      if (await fromCopy() case final here?) return ApiOk(here);
    }
    return answer;
  }

  Future<ApiResult<FormOptions>> formOptions() =>
      _api.get('products/form-options', parse: FormOptions.fromJson);

  Future<ApiResult<ProductDetail>> product(int id) =>
      _api.get('products/$id', parse: ProductDetail.fromJson);

  /// `POST products` (new, always In review) or `POST products/{id}/update`.
  /// [gallery] are new photos only; the ones already there stay.
  Future<ApiResult<ProductDetail>> save({
    int? id,
    required Map<String, dynamic> fields,
    File? picture,
    List<File> gallery = const [],
  }) => _api.postForm(
    id == null ? 'products' : 'products/$id/update',
    fields: fields,
    files: {
      'picture': ?picture,
      for (var i = 0; i < gallery.length; i++) 'gallery_images[$i]': gallery[i],
    },
    parse: ProductDetail.fromJson,
  );

  /// Switches "featured on the brand page"; the new value.
  Future<ApiResult<bool>> toggleFeature(int id) => _api.post(
    'products/$id/feature',
    parse: (d) => Json.flag(Json.map(d)['brand_featured']),
  );

  /// Switches AtomPay; `409` when Atomshop made the whole brand eligible.
  Future<ApiResult<bool>> toggleAtompay(int id) => _api.post(
    'products/$id/atompay',
    parse: (d) => Json.flag(Json.map(d)['atompay_eligible']),
  );

  /// `DELETE products/{id}/gallery/{imageId}`.
  Future<ApiResult<void>> deleteGalleryImage(int id, int imageId) =>
      _api.delete('products/$id/gallery/$imageId', parse: (_) {});

  /// `DELETE products/{id}`; `409` once the product has been ordered. The
  /// answer's [ApiOk.message] is the server's sentence for the toast.
  Future<ApiResult<void>> delete(int id) =>
      _api.delete('products/$id', parse: (_) {});

  /// Without the Inventory add-on: in stock with [stock] units, or out of
  /// stock. Applies at once; `409` while the product isn't live.
  Future<ApiResult<({String status, int stock})>> setAvailability(
    int id, {
    required bool available,
    int? stock,
  }) => _api.post(
    'inventory/$id',
    body: {
      'available': available ? 1 : 0,
      'stock': ?(available ? stock : null),
    },
    parse: (d) {
      final m = Json.map(d);
      return (
        status:
            Json.str(m['status']) ??
            (available ? ProductStatus.published : ProductStatus.outOfStock),
        stock: Json.integer(m['stock']) ?? 0,
      );
    },
  );

  Future<ApiResult<BrandPageData>> page() =>
      _api.get('page', parse: BrandPageData.fromJson);

  Future<ApiResult<BrandPageData>> savePage({
    required Map<String, dynamic> fields,
    File? logo,
    File? banner,
  }) => _api.postForm(
    'page/update',
    fields: fields,
    files: {'picture': ?logo, 'banner': ?banner},
    parse: BrandPageData.fromJson,
  );
}

final catalogueRepositoryProvider = Provider<CatalogueRepository>((ref) {
  final copy = ref.watch(offlineCopyProvider);
  return CatalogueRepository(
    ref.read(apiClientProvider),
    copy: copy,
    store: copy == null ? null : ref.read(syncStoreProvider),
  );
});

/// Reloads when the person or the open outlet changes (`X-Outlet` scopes
/// the available units).
Object? _who(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

/// Products' filter as one key: the search, the status tile and the
/// server's sort (`ProductSort.serverKey`).
typedef ProductsQuery = ({String search, String? status, String? sort});

/// The first page of Products for a query; "Show more" reads the rest.
final productsProvider = FutureProvider.autoDispose
    .family<ProductsPage, ProductsQuery>((ref, q) async {
      _who(ref);
      final r = await ref
          .read(catalogueRepositoryProvider)
          .products(search: q.search, status: q.status, sort: q.sort);
      return switch (r) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

final formOptionsProvider = FutureProvider.autoDispose<FormOptions>((
  ref,
) async {
  _who(ref);
  final r = await ref.read(catalogueRepositoryProvider).formOptions();
  return switch (r) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail, int>((ref, id) async {
      _who(ref);
      final r = await ref.read(catalogueRepositoryProvider).product(id);
      return switch (r) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

final brandPageProvider = FutureProvider.autoDispose<BrandPageData>((
  ref,
) async {
  _who(ref);
  final r = await ref.read(catalogueRepositoryProvider).page();
  return switch (r) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});

/// After a product changes: the list, its detail and the brand page.
void invalidateCatalogue(WidgetRef ref) => ref
  ..invalidate(productsProvider)
  ..invalidate(productDetailProvider)
  ..invalidate(brandPageProvider);
