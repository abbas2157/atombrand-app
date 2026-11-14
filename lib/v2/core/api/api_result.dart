import 'package:flutter/foundation.dart';

/// What went wrong with a call, in the terms the app acts on.
enum ApiFailureKind {
  /// No connection. Without the Offline add-on: the "No internet" screen.
  offline,

  /// The server didn't answer in time.
  timeout,

  /// 401: the token is finished. Signed out, route kept.
  signedOut,

  /// An agent who hasn't chosen their own password yet.
  mustChangePassword,

  /// 403 for a permission the role lacks: "Not in your role".
  notInRole,

  /// 403 for an owner-only area (team, plan, settings).
  ownerOnly,

  /// A late bill (more than 15 days): writes refused, Pay shown.
  readOnly,

  /// Atomshop paused changes on the account; no Pay button.
  restricted,

  /// The package was removed: only My plan, billing and profile open.
  packageRemoved,

  /// No active plan at all.
  noPlan,

  /// 403 with `data.feature_off`: a paid add-on (`data.feature`) is off.
  /// Hide the screen and offer "Turn it on in Plan & billing".
  featureOff,

  /// 404: the record doesn't exist, is outside the scope, or the add-on is
  /// off.
  notFound,

  /// The input was refused; see [ApiFailure.fieldErrors].
  validation,

  /// 409: what the app was shown has changed on the server (a quote); the
  /// new figures are in [ApiFailure.body].
  conflict,

  /// 503: Atomshop is being updated.
  maintenance,

  /// Anything else, including an answer the app couldn't read.
  server,
}

/// A failed call: the kind, the server's message, and the field errors of a
/// refused form.
@immutable
class ApiFailure {
  const ApiFailure(
    this.kind, {
    this.message,
    this.fieldErrors = const {},
    this.statusCode,
    this.body,
  });

  final ApiFailureKind kind;

  /// The server's own words, shown to the person when there are any.
  final String? message;

  /// `field → first error`, from a 422 or a `success: false` with errors.
  final Map<String, String> fieldErrors;
  final int? statusCode;

  /// The raw answer, for screens that need more (`days_late`, `due`).
  final Map<String, dynamic>? body;

  /// Failures that change what the whole app shows, not just one screen.
  bool get isAppWide => const {
    ApiFailureKind.signedOut,
    ApiFailureKind.mustChangePassword,
    ApiFailureKind.readOnly,
    ApiFailureKind.restricted,
    ApiFailureKind.packageRemoved,
    ApiFailureKind.noPlan,
    ApiFailureKind.maintenance,
    ApiFailureKind.featureOff,
  }.contains(kind);

  @override
  String toString() => 'ApiFailure($kind, $statusCode, $message)';
}

/// The answer to a call: [ApiOk] with the parsed value, or [ApiErr].
sealed class ApiResult<T> {
  const ApiResult();

  /// The value, or null on failure.
  T? get valueOrNull => switch (this) {
    ApiOk(:final value) => value,
    ApiErr() => null,
  };

  ApiFailure? get failureOrNull => switch (this) {
    ApiOk() => null,
    ApiErr(:final failure) => failure,
  };

  ApiResult<R> map<R>(R Function(T value) f) => switch (this) {
    ApiOk(:final value, :final message) => ApiOk(f(value), message: message),
    ApiErr(:final failure) => ApiErr(failure),
  };
}

final class ApiOk<T> extends ApiResult<T> {
  const ApiOk(this.value, {this.message});
  final T value;

  /// The server's own sentence on success (the envelope's `message`, e.g.
  /// "Your account has been deleted."), for a screen that shows it. Null
  /// when the answer had none, or didn't come from the server.
  final String? message;
}

final class ApiErr<T> extends ApiResult<T> {
  const ApiErr(this.failure);
  final ApiFailure failure;
}

