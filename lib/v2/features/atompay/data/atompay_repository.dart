import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/session/session_controller.dart';
import '../../orders/data/orders_models.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/data/sync_providers.dart';
import 'atompay_models.dart';

/// What the AtomPay list asks for: one step (null is all), the search and
/// one outlet (null is all; `outlet_id`).
typedef AtompayQuery = ({String? step, String q, int? outletId});

/// A page of AtomPay orders with the step counts (`counts`).
typedef AtompayPage = ({ApiPage<AtompayOrder> page, Map<String, int> counts});

/// AtomPay orders: the list, the page and the hand-over. The hand-over goes
/// through the outbox with the Offline add-on (`atompay.handover`); the
/// seller's payment and Complete use the cash order calls.
class AtompayRepository {
  AtompayRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  (SyncStore, int)? get _copy {
    final c = _ref.read(offlineCopyProvider);
    return c == null ? null : (_ref.read(syncStoreProvider), c.shopId);
  }

  bool get _offlineNow => !(_ref.read(offlineCopyProvider)?.isOnline() ?? true);

  static bool _noSignal(ApiFailure f) =>
      f.kind == ApiFailureKind.offline || f.kind == ApiFailureKind.timeout;

  Map<int, String> get _outletNames => {
    for (final o
        in _ref.read(sessionProvider.notifier).current?.outlets ?? const [])
      o.id: o.name,
  };

  Future<Map<int, int>> _paid(SyncStore store, int shopId) async {
    final out = <int, int>{};
    for (final p in await store.rows('order_payments', shopId: shopId)) {
      final id = Json.integer(p['order_id']);
      if (id != null) {
        out[id] = (out[id] ?? 0) + (Json.integer(p['amount']) ?? 0);
      }
    }
    return out;
  }

  Map<String, dynamic> _shape(Map<String, dynamic> row, int paid) {
    final outletId = Json.integer(row['brand_outlet_id']);
    return {
      ...row,
      'paid': paid,
      'product': {'title': row['product_title']},
      if (outletId != null)
        'outlet': {'id': outletId, 'label': _outletNames[outletId] ?? ''},
    };
  }

