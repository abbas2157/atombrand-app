import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/api/atom_server.dart';
import '../../../core/app_providers.dart';
import '../../../core/session/session_controller.dart';
import 'outlet_models.dart';

/// Outlets calls (atomshop `Api\BrandApp\OutletsController`, owner only).
abstract interface class OutletsRepository {
  /// `GET outlets?p=`: every outlet with its figures for the period.
  Future<ApiResult<OutletList>> outlets(OutletPeriod period);

  /// `GET outlets/{id}`: with `open_orders` and this month's figures.
  Future<ApiResult<BrandOutlet>> outlet(int id);

  /// `POST outlets`.
  Future<ApiResult<BrandOutlet>> add(OutletDraft draft);

  /// `POST outlets/{id}` (a closed outlet can't be changed).
  Future<ApiResult<BrandOutlet>> update(int id, OutletDraft draft);

  /// `POST outlets/{id}/status`.
  Future<ApiResult<BrandOutlet>> setStatus(int id, OutletStatus status);

  /// The cities an outlet can be in or serve, for an older server without
  /// [formOptions]: the site's public `GET api/cities`.
  Future<ApiResult<List<City>>> cities();

  /// `GET outlets/form-options?outlet_id=`: cities (with the ones other
  /// outlets serve), who can run it and who runs it now.
  Future<ApiResult<OutletFormOptions>> formOptions({int? outletId});

  /// `GET orders?cash=1&outlet_id=`: the outlet's latest orders.
  Future<ApiResult<List<OutletOrder>>> latestOrders(int outletId);
}

class ApiOutletsRepository implements OutletsRepository {
  const ApiOutletsRepository(this._api);

  final ApiClient _api;

  static BrandOutlet _outlet(Object? d) =>
      BrandOutlet.fromJson(Json.map(d)['outlet']);

  @override
  Future<ApiResult<OutletList>> outlets(OutletPeriod period) =>
      _api.get('outlets', query: {'p': period.key}, parse: OutletList.fromJson);

  @override
  Future<ApiResult<BrandOutlet>> outlet(int id) =>
      _api.get('outlets/$id', parse: _outlet);

  @override
  Future<ApiResult<BrandOutlet>> add(OutletDraft draft) =>
      _api.post('outlets', body: draft.toBody(), parse: _outlet);

  @override
  Future<ApiResult<BrandOutlet>> update(int id, OutletDraft draft) => _api.post(
    'outlets/$id',
    body: draft.toBody()..remove('opened_on'),
    parse: _outlet,
  );

  @override
  Future<ApiResult<BrandOutlet>> setStatus(int id, OutletStatus status) => _api
      .post('outlets/$id/status', body: {'status': status.key}, parse: _outlet);

  @override
  Future<ApiResult<List<City>>> cities() => _api.get(
    '${AtomServer.site}api/cities',
    parse: (d) => [
      for (final c in Json.list(d))
        if (Json.integer(Json.map(c)['id']) case final id?)
          (id: id, title: Json.str(Json.map(c)['title']) ?? ''),
    ]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase())),
  );

  @override
  Future<ApiResult<OutletFormOptions>> formOptions({int? outletId}) => _api.get(
    'outlets/form-options',
    query: {'outlet_id': ?outletId},
    parse: OutletFormOptions.fromJson,
  );

  @override
  Future<ApiResult<List<OutletOrder>>> latestOrders(int outletId) => _api.get(
    'orders',
    // this month's (the page's "Orders this month"), newest first
    query: {'cash': 1, 'outlet_id': outletId, 'from': _monthStart()},
    parse: (d) => ApiPage.fromJson(d, OutletOrder.fromJson).items,
  );
}

final outletsRepositoryProvider = Provider<OutletsRepository>(
  (ref) => ApiOutletsRepository(ref.read(apiClientProvider)),
);

Object? _brandKey(Ref ref) => ref.watch(
  sessionProvider.select((s) => s is SignedIn ? s.session.userId : null),
);

T _value<T>(ApiResult<T> r) => switch (r) {
  ApiOk(:final value) => value,
  ApiErr(:final failure) => throw failure,
};

/// `GET outlets?p=`.
final outletListProvider = FutureProvider.autoDispose
    .family<OutletList, OutletPeriod>((ref, period) async {
      _brandKey(ref);
      return _value(await ref.read(outletsRepositoryProvider).outlets(period));
    });

/// `GET outlets/{id}`.
final outletProvider = FutureProvider.autoDispose.family<BrandOutlet, int>((
  ref,
  id,
) async {
  _brandKey(ref);
  return _value(await ref.read(outletsRepositoryProvider).outlet(id));
});

/// The outlet's latest orders (11.9's Orders this month).
final outletOrdersProvider = FutureProvider.autoDispose
    .family<List<OutletOrder>, int>((ref, id) async {
      _brandKey(ref);
      return _value(await ref.read(outletsRepositoryProvider).latestOrders(id));
    });

/// Every city, kept while the app runs (it hardly changes).
final citiesProvider = FutureProvider<List<City>>((ref) async {
  return _value(await ref.read(outletsRepositoryProvider).cities());
});

/// The form's choices for a new outlet (null) or the one being changed.
/// Null when the server has no `outlets/form-options` yet (404): the form
/// then uses [citiesProvider], the outlet list and the team list.
final outletFormOptionsProvider = FutureProvider.autoDispose
    .family<OutletFormOptions?, int?>((ref, outletId) async {
      _brandKey(ref);
      final r = await ref
          .read(outletsRepositoryProvider)
          .formOptions(outletId: outletId);
      return switch (r) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) when failure.kind == ApiFailureKind.notFound =>
          null,
        ApiErr(:final failure) => throw failure,
      };
    });

/// Reads the outlets again after a change.
void refreshOutlets(WidgetRef ref) => ref
  ..invalidate(outletListProvider)
  ..invalidate(outletProvider)
  ..invalidate(outletFormOptionsProvider);

/// The first of this month as the server's `from` (yyyy-mm-dd).
String _monthStart() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-01';
}