/// Reads a server answer into an [ApiFailure].
///
/// The server marks the app-wide states with flags in the body, often on a
/// plain 403, so the flags are read first and the status code second. A
/// `success: false` on HTTP 200 is a refusal too (the server's `sendError`
/// defaults to 200).
ApiFailure classifyFailure({required int? statusCode, Object? body}) {
  final map = body is Map ? Map<String, dynamic>.from(body) : null;
  final message = _message(map);
  ApiFailure f(ApiFailureKind kind) => ApiFailure(
    kind,
    message: message,
    statusCode: statusCode,
    body: map,
    fieldErrors: kind == ApiFailureKind.validation
        ? _fieldErrors(map)
        : const {},
  );

  if (map != null) {
    if (map['must_change_password'] == true) {
      return f(ApiFailureKind.mustChangePassword);
    }
    if (map['package_removed'] == true) return f(ApiFailureKind.packageRemoved);
    if (map['requires_subscription'] == true) return f(ApiFailureKind.noPlan);
    if (map['restricted'] == true) return f(ApiFailureKind.restricted);
    if (map['billing_state'] == 'readonly') return f(ApiFailureKind.readOnly);
    if (map['owner_only'] == true) return f(ApiFailureKind.ownerOnly);
    // An add-on that is off: `{feature_off: true, feature: "inventory"}`,
    // in `data` (EnsureBrandAddon, stock) or, from an older server, at the
    // top. Stock's older refusal said `data.reason: inventory` instead.
    // `failure.body['feature']` names the add-on either way. A lapsed
    // add-on (`reason: read_only`) is not off: its screens stay readable.
    final data = map['data'];
    final inner = data is Map ? Map<String, dynamic>.from(data) : null;
    final off =
        inner?['feature_off'] == true ||
        map['feature_off'] == true ||
        inner?['reason'] == 'inventory';
    if (off) {
      return ApiFailure(
        ApiFailureKind.featureOff,
        message: message,
        statusCode: statusCode,
        body: {
          ...map,
          ...?inner,
          'feature':
              _str(inner?['feature']) ??
              _str(map['feature']) ??
              (inner?['reason'] == 'inventory' ? 'inventory' : null),
        },
      );
    }
    if (data is Map) {
      if (data['owner_only'] == true) return f(ApiFailureKind.ownerOnly);
      if (data['must_change_password'] == true) {
        return f(ApiFailureKind.mustChangePassword);
      }
    }
  }

  return switch (statusCode) {
    401 => f(ApiFailureKind.signedOut),
    403 => f(ApiFailureKind.notInRole),
    404 => f(ApiFailureKind.notFound),
    409 => f(ApiFailureKind.conflict),
    422 => f(ApiFailureKind.validation),
    503 => f(ApiFailureKind.maintenance),
    // A refusal on 200 that carries field errors is a validation answer.
    200 ||
    201 when _fieldErrors(map).isNotEmpty => f(ApiFailureKind.validation),
    _ => f(ApiFailureKind.server),
  };
}

String? _str(Object? v) {
  final s = v is String ? v.trim() : null;
  return s == null || s.isEmpty ? null : s;
}

/// The envelope's `message`, trimmed; null when there is none.
String? serverMessage(Object? body) =>
    _message(body is Map ? Map<String, dynamic>.from(body) : null);

String? _message(Map<String, dynamic>? map) {
  final m = map?['message'];
  return m is String && m.trim().isNotEmpty ? m.trim() : null;
}

/// Laravel validation errors: `data` (or `errors`) as `{field: [messages]}`.
Map<String, String> _fieldErrors(Map<String, dynamic>? map) {
  final raw = map?['errors'] ?? map?['data'];
  if (raw is! Map) return const {};
  final out = <String, String>{};
  raw.forEach((key, value) {
    if (value is List && value.isNotEmpty && value.first is String) {
      out['$key'] = value.first as String;
    } else if (value is String) {
      out['$key'] = value;
    }
  });
  return out;
}
