import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_page.dart';
import '../../../core/api/api_result.dart';
import '../../../core/session/session_controller.dart';
import 'orders_models.dart';
import 'orders_repository.dart';

/// Read again when the person or the outlet chosen changes (`X-Outlet`).
void _followOutlet(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.outletId) : null,
  ),
);

/// The first page of cash orders for a query.
final ordersPageProvider = FutureProvider.autoDispose
    .family<ApiPage<CashOrder>, OrdersQuery>((ref, q) async {
      _followOutlet(ref);
      return switch (await ref.read(ordersRepositoryProvider).list(q)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

/// Orders per status key for the chips (the status of [q] is ignored).
final orderCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, OrdersQuery>((ref, q) async {
      _followOutlet(ref);
      return switch (await ref.read(ordersRepositoryProvider).counts(q)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

/// The order page (6.2).
final orderDetailProvider = FutureProvider.autoDispose
    .family<CashOrderDetail, String>((ref, uuid) async {
      _followOutlet(ref);
      return switch (await ref.read(ordersRepositoryProvider).detail(uuid)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

/// The receipt (6.7).
final orderReceiptProvider = FutureProvider.autoDispose
    .family<OrderReceipt, String>((ref, uuid) async {
      return switch (await ref.read(ordersRepositoryProvider).receipt(uuid)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

/// Reads an order again everywhere it shows, after a change.
void refreshOrder(WidgetRef ref, String uuid) {
  ref
    ..invalidate(orderDetailProvider(uuid))
    ..invalidate(ordersPageProvider)
    ..invalidate(orderCountsProvider)
    ..invalidate(orderReceiptProvider(uuid));
}
