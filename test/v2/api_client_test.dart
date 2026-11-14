// The API client decides how every server refusal shows up in the app:
// signed out, read-only, restricted, removed package, not in role… These
// tests feed it the server's real answer shapes (atomshop middleware and
// BaseController) and check the kind that comes out.

import 'dart:convert';
import 'dart:typed_data';

import 'package:atombrand_app/v2/core/api/api_client.dart';
import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth implements ApiAuthSource {
  _Auth({this.token, this.outletId});
  @override
  String? token;
  @override
  int? outletId;
}

/// Answers every request with [status] and [body], and keeps the request.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body, {this.error});
  final int status;
  final Object? body;
  final DioExceptionType? error;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (error != null) {
      throw DioException(requestOptions: options, type: error!);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  ({ApiClient client, _Adapter adapter, List<ApiFailure> appWide}) make(
    int status,
    Object? body, {
    DioExceptionType? error,
    _Auth? auth,
  }) {
    final adapter = _Adapter(status, body, error: error);
    final dio = Dio()..httpClientAdapter = adapter;
    final appWide = <ApiFailure>[];
    final client = ApiClient(
      auth: auth ?? _Auth(),
      dio: dio,
      onAppWideFailure: appWide.add,
    );
    return (client: client, adapter: adapter, appWide: appWide);
  }

  Future<ApiFailure> failureOf(int status, Object? body) async {
    final r = await make(status, body).client.get('x', parse: (d) => d);
    return r.failureOrNull!;
  }

  test('a success parses data', () async {
    final m = make(200, {
      'success': true,
      'message': 'ok',
      'data': {'n': '7'},
    });
    final r = await m.client.get(
      'x',
      parse: (d) => Json.integer(Json.map(d)['n']),
    );
    expect(r.valueOrNull, 7);
  });

  test('a success keeps the server message for the screen', () async {
    final m = make(200, {
      'success': true,
      'message': 'Your account has been deleted.',
      'data': [],
    });
    final r = await m.client.post('me/delete', parse: (_) {});
    final ok = r as ApiOk<void>;
    expect(ok.message, 'Your account has been deleted.');
    expect((ok.map((_) => 1) as ApiOk<int>).message, ok.message);
  });

  test('delete sends a DELETE', () async {
    final m = make(200, {'success': true, 'message': 'Deleted.', 'data': null});
    final r = await m.client.delete('products/5', parse: (_) {});
    expect(m.adapter.last!.method, 'DELETE');
    expect(m.adapter.last!.path, 'products/5');
    expect((r as ApiOk<void>).message, 'Deleted.');
  });

  test('sends the token and the selected shop', () async {
    final m = make(200, {
      'success': true,
      'data': null,
    }, auth: _Auth(token: 'abc', outletId: 12));
    await m.client.get('x', parse: (d) => d);
    expect(m.adapter.last!.headers['Authorization'], 'Bearer abc');
    expect(m.adapter.last!.headers['X-Outlet'], '12');
    expect(m.adapter.last!.headers['X-Atom-Brand-App'], '2');
  });

  test('no token and no outlet send neither header', () async {
    final m = make(200, {'success': true, 'data': null});
    await m.client.get('x', parse: (d) => d);
    expect(m.adapter.last!.headers.containsKey('Authorization'), isFalse);
    expect(m.adapter.last!.headers.containsKey('X-Outlet'), isFalse);
  });

  group('refusals', () {
    test('401 signs out, app-wide', () async {
      final m = make(401, {'success': false, 'message': 'Unauthorized.'});
      final r = await m.client.get('x', parse: (d) => d);
      expect(r.failureOrNull!.kind, ApiFailureKind.signedOut);
      expect(m.appWide.single.kind, ApiFailureKind.signedOut);
    });

    test('an agent who must choose a password', () async {
      expect(
        (await failureOf(403, {
          'success': false,
          'message': 'Choose your own password first.',
          'must_change_password': true,
        })).kind,
        ApiFailureKind.mustChangePassword,
      );
    });

    test('late bill: read-only with days late and amount due', () async {
      final f = await failureOf(403, {
        'success': false,
        'message': 'Your bill is late.',
        'billing_state': 'readonly',
        'days_late': 17,
        'due': 4500,
      });
      expect(f.kind, ApiFailureKind.readOnly);
      expect(f.body!['days_late'], 17);
      expect(f.message, 'Your bill is late.');
    });

    test('restricted by Atomshop', () async {
      expect(
        (await failureOf(403, {
          'success': false,
          'message': 'Send the NTN.',
          'restricted': true,
        })).kind,
        ApiFailureKind.restricted,
      );
    });

    test('package removed beats no plan', () async {
      expect(
        (await failureOf(403, {
          'success': false,
          'requires_subscription': true,
          'package_removed': true,
        })).kind,
        ApiFailureKind.packageRemoved,
      );
      expect(
        (await failureOf(403, {
          'success': false,
          'requires_subscription': true,
        })).kind,
        ApiFailureKind.noPlan,
      );
    });

    test('owner only, then plain 403 is not in role', () async {
      expect(
        (await failureOf(403, {'success': false, 'owner_only': true})).kind,
        ApiFailureKind.ownerOnly,
      );
      expect(
        (await failureOf(403, {
          'success': false,
          'permission': 'orders.create',
        })).kind,
        ApiFailureKind.notInRole,
      );
    });

    test('an add-on that is off names it, in every shape', () async {
      for (final body in [
        {
          'success': false,
          'data': {'feature': 'inventory', 'feature_off': true},
        },
        {'success': false, 'feature_off': true, 'feature': 'inventory'},
        // Stock's older refusal.
        {
          'success': false,
          'data': {'reason': 'inventory'},
        },
      ]) {
        final m = make(403, body);
        final f = (await m.client.get('stock', parse: (d) => d)).failureOrNull!;
        expect(f.kind, ApiFailureKind.featureOff, reason: '$body');
        expect(f.body!['feature'], 'inventory');
        expect(m.appWide, hasLength(1));
      }
      // Lapsed: read-only, not off.
      expect(
        (await failureOf(403, {
          'success': false,
          'data': {'reason': 'read_only'},
        })).kind,
        ApiFailureKind.notInRole,
      );
    });

    test('validation errors come back per field', () async {
      final f = await failureOf(422, {
        'success': false,
        'message': 'Validation Error.',
        'data': {
          'phone': ['The phone has already been taken.'],
          'name': ['The name field is required.', 'second'],
        },
      });
      expect(f.kind, ApiFailureKind.validation);
      expect(f.fieldErrors['phone'], 'The phone has already been taken.');
      expect(f.fieldErrors['name'], 'The name field is required.');
    });

    test(
      'success false on 200 with errors is validation, without is server',
      () async {
        expect(
          (await failureOf(200, {
            'success': false,
            'data': {
              'amount': ['Too much.'],
            },
          })).kind,
          ApiFailureKind.validation,
        );
        expect(
          (await failureOf(200, {'success': false, 'message': 'No.'})).kind,
          ApiFailureKind.server,
        );
      },
    );

    test('404, 503 and an unreadable answer', () async {
      expect(
        (await failureOf(404, {'success': false})).kind,
        ApiFailureKind.notFound,
      );
      expect((await failureOf(503, '<html>')).kind, ApiFailureKind.maintenance);
      expect((await failureOf(500, null)).kind, ApiFailureKind.server);
    });
  });

  test('a parser that throws is a server failure, not a crash', () async {
    final m = make(200, {'success': true, 'data': 'text'});
    final r = await m.client.get<int>(
      'x',
      parse: (d) => (d as Map)['n'] as int,
    );
    expect(r.failureOrNull!.kind, ApiFailureKind.server);
  });

  test('no connection and timeouts', () async {
    final offline = make(0, null, error: DioExceptionType.connectionError);
    expect(
      (await offline.client.get('x', parse: (d) => d)).failureOrNull!.kind,
      ApiFailureKind.offline,
    );
    final slow = make(0, null, error: DioExceptionType.receiveTimeout);
    expect(
      (await slow.client.get('x', parse: (d) => d)).failureOrNull!.kind,
      ApiFailureKind.timeout,
    );
    // Neither changes the whole app.
    expect(offline.appWide, isEmpty);
  });

  test('Json readers accept the server loose types', () {
    expect(Json.integer('12'), 12);
    expect(Json.integer('12.6'), 13);
    expect(Json.integer(null), isNull);
    expect(Json.flag('1'), isTrue);
    expect(Json.flag(0), isFalse);
    expect(Json.str('  '), isNull);
  });
}
