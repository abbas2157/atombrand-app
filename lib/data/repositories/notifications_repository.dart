import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../models/json.dart';

/// An inbox row (BRAND_APP.md §8.10).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.screen,
    this.data = const {},
    this.isRead = false,
    this.timeAgo,
    this.createdAt,
  });

  factory AppNotification.fromJson(Json j) => AppNotification(
        id: asInt(j['id']),
        type: asStrOr(j['type']),
        title: asStrOr(j['title']),
        body: asStrOr(j['body']),
        screen: asStr(j['screen']),
        data: asMap(j['data']),
        isRead: asBool(j['is_read']),
        timeAgo: asStr(j['time_ago']),
        createdAt: asStr(j['created_at']),
      );

  final int id;
  final String type;
  final String title;
  final String body;

  /// `order`, `bulk_request` or `product`.
  final String? screen;
  final Json data;
  final bool isRead;
  final String? timeAgo;
  final String? createdAt;

  /// The app route this notification opens, or null if it opens nothing.
  String? get route => switch (screen) {
        'order' when asStr(data['order_uuid']) != null =>
          '/orders/${asStrOr(data['order_type'], 'retail')}/${data['order_uuid']}',
        'bulk_request' when asStr(data['bulk_request_id']) != null => '/bulk/${data['bulk_request_id']}',
        'product' when asStr(data['product_id']) != null => '/products/${data['product_id']}',
        _ => null,
      };

  AppNotification markedRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        screen: screen,
        data: data,
        isRead: true,
        timeAgo: timeAgo,
        createdAt: createdAt,
      );
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<Paged<AppNotification>> list({int page = 1}) async =>
      Paged.fromJson((await _api.get('notifications', query: {'page': page})).map, AppNotification.fromJson);

  Future<int> unreadCount() async => asInt((await _api.get('notifications/count')).map['count']);

  Future<void> markRead(int id) => _api.post('notifications/$id/read');

  Future<void> markAllRead() => _api.post('notifications/read-all');
}

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));

/// Unread count for the bell. Invalidate it after reading notifications.
final unreadNotificationsProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).unreadCount(),
);
