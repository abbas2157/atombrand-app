import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import '../settings/ui/settings_screens.dart' show ProfileScreen, RateSheetBody;
import 'ui/addon_switch_sheet.dart';
import 'ui/daily_summary_screen.dart';
import 'ui/pay_bill_screen.dart';
import 'ui/plan_screen.dart';
import 'ui/report_view_screen.dart';
import 'ui/reports_screen.dart';
import 'ui/shop_settings_screen.dart';

/// Account: Plan & billing, reports, profile, shop settings and the
/// account's own settings screens (12.4–12.8, 16.1, 18.2, 18.10, 18.12).
/// Owned by the Account feature: edit only this file and the rest of
/// `features/account/` (docs/v2-foundation.md).

/// Children of `/menu` (relative paths).
final accountMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'plan',
    builder: (_, _) => const PlanScreen(),
    routes: [
      GoRoute(
        path: 'addon/:key',
        pageBuilder: (_, state) => AccountSheetPage<void>(
          key: state.pageKey,
          child: AddonSwitchSheet(addonKey: textParam(state, 'key')),
        ),
      ),
      GoRoute(
        path: 'paid',
        builder: (_, state) =>
            PayBillScreen(billNumber: state.uri.queryParameters['bill']),
      ),
    ],
  ),
  GoRoute(
    path: 'reports',
    builder: (_, _) => const ReportsScreen(),
    routes: [
      GoRoute(
        path: ':name',
        builder: (_, state) => ReportViewScreen(
          reportKey: textParam(state, 'name'),
          period: state.uri.queryParameters['period'],
          outletId: int.tryParse(state.uri.queryParameters['outlet'] ?? ''),
        ),
      ),
    ],
  ),
  GoRoute(path: 'profile', builder: (_, _) => const ProfileScreen()),
  GoRoute(path: 'shop-settings', builder: (_, _) => const ShopSettingsScreen()),
  GoRoute(path: 'daily-summary', builder: (_, _) => const DailySummaryScreen()),
  GoRoute(
    path: 'rate',
    pageBuilder: (_, state) => AccountSheetPage<void>(
      key: state.pageKey,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: RateSheetBody(),
      ),
    ),
  ),
];
