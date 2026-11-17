import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../session/session_store.dart';
import '../../features/sync/data/background_sync.dart';
import '../api/atom_server.dart';
import '../quiet_logs.dart';
import '../update/update_store.dart';

/// Receives messages while the app is backgrounded or terminated.
///
/// Must be a top-level (or static) function annotated with
/// `@pragma('vm:entry-point')`: the platform may invoke it in a fresh
/// background isolate that never ran `main()`, so Firebase needs to be
/// (re)initialized before anything else can touch it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  quietLogsInRelease();
  if (Firebase.apps.isEmpty) {
    // From google-services.json / GoogleService-Info.plist (docs/RELEASE.md).
    await Firebase.initializeApp();
  }
  debugPrint('[FCM] Background message received — id: ${message.messageId}');
  debugPrint(
    '[FCM] Background notification — title: ${message.notification?.title}, '
    'body: ${message.notification?.body}',
  );
  debugPrint('[FCM] Background data payload: ${message.data}');
  // Atomshop's "something changed" nudge (`SyncNow.php`) with the app in
  // the background or closed: a sync as soon as there is a network,
  // rather than when the seller next opens the app.
  // Coalesced: a closed app syncs at most once every few minutes however
  // many nudges arrive (BackgroundSync.nudgeGap).
  if (message.data['type'] == 'sync_now') {
    await BackgroundSync.soon(nudge: true);
  }
  // "Check for an update now" (admin: App updates): the next open asks the
  // server instead of using the answer it kept.
  if (message.data['type'] == 'app_update') await FileUpdateStore.markStale();
}

class FcmService {
  FcmService._();

