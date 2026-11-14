import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_headers.dart';
import 'atom_states.dart';

/// A screen that is not built yet: the canvas board's number and title, so
/// the route can be opened, linked to and checked before its feature lands.
///
/// Feature engineers replace these in their own `<feature>_routes.dart`.
/// [tab] true draws a tab root (no Back; the tab bar shows under it).
class AtomPlaceholderScreen extends StatelessWidget {
  const AtomPlaceholderScreen({
    super.key,
    required this.title,
    this.board,
    this.tab = false,
    this.detail,
  });

  /// The canvas screen name ("Cash order").
  final String title;

  /// The canvas board number ("6.2").
  final String? board;

  /// A tab root: no Back button.
  final bool tab;

  /// What the route was opened with (an id, a query), shown small.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtomColors.surface,
      body: Column(
        children: [
          AtomFlowBar(
            leading: tab ? AtomFlowLeading.none : AtomFlowLeading.back,
            title: title,
          ),
          Expanded(
            child: AtomMessageState(
              icon: LucideIcons.hammer,
              tone: AtomTone.blue,
              title: board == null ? title : '$board $title',
              body: [
                AppLocalizations.of(context).commonBeingBuilt,
                ?detail,
              ].join('\n'),
            ),
          ),
        ],
      ),
    );
  }
}
