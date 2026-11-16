import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/db/outbox_actions.dart';
import '../../../core/db/sync_store.dart';
import '../../../core/format/dates.dart';
import '../../../core/pdf/server_pdf.dart';
import '../../../core/session/session_controller.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/data/sync_providers.dart';
import 'bulk_logic.dart';
import 'bulk_models.dart';
import 'bulk_offline.dart';

/// Bulk requests, seller requests, quotes and deals
/// (docs/BRAND_APP.md "Bulk deals"; `bulk.view` to read, `bulk.quote` to
/// work a request, `bulk.deal` for deliveries and payments).
///
/// Status changes, deliveries and payments can wait for a signal with the
/// Offline add-on (`bulk.status`, `deal.deliver`, `deal.payment`); quotes,
/// won and lost need the server (prices are worked out live).
class BulkRepository {
  const BulkRepository(this._api, [this._offline, this._copy, this._store]);

  final ApiClient _api;
  final OfflineSaves? _offline;
  final OfflineCopy? _copy;
  final SyncStore? _store;

  BulkCopy? get _reader {
    final copy = _copy, store = _store;
    if (copy == null || store == null) return null;
    return BulkCopy(store, shopId: copy.shopId);
  }

  /// The server's answer, or the copy's when there is no signal.
  Future<ApiResult<T>> _orCopy<T>(
    Future<ApiResult<T>> Function() online,
    Future<T?> Function(BulkCopy copy) fromCopy,
  ) async {
    final reader = _reader;
    if (reader == null) return online();
    if (!_copy!.isOnline()) {
      final here = await fromCopy(reader);
      if (here != null) return ApiOk(here);
    }
    final answer = await online();
    if (answer case ApiErr(:final failure)
        when failure.kind == ApiFailureKind.offline ||
            failure.kind == ApiFailureKind.timeout) {
      final here = await fromCopy(reader);
      if (here != null) return ApiOk(here);
    }
    return answer;
  }

  Future<Saved<T>> _save<T>({
    required String action,
    required Map<String, dynamic> data,
    required Future<ApiResult<T>> Function() send,
    Map<String, dynamic> seen = const {},
    Map<String, File> files = const {},
    Future<void> Function(SyncStore store, int shopId)? alsoHere,
  }) async {
    final offline = _offline;
    if (offline == null) {
      return switch (await send()) {
        ApiOk(:final value) => SavedOnServer<T>(value),
        ApiErr(:final failure) => SaveFailed<T>(failure),
      };
    }
    return offline.save<T>(
      action: action,
      data: data,
      seen: seen,
      files: files,
      send: send,
      alsoHere: alsoHere,
    );
  }

  // ───────────────────────────────────────────── requests

  /// `GET bulk-orders/count`: the tab badges.
  Future<ApiResult<BulkCounts>> counts() =>
      _api.get('bulk-orders/count', parse: BulkCounts.fromJson);

  /// `GET bulk-orders?from=sellers|buyers&status=`; a null [status] is
  /// every status (`status=all`), [changeAsked] the seller requests owing
  /// a new revision (`status=change_asked`). [since] and [until] are the
  /// days it came in (`received_from` / `received_to`, inclusive). The
  /// counts are per status under [from] and the days.
  Future<ApiResult<BulkRequestsPage>> requests({
    required String from,
    required RequestStatus? status,
    bool changeAsked = false,
    DateTime? since,
    DateTime? until,
    String? search,
    int page = 1,
  }) => _orCopy(
    () => _api.get(
      'bulk-orders',
      query: {
        'from': from,
        'status': changeAsked ? 'change_asked' : status?.key ?? 'all',
        if (since != null) 'received_from': AtomDates.api(since),
        if (until != null) 'received_to': AtomDates.api(until),
        if (page > 1) 'page': page,
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      },
      parse: BulkRequestsPage.fromJson,
    ),
    // The copy can't tell a change asked; that list needs the server.
    (copy) => page > 1 || changeAsked
        ? Future.value(null)
        : copy.requests(
            from: from,
            status: status?.key,
            search: search,
            since: since,
            until: until,
          ),
  );

