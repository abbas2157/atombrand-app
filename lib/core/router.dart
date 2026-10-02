import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/order.dart';
import '../features/auth/apply_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/new_password_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/verify_code_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/brand_page/brand_page_screen.dart';
import '../features/bulk/bulk_dossier_screen.dart';
import '../features/bulk/bulk_screen.dart';
import '../features/catalogue/catalogue_screen.dart';
import '../features/catalogue/product_detail_screen.dart';
import '../features/catalogue/product_form_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/profile/more_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/shell/main_shell.dart';
import 'session.dart';

const _authPaths = {
  '/welcome',
  '/sign-in',
  '/forgot',
  '/verify',
  '/new-password',
  '/apply',
  '/apply/submitted',
};

final _rootKey = GlobalKey<NavigatorState>();

/// Navigation map from BRAND_APP.md §3.1, with an auth redirect.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => session.value = next);
  ref.onDispose(session.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuth = _authPaths.contains(loc);
      switch (session.value) {
        case SessionLoading() || SessionUnreachable():
          return loc == '/splash' ? null : '/splash';
        case SignedOut():
          return isAuth ? null : '/welcome';
        case SignedIn():
          return (isAuth || loc == '/splash') ? '/home' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/verify',
        redirect: (_, state) => state.extra is VerifyArgs ? null : '/welcome',
        builder: (_, state) => VerifyCodeScreen(args: state.extra! as VerifyArgs),
      ),
      GoRoute(
        path: '/new-password',
        redirect: (_, state) => state.extra is String ? null : '/forgot',
        builder: (_, state) => NewPasswordScreen(resetToken: state.extra! as String),
      ),
      GoRoute(path: '/apply', builder: (_, _) => const ApplyScreen()),
      GoRoute(path: '/apply/submitted', builder: (_, state) => ApplySubmittedScreen(message: state.extra as String?)),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              builder: (_, state) => OrdersScreen(
                initialType: state.uri.queryParameters['type'],
                initialStatus: state.uri.queryParameters['status'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bulk', builder: (_, _) => const BulkScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalogue',
              builder: (_, state) => CatalogueScreen(initialStatus: state.uri.queryParameters['status']),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),

      // Full-screen pages pushed over the tabs.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/orders/:type/:uuid',
        builder: (_, state) => OrderDetailScreen(
          type: state.pathParameters['type'] == 'instalment' ? OrderFeed.instalment : OrderFeed.retail,
          uuid: state.pathParameters['uuid']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/bulk/:id',
        builder: (_, state) => BulkDossierScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/products/new', builder: (_, _) => const ProductFormScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/products/:id',
        builder: (_, state) => ProductDetailScreen(id: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'edit',
            builder: (_, state) => ProductFormScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/brand-page', builder: (_, _) => const BrandPageScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/change-password', builder: (_, _) => const ChangePasswordScreen()),
    ],
  );
});
