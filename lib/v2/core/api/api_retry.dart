import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_result.dart';

/// Riverpod's retry for providers that read the server. A definite answer
/// (404, 403, 422, a block on the account) is final: asking again gives the
/// same answer, and Riverpod's default ten tries kept a "Not found" order
/// spinning for about 50 seconds. A dropped connection, a timeout or a 5xx
/// is tried again as Riverpod does by default.
Duration? apiRetry(int retryCount, Object error) {
  if (error is ApiFailure &&
      error.kind != ApiFailureKind.offline &&
      error.kind != ApiFailureKind.timeout &&
      error.kind != ApiFailureKind.server) {
    return null;
  }
  return ProviderContainer.defaultRetry(retryCount, error);
}
