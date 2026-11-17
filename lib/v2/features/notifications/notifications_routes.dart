import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import 'data/notifications_repository.dart';
import 'ui/allow_notifications_screen.dart';
import 'ui/notifications_screens.dart';

/// Notifications (15.x), opened over the tabs.
final notificationsRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.allowNotifications,
    builder: (_, _) => const AllowNotificationsScreen(),
  ),
  GoRoute(
    path: V2Routes.notifications,
    builder: (_, state) => NotificationsScreen(
      recommendations: state.uri.queryParameters['only'] == 'atomshop',
    ),
    routes: [
      GoRoute(
        path: 'settings',
        builder: (_, _) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: 'message',
        builder: (_, state) =>
            NoticeMessageScreen(notice: state.extra as Notice?),
      ),
    ],
  ),
];
