import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import 'ui/terms_screen.dart';

/// The partner terms to accept, on the way in.
final termsRoutes = <RouteBase>[
  GoRoute(path: V2Routes.terms, builder: (_, _) => const TermsAcceptScreen()),
];
