import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';

/// A role as a member row names it (`member.role`).
@immutable
class RoleRef {
  const RoleRef({required this.id, required this.name, this.key});

  final int id;
  final String name;
  final String? key;

  static RoleRef? fromJson(Object? raw) {
    final j = Json.map(raw);
    final id = Json.integer(j['id']);
    if (id == null) return null;
    return RoleRef(
      id: id,
      name: Json.str(j['name']) ?? '',
      key: Json.str(j['key']),
    );
  }
}

/// Where a member stands (`member.status`): working, still on the
/// temporary password, or switched off.
enum MemberStatus {
  active,
  waiting,
  off;

  static MemberStatus parse(Object? raw) => switch (Json.str(raw)) {
    'off' => MemberStatus.off,
    'waiting' => MemberStatus.waiting,
    _ => MemberStatus.active,
  };
}

/// One team member (`GET team` → `members[]`, `GET team/{id}` → `member`):
/// `{id, user_id, name, phone, email, cnic, role {id, name, key}, scope,
/// outlets [{id, name}], status, must_change_password, last_active_at,
/// switched_off_at, created_at}`.
@immutable
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.userId,
    this.phone,
    this.email,
    this.cnic,
    this.role,
    this.scope = 'all',
    this.outlets = const [],
    this.status = MemberStatus.active,
    this.mustChangePassword = false,
    this.lastActiveAt,
    this.switchedOffAt,
    this.createdAt,
  });

  final int id;
  final int? userId;
  final String name;

  /// Their mobile number: also their username.
  final String? phone;
  final String? email;
  final String? cnic;
  final RoleRef? role;

  /// `all` (every outlet) or `outlets` (only [outlets]).
  final String scope;

  /// id → name; empty when [scope] is `all`.
  final List<(int, String)> outlets;
  final MemberStatus status;
  final bool mustChangePassword;
  final DateTime? lastActiveAt;
  final DateTime? switchedOffAt;
  final DateTime? createdAt;

  bool get isOff => status == MemberStatus.off;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory TeamMember.fromJson(Object? raw) {
    final j = Json.map(raw);
    return TeamMember(
      id: Json.integer(j['id']) ?? 0,
      userId: Json.integer(j['user_id']),
      name: Json.str(j['name']) ?? '',
      phone: Json.str(j['phone']),
      email: Json.str(j['email']),
      cnic: Json.str(j['cnic']),
      role: RoleRef.fromJson(j['role']),
      scope: Json.str(j['scope']) ?? 'all',
      outlets: [
        for (final o in Json.list(j['outlets']))
          if (Json.integer(Json.map(o)['id']) case final id?)
            (id, Json.str(Json.map(o)['name']) ?? ''),
      ],
      status: MemberStatus.parse(j['status']),
      mustChangePassword: Json.flag(j['must_change_password']),
      lastActiveAt: AtomDates.parse(j['last_active_at']),
      switchedOffAt: AtomDates.parse(j['switched_off_at']),
      createdAt: AtomDates.parse(j['created_at']),
    );
  }
}

/// `GET team`: the members, and the scopes this brand can give (`all`
/// only on a single-outlet account).
@immutable
class TeamList {
  const TeamList({required this.members, this.scopes = const ['all']});

  final List<TeamMember> members;
  final List<String> scopes;

  factory TeamList.fromJson(Object? data) {
    final d = Json.map(data);
    final scopes = [for (final s in Json.list(d['scopes'])) ?Json.str(s)];
    return TeamList(
      members: [
        for (final m in Json.list(d['members'])) TeamMember.fromJson(m),
      ],
      scopes: scopes.isEmpty ? const ['all'] : scopes,
    );
  }
}

/// The login the server makes once, on add, switch on and reset:
/// `{username, temporary_password, sign_in_url, whatsapp}`.
@immutable
class TeamLogin {
  const TeamLogin({
    required this.username,
    required this.password,
    this.signInUrl,
    this.whatsapp,
  });

  final String username;
  final String password;
  final String? signInUrl;

  /// `92300…`, for a wa.me link.
  final String? whatsapp;

