import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/team_models.dart';
import '../data/team_repository.dart';
import '../data/team_rules.dart';
import 'team_parts.dart';
import '../../orders/ui/order_parts.dart' show CountChips;

enum _Filter { active, off, all }

/// Team & roles (11.1): People, with a link to Roles. KPIs, Active /
/// Switched off / All, and each member with their brand role, where they
/// work, when they were last active and their status. The owner sees
/// themselves first.
///
/// Left out until the server gives them: orders handled this month and
/// the recent team activity.
class TeamListScreen extends ConsumerStatefulWidget {
  const TeamListScreen({super.key});

  @override
  ConsumerState<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends ConsumerState<TeamListScreen> {
  AppLocalizations get l => AppLocalizations.of(context);

  _Filter _filter = _Filter.active;

  bool _shows(TeamMember m) => switch (_filter) {
    _Filter.active => !m.isOff,
    _Filter.off => m.isOff,
    _Filter.all => true,
  };

  List<Widget> _body(TeamList list, TeamRoles? roles, bool online) {
    final session = watchSession(ref);
    final members = list.members;
    // The owner is listed first and counted, as on the board (5 people:
    // the owner and four members). The owner is using the app now, so is
    // active and signed in today.
    final isOwner = session != null && session.who.isOwner;
    final me = isOwner ? 1 : 0;
    final on = members.where((m) => !m.isOff).length;
    final off = members.length - on;
    final working = members
        .where((m) => m.status == MemberStatus.active)
        .length;
    final rows = members.where(_shows).toList();
    final owner = isOwner && _filter != _Filter.off;
    return [
      AtomKpiGrid(
        kpis: [
          AtomKpi(
            label: l.teamKpiMembers,
            value: '${members.length + me}',
            note: l.teamKpiMembersNote(working + me),
          ),
          AtomKpi(
            label: l.teamKpiToday,
            value: '${activeToday(members) + me}',
            note: l.teamKpiTodayNote,
          ),
          AtomKpi(
            label: l.teamKpiOrders,
            value: list.ordersMonth == null ? '–' : '${list.ordersMonth}',
            note: l.teamKpiOrdersNote,
          ),
          AtomKpi(
            label: l.teamKpiRoles,
            value: roles == null ? '–' : '${roles.roles.length}',
            note: roles == null
                ? null
                : l.teamKpiRolesNote(roles.readyMade.length, roles.own.length),
          ),
        ],
      ),
      const SizedBox(height: AtomSpace.s3),
      // Plain count chips, as on the board (no dropdown arrow: they pick).
      CountChips<_Filter>(
        padding: EdgeInsets.zero,
        selected: _filter,
        onPick: (f) => setState(() => _filter = f),
        chips: [
          (_Filter.active, l.teamFilterActive, on + me),
          (_Filter.off, l.teamFilterOff, off),
          (_Filter.all, l.teamFilterAll, members.length + me),
        ],
      ),
      const SizedBox(height: 10),
      if (rows.isEmpty && !owner)
        SizedBox(
          height: 280,
          child: _filter == _Filter.off
              ? AtomMessageState(icon: LucideIcons.users, title: l.teamEmptyOff)
              : AtomMessageState(
                  icon: LucideIcons.users,
                  title: l.teamEmptyTitle,
                  body: l.teamEmptyBody,
                  actionLabel: online ? l.teamAddMember : null,
                  onAction: online
                      ? () => context.push(V2Routes.teamAdd)
                      : null,
                ),
        )
      else
        AtomListCard(
          children: [
            if (owner) _OwnerRow(name: session.name),
            for (final m in rows)
              _MemberRow(
                member: m,
                onTap: () => context.push(V2Routes.teamMemberOf(m.id)),
              ),
          ],
        ),
      const SizedBox(height: 10),
      TeamFoot(online ? l.teamFootOnline : l.teamFootOffline),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(teamListProvider);
    final roles = ref.watch(teamRolesProvider).value;
    final online = watchOnline(ref);
    final list = data.value;
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.teamTitle,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: AppLocalizations.of(context).commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (online)
                AtomButton.small(
                  label: MediaQuery.sizeOf(context).width < 380
                      ? l.teamAdd
                      : l.teamAddMember,
                  kind: AtomButtonKind.primary,
                  onPressed: () => context.push(V2Routes.teamAdd),
                ),
              // with the header's 8: the 16px gutter
              const SizedBox(width: 8),
            ],
            tabs: [
              AtomHeaderTab(
                l.teamPeople,
                // the owner is one of the people listed
                count: list == null
                    ? null
                    : list.members.length +
                          ((watchSession(ref)?.who.isOwner ?? false) ? 1 : 0),
              ),
            ],
            selectedTab: 0,
            // Roles is an outlined button beside People, as on the board.
            tabsTrailing: _RolesButton(
              count: roles?.roles.length,
              onTap: () => context.push(V2Routes.teamRoles),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(teamRolesProvider);
                return ref.refresh(teamListProvider.future);
              },
              child: AtomReadableWidth(
                maxWidth: 720,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AtomSpace.gutter,
                    10,
                    AtomSpace.gutter,
                    AtomSpace.s6,
                  ),
                  children: data.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const [
                      AtomLoadingCard(count: 2),
                      SizedBox(height: 12),
                      AtomLoadingRows(),
                    ],
                    error: (e, _) => [
                      SizedBox(
                        height: 420,
                        child: teamFailure(
                          e,
                          () => ref.invalidate(teamListProvider),
                        ),
                      ),
                    ],
                    data: (list) => _body(list, roles, online),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The owner's own row: blue Owner, every outlet, active now.
class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final big = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final pill = AtomPill(
      label: l.teamOwner,
      tone: AtomTone.blue,
      compact: true,
    );
    return Semantics(
      container: true,
      label: '$name, ${l.teamOwner}',
      excludeSemantics: true,
      child: Container(
        color: AtomColors.paper,
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: AtomSpace.s3,
        ),
        child: Row(
          children: [
            AtomInitials(name: name, tone: AtomTone.blue),
            const SizedBox(width: AtomSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AtomText.listTitle),
                  Text(
                    '${l.teamOwner} · ${l.teamEveryOutlet}',
                    style: AtomText.secondary,
                  ),
                  SeenText(text: l.teamActiveNow, tone: SeenTone.now),
                  if (big) ...[const SizedBox(height: 4), pill],
                ],
              ),
            ),
            if (!big) ...[const SizedBox(width: AtomSpace.s2), pill],
          ],
        ),
      ),
    );
  }
}

