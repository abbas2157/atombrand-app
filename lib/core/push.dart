import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/json.dart';
import '../data/repositories/notifications_repository.dart';

/// A push (§8.10), reduced to what the app shows and where a tap goes.
class PushMessage {
  const PushMessage({required this.title, required this.body, this.route});

  factory PushMessage.fromRemote(RemoteMessage m) {
    final data = Map<String, dynamic>.from(m.data);
    return PushMessage(
      title: m.notification?.title ?? asStrOr(data['title']),
      body: m.notification?.body ?? asStrOr(data['body']),
      route: notificationRoute(asStr(data['screen']), data),
    );
  }

  final String title;
  final String body;

  /// Where tapping it goes, or null if it opens nothing.
  final String? route;
}

/// Push via Firebase Cloud Messaging (F12). Firebase is optional: without
/// `google-services.json` / `GoogleService-Info.plist` (docs/RELEASE.md)
/// initialisation fails and every method here quietly does nothing.
class PushService {
  Future<bool>? _ready;
  bool _initialTaken = false;

  Future<bool> get _available => _ready ??= _init();

  static Future<bool> _init() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (e) {
      debugPrint('Push is off: $e');
      return false;
    }
  }

  Stream<T> _whenAvailable<T>(Stream<T> Function() source) async* {
    if (await _available) yield* source();
  }

  /// The FCM token, without prompting the user. Null when push is off.
  Future<String?> currentToken() async {
    if (!await _available) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('No FCM token: $e');
      return null;
    }
  }

  Stream<String> get tokenRefreshes => _whenAvailable(() => FirebaseMessaging.instance.onTokenRefresh);

  /// Asks to show notifications (iOS, Android 13+). Call once signed in.
  Future<void> requestPermission() async {
    if (!await _available) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('Push permission request failed: $e');
    }
  }

  /// Pushes that arrive while the app is open; the OS shows no banner for these.
  Stream<PushMessage> get foreground => _whenAvailable(() => FirebaseMessaging.onMessage.map(PushMessage.fromRemote));

  /// Pushes the user tapped, starting with the one that launched the app.
  Stream<PushMessage> get opened => _whenAvailable(() async* {
        if (!_initialTaken) {
          _initialTaken = true;
          final first = await FirebaseMessaging.instance.getInitialMessage();
          if (first != null) yield PushMessage.fromRemote(first);
        }
        yield* FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);
      });
}

final pushServiceProvider = Provider((ref) => PushService());
