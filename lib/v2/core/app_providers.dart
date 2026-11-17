import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'access/access_controller.dart';
import 'api/api_client.dart';
import 'api/api_result.dart';
import 'net/network_status.dart';
import 'session/session_controller.dart';

/// The one [ApiClient], wired to the session (token, outlet) and to the
/// handlers for app-wide failures.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    auth: _SessionAuth(ref),
    onAppWideFailure: (failure) => handleAppWideFailure(ref, failure),
    isOnline: () => ref.read(networkStatusProvider).check(),
  );
});

/// Where a failure that changes the whole app goes. Kept here, not in the
/// client, so the client stays free of Riverpod and easy to test.
void handleAppWideFailure(Ref ref, ApiFailure failure) {
  switch (failure.kind) {
    case ApiFailureKind.signedOut:
      ref.read(sessionProvider.notifier).signOut(reason: SignOutReason.expired);
    case ApiFailureKind.mustChangePassword:
      final s = ref.read(sessionProvider.notifier);
      final who = s.current?.who;
      if (who != null && !who.mustChangePassword) {
        s.updateWho(who.copyWith(mustChangePassword: true));
      }
    default:
      ref.read(accessProvider.notifier).onFailure(failure);
  }
}

class _SessionAuth implements ApiAuthSource {
  _SessionAuth(this._ref);
  final Ref _ref;

  @override
  String? get token => _ref.read(sessionProvider.notifier).current?.token;

  @override
  int? get outletId => _ref.read(sessionProvider.notifier).current?.outletId;
}
