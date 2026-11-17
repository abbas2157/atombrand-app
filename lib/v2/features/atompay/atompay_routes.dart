import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import '../../app/routes.dart';
import 'ui/atompay_detail_screen.dart';
import 'ui/atompay_handover_screen.dart';

/// AtomPay orders (6.9–6.10; the 6.8 list is the Orders tab's
/// `?tab=atompay`). Owned by the AtomPay feature: edit only this file and
/// the rest of `features/atompay/` (docs/v2-foundation.md).

/// Opened over the tabs.
final atompayRoutes = <RouteBase>[
  GoRoute(
    path: V2Routes.atompayPattern,
    builder: (_, state) => AtompayScreen(uuid: textParam(state, 'uuid')),
    routes: [
      GoRoute(
        path: 'handover',
        builder: (_, state) =>
            AtompayHandoverScreen(uuid: textParam(state, 'uuid')),
      ),
    ],
  ),
];
