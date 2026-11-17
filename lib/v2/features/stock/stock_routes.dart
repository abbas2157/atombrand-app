import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import '../../app/routes.dart';
import 'ui/inventory_home_screen.dart';
import 'ui/product_stock_screen.dart';
import 'ui/scan_unit_screen.dart';
import 'ui/stock_adjust_screen.dart';
import 'ui/stock_history_screen.dart';
import 'ui/stock_in_screen.dart';
import 'ui/stock_list_screen.dart';
import 'ui/stock_parts.dart';
import 'ui/stock_transfer_screen.dart';
import 'ui/warehouses_screen.dart';

/// Stock (9.x, Inventory add-on; the route rule in `routes.dart` sends a
/// person without it Home). Owned by the Stock feature: edit only this file
/// and the rest of `features/stock/` (docs/v2-foundation.md).
///
/// Query parameters the stock screens read besides the V2Routes ones:
/// `move?serial=&product=`, `adjust?serial=&dir=in&product=`,
/// `history?product_id=`.

String? _text(GoRouterState state, String key) {
  final v = state.uri.queryParameters[key]?.trim();
  return v == null || v.isEmpty ? null : v;
}

/// Opened over the tabs.
final stockRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.stock,
    builder: (_, _) => const InventoryHomeScreen(),
    routes: [
      GoRoute(
        path: 'list',
        builder: (_, state) =>
            StockListScreen(show: _text(state, 'show') ?? 'all'),
      ),
      GoRoute(
        path: 'product/:id',
        builder: (_, state) =>
            ProductStockScreen(productId: intParam(state, 'id')),
      ),
      GoRoute(
        path: 'in',
        builder: (_, state) => StockInScreen(
          productId: intQuery(state, 'product'),
          serial: _text(state, 'serial'),
        ),
      ),
      GoRoute(
        path: 'move',
        builder: (_, state) => StockTransferScreen(
          serial: _text(state, 'serial'),
          productId: intQuery(state, 'product'),
        ),
      ),
      // 9.7 is a bottom sheet over the screen that opened it.
      GoRoute(
        path: 'adjust',
        pageBuilder: (_, state) => StockSheetPage<void>(
          key: state.pageKey,
          child: StockAdjustScreen(
            serial: _text(state, 'serial'),
            found: _text(state, 'dir') == 'in',
            productId: intQuery(state, 'product'),
          ),
        ),
      ),
      GoRoute(path: 'scan', builder: (_, _) => const ScanUnitScreen()),
      GoRoute(
        path: 'history',
        builder: (_, state) =>
            StockHistoryScreen(productId: intQuery(state, 'product_id')),
      ),
      GoRoute(path: 'warehouses', builder: (_, _) => const WarehousesScreen()),
    ],
  ),
];
