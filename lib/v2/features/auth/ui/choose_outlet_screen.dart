import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/getting_ready_due.dart';
import 'auth_parts.dart';

/// 2.6 "Where are you working today?", on the way in for a person on a
/// brand with more than one outlet. The outlets come from the session
/// (`GET outlets`, read by the access controller after sign-in); a team
/// member sees only the outlets they work in. "All outlets" is the brand
/// as a whole (no `X-Outlet` header).
///
/// The same choice later is the Home feature's outlet switcher (5.7),
/// which calls `sessionProvider.notifier.selectOutlet` too.
class ChooseOutletScreen extends ConsumerStatefulWidget {
  const ChooseOutletScreen({super.key});

  @override
  ConsumerState<ChooseOutletScreen> createState() => _ChooseOutletScreenState();
}

class _ChooseOutletScreenState extends ConsumerState<ChooseOutletScreen> {
  /// The outlet picked; null is All outlets.
  int? _picked;
  bool _pickedSet = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.watch(sessionProvider);
    final session = ref.read(sessionProvider.notifier).current;
    final who = session?.who;
    final offlineAddon = ref.watch(
      accessProvider.select((a) => a.has(Addon.offline)),
    );
    // Every outlet this person works in. A paused one is listed (as on the
    // board) but can't be picked: its team is signed out until it reopens.
    final mine = [
      for (final o in session?.outlets ?? const <Outlet>[])
        if ((o.active || o.paused) && (who?.worksIn(o.id) ?? true)) o,
    ];
    final open = [
      for (final o in mine)
        if (o.active) o,
    ];
    if (!_pickedSet && open.isNotEmpty) {
      _pickedSet = true;
      // The board starts on the main outlet; else the one chosen before.
      _picked =
          session?.outletId ??
          (open.where((o) => o.isMain).firstOrNull ?? open.first).id;
    }
    final canAll = who?.outletIds == null;
    final picked = open.where((o) => o.id == _picked).firstOrNull;
    final padding = MediaQuery.paddingOf(context);

    Widget row({
      required String title,
      required IconData icon,
      required AtomTone tone,
      String? subtitle,
      Widget? tag,
      required bool on,
      required VoidCallback? onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AtomOptionCard(
        leading: AtomIconTile(icon: icon, tone: tone),
        title: title,
        subtitle: subtitle,
        titleTag: tag,
        selected: on,
        onTap: onTap,
      ),
    );

    String? line(Outlet o) {
      if (o.paused) {
        return who?.isOwner ?? false
            ? l.authOutletPausedByYou
            : l.authOutletPausedByOwner;
      }
      if (o.serves.isEmpty) return o.city;
      final serves = o.serves.join(', ');
      return o.city == null
          ? l.authOutletServesOnly(serves)
          : l.authOutletServes(o.city!, serves);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, padding.top + 16, 20, 16),
                children: [
                  if (session?.brandName case final brand?)
                    Text(
                      brand.toUpperCase(),
                      style: AtomText.section.copyWith(
                        color: AtomColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  const SizedBox(height: AtomSpace.s2),
                  Semantics(
                    header: true,
                    child: Text(l.outletTitle, style: AuthText.h1),
                  ),
                  const SizedBox(height: 8),
                  Text(l.outletBody, style: AuthText.sub),
                  const SizedBox(height: 22),
                  if (open.isEmpty)
                    AtomNote(kind: AtomNoteKind.info, message: l.outletNone),
                  if (canAll && open.isNotEmpty)
                    row(
                      title: l.outletAll,
                      icon: LucideIcons.layoutGrid,
                      tone: AtomTone.grey,
                      subtitle: l.authOutletAllSub(open.length),
                      on: _picked == null,
                      onTap: () => setState(() => _picked = null),
                    ),
                  for (final o in mine)
                    row(
                      title: o.name,
                      icon: LucideIcons.store,
                      tone: o.paused ? AtomTone.amber : AtomTone.blue,
                      subtitle: line(o),
                      tag: o.paused
                          ? AtomPill(
                              label: l.homePausedPill,
                              tone: AtomTone.amber,
                            )
                          : o.isMain
                          ? AtomPill(label: l.outletMain, tone: AtomTone.blue)
                          : null,
                      on: _picked == o.id,
                      onTap: o.paused
                          ? null
                          : () => setState(() => _picked = o.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // With the Offline add-on the copy follows the outlet
                  // chosen (sync/snapshot is scoped by X-Outlet), so the
                  // line says what is really kept; it isn't a switch.
                  if (offlineAddon && open.isNotEmpty) ...[
                    MergeSemantics(
                      child: Semantics(
                        checked: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: AtomCheckbox(on: true),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                picked == null
                                    ? l.authOutletKeepAll
                                    : l.authOutletKeepOne(picked.name),
                                style: AtomText.body.copyWith(
                                  color: AtomColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AtomButton(
                    label: l.outletContinue(picked?.name ?? l.outletAll),
                    onPressed: () {
                      // Getting ready (2.7) follows, with the Offline
                      // add-on.
                      ref.read(gettingReadyDueProvider.notifier).arm();
                      ref
                          .read(sessionProvider.notifier)
                          .selectOutlet(picked?.id, picked?.name);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
