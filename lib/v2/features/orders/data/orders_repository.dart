import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/format/dates.dart';
import '../../../core/session/session_controller.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/data/sync_providers.dart';
import 'order_rules.dart';
import 'orders_copy.dart';
import 'orders_models.dart';

/// Cash orders: the list, the page, status moves, payments, the receipt
/// and moving to another outlet. Status moves, cancel and payments go
/// through the outbox with the Offline add-on (`order.status`,
/// `order.cancel`, `order.payment`, docs/brand-app-sync.md §6).
class OrdersRepository {
  OrdersRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  /// The phone's copy, when the add-on is on and its key is open.
  OrdersCopy? get _copy {
    final c = _ref.read(offlineCopyProvider);
    if (c == null) return null;
    final s = _ref.read(sessionProvider.notifier).current;
    return OrdersCopy(
      _ref.read(syncStoreProvider),
      c.shopId,
      outletNames: {for (final o in s?.outlets ?? const []) o.id: o.name},
    );
  }

  bool get _offlineNow => !(_ref.read(offlineCopyProvider)?.isOnline() ?? true);

  static bool _noSignal(ApiFailure f) =>
      f.kind == ApiFailureKind.offline || f.kind == ApiFailureKind.timeout;

  /// One page of cash orders (`cash=1`).
  Future<ApiResult<ApiPage<CashOrder>>> list(
    OrdersQuery q, {
    int page = 1,
  }) async {
    final copy = _copy;
    if (copy != null && _offlineNow) {
      return page == 1
          ? ApiOk(await copy.list(q))
          : ApiOk(const ApiPage(items: []));
    }
    final r = await _api.get(
      'orders',
      query: {...ordersFilters(q), 'page': page, 'status': ?q.status},
      parse: (d) => ApiPage.fromJson(d, CashOrder.fromJson),
    );
    if (r case ApiErr(:final failure)
        when copy != null && page == 1 && _noSignal(failure)) {
      return ApiOk(await copy.list(q));
    }
    return r;
  }

  /// Orders per status key for the chips: the server's sibling `counts`
  /// of one call (every filter but the status); from an older server that
  /// sends none, one small call per status (its `total`).
  Future<ApiResult<Map<String, int>>> counts(OrdersQuery q) async {
    final copy = _copy;
    if (copy != null && _offlineNow) return ApiOk(await copy.counts(q));
    final filters = ordersFilters(q);
    final one = await _api.get(
      'orders',
      query: filters,
      parse: (d) => orderCountsOf(Json.map(d)['counts']),
    );
    switch (one) {
      case ApiOk(value: final counts?):
        return ApiOk(counts);
      case ApiOk():
        break;
      case ApiErr(:final failure):
        if (copy != null && _noSignal(failure)) {
          return ApiOk(await copy.counts(q));
        }
        return ApiErr(failure);
    }
    final out = <String, int>{};
    final calls = await Future.wait([
      for (final s in OrderStage.values)
        _api.get(
          'orders',
          query: {...filters, 'status': s.key},
          parse: (d) => ApiPage.fromJson(d, (_) => null).total,
        ),
    ]);
    for (var i = 0; i < calls.length; i++) {
      switch (calls[i]) {
        case ApiOk(:final value):
          out[OrderStage.values[i].key] = value;
        case ApiErr(:final failure):
          if (copy != null && _noSignal(failure)) {
            return ApiOk(await copy.counts(q));
          }
          return ApiErr(failure);
      }
    }
    return ApiOk(out);
  }

  /// The order page (6.2).
  Future<ApiResult<CashOrderDetail>> detail(String uuid) async {
    final copy = _copy;
    if (copy != null && _offlineNow) {
      final o = await copy.detail(uuid);
      if (o != null) return ApiOk(o);
    }
    final r = await _api.get(
      'orders/retail/$uuid',
      parse: CashOrderDetail.fromJson,
    );
    if (r case ApiErr(:final failure) when copy != null && _noSignal(failure)) {
      final o = await copy.detail(uuid);
      if (o != null) return ApiOk(o);
    }
    return r;
  }

  /// Tries the server, and with the Offline add-on queues [action] when
  /// there is no signal. Without the add-on it is the plain call.
  Future<Saved<Object?>> _save(
    OfflineAction action, {
    required Future<ApiResult<Object?>> Function() send,
    Future<void> Function(SyncStore store, int shopId)? alsoHere,
  }) async {
    final saves = _ref.read(offlineSavesProvider);
    if (saves == null) {
      return switch (await send()) {
        ApiOk(:final value) => SavedOnServer(value),
        ApiErr(:final failure) => SaveFailed(failure),
      };
    }
    return saves.saveAction<Object?>(action, send: send, alsoHere: alsoHere);
  }

  /// Shows a move saved on this phone in the copy, until the server's row
  /// comes down.
  Future<void> Function(SyncStore, int) _patchStatus(
    String uuid,
    OrderStage to,
  ) => (store, shopId) async {
    final id = await OrdersCopy(store, shopId).idOf(uuid);
    if (id == null) return;
    await store.patchRow('orders', id, {
      'status': to.key,
      'status_label': to.label,
      'next_statuses': [for (final s in cashTransitions[to]!) s.key],
    }, shopId: shopId);
  };

