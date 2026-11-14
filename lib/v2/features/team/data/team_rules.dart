import '../../../../l10n/app_localizations.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/ids.dart';
import '../../../core/session/session.dart';
import 'team_models.dart';

/// The rules the team screens follow, kept out of the widgets so they can
/// be tested. They mirror atomshop's `BrandTeamService` and `BrandRole`.

// ───────────────────────────────────────────── permissions

/// A "do" permission brings its "see" (`BrandTeamService::NEEDS`): the
/// server adds it on save, so the switches show it on.
const kPermissionNeeds = {
  BrandPermission.ordersStatus: BrandPermission.ordersView,
  BrandPermission.ordersPayment: BrandPermission.ordersView,
  BrandPermission.ordersCancel: BrandPermission.ordersView,
  BrandPermission.bulkQuote: BrandPermission.bulkView,
  BrandPermission.bulkDeal: BrandPermission.bulkView,
  BrandPermission.catalogueEdit: BrandPermission.catalogueView,
  BrandPermission.stockChange: BrandPermission.stockView,
  BrandPermission.stockManage: BrandPermission.stockView,
  BrandPermission.moneyExport: BrandPermission.moneyReports,
};

/// Short chips for role rows, in this order (`BrandRole::CHIPS`).
Map<String, String> roleChipWords(AppLocalizations l) => {
  BrandPermission.ordersView: l.teamChipOrders,
  BrandPermission.ordersPayment: l.teamChipPayments,
  BrandPermission.atompayView: l.teamChipAtompay,
  BrandPermission.bulkView: l.teamChipBulk,
  BrandPermission.bulkQuote: l.teamChipQuotes,
  BrandPermission.catalogueEdit: l.teamChipProducts,
  BrandPermission.pageEdit: l.teamChipPage,
  BrandPermission.stockView: l.teamChipSeeStock,
  BrandPermission.stockChange: l.teamChipStockChanges,
  BrandPermission.moneyReports: l.teamChipReports,
  BrandPermission.moneyExport: l.teamChipExports,
  BrandPermission.teamManage: l.teamChipAddTeam,
};

/// [picked] with every permission they bring, as the server saves it.
Set<String> withNeeded(Set<String> picked) => {
  ...picked,
  for (final p in picked) ?kPermissionNeeds[p],
};

/// Turns [key] on or off. Turning a "see" off turns off what needs it.
Set<String> flipPermission(Set<String> on, String key) {
  final shown = withNeeded(on);
  if (!shown.contains(key)) return withNeeded({...on, key});
  return {
    for (final p in shown)
      if (p != key && kPermissionNeeds[p] != key) p,
  };
}

/// A group's All: every key on, or every key off when all already are.
Set<String> toggleGroup(Set<String> on, List<String> keys) {
  final shown = withNeeded(on);
  if (keys.every(shown.contains)) {
    var out = shown;
    for (final k in keys) {
      if (out.contains(k)) out = flipPermission(out, k);
    }
    return out;
  }
  return withNeeded({...shown, ...keys});
}

/// [perms] in the menu's order, only those the brand can give.
List<String> orderedPermissions(
  Set<String> perms,
  List<PermissionGroup> groups,
) => [
  for (final g in groups)
    for (final k in g.keys)
      if (perms.contains(k)) k,
];

/// The chips a role row shows ("Orders", "Payments", "See stock"), for the
/// permissions this brand can give ([grantable]; null keeps every one).
List<String> roleChips(
  AppLocalizations l,
  Iterable<String> permissions, {
  Set<String>? grantable,
}) {
  final has = permissions.toSet();
  return [
    for (final e in roleChipWords(l).entries)
      if (has.contains(e.key) &&
          (grantable == null || grantable.contains(e.key)))
        e.value,
  ];
}

/// What a role covers in one line: its description, or its groups
/// ("Orders, atompay, catalogue").
String roleSummary(TeamRole r) {
  final d = r.description;
  if (d != null && d.isNotEmpty) return d;
  final groups = [for (final g in r.summary) g.$1];
  if (groups.isEmpty) return '';
  return [
    groups.first,
    for (final g in groups.skip(1)) g.toLowerCase(),
  ].join(', ');
}

/// A free name for a copy of [name]: "Order handler copy", then
/// "Order handler copy 2"…, kept within the server's 40 letters.
String copyName(AppLocalizations l, String name, Iterable<String> taken) {
  final used = {for (final t in taken) t.trim().toLowerCase()};
  for (var n = 1; ; n++) {
    final tail = ' ${n == 1 ? l.teamCopyTail : l.teamCopyTailN(n)}';
    final base = name.length + tail.length > 40
        ? name.substring(0, 40 - tail.length).trimRight()
        : name;
    final candidate = '$base$tail';
    if (!used.contains(candidate.toLowerCase())) return candidate;
  }
}

// ───────────────────────────────────────────── who may do what

/// The roles [who] may give: the owner any; a member who manages the team
/// only roles inside their own permissions and never Team (the server's
/// guard rails, `assertCanGrant`).
List<TeamRole> grantableRoles(List<TeamRole> roles, Who who) {
  if (who.isOwner) return roles;
  return [
    for (final r in roles)
      if (!r.permissions.contains(BrandPermission.teamManage) &&
          r.permissions.every(who.can))
        r,
  ];
}