  static final _dio = Dio(
    BaseOptions(
      baseUrl: AtomServer.api,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'X-Atom-Brand-App': '2',
      },
    ),
  );

  /// `POST fcm-token {fcm_token}` (signed in): links this phone to the
  /// person. Signing out revokes the token on the server (`auth/logout`),
  /// which unlinks it there.
  static const _fcmAttachUser = 'fcm-token';
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());
  static const _keyFcmToken = 'fcm_token';

  /// The status bar icon. The launcher icon until a white status-bar
  /// shape (`res/drawable/ic_stat_brand.xml`) is drawn for Brand Partner.
  static const _statusIcon = '@mipmap/ic_launcher';
  static StreamSubscription<String>? _refreshSubscription;
  static bool _listenersAttached = false;

  /// Android requires a registered channel before any notification can be
  /// shown on it (Android 8+). One "important updates" channel covers every
  /// push this app sends: orders, bulk requests, billing, account activity.
  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'Important updates',
    description: 'Order, bulk request, billing and account notifications.',
    importance: Importance.high,
  );

  /// [requestPermission] false leaves the system prompt for later: v2
  /// explains why first (canvas 16.8) and calls [requestPermission] itself.
  static Future<void> initialize({bool requestPermission = true}) async {
    if (kIsWeb) return;
    if (!_isSupportedPlatform) return;

    if (requestPermission) await _requestPermission();
    // Showing pushes while the app is open is a nicety; the listeners below
    // are not. A failure here (a missing icon once stopped everything after
    // it: the sync and update nudges, opening a tapped push, new tokens)
    // must never take them with it.
    try {
      await _initLocalNotifications();
    } catch (e) {
      debugPrint('[FCM] local notifications did not start: $e');
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _attachMessageListeners();

    final token = await _fetchTokenWithRetry();
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: _keyFcmToken, value: token);
      await syncToken(token);
    } else {
      debugPrint('[FCM] No token obtained — skipping initial sync.');
    }

    await _refreshSubscription?.cancel();
    _refreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed: $newToken');
      await _storage.write(key: _keyFcmToken, value: newToken);
      await syncToken(newToken);
    });
  }

  /// `getToken()` can transiently throw `SERVICE_NOT_AVAILABLE` — e.g. while
  /// a freshly created Firebase project finishes provisioning, or on a brief
  /// connectivity blip at cold start. Retry with backoff before giving up;
  /// `onTokenRefresh` will pick it up later regardless if every attempt fails.
  static Future<String?> _fetchTokenWithRetry({int maxAttempts = 3}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final token = await _messaging.getToken();
        debugPrint('[FCM] Device token: $token');
        return token;
      } catch (e, st) {
        debugPrint(
          '[FCM] _messaging.getToken() threw on attempt $attempt/$maxAttempts: $e',
        );
        if (attempt == maxAttempts) {
          debugPrint('[FCM] $st');
          return null;
        }
        final delay = Duration(seconds: 2 * attempt);
        debugPrint('[FCM] Retrying getToken() in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
    return null;
  }

  // ── Foreground display & tap-to-open ───────────────────────────────────

  static Future<void> _initLocalNotifications() async {
    // A drawable, by name: the plugin looks for small icons among
    // drawables, and 'ic_launcher' is only a mipmap — asking for it failed
    // with invalid_icon. `ic_stat_atom` is the white status bar shape
    // (res/drawable/ic_stat_atom.xml); the manifest uses it too.
    const androidInit = AndroidInitializationSettings(_statusIcon);
    // Permission is requested once via `_requestPermission()` (covers both
    // FCM and local alerts on iOS), so the plugin shouldn't prompt again.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // iOS stays silent for foreground pushes unless told otherwise.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Set by the app: a tapped push opens its screen. A tap that arrives
  /// before it is set (the app started from the notification) is kept and
  /// delivered when it is.
  static void Function(Map<String, dynamic> data)? get onOpen => _onOpen;
  static set onOpen(void Function(Map<String, dynamic> data)? f) {
    _onOpen = f;
    final pending = _pendingOpen;
    if (f != null && pending != null) {
      _pendingOpen = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => f(pending));
    }
  }

  static void Function(Map<String, dynamic> data)? _onOpen;
  static Map<String, dynamic>? _pendingOpen;

  static void _deliverOpen(Map<String, dynamic> data) {
    final f = _onOpen;
    if (f == null) {
      _pendingOpen = data;
    } else {
      f(data);
    }
  }

  /// Set by the app: a push while the app is open shows its banner instead
  /// of a system notification. Null shows the system notification.
  static void Function(String title, String body, Map<String, dynamic> data)?
  onForeground;

  /// Set by the app: every message's data, whether or not it carries
  /// anything to show. Atomshop's "sync now" nudge (`SyncNow.php`) is a
  /// data-only message — `{type: sync_now, reason}` with no notification
  /// — so it would otherwise be dropped on the floor here.
  static void Function(Map<String, dynamic> data)? onData;

  /// Set by the app: Atomshop says to check for an update now
  /// (`{type: app_update}`, admin: App updates).
  static void Function()? onAppUpdate;

  static void _attachMessageListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    // App is open: the OS won't surface a banner for us, so render one.
    FirebaseMessaging.onMessage.listen((message) {
      onData?.call(message.data);
      if (message.data['type'] == 'app_update') onAppUpdate?.call();
      _showLocalNotification(message);
    });

    // App was backgrounded and the user tapped the system notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    // App was terminated and launched by tapping the notification.
    _messaging.getInitialMessage().then((message) {
      if (message != null) _openFromMessage(message);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    debugPrint('[FCM] Foreground message received — id: ${message.messageId}');
    debugPrint(
      '[FCM] Notification — title: ${notification?.title}, '
      'body: ${notification?.body}',
    );
    debugPrint('[FCM] Data payload: ${message.data}');
    if (notification == null) return;
    if (onForeground != null) {
      onForeground!(
        notification.title ?? '',
        notification.body ?? '',
        message.data,
      );
      return;
    }

    final body = notification.body;
    final imageUrl =
        notification.android?.imageUrl ?? notification.apple?.imageUrl;
    final bigPicture = imageUrl == null
        ? null
        : await _downloadBitmap(imageUrl);

    StyleInformation? styleInformation;
    if (bigPicture != null) {
      styleInformation = BigPictureStyleInformation(
        bigPicture,
        contentTitle: notification.title,
        summaryText: body,
        hideExpandedLargeIcon: true,
      );
    } else if (body != null && body.length > 40) {
      styleInformation = BigTextStyleInformation(body);
    }

    await _localNotifications.show(
      id: message.hashCode & 0x7fffffff,
      title: notification.title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          // Always ours: a name sent by the server that this app does not
          // have would stop the notification from showing at all.
          icon: _statusIcon,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: const Color(0xFFFFA500),
          styleInformation: styleInformation,
          groupKey: _androidChannel.id,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Downloads a remote image for the big-picture notification style.
  ///
  /// Best effort: a slow/failed fetch must not block the notification — the
  /// caller falls back to a plain text-style notification when this is null.
  static Future<AndroidBitmap<Object>?> _downloadBitmap(String url) async {
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      return ByteArrayAndroidBitmap(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('[FCM] Failed to download notification image $url: $e');
      return null;
    }
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint(
      '[FCM] Local notification tapped — payload: ${response.payload}',
    );
    final decoded = response.payload == null
        ? null
        : jsonDecode(response.payload!);
    _deliverOpen(decoded is Map ? Map<String, dynamic>.from(decoded) : {});
  }

  static void _openFromMessage(RemoteMessage message) {
    final notification = message.notification;
    debugPrint(
      '[FCM] Notification opened app — title: ${notification?.title}, '
      'body: ${notification?.body}',
    );
    debugPrint('[FCM] Data payload: ${message.data}');
    _deliverOpen(message.data);
  }

  static Future<String?> getToken() async {
    if (kIsWeb || !_isSupportedPlatform) return null;
    final existing = await _storage.read(key: _keyFcmToken);
    if (existing != null && existing.isNotEmpty) return existing;

    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] getToken() fetched fresh token: $token');
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: _keyFcmToken, value: token);
      }
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken() failed: $e');
      return null;
    }
  }

  static Future<void> syncToken([String? token]) async {
    final resolvedToken = token ?? await getToken();
    if (resolvedToken == null || resolvedToken.isEmpty) {
      debugPrint('[FCM] syncToken() — no token to sync, aborting.');
      return;
    }

    final userId = await _signedInUserId();
    if (userId != null && userId.isNotEmpty) {
      await attachUser(userId: userId, fcmToken: resolvedToken);
      return;
    }

    // Nobody signed in yet: the token goes with the sign-in instead.
    await storeGuestToken(resolvedToken);
  }

  /// The signed-in person's user id, from v2's stored session.
  static Future<String?> _signedInUserId() async {
    final session = await const SecureSessionStore().read();
    return session?.userId.toString();
  }

  /// The brand server has no guest registration: a phone is linked at
  /// sign-in (`fcm-token`), so nothing is sent before then.
  static Future<void> storeGuestToken(String fcmToken) async {}

  static Future<void> attachUser({
    required String userId,
    String? fcmToken,
  }) async {
    final resolvedToken = fcmToken ?? await getToken();
    if (resolvedToken == null || resolvedToken.isEmpty || userId.isEmpty) {
      return;
    }
    final session = await const SecureSessionStore().read();
    final bearer = session?.token;
    if (bearer == null || bearer.isEmpty) return;
    await _safePost(_fcmAttachUser, {
      'fcm_token': resolvedToken,
    }, bearer: bearer);
  }

  /// Nothing to send: `auth/logout` revokes the token, which unlinks the
  /// phone on the server.
  static Future<void> unlinkUser({String? userId, String? fcmToken}) async {}

  /// Asks the phone for permission to show notifications. True when they
  /// are allowed afterwards.
  static Future<bool> requestPermission() async {
    if (kIsWeb || !_isSupportedPlatform || Firebase.apps.isEmpty) return false;
    await _requestPermission();
    return notificationsAllowed();
  }

  /// Whether notifications are allowed now, without asking.
  static Future<bool> notificationsAllowed() async {
    if (kIsWeb || !_isSupportedPlatform || Firebase.apps.isEmpty) return false;
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[FCM] Reading notification settings threw: $e');
      return false;
    }
  }

  static Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      debugPrint(
        '[FCM] Permission request result: ${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('[FCM] Permission request threw: $e');
      // Permission prompts are platform-dependent; token sync remains best effort.
    }
  }

  static Future<void> _safePost(
    String endpoint,
    Map<String, dynamic> data, {
    String? bearer,
  }) async {
    try {
      debugPrint('[FCM] POST $endpoint');
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
        ),
      );
      debugPrint('[FCM] POST $endpoint <- ${response.statusCode}');
    } catch (e) {
      debugPrint('[FCM] POST $endpoint threw: $e');
      // FCM sync must not block app launch, auth, or logout.
    }
  }

  static bool get _isSupportedPlatform {
    return Firebase.apps.isNotEmpty &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }
}
