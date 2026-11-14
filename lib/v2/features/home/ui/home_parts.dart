import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Pieces of Home drawn as on the boards (5.1–5.8): the header's brand
/// button, the Ask Atom bar, the hero and its buttons, cards, rows, the
/// pipeline, the activity feed and the small buttons.

/// Text at 150% or more: rows that put a button beside text stack instead.
bool homeLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) >= 15;

/// The brand at the top of Home (`.shop-btn`): the logo on a white tile,
/// the brand and the outlet. With [onTap] it opens the outlet switcher
/// and shows a ▾.
class BrandHeaderButton extends StatelessWidget {
  const BrandHeaderButton({
    super.key,
    required this.title,
    required this.subtitle,
    this.logo,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? logo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final url = logo;
    final tile = url == null || url.isEmpty
        ? const AtomBrandTile(size: 36)
        : Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(4),
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AtomRadius.brControl,
            ),
            child: AtomPhoto(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const AtomBrandTile(size: 28),
            ),
          );
    final content = Row(
      children: [
        tile,
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtomText.listTitle.copyWith(color: Colors.white),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtomText.secondary.copyWith(
                        color: AtomColors.navText,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 14,
                      color: AtomColors.navText,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) {
      return Semantics(
        container: true,
        label: '$title, $subtitle',
        child: ExcludeSemantics(child: content),
      );
    }
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      semanticLabel: '${l.homeSwitchOutlet}, $title, $subtitle',
      builder: (_, _) => ExcludeSemantics(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: content,
        ),
      ),
    );
  }
}

/// The Ask Atom bar on the navy header: the mark in a white circle, the
/// prompt, a blue mic circle.
class AskAtomBar extends StatelessWidget {
  const AskAtomBar({
    super.key,
    required this.label,
    required this.onTap,
    this.light = false,
  });

  final String label;
  final VoidCallback onTap;

  /// On the tablet's white top bar (TabletHome `.ask`): grey fill and line,
  /// no mic.
  final bool light;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      focusRadius: AtomRadius.brPill,
      scaleOnPress: false,
      builder: (_, pressed) => ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: AtomSize.askBar),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: light
                ? AtomColors.surface
                : (pressed ? AtomColors.nav3 : AtomColors.nav2),
            borderRadius: AtomRadius.brPill,
            border: Border.all(
              color: light ? AtomColors.line : AtomColors.navLine,
            ),
          ),
          child: Row(
            children: [
              const AtomAiMark(size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: homeLargeText(context) ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtomText.body.copyWith(
                    color: light ? AtomColors.muted : AtomColors.navText,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
              if (!light) ...[
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AtomColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.mic,
                    size: AtomIcon.inline,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The navy hero card (`.hero`): a small label row, then [child].
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.label,
    this.labelEnd,
    required this.child,
  });

  final String label;
  final String? labelEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AtomColors.nav2,
      borderRadius: const BorderRadius.all(Radius.circular(AtomRadius.sheet)),
      border: Border.all(color: AtomColors.navLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AtomText.small.copyWith(color: AtomColors.navText),
              ),
            ),
            if (labelEnd != null)
              Text(
                labelEnd!,
                style: AtomText.small.copyWith(color: AtomColors.navMuted),
              ),
          ],
        ),
        child,
      ],
    ),
  );
}

/// One of the owner hero's three count tiles: the number, a coloured dot
/// and what it counts.
class HeroCountTile extends StatelessWidget {
  const HeroCountTile({
    super.key,
    required this.count,
    required this.label,
    required this.dot,
    required this.onTap,
  });

