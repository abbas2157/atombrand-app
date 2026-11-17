import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/team_models.dart';
import '../data/team_rules.dart';
import 'team_parts.dart';

/// Team member added (11.3): the username and the temporary password,
/// shown once, with Copy and Send on WhatsApp. The member comes as the
/// route's `extra`; after Android restarts the app it is gone, and the
/// screen says to reset the password instead.
class TeamAddedScreen extends ConsumerWidget {
  const TeamAddedScreen({super.key, this.added});

  final MemberWithLogin? added;

  void _done(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(V2Routes.team);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = added;
    final offline = ref.watch(accessProvider).has(Addon.offline);
    return Scaffold(
      backgroundColor: AtomColors.paper,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomFlowBar(
            leading: AtomFlowLeading.close,
            onLeading: () => _done(context),
          ),
          Expanded(
            child: a == null
                ? AtomMessageState(
                    icon: LucideIcons.keyRound,
                    title: l.teamAddedGoneTitle,
                    body: l.teamAddedGoneBody,
                  )
                : AtomReadableWidth(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AtomSpace.gutter),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: AtomColors.greenSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.check,
                                  size: 34,
                                  color: AtomColors.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Semantics(
                                header: true,
                                child: Text(
                                  l.teamAddedTitle(a.member.name),
                                  textAlign: TextAlign.center,
                                  style: AtomText.successTitle,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${a.member.role?.name ?? l.teamNoRole} · ${worksIn(l, a.member)}',
                                textAlign: TextAlign.center,
                                style: AtomText.body.copyWith(
                                  color: AtomColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AtomSpace.gutter,
                            18,
                            AtomSpace.gutter,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TeamLoginCard(added: a),
                              const SizedBox(height: AtomSpace.s3),
                              AtomNote(
                                kind: AtomNoteKind.info,
                                iconless: true,
                                message: _addedNote(
                                  l,
                                  a.member.role?.name ?? l.teamMemberTitle,
                                  offline: offline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          TeamBottomBar(
            children: [
              AtomButton(label: l.teamDone, onPressed: () => _done(context)),
            ],
          ),
        ],
      ),
    );
  }
}

/// "… only what an Outlet manager may see, and can work offline on it."
String _addedNote(AppLocalizations l, String role, {required bool offline}) {
  final a = RegExp('^[aeiouAEIOU]').hasMatch(role)
      ? l.teamArticleAn(role)
      : l.teamArticleA(role);
  return offline ? l.teamAddedNoteOffline(a) : l.teamAddedNote(a);
}
