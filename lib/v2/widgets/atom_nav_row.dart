import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'atom_pressable.dart';
import 'atom_spinner.dart';

/// A white card holding [AtomNavRow]s, with a line between rows.
class AtomRowGroup extends StatelessWidget {
  const AtomRowGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: AtomSpace.gutter),
  });

  final List<Widget> children;

  /// The page gutter by default; zero inside something already padded
  /// (a sheet).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      // 1 for the line, which is drawn over the rows: under them, each
      // row's own white hid it at the rounded corners.
      padding: const EdgeInsets.all(1),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brCard,
      ),
      foregroundDecoration: AtomDecor.cardOutline,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The Settings row, used for every navigation row in the app.
///
/// An icon on a tinted tile, the title, a second line, then an optional
/// trailing value, a red count badge and a chevron.
///
/// States (board 19.x Settings):
/// - [disabledReason] greys the row, replaces the second line with the
///   reason ("Needs internet") and stops taps. It is not hidden: only an
///   add-on that is off is left out.
/// - [loading] shows a spinner instead of the trailing value.
/// - [error] shows the second line in rose ("Couldn't load · tap to try
///   again"); the row stays tappable so the tap can retry.
/// - [danger] makes the row red, for Sign out and Close the account.
///
/// Text wraps instead of being cut off, so the row grows at 200% text size.
class AtomNavRow extends StatelessWidget {
  const AtomNavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tone = AtomTone.grey,
    this.trailing,
    this.badge,
    this.disabledReason,
    this.loading = false,
    this.error,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? subtitle;

  /// The colour of the icon tile.
  final AtomTone tone;

  /// A value at the end of the row ("English", "On", "270 MB").
  final String? trailing;

  /// A count in a red badge.
  final int? badge;
  final String? disabledReason;
  final bool loading;
  final String? error;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final disabled = disabledReason != null;
    final second = disabledReason ?? error ?? subtitle;
    final tileTone = danger ? AtomTone.rose : tone;
    final titleColor = danger ? AtomColors.rose : AtomColors.ink;
    // From 150% text the trailing value moves under the second line, so the
    // title keeps the width it needs to wrap by words, not by letters.
    final stacked = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final showTrailing =
        !loading && trailing != null && !disabled && error == null;
    final trailingText = showTrailing
        ? Text(
            trailing!,
            textAlign: stacked ? TextAlign.start : TextAlign.right,
            style: AtomText.body.copyWith(
              color: AtomColors.muted,
              fontWeight: FontWeight.w500,
            ),
          )
        : null;

    return AtomPressable(
      onTap: disabled ? null : onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [
        title,
        ?second,
        if (!disabled && !loading) ?trailing,
        if (badge != null && !disabled) '$badge',
      ].join(', '),
      builder: (context, pressed) => Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: AtomSize.row),
          padding: const EdgeInsets.symmetric(
            horizontal: AtomSpace.inset,
            vertical: 10,
          ),
          color: pressed ? AtomColors.head : AtomColors.paper,
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: AtomSize.rowTile,
                  height: AtomSize.rowTile,
                  decoration: BoxDecoration(
                    color: tileTone.bg,
                    borderRadius: AtomRadius.brControl,
                  ),
                  child: Icon(icon, size: 18, color: tileTone.fg),
                ),
                const SizedBox(width: AtomSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AtomText.listTitle.copyWith(color: titleColor),
                      ),
                      if (second != null)
                        Text(
                          second,
                          style: AtomText.secondary.copyWith(
                            color: error != null && !disabled
                                ? AtomColors.rose
                                : AtomColors.muted,
                          ),
                        ),
                      if (stacked && trailingText != null) trailingText,
                    ],
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: AtomSpace.s2),
                  const AtomSpinner(),
                ] else if (!stacked && trailingText != null) ...[
                  const SizedBox(width: AtomSpace.s2),
                  trailingText,
                ],
                if (badge != null && !disabled) ...[
                  const SizedBox(width: AtomSpace.s2),
                  AtomCountBadge(count: badge!),
                ],
                if (showChevron && !danger) ...[
                  const SizedBox(width: AtomSpace.s1),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AtomColors.chevron,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A red pill with a count, for rows and the alerts bell.
class AtomCountBadge extends StatelessWidget {
  const AtomCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AtomColors.alertBadge,
        borderRadius: AtomRadius.brPill,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AtomText.small.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
