import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'atom_pressable.dart';
import 'atom_photo.dart';

/// A round tile with a person's initials, in a tone picked from their name
/// so the same person always has the same colour. With [imageUrl] (their
/// photo) the photo fills the circle; the initials show while it loads or
/// when it can't be had.
class AtomInitials extends StatelessWidget {
  const AtomInitials({
    super.key,
    required this.name,
    this.size = 40,
    this.imageUrl,
    this.tone,
  });

  final String name;
  final double size;
  final String? imageUrl;

  /// In place of the tone picked from the name, when the colour means
  /// something (a lead's source, won or lost).
  final AtomTone? tone;

  static const _tones = [
    AtomTone.blue,
    AtomTone.green,
    AtomTone.amber,
    AtomTone.purple,
    AtomTone.rose,
  ];

  static String initialsOf(String name) {
    // Words only: "Lahore · Gulberg" is LG, not "L·".
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (p) =>
              p.isNotEmpty &&
              RegExp(r'^[\p{L}\p{N}]', unicode: true).hasMatch(p),
        );
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final tone =
        this.tone ??
        _tones[name.codeUnits.fold(0, (a, b) => a + b) % _tones.length];
    final letters = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
      child: Text(
        initialsOf(name),
        style: AtomText.body.copyWith(
          color: tone.fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final url = imageUrl;
    if (url == null || url.isEmpty) return letters;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: AtomPhoto(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Only as many pixels as the circle needs.
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (_, _, _) => letters,
          frameBuilder: (_, child, frame, sync) =>
              frame == null && !sync ? letters : child,
        ),
      ),
    );
  }
}

/// A row in a list card: initials, a name and a second line, then an amount
/// with a small tag under it, and an optional action button.
///
/// Used by Collections, Orders, Customers and Leads. Wraps at large text.
class AtomListRow extends StatelessWidget {
  const AtomListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.amount,
    this.tag,
    this.tagTone,
    this.action,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Already formatted (`Rs 8,400`).
  final String? amount;
  final String? tag;
  final AtomTone? tagTone;

  /// A small button after the row ("Collect", "Receipt").
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final money = amount == null && tag == null
        ? null
        : Column(
            crossAxisAlignment: stacked
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (amount != null) Text(amount!, style: AtomText.money),
              if (tag != null)
                Text(
                  tag!,
                  textAlign: stacked ? TextAlign.start : TextAlign.end,
                  style: AtomText.small.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (tagTone ?? AtomTone.grey).fg,
                  ),
                ),
            ],
          );

    final row = AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: BorderRadius.zero,
      semanticLabel: [title, ?subtitle, ?amount, ?tag].join(', '),
      builder: (context, pressed) => Container(
        color: pressed ? AtomColors.head : AtomColors.paper,
        padding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: AtomSpace.s3,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AtomSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AtomText.listTitle),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: AtomText.secondary),
                      ),
                    if (stacked && money != null) ...[
                      const SizedBox(height: 4),
                      money,
                    ],
                  ],
                ),
              ),
              if (!stacked && money != null) ...[
                const SizedBox(width: AtomSpace.s2),
                // Its own width, up to 40% of the row, so a long tag ("41
                // days late") wraps rather than pushing past a narrow row,
                // and the title keeps the rest (a Flexible here split the
                // row in half and left "+1" in the middle).
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                  child: money,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (action == null) return row;
    return ColoredBox(
      color: AtomColors.paper,
      child: Row(
        children: [
          Expanded(child: row),
          Padding(
            padding: const EdgeInsets.only(right: AtomSpace.s3),
            child: action,
          ),
        ],
      ),
    );
  }
}

/// A white card holding list rows, with a line between them.
class AtomListCard extends StatelessWidget {
  const AtomListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1 for the line, as a CSS border takes its width inside the card.
      padding: const EdgeInsets.all(1),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brCard,
      ),
      // Over the rows: under them, a row's own white hid it at the corners.
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

/// [AtomListCard] for a list that can be long (orders, customers, stock):
/// a sliver that builds only the rows on screen, one at a time, and draws
/// the same card around them. Each row carries its own piece of the card:
/// the first the top border and corners, the last the bottom ones, and
/// every row after the first a hairline above it.
///
/// Put it in a [CustomScrollView] (inside a [SliverPadding] for the side
/// gutters); show an empty state instead when [itemCount] is 0.
class SliverAtomListCard extends StatelessWidget {
  const SliverAtomListCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, i) => AtomListCardSlice(
        first: i == 0,
        last: i == itemCount - 1,
        child: itemBuilder(context, i),
      ),
    );
  }
}

/// A scrolling page of [slivers] with [padding] round them, always
/// scrollable so pull-to-refresh works on a short list: the sliver form of
/// `ListView(physics: AlwaysScrollableScrollPhysics(), padding: …)`.
class AtomSliverPage extends StatelessWidget {
  const AtomSliverPage({
    super.key,
    required this.slivers,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> slivers;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
      ],
    );
  }
}

