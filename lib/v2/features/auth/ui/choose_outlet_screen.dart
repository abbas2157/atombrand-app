import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
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
    final outlets = [
      for (final o in session?.outlets ?? const <Outlet>[])
        if (o.active && (who?.worksIn(o.id) ?? true)) o,
    ];
    if (!_pickedSet && outlets.isNotEmpty) {
      _pickedSet = true;
      _picked =
          session?.outletId ??
          (who?.outletIds == null ? null : outlets.first.id);
    }
    final canAll = who?.outletIds == null;
    final picked = outlets.where((o) => o.id == _picked).firstOrNull;
    final padding = MediaQuery.paddingOf(context);

    Widget row({
      required String title,
      String? subtitle,
      Widget? tag,
      required bool on,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AtomOptionCard(
        leading: AtomIconTile(
          icon: LucideIcons.store,
          tone: on ? AtomTone.blue : AtomTone.grey,
        ),
        title: title,
        subtitle: subtitle,
        trailing: tag,
        selected: on,
        onTap: onTap,
      ),
    );

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
                  const SizedBox(height: 20),
                  if (outlets.isEmpty)
                    AtomNote(kind: AtomNoteKind.info, message: l.outletNone),
                  if (canAll && outlets.isNotEmpty)
                    row(
                      title: l.outletAll,
                      subtitle: l.outletAllSub,
                      on: _picked == null,
                      onTap: () => setState(() => _picked = null),
                    ),
                  for (final o in outlets)
                    row(
                      title: o.name,
                      subtitle: o.city,
                      tag: o.isMain
                          ? AtomPill(label: l.outletMain, tone: AtomTone.blue)
                          : null,
                      on: _picked == o.id,
                      onTap: () => setState(() => _picked = o.id),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, padding.bottom + 16),
              child: AtomButton(
                label: l.outletContinue(picked?.name ?? l.outletAll),
                onPressed: () {
                  // Getting ready (2.7) follows, with the Offline add-on.
                  ref.read(gettingReadyDueProvider.notifier).arm();
                  ref
                      .read(sessionProvider.notifier)
                      .selectOutlet(picked?.id, picked?.name);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
