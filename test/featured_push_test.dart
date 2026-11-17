import 'dart:convert';
import 'dart:typed_data';

import 'package:atombrand_app/core/api_client.dart';
import 'package:atombrand_app/core/push.dart';
import 'package:atombrand_app/data/repositories/catalogue_repository.dart';
import 'package:atombrand_app/data/repositories/notifications_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake `products/{id}/feature` toggle that remembers the flag.
class _ToggleAdapter implements HttpClientAdapter {
  _ToggleAdapter(this.featured);
  bool featured;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    featured = !featured;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'message': '', 'data': {'brand_featured': featured}}),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

CatalogueRepository _repo(_ToggleAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test/api/brand-app/'))..httpClientAdapter = adapter;
  return CatalogueRepository(ApiClient(TokenStore(), dio: dio));
}

void main() {
  group('setFeatured', () {
    test('one toggle when the product is in the expected state', () async {
      final server = _ToggleAdapter(false);
      await _repo(server).setFeatured(5, true);
      expect(server.featured, isTrue);
      expect(server.calls, 1);
    });

    test('toggles back when the product was already featured elsewhere', () async {
      final server = _ToggleAdapter(true);
      await _repo(server).setFeatured(5, true);
      expect(server.featured, isTrue);
      expect(server.calls, 2);
    });

    test('unfeatures', () async {
      final server = _ToggleAdapter(true);
      await _repo(server).setFeatured(5, false);
      expect(server.featured, isFalse);
    });
  });

  group('push routing (§8.10)', () {
    test('order, bulk request and product pushes open their screens', () {
      PushMessage push(Map<String, String> data) => PushMessage.fromRemote(
            RemoteMessage(notification: const RemoteNotification(title: 'T', body: 'B'), data: data),
          );

      expect(push({'screen': 'order', 'order_type': 'retail', 'order_uuid': 'u1'}).route, '/orders/retail/u1');
      expect(push({'screen': 'bulk_request', 'bulk_request_id': '88'}).route, '/bulk/88');
      expect(push({'screen': 'product', 'product_id': '5'}).route, '/products/5');
      expect(push({'screen': 'order'}).route, isNull);
      expect(push({'screen': 'order', 'order_uuid': 'u1'}).title, 'T');
    });

    test('inbox rows and pushes share one route table', () {
      expect(notificationRoute('order', {'order_uuid': 'u2'}), '/orders/retail/u2');
      expect(notificationRoute(null, {}), isNull);
    });
  });
}
