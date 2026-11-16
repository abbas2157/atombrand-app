import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/data/sync_providers.dart';
import 'stock_copy.dart';
import 'stock_models.dart';
import 'stock_rules.dart';

/// Stock calls (the Inventory add-on, `/api/brand-app/stock*`). Reads need
/// `stock.view`, changes `stock.change`, warehouses `stock.manage`. Off: 403
/// `data.reason = inventory`; lapsed: changes answer 403 `read_only`.
///
/// With the Offline add-on, the list, a product, the forms and a serial
/// read the phone's copy when there is no signal, and stock in, adjust and
/// move wait in the outbox (`stock.in`, `stock.adjust`, `stock.transfer`).
class StockRepository {
  const StockRepository(this._api, {this.offline, this.copy});

  final ApiClient _api;
  final OfflineSaves? offline;

  /// The phone's copy, read when there is no signal.
  final ({StockCopy reader, bool Function() isOnline})? copy;

  /// The server's answer, or the copy's when there is no signal.
  Future<ApiResult<T>> _orCopy<T>(
    Future<ApiResult<T>> Function() online,
    Future<T?> Function(StockCopy copy) fromCopy,
  ) async {
    final c = copy;
    if (c == null) return online();
    if (!c.isOnline()) {
      final here = await _safe(() => fromCopy(c.reader));
      if (here != null) return ApiOk(here);
    }
    final answer = await online();
    if (answer case ApiErr(:final failure)
        when failure.kind == ApiFailureKind.offline ||
            failure.kind == ApiFailureKind.timeout) {
      final here = await _safe(() => fromCopy(c.reader));
      if (here != null) return ApiOk(here);
    }
    return answer;
  }