  final int count;
  final String label;
  final Color dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    semanticLabel: '$count $label',
    focusRadius: AtomRadius.brCard,
    builder: (_, pressed) => ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: pressed ? 0.12 : 0.06),
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: AtomColors.navLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '$count',
                      style: AtomText.amount.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AtomText.small.copyWith(
                color: AtomColors.navText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A count on one line (the team member's and the offline hero): the big
/// number and what it counts.
class HeroCountLine extends StatelessWidget {
  const HeroCountLine({
    super.key,
    required this.count,
    required this.label,
    this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    scaleOnPress: false,
    semanticLabel: '$count $label',
    builder: (_, _) => ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 34),
              child: Text(
                '$count',
                style: AtomText.amount.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AtomText.body.copyWith(color: AtomColors.navSoftText),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A button in the hero: 44 tall, 15px, light or a navy outline, with an
/// optional icon before and a badge after.
class HeroButton extends StatelessWidget {
  const HeroButton({
    super.key,
    required this.label,
    required this.onTap,
    this.light = false,
    this.icon,
    this.badge,
  });

  final String label;
  final VoidCallback onTap;
  final bool light;
  final IconData? icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final fg = light ? AtomColors.nav : Colors.white;
    return AtomPressable(
      onTap: onTap,
      semanticLabel: badge == null ? label : '$label, $badge',
      builder: (_, pressed) => ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AtomSize.heroButton,
            minWidth: double.infinity,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: light
                ? (pressed ? AtomColors.lightPressed : Colors.white)
                : (pressed ? AtomColors.nav3 : Colors.transparent),
            borderRadius: AtomRadius.brControl,
            border: Border.all(
              color: light ? Colors.transparent : AtomColors.navLine,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AtomText.button.copyWith(color: fg, fontSize: 15),
                  ),
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AtomColors.alertBadge,
                    borderRadius: AtomRadius.brPill,
                  ),
                  child: Text(
                    '$badge',
                    style: AtomText.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A tile with an icon, in a tone (`.ico`).
class HomeIconTile extends StatelessWidget {
  const HomeIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 40,
    this.iconSize = AtomIcon.row,
    this.background,
  });

  final IconData icon;
  final AtomTone tone;
  final double size;
  final double iconSize;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background ?? tone.bg,
      borderRadius: AtomRadius.brControl,
    ),
    child: Icon(icon, size: iconSize, color: tone.fg),
  );
}

/// A white card with the line and 14 radius (`.card`, `.chart`); children
/// separated by a hairline.
class HomeCard extends StatelessWidget {
  const HomeCard({super.key, this.child, this.children, this.padding})
    : assert(child != null || children != null);

  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: AtomDecor.card,
    foregroundDecoration: AtomDecor.cardOutline,
    child:
        child ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children!.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AtomColors.line),
              children![i],
            ],
          ],
        ),
  );
}

/// A row in a Home card (`.person`): a leading tile, a title and a line,
/// an amount and a pill on the right.
class HomeRow extends StatelessWidget {
  const HomeRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.amount,
    this.pill,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? amount;
  final Widget? pill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final large = homeLargeText(context);
    final end = amount == null && pill == null
        ? null
        : Column(
            crossAxisAlignment: large
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              if (amount != null) Text(amount!, style: AtomText.money),
              if (pill != null) ...[const SizedBox(height: 2), pill!],
            ],
          );
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: large ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtomText.listTitle,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      maxLines: large ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtomText.secondary,
                    ),
                  ),
                if (large && end != null) ...[const SizedBox(height: 4), end],
              ],
            ),
          ),
          if (!large && end != null) ...[const SizedBox(width: 12), end],
        ],
      ),
    );
    if (onTap == null) return row;
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      semanticLabel: [title, ?subtitle, ?amount].join(', '),
      builder: (_, pressed) => ColoredBox(
        color: pressed ? AtomColors.head : AtomColors.paper,
        child: row,
      ),
    );
  }
}

/// A small pill for a row (`.pill`, 20 tall, 11px).
class RowPill extends StatelessWidget {
  const RowPill({super.key, required this.label, required this.tone});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: AtomRadius.brPill,
      border: Border.all(color: tone.border),
    ),
    child: Text(
      label,
      style: AtomText.tag.copyWith(color: tone.fg, fontWeight: FontWeight.w600),
    ),
  );
}

