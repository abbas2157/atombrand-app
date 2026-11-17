import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import '../../app/routes.dart';
import 'ui/bulk_tab_root.dart';
import 'ui/deal_screens.dart';
import 'ui/quote_screen.dart';
import 'ui/request_screens.dart';
import 'ui/status_sheets.dart';

/// Bulk deals (7.x). Owned by the Bulk feature: edit only this file and the
/// rest of `features/bulk/` (docs/v2-foundation.md).

/// The Bulk deals tab root (7.1), with `?tab=sellers|website|deals`.
///
/// A team member without `bulk.view` gets AtomPay orders in this slot
/// instead (5.2: Home · Orders · ＋ · AtomPay · Products), so no tab can
/// only say no.
final bulkTab = GoRoute(
  path: V2Routes.bulk,
  builder: (_, state) => BulkTabRoot(tab: state.uri.queryParameters['tab']),
);

/// Opened over the tabs.
final bulkRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.sellerRequestPattern,
    builder: (_, state) =>
        BulkRequestScreen(id: intParam(state, 'id'), seller: true),
    routes: [
      GoRoute(
        path: 'quote',
        builder: (_, state) => QuoteScreen(id: intParam(state, 'id')),
      ),
    ],
  ),
  GoRoute(
    path: V2Routes.bulkRequestPattern,
    builder: (_, state) => BulkRequestScreen(id: intParam(state, 'id')),
    routes: [
      GoRoute(
        path: 'quote',
        builder: (_, state) => QuoteScreen(id: intParam(state, 'id')),
      ),
      GoRoute(
        path: 'status',
        pageBuilder: (_, state) => BulkSheetPage<bool>(
          key: state.pageKey,
          child: StatusSheet(id: intParam(state, 'id')),
        ),
      ),
      GoRoute(
        path: 'deal',
        pageBuilder: (_, state) => BulkSheetPage<bool>(
          key: state.pageKey,
          child: WonSheet(id: intParam(state, 'id')),
        ),
      ),
    ],
  ),
  GoRoute(
    path: V2Routes.dealPattern,
    builder: (_, state) => DealScreen(id: intParam(state, 'id')),
    routes: [
      GoRoute(
        path: 'deliver',
        builder: (_, state) => DealDeliverScreen(id: intParam(state, 'id')),
      ),
      GoRoute(
        path: 'payment',
        builder: (_, state) => DealPaymentScreen(id: intParam(state, 'id')),
      ),
    ],
  ),
];
