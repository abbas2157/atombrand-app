import 'package:go_router/go_router.dart';

import 'ui/ask_atom_screen.dart';

/// Ask Atom (12.10–12.12, Ask Atom add-on). Owned by the Ask Atom feature:
/// edit only this file and the rest of `features/ask_atom/`
/// (docs/v2-foundation.md). The add-on is checked by `routeRules`
/// (`/menu/ask-atom`): without it the route goes Home.
///
/// `?q=` asks a question straight away and `?error=` sends the refusal the
/// app just showed ("Why?" on any refusal, `POST ask-atom` → `error`).

/// Children of `/menu` (relative paths).
final askAtomMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'ask-atom',
    builder: (_, state) => AskAtomScreen(
      question: state.uri.queryParameters['q'],
      error: state.uri.queryParameters['error'],
    ),
  ),
];