/// A small button (`.mini`): 36 tall, 13px. Primary is the blue one.
class MiniButton extends StatelessWidget {
  const MiniButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.onDark = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  /// On the navy message banner.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = primary || onDark ? Colors.white : AtomColors.ink;
    final Color bg;
    final Color line;
    if (primary) {
      bg = AtomColors.primary;
      line = AtomColors.primary;
    } else if (onDark) {
      bg = AtomColors.nav2;
      line = AtomColors.navLine;
    } else {
      bg = AtomColors.paper;
      line = AtomColors.line2;
    }
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (_, pressed) => ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: AtomSize.small),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed
                ? (primary ? AtomColors.primaryPressed : AtomColors.surface)
                : bg,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: line),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: AtomText.smallButton.copyWith(
              color: pressed && onDark ? AtomColors.ink : fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// One step in the order pipeline.
class PipeStep {
  const PipeStep(this.label, this.count, this.colour, this.onTap);
  final String label;
  final int count;
  final Color colour;
  final VoidCallback onTap;
}

/// Orders by step (`.pipe` and `.pipe-l`): a bar split by count and the
/// steps under it, three to a row.
class OrderPipeline extends StatelessWidget {
  const OrderPipeline({
    super.key,
    required this.steps,
    required this.semanticLabel,
  });

  final List<PipeStep> steps;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bar = [
      for (final s in steps)
        if (s.count > 0) s,
    ];
    return HomeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: semanticLabel,
            child: ClipRRect(
              borderRadius: AtomRadius.brTag,
              child: SizedBox(
                height: 10,
                child: bar.isEmpty
                    ? const ColoredBox(color: AtomColors.surface)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < bar.length; i++) ...[
                            if (i > 0) const SizedBox(width: 2),
                            Expanded(
                              flex: bar[i].count,
                              child: ColoredBox(color: bar[i].colour),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  for (final s in steps)
                    SizedBox(
                      width: w,
                      child: _PipeLabel(step: s),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PipeLabel extends StatelessWidget {
  const _PipeLabel({required this.step});
  final PipeStep step;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: step.onTap,
    scaleOnPress: false,
    semanticLabel: '${step.count} ${step.label}',
    builder: (_, _) => ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: step.colour,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${step.count}',
                  style: AtomText.input.copyWith(
                    color: AtomColors.ink,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(step.label, style: AtomText.small),
          ],
        ),
      ),
    ),
  );
}

/// A line in Recent activity (`.ev`): a 32 tile and the text, with when
/// under it.
class ActivityLine extends StatelessWidget {
  const ActivityLine({
    super.key,
    required this.icon,
    required this.tone,
    required this.text,
    required this.meta,
    this.onTap,
  });

  final IconData icon;
  final AtomTone tone;
  final String text;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    scaleOnPress: false,
    semanticLabel: '$text, $meta',
    builder: (_, _) => ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeIconTile(icon: icon, tone: tone, size: 32, iconSize: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AtomText.body.copyWith(
                      color: AtomColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    meta,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A filter chip on Search (`.chip`): white, or blue when chosen.
class HomeChip extends StatelessWidget {
  const HomeChip({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    selected: on,
    scaleOnPress: false,
    semanticLabel: label,
    focusRadius: AtomRadius.brPill,
    builder: (_, _) => ExcludeSemantics(
      child: SizedBox(
        height: AtomSize.tapTarget,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: EdgeInsets.symmetric(
              horizontal: on ? 11 : 12,
              vertical: 6,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AtomColors.primarySoft : AtomColors.paper,
              borderRadius: AtomRadius.brPill,
              border: Border.all(
                color: on ? AtomColors.primary : AtomColors.line2,
                width: on ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: AtomText.smallButton.copyWith(
                color: on ? AtomColors.primary : AtomColors.text,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A grey sheet grab handle, for the sheets opened as routes.
class SheetGrab extends StatelessWidget {
  const SheetGrab({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 40,
      height: 4,
      decoration: const BoxDecoration(
        color: AtomColors.line2,
        borderRadius: AtomRadius.brPill,
      ),
    ),
  );
}