  /// Moves the order on (`order.status`): confirm, process, complete, and
  /// delivered with its fields (6.3). [seen] is the status on screen.
  Future<Saved<Object?>> setStatus(
    String uuid, {
    required OrderStage to,
    required OrderStage seen,
    String? receivedBy,
    String? serial,
    int? codAmount,
    String? codMethod,
    File? photo,
  }) {
    final fields = <String, dynamic>{
      'status': to.key,
      if (receivedBy != null && receivedBy.trim().isNotEmpty)
        'received_by': receivedBy.trim(),
      if (serial != null && serial.trim().isNotEmpty) 'serial': serial.trim(),
      if (codAmount != null && codAmount > 0) ...{
        'cod_amount': codAmount,
        'cod_method': ?codMethod,
      },
    };
    final files = {'delivered_photo': ?photo};
    return _save(
      OfflineAction.orderStatus(
        orderUuid: uuid,
        status: to.key,
        seenStatus: seen.key,
        receivedBy: receivedBy,
        serial: serial,
        codAmount: codAmount != null && codAmount > 0 ? codAmount : null,
        codMethod: codAmount != null && codAmount > 0 ? codMethod : null,
        deliveredPhoto: photo,
      ),
      send: () => files.isEmpty
          ? _api.post('orders/$uuid/status', body: fields, parse: (d) => d)
          : _api.postForm(
              'orders/$uuid/status',
              fields: fields,
              files: files,
              parse: (d) => d,
            ),
      alsoHere: _patchStatus(uuid, to),
    );
  }

  /// Cancels the order (`order.cancel`, 6.5): reason keys and an optional
  /// note.
  Future<Saved<Object?>> cancel(
    String uuid, {
    required OrderStage seen,
    required List<String> reasons,
    String? note,
  }) {
    final body = <String, dynamic>{
      'status': OrderStage.cancelled.key,
      'reasons': reasons,
      if (note != null && note.trim().isNotEmpty) 'reason': note.trim(),
    };
    return _save(
      OfflineAction.orderCancel(
        orderUuid: uuid,
        seenStatus: seen.key,
        reasons: reasons,
        reason: note,
      ),
      send: () => _api.post('orders/$uuid/status', body: body, parse: (d) => d),
      alsoHere: _patchStatus(uuid, OrderStage.cancelled),
    );
  }

  /// Records a payment (`order.payment`, 6.4): a cash order's, or the
  /// seller's on a handed-over AtomPay order. [seenPaid] is the paid total
  /// on screen.
  Future<Saved<Object?>> pay(
    String uuid, {
    required int amount,
    required String method,
    required DateTime paidOn,
    required int seenPaid,
    String? reference,
    File? receipt,
    String table = 'order_payments',
  }) {
    final fields = <String, dynamic>{
      'amount': amount,
      'method': method,
      'paid_on': AtomDates.api(paidOn),
      if (reference != null && reference.trim().isNotEmpty)
        'reference': reference.trim(),
    };
    final files = {'receipt': ?receipt};
    return _save(
      OfflineAction.orderPayment(
        orderUuid: uuid,
        amount: amount,
        method: method,
        reference: reference,
        paidOn: paidOn,
        seenPaid: seenPaid,
        receipt: receipt,
      ),
      send: () => files.isEmpty
          ? _api.post('orders/$uuid/payment', body: fields, parse: (d) => d)
          : _api.postForm(
              'orders/$uuid/payment',
              fields: fields,
              files: files,
              parse: (d) => d,
            ),
      alsoHere: (store, shopId) async {
        // The payment shows on the order at once, as a row of its own.
        int? id;
        for (final t in const ['orders', 'atompay_orders']) {
          for (final r in await store.rows(t, shopId: shopId)) {
            if (r['uuid'] == uuid) id = Json.integer(r['id']);
          }
        }
        if (id == null) return;
        await store.addLocalRow(
          table,
          tempId: 'pay-$uuid-${DateTime.now().millisecondsSinceEpoch}',
          fields: {
            'order_id': id,
            'amount': amount,
            'method': method,
            'reference': fields['reference'],
            'paid_on': fields['paid_on'],
          },
          shopId: shopId,
        );
      },
    );
  }

  /// The receipt as data (6.7). Online only.
  Future<ApiResult<OrderReceipt>> receipt(String uuid) =>
      _api.get('orders/$uuid/receipt', parse: OrderReceipt.fromJson);

  /// Moves the order to another outlet (6.6, owner). Online only: the
  /// server never takes it offline (`order.move`).
  Future<ApiResult<Object?>> move(String uuid, int outletId) => _api.post(
    'orders/$uuid/move',
    body: {'outlet_id': outletId},
    parse: (d) => d,
  );
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  OrdersRepository.new,
);
