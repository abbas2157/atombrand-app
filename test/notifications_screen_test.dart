import 'package:atombrand_app/core/session.dart';
import 'package:atombrand_app/core/theme.dart';
import 'package:atombrand_app/data/models/dashboard.dart';
import 'package:atombrand_app/data/models/json.dart';
import 'package:atombrand_app/data/repositories/notifications_repository.dart';
import 'package:atombrand_app/features/dashboard/dashboard_screen.dart';
import 'package:atombrand_app/features/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _ago(Duration d) {
  final t = DateTime.now().subtract(d);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:00';
}

class _FakeRepo implements NotificationsRepository {
  final read = <int>[];
  final items = [
    AppNotification.fromJson({
      'id': 1, 'type': 'brand_new_order', 'screen': 'order', 'title': 'New order received',
      'body': "New order for 'OXY 4318L (BB) Gold' (Rs. 78,840).", 'is_read': false, 'created_at': _ago(const Duration(minutes: 5)),
    }),
    AppNotification.fromJson({
      'id': 2, 'type': 'brand_new_bulk_request', 'screen': 'bulk_request', 'title': 'New bulk request',
      'body': "Saeed Trader wants 80 × 'OXY 6518G'.", 'is_read': true, 'created_at': _ago(const Duration(days: 1, hours: 1)),
    }),
    AppNotification.fromJson({
      'id': 3, 'type': 'brand_product_reviewed', 'screen': 'product', 'title': 'Product put on hold',
      'body': "'OXY 5018 N1' is on hold.", 'data': {'status': 'On hold', 'product_id': '164'}, 'is_read': false,
      'created_at': _ago(const Duration(days: 3)),
    }),
  ];

  @override
  Future<Paged<AppNotification>> list({int page = 1}) async =>
      Paged(items, const Pagination(), {'unread_count': items.where((n) => !n.isRead).length});
  @override
  Future<int> unreadCount() async => 0;
  @override
  Future<void> markRead(int id) async => read.add(id);
  @override
  Future<void> markAllRead() async {}
}

void main() {
  testWidgets('groups, filters and marks read with a swipe', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        signedInProvider.overrideWithValue(null),
        dashboardProvider.overrideWith((ref) => Future<Dashboard>.error('offline')),
      ],
      child: MaterialApp(theme: buildTheme(AppPalette.light), home: const NotificationsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('Product put on hold'), findsOneWidget);

    // Chips only for categories present; All shows the unread count.
    expect(find.text('Bulk leads'), findsOneWidget);
    expect(find.text('Payments'), findsNothing);
    await tester.tap(find.text('Bulk leads'));
    await tester.pumpAndSettle();
    expect(find.text('New order received'), findsNothing);
    expect(find.text('New bulk request'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('New order received'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(repo.read, [1]);
    expect(find.text('New order received'), findsOneWidget); // marked read, not removed
  });
}