  factory TeamLogin.fromJson(Object? raw) {
    final j = Json.map(raw);
    return TeamLogin(
      username: Json.str(j['username']) ?? '',
      password: Json.str(j['temporary_password']) ?? '',
      signInUrl: Json.str(j['sign_in_url']),
      whatsapp: Json.str(j['whatsapp']),
    );
  }
}

/// A member with the temporary password shown once (11.3 and the reset
/// sheet). It lives only as long as the screen showing it.
typedef MemberWithLogin = ({TeamMember member, TeamLogin login});

/// A role (`GET team/roles` → `roles[]`).
@immutable
class TeamRole {
  const TeamRole({
    required this.id,
    required this.name,
    this.key,
    this.description,
    this.readyMade = false,
    this.permissions = const [],
    this.summary = const [],
  });

  final int id;
  final String? key;
  final String name;
  final String? description;

  /// Atomshop's own: can't be changed or deleted, only copied.
  final bool readyMade;
  final List<String> permissions;

  /// The server's words, grouped like the menu: group → what they can do.
  final List<(String, List<String>)> summary;

  factory TeamRole.fromJson(Object? raw) {
    final j = Json.map(raw);
    return TeamRole(
      id: Json.integer(j['id']) ?? 0,
      key: Json.str(j['key']),
      name: Json.str(j['name']) ?? '',
      description: Json.str(j['description']),
      readyMade: Json.flag(j['ready_made']),
      permissions: [for (final p in Json.list(j['permissions'])) ?Json.str(p)],
      summary: [
        for (final e in Json.map(j['summary']).entries)
          (e.key, [for (final s in Json.list(e.value)) ?Json.str(s)]),
      ],
    );
  }
}

/// One group of permissions a role can have, named and ordered as the
/// server's menu (`permission_groups`: `{group: {key: label}}`).
@immutable
class PermissionGroup {
  const PermissionGroup({required this.name, required this.permissions});

  final String name;

  /// key → the server's words, in order.
  final List<(String, String)> permissions;

  List<String> get keys => [for (final p in permissions) p.$1];
}

/// `GET team/roles`: ready-made and own roles, and what this brand can put
/// in a role (Inventory only with the add-on: the server decides).
@immutable
class TeamRoles {
  const TeamRoles({required this.roles, this.groups = const []});

  final List<TeamRole> roles;
  final List<PermissionGroup> groups;

  List<TeamRole> get readyMade => [
    for (final r in roles)
      if (r.readyMade) r,
  ];
  List<TeamRole> get own => [
    for (final r in roles)
      if (!r.readyMade) r,
  ];

  /// key → the server's words.
  Map<String, String> get labels => {
    for (final g in groups)
      for (final (k, label) in g.permissions) k: label,
  };

  TeamRole? byId(int? id) =>
      id == null ? null : roles.where((r) => r.id == id).firstOrNull;

  factory TeamRoles.fromJson(Object? data) {
    final d = Json.map(data);
    return TeamRoles(
      roles: [for (final r in Json.list(d['roles'])) TeamRole.fromJson(r)],
      groups: [
        for (final e in Json.map(d['permission_groups']).entries)
          PermissionGroup(
            name: e.key,
            permissions: [
              for (final p in Json.map(e.value).entries)
                (p.key, Json.str(p.value) ?? p.key),
            ],
          ),
      ],
    );
  }
}

/// A member's details as typed on 11.2 (add, or change one).
@immutable
class MemberDraft {
  const MemberDraft({
    required this.name,
    required this.roleId,
    required this.scope,
    this.phone,
    this.email,
    this.cnic,
    this.outletIds = const [],
  });

  final String name;

  /// Only for a new member: their username, it can't change.
  final String? phone;
  final String? email;

  /// Kept as it is when changing a member (this form doesn't show it).
  final String? cnic;
  final int roleId;
  final String scope;
  final List<int> outletIds;

  Map<String, dynamic> toBody() => {
    'name': name,
    'phone': ?phone,
    'email': (email == null || email!.trim().isEmpty) ? null : email!.trim(),
    'cnic': ?cnic,
    'brand_role_id': roleId,
    'scope': scope,
    'outlet_ids': scope == 'outlets' ? outletIds : const <int>[],
  };
}
