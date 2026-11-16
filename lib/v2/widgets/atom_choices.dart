import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'atom_pressable.dart';

/// One side of an [AtomSegmented].
class AtomSegment<T> {
  const AtomSegment(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// Two choices side by side in a grey track ("Shop owner | Team member",
/// "Instalment | Cash").
class AtomSegmented<T> extends StatelessWidget {
  const AtomSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AtomSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    // `.seg` is 48 tall: a 1 border, 4 padding and the 38 buttons. Each
    // button's 48 tap area takes the whole height, so the border is painted
    // over it rather than added to it.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        color: AtomColors.surface,
        borderRadius: AtomRadius.brControl,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: AtomColors.line),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: AtomPressable(
                onTap: () => onChanged(s.value),
                selected: s.value == selected,
                scaleOnPress: false,
                semanticLabel: s.label,
                builder: (context, _) {
                  final on = s.value == selected;
                  final colour = on ? AtomColors.ink : AtomColors.muted;
                  return Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? AtomColors.paper : Colors.transparent,
                      borderRadius: AtomRadius.brControl,
                      boxShadow: on
                          ? const [
                              BoxShadow(
                                color: Color(0x14101828),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                              BoxShadow(
                                color: AtomColors.line,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.icon != null) ...[
                            Icon(s.icon, size: AtomIcon.inline, color: colour),
                            const SizedBox(width: 6),
                          ],
                          // One line, as on the boards: a long label in a
                          // narrow segment ("This month" in four) shrinks a
                          // little instead of wrapping.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                s.label,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: AtomText.body.copyWith(
                                  color: colour,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A radio circle.
class AtomRadio extends StatelessWidget {
  const AtomRadio({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: on ? AtomColors.primary : AtomColors.line2,
        width: on ? 7 : 2,
      ),
    ),
  );
}

/// A checkbox square.
class AtomCheckbox extends StatelessWidget {
  const AtomCheckbox({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      color: on ? AtomColors.primary : AtomColors.paper,
      borderRadius: AtomRadius.brTag,
      border: Border.all(
        color: on ? AtomColors.primary : AtomColors.line2,
        width: 2,
      ),
    ),
    child: on
        ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
        : null,
  );
}

/// A choice drawn as a card: a radio (or checkbox), a title and a line of
/// explanation. Selected has a 2px primary border and a soft ring.
class AtomOptionCard extends StatelessWidget {
  const AtomOptionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.multi = false,
    this.trailing,
    this.leading,
    this.titleTag,
    this.subtitleWidget,
    this.inset = 12,
    this.minHeight = 0,
  });

  final String title;
  final String? subtitle;
  final bool selected;

  /// Padding inside the card (one less when selected, for the 2px line).
  /// Choose shop's cards are 14 in and 72 tall (2.5).
  final double inset;
  final double minHeight;
  final VoidCallback? onTap;
  final bool multi;
  final Widget? trailing;

  /// An icon tile at the start. With one, the radio moves to the end
  /// (Forgot password's channels, Choose shop).
  final Widget? leading;

  /// A pill beside the title ("Main", "Paused").
  final Widget? titleTag;

  /// More under the subtitle, such as a shop's figures.
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      selected: selected,
      scaleOnPress: false,
      focusRadius: AtomRadius.brCard,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      builder: (context, pressed) => Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.all(selected ? inset - 1 : inset),
          decoration: BoxDecoration(
            color: pressed ? AtomColors.head : AtomColors.paper,
            borderRadius: AtomRadius.brCard,
            border: Border.all(
              color: selected ? AtomColors.primary : AtomColors.line,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3),
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                if (leading != null)
                  leading!
                else
                  multi ? AtomCheckbox(on: selected) : AtomRadio(on: selected),
                const SizedBox(width: AtomSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: AtomSpace.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: AtomText.listTitle),
                          ?titleTag,
                        ],
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: AtomText.secondary),
                      if (subtitleWidget != null) ...[
                        const SizedBox(height: 4),
                        subtitleWidget!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AtomSpace.s2),
                  trailing!,
                ],
                if (leading != null) ...[
                  const SizedBox(width: AtomSpace.s2),
                  multi ? AtomCheckbox(on: selected) : AtomRadio(on: selected),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice among fixed ones laid in a grid (Cash, JazzCash, EasyPaisa,
/// Bank).
class AtomChoiceGrid<T> extends StatelessWidget {
  const AtomChoiceGrid({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.columns = 4,
  });

  final List<AtomSegment<T>> choices;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final int columns;

  @override
  Widget build(BuildContext context) {
    // Rows of Expanded cells, not a LayoutBuilder: a form that fills the
    // screen (SliverFillRemaining) asks for its intrinsic height, which a
    // LayoutBuilder can't give, and Apply rendered blank.
    // At large text the four columns become two.
    final scaled = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final cols = scaled ? (columns / 2).ceil() : columns;
    TextStyle style(bool on) => AtomText.smallButton.copyWith(
      color: on ? AtomColors.primary : AtomColors.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < choices.length; r += cols) ...[
          if (r > 0) const SizedBox(height: AtomSpace.s2),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = r; i < r + cols; i++) ...[
                  if (i > r) const SizedBox(width: AtomSpace.s2),
                  Expanded(
                    child: i < choices.length
                        ? _cell(choices[i], style)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _cell(AtomSegment<T> c, TextStyle Function(bool on) style) =>
      AtomPressable(
        onTap: onChanged == null ? null : () => onChanged!(c.value),
        selected: c.value == selected,
        semanticLabel: c.label,
        builder: (context, pressed) {
          final on = c.value == selected;
          return Container(
            constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: on
                  ? AtomColors.primarySoft
                  : pressed
                  ? AtomColors.surface
                  : AtomColors.paper,
              borderRadius: AtomRadius.brControl,
              border: Border.all(
                color: on ? AtomColors.primary : AtomColors.line2,
                width: on ? 2 : 1,
              ),
            ),
            // One word ("EasyPaisa") never breaks mid-word on a
            // narrow phone: it shrinks a little instead.
            child: c.label.contains(' ')
                ? Text(c.label, textAlign: TextAlign.center, style: style(on))
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      c.label,
                      maxLines: 1,
                      softWrap: false,
                      style: style(on),
                    ),
                  ),
          );
        },
      );
}
