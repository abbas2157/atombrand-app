import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import '../../app/routes.dart';
import 'ui/brand_page_screen.dart';
import 'ui/product_form_screen.dart';
import 'ui/products_screen.dart';

/// Catalogue and brand page (8.x). Owned by the Catalogue feature: edit
/// only this file and the rest of `features/catalogue/`
/// (docs/v2-foundation.md).

/// The Products tab root (8.1); `?status=` opens one status tile
/// (`V2Routes.productsWith`).
final catalogueTab = GoRoute(
  path: V2Routes.products,
  builder: (_, state) =>
      ProductsScreen(initialStatus: state.uri.queryParameters['status']),
);

/// Opened over the tabs.
final catalogueRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.productNew,
    builder: (_, _) => const ProductFormScreen(),
  ),
  GoRoute(
    path: V2Routes.productEditPattern,
    builder: (_, state) => ProductFormScreen(id: intParam(state, 'id')),
  ),
  GoRoute(path: V2Routes.brandPage, builder: (_, _) => const BrandPageScreen()),
];