  static Future<T?> _safe<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on Object {
      return null;
    }
  }

  Future<Saved<T>> _save<T>({
    required String action,
    required Map<String, dynamic> data,
    required Future<ApiResult<T>> Function() online,
    Future<void> Function(SyncStore store, int shopId)? alsoHere,
  }) async {
    final o = offline;
    if (o == null) {
      return switch (await online()) {
        ApiOk(:final value) => SavedOnServer<T>(value),
        ApiErr(:final failure) => SaveFailed<T>(failure),
      };
    }
    return o.save<T>(
      action: action,
      data: data,
      send: online,
      alsoHere: alsoHere,
    );
  }

  /// `GET stock`. [show] is `all`, `in`, `low` (with out) or `out`.
  Future<ApiResult<StockOverview>> overview({
    String show = 'all',
    String query = '',
    int? outletId,
    int? categoryId,
    int page = 1,
  }) => _orCopy(
    () => _api.get(
      'stock',
      query: {
        if (show != 'all') 'show': show,
        if (query.trim().isNotEmpty) 'q': query.trim(),
        'outlet_id': ?outletId,
        'category_id': ?categoryId,
        'page': page,
        'per_page': 20,
      },
      parse: StockOverview.fromJson,
    ),
    (c) => c.overview(show: show, query: query, outletId: outletId, page: page),
  );

  /// `GET stock/products/{id}`.
  Future<ApiResult<ProductStock>> product(int id) => _orCopy(
    () => _api.get('stock/products/$id', parse: ProductStock.fromJson),
    (c) => c.product(id),
  );

  /// `GET stock/units?serial=`: the units with that number (IMEI 1 or 2),
  /// held and delivered ones included. Online only: with no signal the
  /// caller reads the copy's form options instead.
  Future<ApiResult<SerialUnits>> unitsBySerial(String serial) async {
    final c = copy;
    if (c != null && !c.isOnline()) {
      return const ApiErr(ApiFailure(ApiFailureKind.offline));
    }
    return _api.get(
      'stock/units',
      query: {'serial': serial.trim()},
      parse: SerialUnits.fromJson,
    );
  }

  /// `GET stock/form-options`.
  Future<ApiResult<StockFormOptions>> formOptions() => _orCopy(
    () => _api.get('stock/form-options', parse: StockFormOptions.fromJson),
    (c) => c.formOptions(),
  );

  /// `GET stock/history`. [type] `stock_in|sale|moved|adjusted`,
  /// [period] `30|month|90|all`.
  Future<ApiResult<ApiPage<StockMove>>> history({
    String? type,
    String period = '30',
    String query = '',
    int? outletId,
    int? productId,
    int page = 1,
  }) => _api.get(
    'stock/history',
    query: {
      'type': ?type,
      'period': period,
      if (query.trim().isNotEmpty) 'q': query.trim(),
      'outlet_id': ?outletId,
      'product_id': ?productId,
      'page': page,
    },
    parse: (d) => ApiPage.fromJson(d, StockMove.fromJson),
  );

  /// `GET stock/warehouses`.
  Future<ApiResult<WarehouseBook>> warehouses() =>
      _api.get('stock/warehouses', parse: WarehouseBook.fromJson);

  /// `POST stock/warehouses(/{id})`. [inChargeId] is always sent (null
  /// clears it). Never saved offline.
  Future<ApiResult<StockWarehouse>> saveWarehouse({
    int? id,
    required String name,
    required String type,
    required int outletId,
    String? address,
    required bool sellsOnline,
    required bool isDefault,
    String status = 'active',
    int? inChargeId,
  }) => _api.post(
    id == null ? 'stock/warehouses' : 'stock/warehouses/$id',
    body: {
      'name': name.trim(),
      'type': type,
      'brand_outlet_id': outletId,
      'address': (address ?? '').trim().isEmpty ? null : address!.trim(),
      'sells_online': sellsOnline,
      'is_default': isDefault,
      'status': status,
      'in_charge_id': inChargeId,
    },
    parse: (d) => StockWarehouse.fromJson(Json.map(d)['warehouse']),
  );

  /// `POST stock/products/{id}/tracking`. Never saved offline.
  Future<ApiResult<void>> setTracking(
    int productId,
    Tracking tracking, {
    String? prefix,
  }) => _api.post(
    'stock/products/$productId/tracking',
    body: {
      'tracking': tracking.key,
      if (tracking == Tracking.auto)
        'auto_prefix': prefix?.trim().toUpperCase(),
    },
    parse: (_) {},
  );

  /// `POST stock/in`: answers the units' numbers (auto numbers included).
  Future<Saved<List<String>>> stockIn({
    required int variantId,
    required int warehouseId,
    required int qty,
    required DateTime receivedOn,
    List<String> serials = const [],
    String? reference,
    String? note,
  }) {
    final body = <String, dynamic>{
      'variant_id': variantId,
      'warehouse_id': warehouseId,
      'qty': qty,
      if (serials.isNotEmpty) 'serials': serials,
      'moved_on': AtomDates.api(receivedOn),
      if ((reference ?? '').trim().isNotEmpty) 'reference': reference!.trim(),
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
    };
    return _save(
      action: 'stock.in',
      data: body,
      online: () => _api.post(
        'stock/in',
        body: body,
        parse: (d) => [
          for (final s in Json.list(Json.map(d)['serials'])) ?Json.str(s),
        ],
      ),
    );
  }

  /// `POST stock/adjust` out: a unit taken out of stock (stays on record).
  /// Offline, a unit with no id yet is named by [serial].
  Future<Saved<void>> adjustOut({
    required UnitOption unit,
    required String reason,
    required String note,
    required DateTime on,
  }) {
    final body = <String, dynamic>{
      'direction': 'out',
      if (unit.id != null) 'unit_id': unit.id else 'serial': unit.serial,
      'reason': reason,
      'note': note.trim(),
      'moved_on': AtomDates.api(on),
    };
    return _save(
      action: 'stock.adjust',
      data: body,
      online: () => _api.post('stock/adjust', body: body, parse: (_) {}),
      alsoHere: unit.id == null
          ? null
          : (store, shopId) => store.patchRow('stock_units', unit.id!, {
              'status': 'damaged',
            }, shopId: shopId),
    );
  }

  /// `POST stock/adjust` in: a unit found or added back.
  Future<Saved<void>> adjustIn({
    required int variantId,
    required int warehouseId,
    String? serial,
    required String reason,
    required String note,
    required DateTime on,
  }) {
    final body = <String, dynamic>{
      'direction': 'in',
      'variant_id': variantId,
      'warehouse_id': warehouseId,
      if ((serial ?? '').trim().isNotEmpty) 'serial': serial!.trim(),
      'reason': reason,
      'note': note.trim(),
      'moved_on': AtomDates.api(on),
    };
    return _save(
      action: 'stock.adjust',
      data: body,
      online: () => _api.post('stock/adjust', body: body, parse: (_) {}),
    );
  }

  /// `POST stock/transfer`: answers how many moved.
  Future<Saved<int>> transfer({
    required List<UnitOption> units,
    required int toWarehouseId,
    required DateTime on,
    String? note,
  }) {
    final ids = [for (final u in units) ?u.id];
    final serials = [
      for (final u in units)
        if (u.id == null) u.serial,
    ];
    final body = <String, dynamic>{
      'unit_ids': ids,
      if (serials.isNotEmpty) 'serials': serials,
      'to_warehouse_id': toWarehouseId,
      'moved_on': AtomDates.api(on),
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
    };
    return _save(
      action: 'stock.transfer',
      data: body,
      online: () => _api.post(
        'stock/transfer',
        body: body,
        parse: (d) => Json.integer(Json.map(d)['moved']) ?? ids.length,
      ),
      alsoHere: (store, shopId) async {
        for (final id in ids) {
          await store.patchRow('stock_units', id, {
            'warehouse_id': toWarehouseId,
          }, shopId: shopId);
        }
      },
    );
  }
}

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final copy = ref.watch(offlineCopyProvider);
  final session = ref.read(sessionProvider.notifier).current;
  final store = ref.watch(syncStoreProvider);
  return StockRepository(
    ref.read(apiClientProvider),
    offline: ref.watch(offlineSavesProvider),
    copy: copy == null
        ? null
        : (
            reader: StockCopy(
              (table) => store.rows(table, shopId: copy.shopId),
              outletNames: {
                for (final o in session?.outlets ?? const []) o.id: o.name,
              },
            ),
            isOnline: copy.isOnline,
          ),
  );
});

