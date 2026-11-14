import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';

enum AtomNoteKind { info, success, warning, problem }

/// A note in a soft colour: information (blue), success (green), warning
/// (amber) or a problem (rose).
class AtomNote extends StatelessWidget {
  const AtomNote({
    super.key,
    required this.kind,
    required this.message,
    this.title,
    this.icon,
    this.bold = const [],
    this.compact = false,
    this.iconless = false,
  });

  final AtomNoteKind kind;
  final String message;

  /// Bold text before the message ("3 changes waiting.").
  final String? title;

  /// Defaults to the kind's icon.
  final IconData? icon;

  /// Parts of [message] drawn in bold, as the boards' `<b>` inside a note
  /// ("Rs 8,400 a month"). Each is bolded where it first appears.
  final List<String> bold;

  /// The boards' smaller inline note (`style="padding: 10px 12px;
  /// font-size: 13px"`), used inside forms and sheets.
  final bool compact;

  /// No icon, 8 above and below: the board's bare `.note` with only text
  /// ("Pays the 4th Month in full.").
  final bool iconless;

  /// [message] split into plain and bold runs.
  List<TextSpan> _runs() {
    final runs = <TextSpan>[];
    var rest = message;
    while (rest.isNotEmpty) {
      var at = -1;
      var hit = '';
      for (final b in bold) {
        if (b.isEmpty) continue;
        final i = rest.indexOf(b);
        if (i >= 0 && (at < 0 || i < at)) (at, hit) = (i, b);
      }
      if (at < 0) {
        runs.add(TextSpan(text: rest));
        break;
      }
      if (at > 0) runs.add(TextSpan(text: rest.substring(0, at)));
      runs.add(
        TextSpan(
          text: hit,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
      rest = rest.substring(at + hit.length);
    }
    return runs;
  }

  @override
  Widget build(BuildContext context) {
    final (
      Color bg,
      Color border,
      Color fg,
      IconData defaultIcon,
    ) = switch (kind) {
      AtomNoteKind.info => (
        AtomColors.primarySoft,
        AtomColors.primaryLine,
        AtomColors.noteBlueText,
        LucideIcons.info,
      ),
      AtomNoteKind.success => (
        AtomColors.greenSoft,
        AtomColors.greenLine,
        AtomColors.noteGreenText,
        LucideIcons.check,
      ),
      AtomNoteKind.warning => (
        AtomColors.amberSoft,
        AtomColors.amberLine,
        AtomColors.amberInk,
        LucideIcons.circleAlert,
      ),
      AtomNoteKind.problem => (
        AtomColors.roseSoft,
        AtomColors.roseLine,
        AtomColors.noteRoseText,
        LucideIcons.circleAlert,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: kind == AtomNoteKind.problem,
      child: Container(
        padding: compact
            ? EdgeInsets.symmetric(horizontal: 12, vertical: iconless ? 8 : 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AtomRadius.brControl,
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!iconless) ...[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon ?? defaultIcon, size: 18, color: fg),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AtomText.body.copyWith(
                    color: fg,
                    fontSize: compact ? 13 : null,
                  ),
                  children: [
                    if (title != null)
                      TextSpan(
                        text: '$title ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ..._runs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A status pill: "Online", "Due", "Late", "Main".
class AtomPill extends StatelessWidget {
  const AtomPill({
    super.key,
    required this.label,
    this.tone = AtomTone.grey,
    this.dot = false,
  });

  final String label;
  final AtomTone tone;

  /// A small dot before the label, for live states (Online / Offline).
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: AtomRadius.brPill,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AtomText.small.copyWith(
              color: tone.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section label in capitals above a group ("ACCOUNT"), with an optional
/// note at the end in normal case.
class AtomSectionLabel extends StatelessWidget {
  const AtomSectionLabel(this.text, {super.key, this.note, this.page = true});

  final String text;
  final String? note;

  /// On a page the label lines up with a row group (18 in, 16 above).
  final bool page;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: page
            ? const EdgeInsets.fromLTRB(18, 16, 18, 8)
            : const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(text.toUpperCase(), style: AtomText.section)),
            if (note != null)
              Text(
                note!,
                style: AtomText.small.copyWith(
                  color: AtomColors.faint,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
