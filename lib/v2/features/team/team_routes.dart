import 'package:go_router/go_router.dart';

import '../../app/route_params.dart';
import 'data/team_models.dart';
import 'ui/role_edit_screen.dart';
import 'ui/team_added_screen.dart';
import 'ui/team_list_screen.dart';
import 'ui/team_member_form.dart';
import 'ui/team_member_screen.dart';
import 'ui/team_roles_screen.dart';

/// Team & roles (11.1–11.6). Owned by the Team feature: edit only this file
/// and the rest of `features/team/` (docs/v2-foundation.md).

/// Children of `/menu` (relative paths).
final teamMenuRoutes = <RouteBase>[
  GoRoute(
    path: 'team',
    builder: (_, _) => const TeamListScreen(),
    routes: [
      GoRoute(path: 'add', builder: (_, _) => const TeamMemberForm()),
      GoRoute(
        path: 'added',
        builder: (_, state) => TeamAddedScreen(
          added: state.extra is MemberWithLogin
              ? state.extra! as MemberWithLogin
              : null,
        ),
      ),
      GoRoute(
        path: 'roles',
        builder: (_, _) => const TeamRolesScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => RoleEditScreen(
              roleId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
              copyOf: state.extra is TeamRole ? state.extra! as TeamRole : null,
            ),
          ),
        ],
      ),
      GoRoute(
        path: ':id',
        builder: (_, state) => TeamMemberScreen(id: intParam(state, 'id')),
      ),
    ],
  ),
];
