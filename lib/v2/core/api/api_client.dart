import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../update/update_policy.dart' show InstalledApp;
import 'api_result.dart';
import 'atom_server.dart';

/// Where the client gets the token and the selected outlet for each call.
abstract interface class ApiAuthSource {
  String? get token;

  /// The outlet to send as `X-Outlet`, or null for every outlet.
  int? get outletId;
}

/// Turns a JSON `data` value into the type a repository wants.
typedef ApiParser<T> = T Function(Object? data);

/// The v2 HTTP client.
///
/// Separate from v1's NetworkManager on purpose: that one throws, raises the
/// v1 subscription gate and signs out through v1's session. This one never
/// throws. Every call returns an [ApiResult]; failures that change the whole
/// app (signed out, read-only, maintenance…) are also passed to
/// [onAppWideFailure] so the session and the router can react in one place.
class ApiClient {
  ApiClient({
    required this.auth,
    Dio? dio,
    this.onAppWideFailure,
    this.isOnline,
    String? baseUrl,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? AtomServer.api,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 60),
             ),
           ) {
    // Every status comes back as a response, so classifyFailure reads the
    // body of a 403 or 422 instead of Dio turning it into an exception.
    _dio.options.validateStatus = (_) => true;
    _dio.options.headers['Accept'] = 'application/json';
  }

  final Dio _dio;
  final ApiAuthSource auth;
  final void Function(ApiFailure failure)? onAppWideFailure;

  /// Whether the phone has any network. With none, a call fails at once as
  /// offline instead of waiting out the 20 s connect timeout (No internet,
  /// 11.9, took half a minute to show).
  final Future<bool> Function()? isOnline;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required ApiParser<T> parse,
  }) => _send(
    () => _dio.get<Object?>(path, queryParameters: query, options: _options()),
    parse,
  );

  /// A file's bytes, from an address the server gave (a photo the Offline
  /// add-on keeps).
  ///
  /// Not through [_send]: this answer is the file itself, not the
  /// `{success, message, data}` envelope every other call uses. The token
  /// still goes with it, because the file is behind the same scope check
  /// as the row it hangs off.
  Future<ApiResult<List<int>>> getBytes(String url) async {
    if (isOnline case final online? when !await online()) {
      return _fail(const ApiFailure(ApiFailureKind.offline));
    }
    try {
      final r = await _dio.get<List<int>>(
        url,
        options: _options().copyWith(responseType: ResponseType.bytes),
      );
      final status = r.statusCode;
      final bytes = r.data;
      if (status == null || status < 200 || status >= 300 || bytes == null) {
        return _fail(classifyFailure(statusCode: status, body: null));
      }
      return ApiOk(bytes);
    } on DioException catch (e) {
      return _fail(_networkFailure(e));
    } on SocketException {
      return _fail(const ApiFailure(ApiFailureKind.offline));
    }
  }

  /// A PDF the server builds: a receipt, a quote, an invoice, a report.
  /// The app never lays one out itself, so the phone shares the same
  /// document the brand downloads from the portal.
  ///
  /// Not through [_send]: a good answer is the PDF itself. A failure is the
  /// usual JSON envelope, read like every other call's.
  ///
  /// Answers the bytes and the server's own file name
  /// (`Content-Disposition`, e.g. `receipt-RCT-2679.pdf`), when it gave one.
  Future<ApiResult<({Uint8List bytes, String? filename})>> getPdf(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (isOnline case final online? when !await online()) {
      return _fail(const ApiFailure(ApiFailureKind.offline));
    }
    final Response<List<int>> r;
    try {
      r = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: _options(accept: 'application/pdf, application/json').copyWith(
          responseType: ResponseType.bytes,
          // A long ledger or recovery sheet takes the server a while.
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
    } on DioException catch (e) {
      return _fail(_networkFailure(e));
    } on SocketException {
      return _fail(const ApiFailure(ApiFailureKind.offline));
    }
    final status = r.statusCode ?? 0;
    final bytes = r.data ?? const <int>[];
    final type = r.headers.value(Headers.contentTypeHeader) ?? '';
    if (status >= 200 && status < 300 && type.contains('pdf')) {
      return ApiOk((
        bytes: Uint8List.fromList(bytes),
        filename: pdfFilename(r.headers.value('content-disposition')),
      ));
    }
    Object? body;
    try {
      body = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      body = null;
    }
    return _fail(classifyFailure(statusCode: status, body: body));
  }

  /// [reportAppWide] false keeps a 401 (or another app-wide answer) to this
  /// call: sign-in's wrong password must not sign out a locked session.
  Future<ApiResult<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required ApiParser<T> parse,
    bool reportAppWide = true,
  }) => _send(
    () => _dio.post<Object?>(path, data: body ?? const {}, options: _options()),
    parse,
    reportAppWide: reportAppWide,
  );

  /// A `DELETE` (`products/{id}`, `products/{id}/gallery/{imageId}`).
  Future<ApiResult<T>> delete<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    required ApiParser<T> parse,
  }) => _send(
    () => _dio.delete<Object?>(
      path,
      data: body,
      queryParameters: query,
      options: _options(),
    ),
    parse,
  );

  /// A form with files (photos, receipts). List values are sent as repeated
  /// fields (`guarantor[]`), which is what the server's validation expects.
  Future<ApiResult<T>> postForm<T>(
    String path, {
    Map<String, dynamic> fields = const {},
    Map<String, File> files = const {},
    required ApiParser<T> parse,
  }) => _send(() async {
    final form = FormData();
    fields.forEach((key, value) {
      if (value is List) {
        for (final v in value) {
          form.fields.add(MapEntry(key, '$v'));
        }
      } else if (value != null) {
        form.fields.add(MapEntry(key, '$value'));
      }
    });
    for (final e in files.entries) {
      form.files.add(
        MapEntry(e.key, await MultipartFile.fromFile(e.value.path)),
      );
    }
    return _dio.post<Object?>(path, data: form, options: _options());
  }, parse);

  Options _options({String? accept}) {
    final token = auth.token;
    final outlet = auth.outletId;
    return Options(
      headers: {
        'Accept': ?accept,
        // The Brand Partner app v2, for server rules that differ from v1.
        'X-Atom-Brand-App': '2',
        // Which store build this is, so the server can tell an iPhone from
        // an Android phone and a pulled build from a good one
        // (docs/trd/2026-11-09-seller-app-updates.md).
        if (InstalledApp.current case final app?) ...{
          'X-Atom-Platform': app.platform,
          if (app.build > 0) 'X-Atom-Build': '${app.build}',
        },
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (outlet != null) 'X-Outlet': '$outlet',
      },
    );
  }

  Future<ApiResult<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    ApiParser<T> parse, {
    bool reportAppWide = true,
  }) async {
    ApiErr<T> fail(ApiFailure failure) =>
        reportAppWide ? _fail(failure) : ApiErr(failure);
    if (isOnline case final online? when !await online()) {
      return fail(const ApiFailure(ApiFailureKind.offline));
    }
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (e) {
      return fail(_networkFailure(e));
    } on SocketException {
      return fail(const ApiFailure(ApiFailureKind.offline));
    }

    final status = response.statusCode;
    final body = response.data;
    final ok =
        status != null &&
        status >= 200 &&
        status < 300 &&
        body is Map &&
        body['success'] == true;
    if (!ok) {
      return fail(classifyFailure(statusCode: status, body: body));
    }

    try {
      return ApiOk(parse(body['data']), message: serverMessage(body));
    } catch (e, st) {
      // An answer in a shape the app doesn't expect is a server failure for
      // the person, and a bug for us.
      debugPrint('[api] could not read ${response.requestOptions.path}: $e');
      debugPrintStack(stackTrace: st, maxFrames: 5);
      return fail(ApiFailure(ApiFailureKind.server, statusCode: status));
    }
  }

  ApiErr<T> _fail<T>(ApiFailure failure) {
    if (failure.isAppWide) onAppWideFailure?.call(failure);
    return ApiErr(failure);
  }

  static ApiFailure _networkFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiFailure(ApiFailureKind.timeout);
      case DioExceptionType.connectionError:
        return const ApiFailure(ApiFailureKind.offline);
      case DioExceptionType.unknown:
        return ApiFailure(
          e.error is SocketException
              ? ApiFailureKind.offline
              : ApiFailureKind.server,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return const ApiFailure(ApiFailureKind.server);
    }
  }
}