  Future<AtompayPage> _fromCopy(
    SyncStore store,
    int shopId,
    AtompayQuery q,
  ) async {
    final paid = await _paid(store, shopId);
    final words = q.q.trim().toLowerCase();
    final all =
        [
              for (final r in await store.rows(
                'atompay_orders',
                shopId: shopId,
              ))
                AtompayOrder.fromJson(
                  _shape(r, paid[Json.integer(r['id'])] ?? 0),
                ),
            ]
            .where(
              (o) =>
                  (q.outletId == null || o.outlet?.id == q.outletId) &&
                  (words.isEmpty ||
                      o.productTitle.toLowerCase().contains(words) ||
                      '${o.id}'.contains(words)),
            )
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id));
    final counts = <String, int>{};
    for (final o in all) {
      counts[o.step.key] = (counts[o.step.key] ?? 0) + 1;
    }
    final items = [
      for (final o in all)
        if (q.step == null || o.step.key == q.step) o,
    ];
    return (page: ApiPage(items: items, total: items.length), counts: counts);
  }

  /// One page of AtomPay orders (6.8), with the counts per step.
  Future<ApiResult<AtompayPage>> list(AtompayQuery q, {int page = 1}) async {
    final copy = _copy;
    if (copy != null && _offlineNow) {
      return ApiOk(await _fromCopy(copy.$1, copy.$2, q));
    }
    final r = await _api.get(
      'atompay',
      query: {
        'page': page,
        'step': ?q.step,
        if (q.q.trim().isNotEmpty) 'q': q.q.trim(),
        'outlet_id': ?q.outletId,
      },
      parse: (d) {
        final p = ApiPage.fromJson(d, AtompayOrder.fromJson);
        final c = Json.map(p.extra['counts']);
        return (
          page: p,
          counts: {
            for (final e in c.entries) e.key: Json.integer(e.value) ?? 0,
          },
        );
      },
    );
    if (r case ApiErr(:final failure)
        when copy != null && page == 1 && _noSignal(failure)) {
      return ApiOk(await _fromCopy(copy.$1, copy.$2, q));
    }
    return r;
  }

  Future<AtompayDetail?> _detailFromCopy(
    SyncStore store,
    int shopId,
    String uuid,
  ) async {
    Map<String, dynamic>? row;
    for (final r in await store.rows('atompay_orders', shopId: shopId)) {
      if (r['uuid'] == uuid) row = r;
    }
    if (row == null) return null;
    final id = Json.integer(row['id']);
    final payments = [
      for (final p in await store.rows('order_payments', shopId: shopId))
        if (Json.integer(p['order_id']) == id) p,
    ];
    final paid = payments.fold<int>(
      0,
      (n, p) => n + (Json.integer(p['amount']) ?? 0),
    );
    final account = (await store.rows('account', shopId: shopId)).firstOrNull;
    return AtompayDetail(
      order: AtompayOrder.fromJson(_shape(row, paid)),
      customerName: Json.str(row['customer_name']),
      serial: Json.str(row['handover_serial']),
      payments: [for (final p in payments) OrderPaymentRow.fromJson(p)],
      paymentMethods: [
        for (final m in Json.list(account?['payment_methods'])) ?Json.str(m),
      ],
      history: [
        for (final h in await store.rows('order_history', shopId: shopId))
          if (Json.integer(h['order_id']) == id) OrderEvent.fromJson(h),
      ],
      fromCopy: true,
    );
  }

  /// The AtomPay order page (6.9).
  Future<ApiResult<AtompayDetail>> detail(String uuid) async {
    final copy = _copy;
    if (copy != null && _offlineNow) {
      final d = await _detailFromCopy(copy.$1, copy.$2, uuid);
      if (d != null) return ApiOk(d);
    }
    final r = await _api.get('atompay/$uuid', parse: AtompayDetail.fromJson);
    if (r case ApiErr(:final failure) when copy != null && _noSignal(failure)) {
      final d = await _detailFromCopy(copy.$1, copy.$2, uuid);
      if (d != null) return ApiOk(d);
    }
    return r;
  }

  /// Hands the unit to the seller (6.10, `atompay.handover`).
  Future<Saved<Object?>> handover(
    String uuid, {
    required String receivedBy,
    String? serial,
    String? note,
    File? photo,
  }) async {
    final fields = <String, dynamic>{
      'received_by': receivedBy.trim(),
      if (serial != null && serial.trim().isNotEmpty) 'serial': serial.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final files = {'photo': ?photo};
    Future<ApiResult<Object?>> send() => files.isEmpty
        ? _api.post('atompay/$uuid/handover', body: fields, parse: (d) => d)
        : _api.postForm(
            'atompay/$uuid/handover',
            fields: fields,
            files: files,
            parse: (d) => d,
          );
    final saves = _ref.read(offlineSavesProvider);
    if (saves == null) {
      return switch (await send()) {
        ApiOk(:final value) => SavedOnServer(value),
        ApiErr(:final failure) => SaveFailed(failure),
      };
    }
    return saves.saveAction<Object?>(
      OfflineAction.atompayHandover(
        orderUuid: uuid,
        receivedBy: receivedBy,
        serial: serial,
        note: note,
        photo: photo,
      ),
      send: send,
      alsoHere: (store, shopId) async {
        for (final r in await store.rows('atompay_orders', shopId: shopId)) {
          if (r['uuid'] != uuid) continue;
          final id = Json.integer(r['id']);
          if (id == null) return;
          await store.patchRow('atompay_orders', id, {
            'step': AtompayStep.handed.key,
            'step_label': AtompayStep.handed.label,
            'handover_serial': fields['serial'],
            'handed_over_at': DateTime.now().toIso8601String(),
          }, shopId: shopId);
        }
      },
    );
  }
}

final atompayRepositoryProvider = Provider<AtompayRepository>(
  AtompayRepository.new,
);

void _followOutlet(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

/// The first page of AtomPay orders for a query.
final atompayPageProvider = FutureProvider.autoDispose
    .family<AtompayPage, AtompayQuery>((ref, q) async {
      _followOutlet(ref);
      return switch (await ref.read(atompayRepositoryProvider).list(q)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

/// The AtomPay order page (6.9).
final atompayDetailProvider = FutureProvider.autoDispose
    .family<AtompayDetail, String>((ref, uuid) async {
      _followOutlet(ref);
      return switch (await ref.read(atompayRepositoryProvider).detail(uuid)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

/// Reads an AtomPay order again everywhere it shows.
void refreshAtompay(WidgetRef ref, String uuid) {
  ref
    ..invalidate(atompayDetailProvider(uuid))
    ..invalidate(atompayPageProvider);
}