/// Reads again when the person or their outlet changes.
Object? _who(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

T _value<T>(ApiResult<T> r) => switch (r) {
  ApiOk(:final value) => value,
  ApiErr(:final failure) => throw failure,
};

/// The stock list's filters as one key.
typedef StockQuery = ({
  String show,
  String search,
  int? outletId,
  int? categoryId,
});

const StockQuery allStock = (
  show: 'all',
  search: '',
  outletId: null,
  categoryId: null,
);

/// The first page of `GET stock` for [StockQuery]; later pages are read by
/// the list itself.
final stockOverviewProvider = FutureProvider.autoDispose
    .family<StockOverview, StockQuery>((ref, q) async {
      _who(ref);
      return _value(
        await ref
            .read(stockRepositoryProvider)
            .overview(
              show: q.show,
              query: q.search,
              outletId: q.outletId,
              categoryId: q.categoryId,
            ),
      );
    });

final productStockProvider = FutureProvider.autoDispose
    .family<ProductStock, int>((ref, id) async {
      _who(ref);
      return _value(await ref.read(stockRepositoryProvider).product(id));
    });

final stockFormOptionsProvider = FutureProvider.autoDispose<StockFormOptions>((
  ref,
) async {
  _who(ref);
  return _value(await ref.read(stockRepositoryProvider).formOptions());
});

final warehouseBookProvider = FutureProvider.autoDispose<WarehouseBook>((
  ref,
) async {
  _who(ref);
  return _value(await ref.read(stockRepositoryProvider).warehouses());
});

/// History filters as one key.
typedef HistoryQuery = ({
  String? type,
  String period,
  String search,
  int? outletId,
  int? productId,
});

final stockHistoryProvider = FutureProvider.autoDispose
    .family<ApiPage<StockMove>, HistoryQuery>((ref, q) async {
      _who(ref);
      return _value(
        await ref
            .read(stockRepositoryProvider)
            .history(
              type: q.type,
              period: q.period,
              query: q.search,
              outletId: q.outletId,
              productId: q.productId,
            ),
      );
    });

/// Reads stock again everywhere after a change.
void refreshStock(WidgetRef ref) {
  ref
    ..invalidate(stockOverviewProvider)
    ..invalidate(productStockProvider)
    ..invalidate(stockFormOptionsProvider)
    ..invalidate(warehouseBookProvider)
    ..invalidate(stockHistoryProvider);
}

/// What a scanned or typed serial is: the server's answer for that number
/// (`GET stock/units?serial=`); without a signal, or from an older server,
/// the form options' units in stock (the copy's, offline), else what its
/// ledger rows say. Without a signal the ledger is skipped.
final unitLookupProvider = FutureProvider.autoDispose
    .family<UnitLookup, String>((ref, serial) async {
      _who(ref);
      final repo = ref.read(stockRepositoryProvider);
      if (await repo.unitsBySerial(serial) case ApiOk(:final value)) {
        if (lookUnitFromServer(serial, value) case final found?) return found;
      }
      final options = _value(await repo.formOptions());
      final inStock = options.inStockUnits.any(
        (u) => u.serial.toUpperCase() == serial.trim().toUpperCase(),
      );
      final ledger = switch (await repo.history(query: serial, period: 'all')) {
        ApiOk(:final value) => value.items,
        ApiErr(:final failure) =>
          inStock ||
                  failure.kind == ApiFailureKind.offline ||
                  failure.kind == ApiFailureKind.timeout
              ? const <StockMove>[]
              : throw failure,
      };
      final found = lookUnit(serial, options.inStockUnits, ledger);
      final variantId = found.unit?.variantId;
      return found.withProduct(
        options.variants.where((v) => v.id == variantId).firstOrNull?.productId,
      );
    });