/// One row's piece of a list card, as [SliverAtomListCard] draws it.
class AtomListCardSlice extends StatelessWidget {
  const AtomListCardSlice({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AtomColors.line);
    const corner = Radius.circular(AtomRadius.card);
    final radius = BorderRadius.vertical(
      top: first ? corner : Radius.zero,
      bottom: last ? corner : Radius.zero,
    );
    return Container(
      // 1 for each line, as a CSS border takes its width inside the card.
      padding: EdgeInsets.fromLTRB(1, first ? 1 : 0, 1, last ? 1 : 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AtomColors.paper, borderRadius: radius),
      // Over the row: under it, the row's own white hid it at the corners.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border(
          left: side,
          right: side,
          top: first ? side : BorderSide.none,
          bottom: last ? side : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!first) const Divider(height: 1, color: AtomColors.line),
          child,
        ],
      ),
    );
  }
}

/// The grey strip under a list header with two figures
/// ("To collect today Rs 52,300 · Collected today Rs 18,500").
class AtomSummaryBar extends StatelessWidget {
  const AtomSummaryBar({super.key, required this.items});

  /// Label → value, already formatted.
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtomSpace.gutter,
        vertical: AtomSpace.s3,
      ),
      decoration: const BoxDecoration(
        color: AtomColors.head,
        border: Border(bottom: BorderSide(color: AtomColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (label, value)) in items.indexed) ...[
            // `.sumbar` gap 10.
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // `.sumbar` has the browser's normal line height.
                  Text(
                    label,
                    style: AtomText.secondary.copyWith(
                      height: AtomText.normalHeight,
                    ),
                  ),
                  // A long figure ("Rs 1,039,491") shrinks to its third
                  // rather than running into the next one.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: AtomText.money.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A ▾ filter above a list ("Area: All"). Opens the searchable dropdown.
class AtomFilterChip extends StatelessWidget {
  const AtomFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
    this.minHeight = 32,
  });

  final String label;
  final VoidCallback? onTap;

  /// A filter that is set (not "All").
  final bool active;

  /// The chip's height at the default text size (`.fchip` is 36 on the
  /// list boards).
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colour = active ? AtomColors.primary : AtomColors.text;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, pressed) => Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AtomColors.primarySoft
              : pressed
              ? AtomColors.surface
              : AtomColors.paper,
          borderRadius: AtomRadius.brControl,
          border: Border.all(
            color: active ? AtomColors.primary : AtomColors.line2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Wraps on a narrow phone at large text instead of running off.
            Flexible(
              child: Text(
                label,
                style: AtomText.smallButton.copyWith(color: colour),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: colour),
          ],
        ),
      ),
    );
  }
}

/// A label and a value on one line, with lines between them
/// ("Your role · Recovery").
class AtomInfoLine extends StatelessWidget {
  const AtomInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onDark = false,
    this.total = false,
    this.vertical = AtomSpace.s3,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool onDark;

  /// Space above and below (`.line` is 12; a receipt's `.line` is 8).
  final double vertical;

  /// The sum at the foot ("Customer pays now"): label 16/600 ink, value 20.
  final bool total;

