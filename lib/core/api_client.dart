import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'env.dart';

/// Error raised for every non-2xx answer (or transport failure), carrying the
/// envelope's `message` and, for 422s, the per-field errors in `data`.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isNetwork => statusCode == null;
  bool get isValidation => statusCode == 422;
  bool get isConflict => statusCode == 409;

  /// First message for [field]. Also matches bracket/dot variants such as
  /// `gallery_images.0` when asked for `gallery_images`.
  String? fieldError(String field) {
    final direct = fieldErrors[field];
    if (direct != null && direct.isNotEmpty) return direct.first;
    for (final e in fieldErrors.entries) {
      if (e.key.startsWith('$field.') && e.value.isNotEmpty) return e.value.first;
    }
    return null;
  }

  @override
  String toString() => message;
}

/// A successful envelope: `{ success: true, message, data }`.
class ApiResult {
  const ApiResult(this.message, this.data);
  final String message;
  final dynamic data;

  Map<String, dynamic> get map =>
      data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{};
}

/// Holds the bearer token in memory and in the platform keystore.
/// Tokens never expire server-side; one is kept until a 401.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'brand_app_token';
  final FlutterSecureStorage _storage;
  String? _token;

  String? get token => _token;

  Future<String?> load() async => _token = await _storage.read(key: _key);

  Future<void> save(String token) async {
    _token = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: _key);
  }
}

typedef AuthFailureHandler = void Function(int statusCode, String message);

class ApiClient {
  ApiClient(this._tokens, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: '${Env.apiBase}/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _tokens.token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  final Dio _dio;
  final TokenStore _tokens;

  /// Set by the session: called for 401/403 on an authenticated request, so
  /// the app can clear the token and return to Welcome (§5.3).
  AuthFailureHandler? onAuthFailure;

  static const _getRetries = 2;
  static final _orderStatusPath = RegExp(r'orders/[^/]+/status$');

  Future<ApiResult> get(String path, {Map<String, dynamic>? query}) async {
    final params = query == null
        ? null
        : (Map.of(query)..removeWhere((_, v) => v == null || (v is String && v.isEmpty)));
    for (var attempt = 0;; attempt++) {
      try {
        return await _send(() => _dio.get(path, queryParameters: params));
      } on ApiException catch (e) {
        // Retry only idempotent GETs, and only on transport failures.
        if (!e.isNetwork || attempt >= _getRetries) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
  }

  /// [data] may be a plain map (sent as JSON) or a [FormData] for multipart.
  Future<ApiResult> post(String path, {Object? data}) =>
      _send(() => _dio.post(path, data: data));

  Future<ApiResult> delete(String path) => _send(() => _dio.delete(path));

  Future<ApiResult> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body is Map) {
        return ApiResult(body['message']?.toString() ?? '', body['data']);
      }
      return ApiResult('', body);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final res = e.response;
    if (res == null) {
      return ApiException(
        e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout
            ? 'The server took too long to answer. Check your connection and try again.'
            : 'Could not reach AtomShop. Check your internet connection.',
      );
    }

    final status = res.statusCode ?? 0;
    final body = res.data;
    var message = 'Something went wrong (error $status).';
    final fields = <String, List<String>>{};
    if (body is Map) {
      final m = body['message']?.toString();
      if (m != null && m.isNotEmpty) message = m;
      final data = body['data'];
      if (status == 422 && data is Map) {
        data.forEach((k, v) {
          if (v is List) {
            fields[k.toString()] = v.map((x) => x.toString()).toList();
          } else if (v is String) {
            fields[k.toString()] = [v];
          }
        });
      }
    }

    final wasAuthenticated = e.requestOptions.headers.containsKey('Authorization');
    // A 403 from an order status change means "financed order, read only"
    // (§7.2), not a blocked account, so it must not sign the user out.
    final isOrderLock = status == 403 && _orderStatusPath.hasMatch(e.requestOptions.path);
    if (wasAuthenticated && !isOrderLock && (status == 401 || status == 403)) {
      onAuthFailure?.call(status, message);
    }
    return ApiException(message, statusCode: status, fieldErrors: fields);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStoreProvider)),
);
