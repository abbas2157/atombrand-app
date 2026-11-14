import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import 'ui/getting_ready_screen.dart';
import 'ui/sync_attention_screen.dart';
import 'ui/sync_centre_screen.dart';
import 'ui/sync_clash_screen.dart';
import 'ui/sync_phones_screen.dart';
import 'ui/sync_running_screen.dart';
import 'ui/sync_update_screen.dart';
import 'ui/sync_waiting_screen.dart';

/// Sync centre (10.x, Offline add-on). Owned by the Sync feature: edit only
/// this file and the rest of `features/sync/` (docs/v2-foundation.md).
///
/// The states that cover the whole app (3.4 offline limit, 3.5 account on
/// hold, 10.9 no internet, 10.10 offline ended) are drawn by
/// `ui/offline_gate.dart`, not routes; 10.8 (sign a phone out) is a sheet
/// on 10.7.

/// Opened over the tabs.
final syncRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.gettingReady,
    builder: (_, _) => const GettingReadyScreen(),
  ),
];

/// Children of `/menu` (relative paths).
final syncMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'sync',
    builder: (_, _) => const SyncCentreScreen(),
    routes: [
      GoRoute(path: 'waiting', builder: (_, _) => const SyncWaitingScreen()),
      GoRoute(
        path: 'attention',
        builder: (_, _) => const SyncAttentionScreen(),
      ),
      // `?id=<outbox action id>`: V2Routes.syncClash has no parameter.
      GoRoute(
        path: 'clash',
        builder: (_, state) =>
            SyncClashScreen(id: state.uri.queryParameters['id'] ?? ''),
      ),
      GoRoute(path: 'running', builder: (_, _) => const SyncRunningScreen()),
      GoRoute(path: 'update', builder: (_, _) => const SyncUpdateScreen()),
      GoRoute(path: 'phones', builder: (_, _) => const SyncPhonesScreen()),
    ],
  ),
];