  /// `GET bulk-orders/{id}`.
  Future<ApiResult<BulkDossier>> dossier(int id) => _orCopy(
    () => _api.get('bulk-orders/$id', parse: BulkDossier.fromJson),
    (copy) => copy.dossier(id),
  );

  /// `GET bulk-orders/{id}/quotes`, newest revision first.
  Future<ApiResult<RequestQuotes>> quotes(int id) => _orCopy(
    () => _api.get('bulk-orders/$id/quotes', parse: RequestQuotes.fromJson),
    (copy) => copy.quotes(id),
  );

  /// `GET bulk-orders/quote-options`.
  Future<ApiResult<QuoteOptions>> quoteOptions() =>
      _api.get('bulk-orders/quote-options', parse: QuoteOptions.fromJson);

  /// `POST bulk-orders/{id}/quote`: send it (a new revision) or save the
  /// draft.
  Future<ApiResult<Quote>> saveQuote(
    int id, {
    required List<QuoteDraftLine> lines,
    required int deliveryCharge,
    required DateTime validUntil,
    required int advancePct,
    required String balanceTerms,
    required String notes,
    required bool send,
  }) => _api.post(
    'bulk-orders/$id/quote',
    body: {
      'items': [for (final l in lines) l.toJson()],
      'delivery_charge': deliveryCharge,
      'valid_until': AtomDates.api(validUntil),
      'advance_pct': advancePct,
      'balance_terms': balanceTerms,
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      'action': send ? 'send' : 'draft',
    },
    parse: Quote.fromJson,
  );

  /// The quote's PDF (`GET bulk-orders/quotes/{id}?pdf=1`).
  ServerPdf quotePdf(Quote q) => ServerPdf(
    'bulk-orders/quotes/${q.id}',
    query: const {'pdf': 1},
    filename: 'Quotation-${q.number}.pdf',
  );

  /// `POST bulk-orders/{id}/status` (New Lead, Contacted or Lost), or
  /// `POST bulk-orders/{id}/lost` for Lost. Waits for a signal as
  /// `bulk.status` with the Offline add-on.
  Future<Saved<void>> setStatus(
    int id,
    RequestStatus status, {
    String? reason,
    String? comments,
    RequestStatus? seen,
  }) {
    final note = (comments ?? '').trim();
    final body = {
      'status': status.key,
      if (status == RequestStatus.lost) 'reason': ?reason,
      if (note.isNotEmpty) 'comments': note,
    };
    return _save<void>(
      action: SyncActionKeys.bulkStatus,
      data: {'request_id': id, ...body},
      seen: {'status': ?seen?.key},
      send: () => status == RequestStatus.lost
          ? _api.post(
              'bulk-orders/$id/lost',
              body: {'reason': reason, if (note.isNotEmpty) 'comments': note},
              parse: (_) {},
            )
          : _api.post('bulk-orders/$id/status', body: body, parse: (_) {}),
      alsoHere: (store, shopId) => store.patchRow('bulk_requests', id, {
        'status': status.key,
        if (status == RequestStatus.lost) 'reason': reason,
      }, shopId: shopId),
    );
  }

  /// `POST bulk-orders/{id}/won`: the deal, with what is short in stock.
  Future<ApiResult<Deal>> won(int id, {int? quoteId, int? outletId}) =>
      _api.post(
        'bulk-orders/$id/won',
        body: {'quote_id': ?quoteId, 'brand_outlet_id': ?outletId},
        parse: Deal.fromJson,
      );

  // ───────────────────────────────────────────── deals

  /// `GET deals?status=`.
  Future<ApiResult<DealsPage>> deals({
    DealStatus? status,
    String? search,
    int page = 1,
  }) => _orCopy(
    () => _api.get(
      'deals',
      query: {
        'status': ?status?.key,
        if (page > 1) 'page': page,
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      },
      parse: DealsPage.fromJson,
    ),
    (copy) => page > 1
        ? Future.value(null)
        : copy.deals(status: status?.key, search: search),
  );

