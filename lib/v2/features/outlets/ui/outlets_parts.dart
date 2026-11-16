import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../auth/ui/auth_parts.dart' show atomshopWhatsApp;
import '../data/outlet_models.dart';
import '../data/outlet_rules.dart';

/// Opens a WhatsApp chat with Atomshop with [text] typed.
Future<void> askAtomshop(String text) => launchUrl(
  Uri.parse(
    'https://wa.me/${atomshopWhatsApp.substring(1)}?text=${Uri.encodeComponent(text)}',
  ),
  mode: LaunchMode.externalApplication,
);

/// The status pill: green Open, amber Paused, grey Closed.
class OutletStatusPill extends StatelessWidget {
  const OutletStatusPill({super.key, required this.status});

  final OutletStatus status;

  @override
  Widget build(BuildContext context) => AtomPill(
    label: status.label(AppLocalizations.of(context)),
    tone: switch (status) {
      OutletStatus.open => AtomTone.green,
      OutletStatus.paused => AtomTone.amber,
      OutletStatus.closed => AtomTone.grey,
    },
    // `.pill` at `height: 22px`, as on 11.7
    compact: true,
  );
}

/// The note colour for a status plan.
AtomNoteKind noteKindOf(StatusNote t) => switch (t) {
  StatusNote.good => AtomNoteKind.success,
  StatusNote.warning => AtomNoteKind.warning,
  StatusNote.problem => AtomNoteKind.problem,
};

/// Underlined tabs on a white strip (`.tabs`).
class OutletTabs<T> extends StatelessWidget {
  const OutletTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(bottom: BorderSide(color: AtomColors.line)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AtomSpace.s2),
      child: Row(
        children: [
          for (final (value, label) in tabs)
            AtomPressable(
              onTap: () => onChanged(value),
              selected: value == selected,
              scaleOnPress: false,
              semanticLabel: label,
              builder: (_, pressed) => Container(
                constraints: const BoxConstraints(
                  minHeight: AtomSize.tapTarget,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: value == selected
                          ? AtomColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: AtomText.smallButton.copyWith(
                      fontSize: 14,
                      color: value == selected
                          ? AtomColors.primary
                          : AtomColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// A label over a value (`.f3 div`), for the outlet card's figures.
class OutletFigure extends StatelessWidget {
  const OutletFigure({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AtomText.small),
        Text(
          value,
          style: AtomText.money.copyWith(fontSize: 14, color: AtomColors.ink),
        ),
      ],
    ),
  );
}

/// The white bar at the bottom of a form or page.
class OutletBottomBar extends StatelessWidget {
  const OutletBottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AtomColors.paper,
      border: Border(top: BorderSide(color: AtomColors.line)),
    ),
    padding: EdgeInsets.fromLTRB(
      AtomSpace.gutter,
      AtomSpace.s3,
      AtomSpace.gutter,
      MediaQuery.paddingOf(context).bottom + AtomSpace.s3,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
