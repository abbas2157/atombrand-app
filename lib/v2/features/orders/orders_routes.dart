import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import '../../app/routes.dart';
import 'ui/mark_delivered_screen.dart';
import 'ui/order_detail_screen.dart';
import 'ui/order_payment_screen.dart';
import 'ui/order_sheets.dart';
import 'ui/orders_list_screen.dart';
import 'ui/receipt_screen.dart';

/// Orders (6.1–6.7). Owned by the Orders feature: edit only this file and
/// the rest of `features/orders/` (docs/v2-foundation.md).

/// The Orders tab root: 6.1 cash orders, and with `?tab=atompay` 6.8
/// AtomPay orders (`V2Routes.atompayOrders`). `?status=Pending` and
/// `?payment=unpaid` open Cash orders filtered (a Home task); build the
/// address with `V2Routes.ordersWith`.
final ordersTab = GoRoute(
  path: V2Routes.orders,
  builder: (_, state) => OrdersTabScreen(
    atompay: state.uri.queryParameters['tab'] == 'atompay',
    status: state.uri.queryParameters['status'],
    payment: state.uri.queryParameters['payment'],
  ),
);

/// Opened over the tabs.
final ordersRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.orderPattern,
    builder: (_, state) => OrderScreen(uuid: textParam(state, 'uuid')),
    routes: [
      GoRoute(
        path: 'deliver',
        builder: (_, state) =>
            MarkDeliveredScreen(uuid: textParam(state, 'uuid')),
      ),
      GoRoute(
        path: 'payment',
        builder: (_, state) =>
            OrderPaymentScreen(uuid: textParam(state, 'uuid')),
      ),
      GoRoute(
        path: 'cancel',
        builder: (_, state) =>
            OrderSheetPage(uuid: textParam(state, 'uuid'), move: false),
      ),
      GoRoute(
        path: 'move',
        builder: (_, state) =>
            OrderSheetPage(uuid: textParam(state, 'uuid'), move: true),
      ),
      GoRoute(
        path: 'receipt',
        builder: (_, state) => ReceiptScreen(uuid: textParam(state, 'uuid')),
      ),
    ],
  ),
];