  @override
  Widget build(BuildContext context) {
    final labelStyle = total
        ? AtomText.input.copyWith(
            color: onDark ? Colors.white : AtomColors.ink,
            fontWeight: FontWeight.w600,
          )
        : AtomText.body.copyWith(
            color: onDark ? AtomColors.navText : AtomColors.muted,
            // `.line` has the browser's normal line height, not 1.45.
            height: AtomText.normalHeight,
          );
    final valueStyle = AtomText.body.copyWith(
      fontSize: total ? 20 : null,
      height: AtomText.normalHeight,
      // `.line b`: b is 600 on the boards; the total stays 700.
      fontWeight: total ? FontWeight.w700 : FontWeight.w600,
      // Tabular figures for amounts, phones and dates only: in words a
      // hyphen takes a figure's width ("demo - buyer", "QT - 0001").
      fontFeatures: RegExp(r'^(Rs\s?)?[\d\s,.:+×/\-]+$').hasMatch(value)
          ? const [FontFeature.tabularFigures()]
          : null,
      color: valueColor ?? (onDark ? Colors.white : AtomColors.ink),
    );
    final lw = atomTextWidth(context, label, labelStyle);
    final vw = atomTextWidth(context, value, valueStyle);
    final minL = atomLongestWord(context, label, labelStyle);
    final minV = atomLongestWord(context, value, valueStyle);
    final dir = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    // The label's width in [room], and whether the value wraps: a value
    // that has to wrap fills the rest of the row with its lines left-
    // aligned, as `.line b` does; one that fits sits at the right edge.
    (double, bool) split(double room) {
      if (lw + vw <= room) return (lw.ceilToDouble().clamp(0, room), false);
      final w = (room * lw / (lw + vw)).clamp(
        minL.clamp(0, room),
        (room - minV).clamp(minL.clamp(0, room), room),
      );
      return (w.ceilToDouble().clamp(0, room), true);
    }

    double heightOf(String text, TextStyle style, double width) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: dir,
        textScaler: scaler,
      )..layout(maxWidth: math.max(0, width));
      final h = tp.height;
      tp.dispose();
      return h;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      // `.line` is space-between: each side keeps its own width while both
      // fit; when they don't, each gives up room in proportion to its width
      // (CSS flex-shrink), so a short value ("Works") leaves the label most
      // of the row and a short label ("Sees") leaves it to the value.
      // As in CSS, neither side shrinks below its longest word, so "Phone"
      // never breaks into "Phon / e" beside a long value.
      // Pages that size to their content (SliverFillRemaining, Intrinsic-
      // Height: Maintenance, Update required) ask a line its height before
      // laying it out, which a LayoutBuilder can't answer; _LineIntrinsics
      // answers from the same split, so those pages don't come out blank.
      child: _LineIntrinsics(
        minWidth: minL + 10 + minV,
        maxWidth: lw + 10 + vw,
        heightAt: (width) {
          final room = math.max(0.0, width - 10);
          final (labelW, _) = split(room);
          return math.max(
            heightOf(label, labelStyle, labelW),
            heightOf(value, valueStyle, room - labelW),
          );
        },
        child: LayoutBuilder(
          builder: (context, box) {
            final room = box.maxWidth - 10;
            final (labelW, wraps) = split(room);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // `.line{align-items:center}`: a one-line side sits in the
              // middle of a wrapped one.
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: labelW,
                  child: Text(label, style: labelStyle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    textAlign: wraps ? TextAlign.start : TextAlign.end,
                    style: valueStyle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A line's sizes for the pages that ask before laying out (see
/// [AtomInfoLine]); the layout itself is the child's.
class _LineIntrinsics extends SingleChildRenderObjectWidget {
  const _LineIntrinsics({
    required this.minWidth,
    required this.maxWidth,
    required this.heightAt,
    required super.child,
  });

  final double minWidth;
  final double maxWidth;
  final double Function(double width) heightAt;

  @override
  _RenderLineIntrinsics createRenderObject(BuildContext context) =>
      _RenderLineIntrinsics(minWidth, maxWidth, heightAt);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLineIntrinsics renderObject,
  ) {
    renderObject
      ..minW = minWidth
      ..maxW = maxWidth
      ..heightAt = heightAt;
  }
}

class _RenderLineIntrinsics extends RenderProxyBox {
  _RenderLineIntrinsics(this.minW, this.maxW, this.heightAt);

  double minW;
  double maxW;
  double Function(double width) heightAt;

  double _h(double width) => heightAt(width.isFinite ? width : maxW);

  @override
  double computeMinIntrinsicWidth(double height) => minW;

  @override
  double computeMaxIntrinsicWidth(double height) => maxW;

  @override
  double computeMinIntrinsicHeight(double width) => _h(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _h(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final w = constraints.hasBoundedWidth ? constraints.maxWidth : maxW;
    return constraints.constrain(Size(w, _h(w)));
  }
}

/// [text]'s width on one line.
double atomTextWidth(BuildContext context, String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w + 1;
}

/// The widest single word of [text] (its CSS min-content width).
double atomLongestWord(BuildContext context, String text, TextStyle style) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final w = atomTextWidth(context, word, style);
    if (w > widest) widest = w;
  }
  return widest;
}

/// [text]'s width on one line, as a flex factor (at least 1): two
/// Flexibles with these share a row like CSS space-between, each keeping
/// its width while both fit and giving up room in proportion when not.
int atomTextFlex(BuildContext context, String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w.ceil().clamp(1, 100000);
}

/// [AtomInfoLine]s in a card, with a line between each.
class AtomInfoCard extends StatelessWidget {
  const AtomInfoCard({super.key, required this.lines, this.onDark = false});

  final List<AtomInfoLine> lines;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final line = onDark ? AtomColors.navLine : AtomColors.line;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AtomSpace.inset,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: onDark ? AtomColors.nav2 : AtomColors.paper,
        borderRadius: AtomRadius.brCard,
        border: Border.all(color: line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) Divider(height: 1, color: line),
            lines[i],
          ],
        ],
      ),
    );
  }
}

/// A square icon on a soft tile, as at the start of option cards and above
/// a page title.
class AtomIconTile extends StatelessWidget {
  const AtomIconTile({
    super.key,
    required this.icon,
    this.tone = AtomTone.blue,
    this.size = 40,
    this.glyph,
  });

  final IconData icon;
  final AtomTone tone;
  final double size;

  /// Draws the board's own glyph in place of [icon], when it has no Lucide
  /// match: given the glyph's size and colour.
  final Widget Function(double size, Color color)? glyph;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: BorderRadius.circular(
        size > 44 ? AtomRadius.card : AtomRadius.control,
      ),
    ),
    alignment: Alignment.center,
    child:
        glyph?.call(size * 0.48, tone.fg) ??
        Icon(icon, size: size * 0.48, color: tone.fg),
  );
}
