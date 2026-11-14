import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import 'ui/outlet_form_screen.dart';
import 'ui/outlet_screen.dart';
import 'ui/outlets_screen.dart';

/// Outlets (11.7–11.9, owner only). Owned by the Outlets feature: edit only
/// this file and the rest of `features/outlets/` (docs/v2-foundation.md).

/// Children of `/menu` (relative paths).
final outletsMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'outlets',
    builder: (_, _) => const OutletsScreen(),
    routes: [
      GoRoute(path: 'add', builder: (_, _) => const OutletFormScreen()),
      GoRoute(
        path: ':id',
        builder: (_, state) => OutletScreen(id: intParam(state, 'id')),
      ),
    ],
  ),
];
