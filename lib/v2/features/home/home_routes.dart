import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import 'ui/home_screen.dart';
import 'ui/outlet_switcher_sheet.dart';
import 'ui/quick_actions_sheet.dart';
import 'ui/search_screen.dart';

/// Home (5.x). Owned by the Home feature: edit only this file and the rest
/// of `features/home/` (docs/v2-foundation.md).

/// The Home tab root (5.1 owner, 5.2 team member, 5.3 offline, 5.4 first
/// day, 5.5 basic package: one screen that reads the session and add-ons).
final homeTab = GoRoute(
  path: V2Routes.home,
  builder: (_, _) => const HomeScreen(),
);

/// Opened over the tabs. Quick actions and the outlet switcher are sheets
/// drawn as route pages, so the tab bar's ＋ and Home's header can push
/// them by constant.
final homeRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.quickActions,
    pageBuilder: (_, state) => HomeSheetPage<void>(
      key: state.pageKey,
      child: const QuickActionsSheet(),
    ),
  ),
  GoRoute(
    path: V2Routes.outletSwitcher,
    pageBuilder: (_, state) => HomeSheetPage<void>(
      key: state.pageKey,
      child: const OutletSwitcherSheet(),
    ),
  ),
  GoRoute(path: V2Routes.search, builder: (_, _) => const SearchScreen()),
];
