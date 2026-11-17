import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/access/access.dart';
import '../core/access/access_controller.dart';
import '../core/lock/app_lock.dart';
import '../core/lock/quick_sign_in.dart';
import '../core/session/session_controller.dart';
import '../features/account/account_routes.dart';
import '../features/ask_atom/ask_atom_routes.dart';
import '../features/atompay/atompay_routes.dart';
import '../features/auth/auth_routes.dart';
import '../features/auth/data/tour_due.dart';
import '../features/bulk/bulk_routes.dart';
import '../features/catalogue/catalogue_routes.dart';
import '../features/help/help_routes.dart';
import '../features/home/home_routes.dart';
import '../features/menu/ui/menu_screen.dart';
import '../features/notifications/notifications_routes.dart';
import '../features/orders/orders_routes.dart';
import '../features/outlets/outlets_routes.dart';
import '../features/settings/settings_routes.dart';
import '../features/states/states_routes.dart';
import '../features/states/ui/state_screens.dart' show NotFoundScreen;
import '../features/stock/stock_routes.dart';
import '../features/sync/data/getting_ready_due.dart';
import '../features/sync/sync_routes.dart';
import '../features/team/team_routes.dart';
import '../features/terms/terms_routes.dart';
import 'guards.dart';
import 'routes.dart';
import 'shell.dart';
import 'splash_hold.dart';

/// The root navigator. Routes outside the tab shell open on it, over the
/// tabs, so the tab bar steps aside for them.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The way-in facts the guards need, from the lock and the tour's memory.
final wayInProvider = Provider<WayIn>((ref) {
  final lock = ref.watch(appLockProvider);
  final tour = ref.watch(tourDueProvider);
  final offline = ref.watch(accessProvider.select((a) => a.has(Addon.offline)));
  return WayIn(
    ready: lock.loaded && tour != null,
    pinDue: lock.prefs.pinDue,
    tourDue: tour ?? false,
    readyDue: offline && ref.watch(gettingReadyDueProvider),
    passwordMode: lock.passwordMode,
  );
});

/// The v2 router.
///
/// This file is shared and changes rarely: each feature registers its own
/// screens in `features/<feature>/<feature>_routes.dart`, which is spread
/// in below. A feature adds or changes a screen by editing only its own
/// routes file; the path constants live in `routes.dart`.
///
/// It re-runs the guards whenever the session or the account's access
/// changes, so signing in, a 401, a removed package or maintenance move
/// the person without any screen pushing routes itself.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  // The lock first, so it hears a sign-in before the guards run again.
  ref.read(appLockProvider);
  ref.read(quickSignInProvider);
  ref.read(tourDueProvider);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(accessProvider, (_, _) => refresh.value++);
  ref.listen(wayInProvider, (_, _) => refresh.value++);
  ref.listen(splashHoldProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: V2Routes.launch,
    refreshListenable: refresh,
    // Each tab's stack survives Android killing the app.
    restorationScopeId: 'router',
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => resolveRedirect(
      GuardInput(
        location: state.uri,
        session: ref.read(sessionProvider),
        access: ref.read(accessProvider),
        wayIn: ref.read(wayInProvider),
        splashHeld: ref.read(splashHoldProvider),
      ),
    ),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      ...authRoutes,
      ...termsRoutes,
      ...stateRoutes,

      // The four tabs (5.1 Home · 6.1 Orders · ＋ · 7.1 Bulk deals ·
      // 8.1 Products). The ＋ opens Quick actions (5.6), not a tab.
      StatefulShellRoute.indexedStack(
        restorationScopeId: 'shell',
        builder: (_, _, shell) => AtomShell(navigationShell: shell),
        branches: [
          _tab(homeTab),
          _tab(ordersTab),
          _tab(bulkTab),
          _tab(catalogueTab),
        ],
      ),

      // Over the tabs.
      ...homeRoutes,
      ...ordersRoutes,
      ...atompayRoutes,
      ...bulkRoutes,
      ...catalogueRoutes,
      ...stockRoutes,
      ...syncRoutes,
      ...notificationsRoutes,

      // The Menu (12.1, from the avatar) and everything opened from it.
      GoRoute(
        path: V2Routes.menu,
        builder: (_, _) => const MenuScreen(),
        routes: [
          ...accountMenuRoutes,
          ...teamMenuRoutes,
          ...outletsMenuRoutes,
          ...askAtomMenuRoutes,
          ...syncMenuRoutes,
          ...helpMenuRoutes,
          ...settingsMenuRoutes,
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

StatefulShellBranch _tab(GoRoute root) =>
    StatefulShellBranch(restorationScopeId: 'tab${root.path}', routes: [root]);
