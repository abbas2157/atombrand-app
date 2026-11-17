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

/// Roles and permissions (11.5): the brand's own roles (Edit; Copy and
/// Delete on the role) and the ready-made ones, read-only with Copy, each
/// with what it covers and how many people have it. New role. Making and
/// changing roles is the owner's: a team manager sees the roles only.
class TeamRolesScreen extends ConsumerWidget {
  const TeamRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(teamRolesProvider);
    final members = ref.watch(teamListProvider).value?.members;
    final owner = watchSession(ref)?.who.isOwner ?? false;
    final online = watchOnline(ref);
    final canMake = owner && online;

    (int, int)? countOf(TeamRole r) {
      if (members == null) return null;
      final have = members.where((m) => m.role?.id == r.id);
      return (have.length, have.where((m) => m.isOff).length);
    }

    Widget row(TeamRole r, Set<String> grantable) {
      final n = countOf(r);
      final chips = roleChips(l, r.permissions, grantable: grantable);
      final sub = n == null
          ? roleBlurb(l, r)
          : n.$2 == 0
          ? l.teamPeopleCount(n.$1)
          : n.$1 == n.$2
          ? l.teamPeopleAllOff(l.teamPeopleCount(n.$1))
          : l.teamPeopleSomeOff(l.teamPeopleCount(n.$1), n.$2);
      final Widget? trailing = !canMake
          ? null
          : r.readyMade
          ? AtomButton.small(
              label: l.teamCopy,
              onPressed: () => context.push(V2Routes.roleEdit(), extra: r),
            )
          : IgnorePointer(
              child: AtomButton.small(label: l.teamEdit, onPressed: () {}),
            );
      return AtomPressable(
        onTap: () => context.push(V2Routes.roleEdit(roleId: r.id)),
        scaleOnPress: false,
        focusRadius: BorderRadius.zero,
        semanticLabel: [r.name, sub, ...chips].join(', '),
        builder: (_, pressed) => Container(
          color: pressed ? AtomColors.head : AtomColors.paper,
          padding: const EdgeInsets.symmetric(
            horizontal: AtomSpace.inset,
            vertical: AtomSpace.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: AtomIconTile(
                  icon: LucideIcons.user,
                  tone: r.readyMade ? AtomTone.grey : AtomTone.green,
                ),
              ),
              const SizedBox(width: AtomSpace.s3),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: AtomText.listTitle),
                      if (sub.isNotEmpty) Text(sub, style: AtomText.secondary),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _Chips(chips),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AtomSpace.s2),
                trailing,
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomPageHeader(
            title: l.teamRoles,
            leading: AtomIconButton(
              icon: LucideIcons.chevronLeft,
              label: AppLocalizations.of(context).commonBack,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (canMake)
                AtomButton.small(
                  label: l.teamNewRole,
                  kind: AtomButtonKind.primary,
                  onPressed: () => context.push(V2Routes.roleEdit()),
                ),
              // with the header's 8: the 16px gutter
              const SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(teamListProvider);
                return ref.refresh(teamRolesProvider.future);
              },
              child: AtomReadableWidth(
                maxWidth: 720,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AtomSpace.gutter,
                    AtomSpace.s3,
                    AtomSpace.gutter,
                    AtomSpace.s6,
                  ),
                  children: data.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const [AtomLoadingRows()],
                    error: (e, _) => [
                      SizedBox(
                        height: 420,
                        child: teamFailure(
                          e,
                          () => ref.invalidate(teamRolesProvider),
                        ),
                      ),
                    ],
                    data: (all) {
                      final grantable = all.labels.keys.toSet();
                      final mine = all.own;
                      return [
                        if (!owner) ...[
                          AtomNote(
                            kind: AtomNoteKind.info,
                            message: l.teamOwnerOnlyRoles,
                          ),
                          const SizedBox(height: AtomSpace.s3),
                        ],
                        if (mine.isNotEmpty || canMake) ...[
                          AtomSectionLabel(l.teamYours, page: false),
                          if (mine.isEmpty)
                            AtomListCard(
                              children: [
                                AtomNavRow(
                                  icon: LucideIcons.plus,
                                  tone: AtomTone.blue,
                                  title: l.teamNewRole,
                                  subtitle: l.teamNoOwnRoles,
                                  onTap: () =>
                                      context.push(V2Routes.roleEdit()),
                                ),
                              ],
                            )
                          else
                            AtomListCard(
                              children: [
                                for (final r in mine) row(r, grantable),
                              ],
                            ),
                          const SizedBox(height: 14),
                        ],
                        AtomSectionLabel(l.teamReadyMade, page: false),
                        AtomListCard(
                          children: [
                            const _OwnerRoleRow(),
                            for (final r in all.readyMade) row(r, grantable),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TeamFoot(l.teamReadyNote),
                      ];
                    },
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

/// The Owner, first among the ready-made roles: not a role anyone can be
/// given.
class _OwnerRoleRow extends StatelessWidget {
  const _OwnerRoleRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: '${l.teamOwnerRole}, ${l.teamOwnerRoleSum}',
      excludeSemantics: true,
      child: Container(
        color: AtomColors.paper,
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: AtomSpace.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AtomIconTile(icon: LucideIcons.shield, tone: AtomTone.blue),
            const SizedBox(width: AtomSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.teamOwnerRole, style: AtomText.listTitle),
                  Text(l.teamOwnerRoleSum, style: AtomText.secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small blue chips (`.cp span`).
class _Chips extends StatelessWidget {
  const _Chips(this.chips);

  final List<String> chips;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final c in chips)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AtomColors.primarySoft,
            borderRadius: AtomRadius.brTag,
          ),
          child: Text(
            c,
            style: AtomText.tag.copyWith(
              fontWeight: FontWeight.w600,
              color: AtomColors.primary,
            ),
          ),
        ),
    ],
  );
}
