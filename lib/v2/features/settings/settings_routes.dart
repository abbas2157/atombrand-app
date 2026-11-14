import 'package:go_router/go_router.dart';

import 'ui/device_screens.dart';
import 'ui/security_screens.dart';
import 'ui/settings_screens.dart';

/// Settings (18.x) and its phone and security screens. Children of `/menu`
/// (relative paths). Shop settings, Daily summary and Rate are the Account
/// feature's (`V2Routes.shopSettings`, `dailySummary`, `rateApp`).
final settingsMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'settings',
    builder: (_, _) => const SettingsScreen(),
    routes: [
      GoRoute(path: 'password', builder: (_, _) => const PasswordScreen()),
      GoRoute(path: 'language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: 'devices', builder: (_, _) => const DevicesScreen()),
      GoRoute(path: 'feedback', builder: (_, _) => const FeedbackScreen()),
      GoRoute(path: 'data', builder: (_, _) => const DataScreen()),
      GoRoute(
        path: 'close-account',
        builder: (_, _) => const CloseAccountScreen(),
      ),
      GoRoute(path: 'security', builder: (_, _) => const SecurityScreen()),
      GoRoute(path: 'pin', builder: (_, _) => const SetPinScreen()),
      GoRoute(
        path: 'permissions',
        builder: (_, _) => const PermissionsScreen(),
      ),
      GoRoute(path: 'storage', builder: (_, _) => const StorageScreen()),
    ],
  ),
];