/// A member on 11.1: initials, name, role · where they work, when they
/// were last active, and their status. Switched-off members are faded.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final TeamMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = member;
    final (seenAt, tone) = seenLine(l, m);
    final seen = m.ordersMonth > 0 && !m.isOff
        ? '$seenAt · ${l.teamOrdersMonthN(m.ordersMonth)}'
        : seenAt;
    final role = '${m.role?.name ?? l.teamNoRole} · ${worksIn(l, m)}';
    // Large text: the status goes under the lines, not beside them.
    final big = MediaQuery.textScalerOf(context).scale(10) >= 15;
    // Its own node: without it the rows merged into one for screen
    // readers, and a tap at that node's middle fell on the divider.
    return Semantics(
      container: true,
      child: AtomPressable(
        onTap: onTap,
        scaleOnPress: false,
        focusRadius: BorderRadius.zero,
        semanticLabel: [
          m.name,
          role,
          seen,
          statusLabel(l, m.status),
        ].join(', '),
        builder: (_, pressed) => Container(
          color: pressed ? AtomColors.head : AtomColors.paper,
          padding: const EdgeInsets.symmetric(
            horizontal: AtomSpace.inset,
            vertical: AtomSpace.s3,
          ),
          child: ExcludeSemantics(
            child: Opacity(
              opacity: m.isOff ? 0.6 : 1,
              child: Row(
                children: [
                  MemberInitials(member: m),
                  const SizedBox(width: AtomSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: AtomText.listTitle),
                        Text(role, style: AtomText.secondary),
                        SeenText(text: seen, tone: tone),
                        if (big) ...[
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: MemberStatusPill(status: m.status),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!big) ...[
                    const SizedBox(width: AtomSpace.s2),
                    MemberStatusPill(status: m.status),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.mini` "Roles 6" beside the People tab: 36 tall (44 to tap), 13px,
/// the count in muted grey 6 after.
class _RolesButton extends StatelessWidget {
  const _RolesButton({required this.count, required this.onTap});

  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomPressable(
      onTap: onTap,
      semanticLabel: count == null ? l.teamRoles : '${l.teamRoles}, $count',
      builder: (_, pressed) => SizedBox(
        height: 44,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: pressed ? AtomColors.head : AtomColors.paper,
              borderRadius: AtomRadius.brControl,
              border: Border.all(color: AtomColors.line2),
            ),
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  text: l.teamRoles,
                  children: [
                    if (count != null)
                      TextSpan(
                        text: '  $count',
                        style: const TextStyle(color: AtomColors.muted),
                      ),
                  ],
                ),
                style: AtomText.smallButton.copyWith(color: AtomColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