  /// `GET deals/{id}`.
  Future<ApiResult<Deal>> deal(int id) => _orCopy(
    () => _api.get('deals/$id', parse: Deal.fromJson),
    (copy) => copy.deal(id),
  );

  /// The deal's invoice (`GET deals/{id}/invoice`).
  ServerPdf invoice(Deal d) =>
      ServerPdf('deals/${d.id}/invoice', filename: 'Invoice-${d.number}.pdf');

  /// `POST deals/{id}/deliver`. [picked] is deal item id → units, with
  /// their serials. Waits as `deal.deliver`.
  Future<Saved<Deal>> deliver(
    Deal deal, {
    required Map<int, ({int qty, List<String> serials})> picked,
    required String receivedBy,
    required DateTime deliveredOn,
    String? note,
    File? photo,
  }) {
    final items = {
      for (final e in picked.entries)
        if (e.value.qty > 0)
          '${e.key}': {
            'qty': e.value.qty,
            if (e.value.serials.isNotEmpty) 'serials': e.value.serials,
          },
    };
    final cleanNote = (note ?? '').trim();
    final fields = {
      'delivered_on': AtomDates.api(deliveredOn),
      'received_by': receivedBy.trim(),
      if (cleanNote.isNotEmpty) 'note': cleanNote,
    };
    Future<ApiResult<Deal>> send() {
      if (photo == null) {
        return _api.post(
          'deals/${deal.id}/deliver',
          body: {'items': items, ...fields},
          parse: Deal.fromJson,
        );
      }
      return _api.postForm(
        'deals/${deal.id}/deliver',
        fields: {
          ...fields,
          for (final e in picked.entries)
            if (e.value.qty > 0) ...{
              'items[${e.key}][qty]': e.value.qty,
              if (e.value.serials.isNotEmpty)
                'items[${e.key}][serials][]': e.value.serials,
            },
        },
        files: {'photo': photo},
        parse: Deal.fromJson,
      );
    }

    return _save<Deal>(
      action: SyncActionKeys.dealDeliver,
      data: {'deal_id': deal.id, 'items': items, ...fields},
      files: {'photo': ?photo},
      send: send,
      alsoHere: (store, shopId) async {
        final row = await store.row('deals', deal.id, shopId: shopId);
        if (row == null) return;
        await store.patchRow('deals', deal.id, {
          'status': 'delivering',
          'items': [
            for (final i in Json.list(row['items']))
              {
                ...Json.map(i),
                'delivered_qty':
                    (Json.integer(Json.map(i)['delivered_qty']) ?? 0) +
                    (picked[Json.integer(Json.map(i)['id'])]?.qty ?? 0),
              },
          ],
        }, shopId: shopId);
      },
    );
  }

  /// `POST deals/{id}/payment`. Waits as `deal.payment`; [seenPaid] is
  /// what the deal showed paid when the person opened it.
  Future<Saved<Deal>> payment(
    Deal deal, {
    required int amount,
    required String method,
    required DateTime paidOn,
    String? reference,
    File? receipt,
  }) {
    final ref = (reference ?? '').trim();
    final fields = {
      'amount': amount,
      'method': method,
      'paid_on': AtomDates.api(paidOn),
      if (ref.isNotEmpty) 'reference': ref,
    };
    return _save<Deal>(
      action: SyncActionKeys.dealPayment,
      data: {'deal_id': deal.id, ...fields},
      seen: {'paid': deal.paid},
      files: {'receipt': ?receipt},
      send: () => receipt == null
          ? _api.post(
              'deals/${deal.id}/payment',
              body: fields,
              parse: Deal.fromJson,
            )
          : _api.postForm(
              'deals/${deal.id}/payment',
              fields: fields,
              files: {'receipt': receipt},
              parse: Deal.fromJson,
            ),
      alsoHere: (store, shopId) => store.patchRow('deals', deal.id, {
        'paid': deal.paid + amount,
        'balance': (deal.balance - amount).clamp(0, deal.total),
      }, shopId: shopId),
    );
  }
}

