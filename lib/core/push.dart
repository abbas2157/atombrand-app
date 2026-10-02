import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push-token plumbing (F12). The backend registers tokens via
/// `POST fcm-token`, but sends nothing to brands yet (BRAND_APP.md §11.1).
///
/// TODO(push): add `firebase_core` + `firebase_messaging` once the Firebase
/// project files (google-services.json / GoogleService-Info.plist) exist,
/// then return `FirebaseMessaging.instance.getToken()` here and forward
/// `onTokenRefresh` to [tokenRefreshes].
class PushService {
  Future<String?> currentToken() async => null;

  Stream<String> get tokenRefreshes => const Stream.empty();
}

final pushServiceProvider = Provider((ref) => PushService());