/// Whether [who] (signed in as [myUserId]) may change [member]: the owner
/// anyone; a team manager neither themselves nor another team manager
/// ([roles] tells whose role manages the team).
bool canChangeMember(
  TeamMember member,
  Who who, {
  required int myUserId,
  TeamRoles? roles,
}) {
  if (who.isOwner) return true;
  if (member.userId != null && member.userId == myUserId) return false;
  final role = roles?.byId(member.role?.id);
  if (role == null) return roles != null;
  return !role.permissions.contains(BrandPermission.teamManage);
}

/// The scopes [who] can give: a member limited to outlets can't give
/// Every outlet.
List<String> scopesFor(List<String> serverScopes, Who who) => [
  for (final s in serverScopes)
    if (!(s == 'all' && who.outletIds != null)) s,
];

// ───────────────────────────────────────────── words

/// "Every outlet", or the outlets' names.
String worksIn(AppLocalizations l, TeamMember m) =>
    m.scope == 'outlets' && m.outlets.isNotEmpty
    ? m.outlets.map((o) => o.$2).join(', ')
    : l.teamEveryOutlet;

/// The status pill's words.
String statusLabel(AppLocalizations l, MemberStatus s) => switch (s) {
  MemberStatus.active => l.teamFilterActive,
  MemberStatus.waiting => l.teamKpiWaiting,
  MemberStatus.off => l.teamFilterOff,
};

/// How recently a member was active, for the dot beside it.
enum SeenTone { now, earlier, never }

/// When [m] was last active and the dot's colour: "Active now", "Active
/// 10:42 am", "Last active yesterday", "Last active 3 Nov", "Temporary:
/// not signed in yet" or "Switched off 12 Oct · can't sign in".
(String, SeenTone) seenLine(AppLocalizations l, TeamMember m, {DateTime? now}) {
  final at = m.lastActiveAt?.toLocal();
  if (m.isOff) {
    final off = m.switchedOffAt?.toLocal();
    return (
      off == null ? l.teamSeenOff : l.teamSeenOffOn(AtomDates.short(off)),
      SeenTone.never,
    );
  }
  if (at == null) {
    return (
      m.status == MemberStatus.waiting ? l.teamSeenTemporary : l.teamSeenNever,
      SeenTone.never,
    );
  }
  final n = now ?? AtomDates.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(at.year, at.month, at.day);
  if (n.difference(at).inMinutes < 5) return (l.teamActiveNow, SeenTone.now);
  if (day == today) return (l.teamSeenAt(AtomDates.time(at)), SeenTone.now);
  if (today.difference(day).inDays == 1) {
    return (l.teamSeenYesterday, SeenTone.earlier);
  }
  return (l.teamSeenOn(AtomDates.shortOrYear(at)), SeenTone.earlier);
}

/// The members who were active today (not switched off).
int activeToday(List<TeamMember> members, {DateTime? now}) {
  final n = now ?? AtomDates.now();
  return members.where((m) {
    final at = m.lastActiveAt?.toLocal();
    return !m.isOff &&
        at != null &&
        at.year == n.year &&
        at.month == n.month &&
        at.day == n.day;
  }).length;
}

// ───────────────────────────────────────────── the form (11.2)

/// Letters and spaces only, as the server's `person_name` rule.
final _personName = RegExp(r"^[\p{L} .'-]+$", unicode: true);
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Null when the name is fine, or what's wrong.
String? nameProblem(AppLocalizations l, String name) {
  final n = name.trim();
  if (n.isEmpty) return l.teamNameEmpty;
  if (n.length > 80) return l.teamNameLong;
  if (!_personName.hasMatch(n)) return l.teamNameLetters;
  return null;
}

/// Null when the mobile is a Pakistani mobile number.
String? mobileProblem(AppLocalizations l, String mobile) {
  if (mobile.trim().isEmpty) return l.teamMobileEmpty;
  return AtomIds.normaliseMobile(mobile) == null ? l.teamMobileBad : null;
}

/// Null when the email is empty (it is optional) or looks right.
String? emailProblem(AppLocalizations l, String email) {
  final e = email.trim();
  if (e.isEmpty) return null;
  return _email.hasMatch(e) && e.length <= 120 ? null : l.teamEmailBad;
}

/// What still stops the member form from saving, as the button's words,
/// or null when it can save.
String? memberFormBlocker(
  AppLocalizations l, {
  required String name,
  required String? mobile,
  required String email,
  required int? roleId,
  required String? scope,
  required Set<int> outletIds,
}) {
  if (name.trim().isEmpty) return l.teamBlockName;
  if (nameProblem(l, name) != null) return l.teamBlockNameBad;
  if (mobile != null && mobileProblem(l, mobile) != null) {
    return mobile.trim().isEmpty ? l.teamBlockMobile : l.teamBlockMobileBad;
  }
  if (emailProblem(l, email) != null) return l.teamBlockEmail;
  if (roleId == null) return l.teamBlockRole;
  if (scope == null) return l.teamBlockScope;
  if (scope == 'outlets' && outletIds.isEmpty) {
    return l.teamBlockOutlet;
  }
  return null;
}
