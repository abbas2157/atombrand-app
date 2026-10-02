import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/images.dart';
import '../models/bulk.dart';
import '../models/dashboard.dart';
import '../models/json.dart';
import '../models/order.dart';

class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  Future<Dashboard> dashboard() async => Dashboard.fromJson((await _api.get('dashboard')).map);

  Future<Paged<OrderSummary>> orders({OrderFeed type = OrderFeed.retail, String? status, String? q, int page = 1}) async {
    final res = await _api.get('orders', query: {'type': type.name, 'status': status, 'q': q, 'page': page});
    return Paged.fromJson(res.map, OrderSummary.fromJson);
  }

  Future<OrderDetail> order(OrderFeed type, String uuid) async =>
      OrderDetail.fromJson((await _api.get('orders/${type.name}/$uuid')).map);

  /// Retail cash orders only. `status` is sent exactly as the server spells
  /// it (including `Varification`).
  Future<String> changeStatus(
    String uuid,
    String status, {
    String? receivedBy,
    PickedImage? deliveredPicture,
    String? reason,
    Set<String> flags = const {},
  }) async {
    final fields = <String, dynamic>{
      'status': status,
      if (receivedBy != null && receivedBy.isNotEmpty) 'recieved_by': receivedBy,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      for (final f in flags) f: 1,
    };
    final Object body = deliveredPicture == null
        ? fields
        : (FormData.fromMap(fields)..files.add(MapEntry('delivered_pictrue', deliveredPicture.toMultipart())));
    final res = await _api.post('orders/$uuid/status', data: body);
    return asStrOr(res.map['status'], status);
  }
}

class BulkPage {
  const BulkPage(this.page, this.counts);
  final Paged<BulkRequest> page;
  final Map<String, int> counts;
}

class BulkRepository {
  BulkRepository(this._api);
  final ApiClient _api;

  Future<BulkPage> list({String? status, String? q, int page = 1}) async {
    final res = await _api.get('bulk-orders', query: {'status': status, 'q': q, 'page': page});
    final counts = asMap(res.map['counts']).map((k, v) => MapEntry(k, asInt(v)));
    return BulkPage(Paged.fromJson(res.map, BulkRequest.fromJson), counts);
  }

  Future<int> newCount() async => asInt((await _api.get('bulk-orders/count')).map['count']);

  Future<BulkDossier> dossier(int id) async => BulkDossier.fromJson((await _api.get('bulk-orders/$id')).map);

  Future<String> updateStatus(int id, String status, {String? comments, String? reason}) async {
    final res = await _api.post('bulk-orders/$id/status', data: {
      'status': status,
      if (comments != null && comments.isNotEmpty) 'comments': comments,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return asStrOr(res.map['status'], status);
  }
}

final ordersRepositoryProvider = Provider((ref) => OrdersRepository(ref.watch(apiClientProvider)));
final bulkRepositoryProvider = Provider((ref) => BulkRepository(ref.watch(apiClientProvider)));