/// The file name in a `Content-Disposition` header
/// (`attachment; filename="receipt-RCT-2679.pdf"`, or the RFC 5987
/// `filename*=UTF-8''…` form), or null. Only the last path segment is
/// kept, so a name can never point outside the folder it's saved in.
@visibleForTesting
String? pdfFilename(String? disposition) {
  if (disposition == null) return null;
  final star = RegExp(
    r"filename\*\s*=\s*[^']*'[^']*'([^;]+)",
    caseSensitive: false,
  ).firstMatch(disposition);
  final plain = RegExp(
    r'filename\s*=\s*"?([^";]+)"?',
    caseSensitive: false,
  ).firstMatch(disposition);
  String? name;
  if (star != null) {
    try {
      name = Uri.decodeComponent(star.group(1)!.trim());
    } on ArgumentError {
      name = null;
    }
  }
  name ??= plain?.group(1)?.trim();
  name = name?.split(RegExp(r'[/\\]')).last.trim();
  return name == null || name.isEmpty ? null : name;
}

/// Small readers for loosely typed JSON. The server sends numbers as
/// strings in places, and ids as ints or strings, so models read through
/// these instead of casting.
abstract final class Json {
  static Map<String, dynamic> map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  static List<Object?> list(Object? v) => v is List ? v : const [];

  static String? str(Object? v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static int? integer(Object? v) => switch (v) {
    int i => i,
    double d => d.round(),
    String s => int.tryParse(s.trim()) ?? double.tryParse(s.trim())?.round(),
    _ => null,
  };

  static bool flag(Object? v) => switch (v) {
    bool b => b,
    num n => n != 0,
    String s => s == '1' || s.toLowerCase() == 'true',
    _ => false,
  };
}
