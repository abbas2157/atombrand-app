import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import 'ui/agent_password_screen.dart';
import 'ui/apply_screen.dart';
import 'ui/choose_outlet_screen.dart';
import 'ui/first_tour_screen.dart';
import 'ui/forgot_screens.dart';
import 'ui/launch_screen.dart';
import 'ui/set_pin_screen.dart';
import 'ui/sign_in_screen.dart';
import 'ui/unlock_screens.dart' show QuickSignInScreen;
import 'ui/welcome_screen.dart';

/// Launch, sign in, Apply, forgot password and the way-in steps (1–4, 16.7).
final authRoutes = <RouteBase>[
  GoRoute(path: V2Routes.launch, builder: (_, _) => const LaunchScreen()),
  GoRoute(path: V2Routes.welcome, builder: (_, _) => const WelcomeScreen()),
  GoRoute(path: V2Routes.signIn, builder: (_, _) => const SignInScreen()),
  GoRoute(path: V2Routes.apply, builder: (_, _) => const ApplyScreen()),
  GoRoute(
    path: V2Routes.quickSignIn,
    builder: (_, _) => const QuickSignInScreen(),
  ),
  GoRoute(path: V2Routes.forgot, builder: (_, _) => const ForgotScreen()),
  GoRoute(
    path: V2Routes.forgotCode,
    builder: (_, _) => const ForgotCodeScreen(),
  ),
  GoRoute(
    path: V2Routes.forgotNew,
    builder: (_, _) => const ForgotNewPasswordScreen(),
  ),
  GoRoute(
    path: V2Routes.forgotDone,
    builder: (_, _) => const ForgotDoneScreen(),
  ),
  GoRoute(
    path: V2Routes.agentPassword,
    builder: (_, _) => const AgentPasswordScreen(),
  ),
  GoRoute(path: V2Routes.setPin, builder: (_, _) => const WayInSetPinScreen()),
  GoRoute(
    path: V2Routes.chooseOutlet,
    builder: (_, _) => const ChooseOutletScreen(),
  ),
  GoRoute(path: V2Routes.tour, builder: (_, _) => const FirstTourScreen()),
];
