import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import 'ui/state_screens.dart';

/// App-wide state screens (13.x, 18.15, 18.16).
final stateRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.signedOut,
    builder: (_, state) =>
        SignedOutScreen(from: state.uri.queryParameters['from']),
  ),
  GoRoute(
    path: V2Routes.maintenance,
    builder: (_, _) => const MaintenanceScreen(),
  ),
  GoRoute(
    path: V2Routes.updateRequired,
    builder: (_, _) => const UpdateRequiredScreen(),
  ),
  GoRoute(
    path: V2Routes.stateRemoved,
    builder: (_, _) => const NoPackageScreen(removed: true),
  ),
  GoRoute(
    path: V2Routes.stateNoPlan,
    builder: (_, _) => const NoPackageScreen(removed: false),
  ),
  GoRoute(path: V2Routes.notInRole, builder: (_, _) => const NotInRoleScreen()),
  GoRoute(
    path: V2Routes.restricted,
    builder: (_, _) => const RestrictedScreen(),
  ),
];
