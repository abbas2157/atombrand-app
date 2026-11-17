import 'package:go_router/go_router.dart';

import '../terms/ui/terms_screen.dart' show TermsReadScreen;
import 'data/help_repository.dart';
import 'ui/help_screens.dart';

/// Help (17.x). Children of `/menu` (relative paths).
final helpMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'help',
    builder: (_, _) => const HelpScreen(),
    routes: [
      GoRoute(
        path: 'faqs',
        builder: (_, state) => switch (state.extra) {
          String topic => FaqScreen(topic: topic),
          true => const FaqScreen(search: true),
          _ => const FaqScreen(),
        },
        routes: [
          GoRoute(
            path: 'answer',
            builder: (_, state) =>
                FaqAnswerScreen(faq: state.extra as HelpFaq?),
          ),
        ],
      ),
      GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
      GoRoute(path: 'terms', builder: (_, _) => const TermsReadScreen()),
      GoRoute(
        path: 'support',
        builder: (_, _) => const SupportListScreen(),
        routes: [
          GoRoute(
            path: 'thread',
            builder: (_, state) =>
                SupportThreadScreen(request: state.extra as SupportRequest?),
          ),
        ],
      ),
      GoRoute(path: 'ecosystem', builder: (_, _) => const EcosystemScreen()),
    ],
  ),
];
