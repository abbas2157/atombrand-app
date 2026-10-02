import 'dart:convert';
import 'dart:typed_data';

import 'package:atombrand_app/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with a fixed status and JSON body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);
  final int status;
  final Map<String, dynamic> body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryTokens extends TokenStore {
  _MemoryTokens(this._t);
  final String? _t;
  @override
  String? get token => _t;
}

ApiClient _client(_FakeAdapter adapter, {String? token}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test/api/brand-app/'))..httpClientAdapter = adapter;
  return ApiClient(_MemoryTokens(token), dio: dio);
}

void main() {
  test('unwraps the success envelope and sends the bearer token', () async {
    final adapter = _FakeAdapter(200, {'success': true, 'message': 'OK', 'data': {'count': 3}});
    final api = _client(adapter, token: 'abc');
    final res = await api.get('bulk-orders/count');
    expect(res.map['count'], 3);
    expect(adapter.last!.headers['Authorization'], 'Bearer abc');
  });

  test('422 maps field errors', () async {
    final api = _client(_FakeAdapter(422, {
      'success': false,
      'message': 'Validation Error.',
      'data': {'price': ['The price field is required.'], 'gallery_images.0': ['Too big.']},
    }));
    try {
      await api.post('products');
      fail('should throw');
    } on ApiException catch (e) {
      expect(e.isValidation, isTrue);
      expect(e.fieldError('price'), 'The price field is required.');
      expect(e.fieldError('gallery_images'), 'Too big.');
    }
  });

  test('401 on an authenticated call triggers sign-out', () async {
    final api = _client(_FakeAdapter(401, {'success': false, 'message': 'Unauthenticated.'}), token: 't');
    int? status;
    api.onAuthFailure = (s, _) => status = s;
    await expectLater(api.get('me'), throwsA(isA<ApiException>()));
    expect(status, 401);
  });

  test('401 on sign-in (no token) is just bad credentials', () async {
    final api = _client(_FakeAdapter(401, {'success': false, 'message': 'Invalid login or password.'}));
    var called = false;
    api.onAuthFailure = (_, _) => called = true;
    await expectLater(
      api.post('auth/login'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Invalid login or password.')),
    );
    expect(called, isFalse);
  });

  test('403 for a financed order does not sign out; 403 elsewhere does', () async {
    final locked = _client(_FakeAdapter(403, {'success': false, 'message': 'Financed order.'}), token: 't');
    var lockedCalled = false;
    locked.onAuthFailure = (_, _) => lockedCalled = true;
    await expectLater(locked.post('orders/u1/status'), throwsA(isA<ApiException>()));
    expect(lockedCalled, isFalse);

    final blocked = _client(_FakeAdapter(403, {'success': false, 'message': 'Your account is not active.'}), token: 't');
    String? message;
    blocked.onAuthFailure = (_, m) => message = m;
    await expectLater(blocked.get('dashboard'), throwsA(isA<ApiException>()));
    expect(message, 'Your account is not active.');
  });
}