final bulkRepositoryProvider = Provider<BulkRepository>(
  (ref) => BulkRepository(
    ref.read(apiClientProvider),
    ref.watch(offlineSavesProvider),
    ref.watch(offlineCopyProvider),
    ref.watch(offlineCopyProvider) == null ? null : ref.read(syncStoreProvider),
  ),
);

/// Re-reads when the person or the outlet changes.
Object? _scope(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

T _value<T>(ApiResult<T> r) => switch (r) {
  ApiOk(:final value) => value,
  ApiErr(:final failure) => throw failure,
};

/// The tab badges (7.1).
final bulkCountsProvider = FutureProvider.autoDispose<BulkCounts>((ref) async {
  _scope(ref);
  return _value(await ref.read(bulkRepositoryProvider).counts());
});

/// One request list's filters: a null [status] is All.
typedef RequestsQuery = ({
  String from,
  RequestStatus? status,
  bool changeAsked,
  DateTime? since,
  DateTime? until,
  String search,
});

/// The first page of one request list (7.1 Seller requests / Website).
final bulkRequestsProvider = FutureProvider.autoDispose
    .family<BulkRequestsPage, RequestsQuery>((ref, q) async {
      _scope(ref);
      return _value(
        await ref
            .read(bulkRepositoryProvider)
            .requests(
              from: q.from,
              status: q.status,
              changeAsked: q.changeAsked,
              since: q.since,
              until: q.until,
              search: q.search,
            ),
      );
    });

/// Every request of one list, any status (`status=all`), for the All view.
typedef AllRequestsQuery = ({String from, String search});

final bulkAllRequestsProvider = FutureProvider.autoDispose
    .family<BulkRequestsPage, AllRequestsQuery>((ref, q) async {
      _scope(ref);
      return _value(
        await ref
            .read(bulkRepositoryProvider)
            .requests(from: q.from, status: null, search: q.search),
      );
    });

/// One request with its dossier (7.2, 7.3).
final bulkDossierProvider = FutureProvider.autoDispose.family<BulkDossier, int>(
  (ref, id) async {
    _scope(ref);
    return _value(await ref.read(bulkRepositoryProvider).dossier(id));
  },
);

/// A request's quotes, newest first, and its deal.
final requestQuotesProvider = FutureProvider.autoDispose
    .family<RequestQuotes, int>((ref, id) async {
      _scope(ref);
      return _value(await ref.read(bulkRepositoryProvider).quotes(id));
    });

/// Products, variants and the fixed choices for quotes; kept while the
/// person stays signed in to the same outlet.
final quoteOptionsProvider = FutureProvider<QuoteOptions>((ref) async {
  _scope(ref);
  return _value(await ref.read(bulkRepositoryProvider).quoteOptions());
});

typedef DealsQuery = ({DealStatus? status, String search});

/// The first page of deals (7.1 Deals).
final dealsProvider = FutureProvider.autoDispose.family<DealsPage, DealsQuery>((
  ref,
  q,
) async {
  _scope(ref);
  return _value(
    await ref
        .read(bulkRepositoryProvider)
        .deals(status: q.status, search: q.search),
  );
});

/// One deal (7.7).
final dealProvider = FutureProvider.autoDispose.family<Deal, int>((
  ref,
  id,
) async {
  _scope(ref);
  return _value(await ref.read(bulkRepositoryProvider).deal(id));
});

/// After a request changed: its page, its quotes, the lists and badges.
void refreshRequest(WidgetRef ref, int id) {
  ref.invalidate(bulkDossierProvider(id));
  ref.invalidate(requestQuotesProvider(id));
  ref.invalidate(bulkRequestsProvider);
  ref.invalidate(bulkAllRequestsProvider);
  ref.invalidate(bulkCountsProvider);
  ref.invalidate(dealsProvider);
}

/// After a deal changed: its page and the lists.
void refreshDeal(WidgetRef ref, int id) {
  ref.invalidate(dealProvider(id));
  ref.invalidate(dealsProvider);
  ref.invalidate(bulkRequestsProvider);
}
