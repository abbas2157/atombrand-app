import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'atom_pressable.dart';

/// Home and Collections building blocks: the section heading, the navy hero
/// card, KPI tiles, task rows, the 7-day chart, the plan's schedule rows and
/// a progress bar.

/// A section on a grey page: a 16/700 heading with an optional link on the
/// right, then [child].
class AtomSection extends StatelessWidget {
  const AtomSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// A link ("Reports", "All 4") or a pill ("5 open").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        style: AtomText.input.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    // At 150% text and more a link or pill goes under the title, so
    // neither runs off a narrow phone.
    if (trailing != null && MediaQuery.textScalerOf(context).scale(10) >= 15) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 4),
            Align(alignment: AlignmentDirectional.centerStart, child: trailing),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
    }
    // The heading row is a link's full 48 tall, so a link doesn't push the
    // section down: the 18 above and 10 below the 22-tall title (`.sec-h`)
    // are taken out of that height (13 each side), leaving 5 above it.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
            child: Row(
              children: [
                Expanded(child: heading),
                ?trailing,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A text link for a section heading.
///
/// The tap target is at least 48 wide; a shorter label ("All 7") sits at
/// [alignment] inside it, the end by default, so it lines up with the
/// other section links instead of floating in the middle.
class AtomLink extends StatelessWidget {
  const AtomLink({
    super.key,
    required this.label,
    required this.onTap,
    this.alignment = AlignmentDirectional.centerEnd,
  });

  final String label;
  final VoidCallback? onTap;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      semanticLabel: label,
      builder: (_, pressed) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: AtomSize.tapTarget),
        child: Align(
          alignment: alignment,
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: AtomText.secondary.copyWith(
              color: pressed ? AtomColors.primaryDark : AtomColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// One coloured part of a hero or progress bar.
class AtomBarPart {
  const AtomBarPart(this.fraction, this.colour);
  final double fraction;
  final Color colour;
}

/// The navy card at the top of Home: a label and date, the big amount, a
/// line under it, a split bar, a legend and up to two actions.
class AtomHeroCard extends StatelessWidget {
  const AtomHeroCard({
    super.key,
    required this.label,
    required this.amount,
    this.labelEnd,
    this.meta,
    this.bar = const [],
    this.barLabel,
    this.legendStart,
    this.legendEnd,
    this.actions = const [],
  });

  final String label;
  final String? labelEnd;

  /// Already formatted (`Rs 52,300`).
  final String amount;
  final InlineSpan? meta;
  final List<AtomBarPart> bar;

  /// What the bar shows, for screen readers.
  final String? barLabel;
  final InlineSpan? legendStart;
  final String? legendEnd;

  /// Usually a light button and a dark outline one, 1.4 : 1.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    // `.hero .lbl` and `.meta` have the browser's normal line height.
    final dim = AtomText.secondary.copyWith(
      color: AtomColors.navText,
      height: AtomText.normalHeight,
    );
    return Container(
      // The buttons' 48 tap areas reach 2 past the 44 they show, so the
      // gap above them and the padding under them are 2 less.
      padding: EdgeInsets.fromLTRB(16, 16, 16, actions.isEmpty ? 16 : 14),
      decoration: BoxDecoration(
        color: AtomColors.nav2,
        borderRadius: const BorderRadius.all(Radius.circular(AtomRadius.sheet)),
        border: Border.all(color: AtomColors.navLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            // The date sits at the right edge, as on the board.
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: dim)),
              if (labelEnd != null) ...[
                const SizedBox(width: 8),
                // Large text: the date wraps rather than run off.
                Flexible(
                  child: Text(labelEnd!, style: dim, textAlign: TextAlign.end),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              amount,
              style: AtomText.amountLg.copyWith(color: Colors.white),
            ),
          ),
          if (meta != null) ...[
            const SizedBox(height: 2),
            Text.rich(meta!, style: dim),
          ],
          if (bar.isNotEmpty) ...[
            const SizedBox(height: 14),
            Semantics(
              label: barLabel,
              child: ExcludeSemantics(
                child: _SplitBar(parts: bar, track: AtomColors.navLine),
              ),
            ),
          ],
          if (legendStart != null || legendEnd != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (legendStart != null)
                  Expanded(
                    child: Text.rich(
                      legendStart!,
                      style: AtomText.small.copyWith(color: AtomColors.navText),
                    ),
                  ),
                if (legendEnd != null)
                  Text(
                    legendEnd!,
                    style: AtomText.small.copyWith(
                      color: AtomColors.navText,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AtomSpace.s2),
                  Expanded(flex: i == 0 ? 7 : 5, child: actions[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A thin bar split into coloured parts.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.parts, required this.track});

  final List<AtomBarPart> parts;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AtomRadius.brControl,
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track)),
              Row(
                children: [
                  for (final p in parts)
                    SizedBox(
                      width: box.maxWidth * p.fraction.clamp(0, 1),
                      height: 8,
                      child: ColoredBox(color: p.colour),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A progress bar on a white card (a plan paid so far).
class AtomProgressBar extends StatelessWidget {
  const AtomProgressBar({
    super.key,
    required this.value,
    this.colour = AtomColors.green,
    this.semanticLabel,
  });

  /// 0 to 1.
  final double value;
  final Color colour;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: ExcludeSemantics(
      child: _SplitBar(
        parts: [AtomBarPart(value, colour)],
        track: AtomColors.surface,
      ),
    ),
  );
}

/// One KPI tile: a label, a figure and a line under it.
class AtomKpi {
  const AtomKpi({
    required this.label,
    required this.value,
    this.note,
    this.trend,
    this.valueColour,
  });

  final String label;
  final String value;
  final String? note;

  /// The figure's colour when it isn't ink (an overdue amount is rose).
  final Color? valueColour;

  /// Up (green, ↗), down (rose, ↘) or none.
  final AtomTrend? trend;
}

enum AtomTrend { up, down }

/// KPI tiles, two per row.
class AtomKpiGrid extends StatelessWidget {
  const AtomKpiGrid({super.key, required this.kpis});

  final List<AtomKpi> kpis;

  /// One tile on its own (15.1 puts four in a row).
  static Widget tile(AtomKpi kpi) => _KpiTile(kpi: kpi);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < kpis.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _KpiTile(kpi: kpis[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < kpis.length
                      ? _KpiTile(kpi: kpis[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi});
  final AtomKpi kpi;

  @override
  Widget build(BuildContext context) {
    final noteColour = switch (kpi.trend) {
      AtomTrend.up => AtomColors.green,
      AtomTrend.down => AtomColors.rose,
      null => AtomColors.muted,
    };
    return Semantics(
      container: true,
      label: [kpi.label, kpi.value, ?kpi.note].join(', '),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AtomDecor.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `.kpi`: no line heights of its own, so the normal one.
              Text(
                kpi.label,
                style: AtomText.secondary.copyWith(
                  height: AtomText.normalHeight,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  kpi.value,
                  style: AtomText.pageTitle.copyWith(
                    height: AtomText.normalHeight,
                    color: kpi.valueColour,
                    letterSpacing: -0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (kpi.note != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (kpi.trend != null) ...[
                      Icon(
                        kpi.trend == AtomTrend.up
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        size: 14,
                        color: noteColour,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(
                        kpi.note!,
                        style: AtomText.small.copyWith(color: noteColour),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A task on Home: an icon tile, what to do, a line under it (the part
/// that is due shown in rose), and a small button.
class AtomTaskRow extends StatelessWidget {
  const AtomTaskRow({
    super.key,
    required this.icon,
    required this.title,
    this.tone = AtomTone.blue,
    this.subtitle,
    this.due,
    this.action,
  });

  final IconData icon;
  final AtomTone tone;
  final String title;
  final String? subtitle;

  /// "Today", "Due in 5 h": shown after the subtitle in rose.
  final String? due;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: AtomColors.paper,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: AtomRadius.brControl,
            ),
            child: Icon(icon, size: AtomIcon.row, color: tone.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AtomText.listTitle),
                if (subtitle != null || due != null)
                  Text.rich(
                    TextSpan(
                      style: AtomText.secondary,
                      children: [
                        // The server's text: keep "Rs 4,134,790" on one
                        // line instead of "Rs" and "4,134,790".
                        if (subtitle != null)
                          TextSpan(text: subtitle!.replaceAll('Rs ', 'Rs ')),
                        if (subtitle != null && due != null)
                          const TextSpan(text: ' · '),
                        if (due != null)
                          TextSpan(
                            text: due,
                            style: const TextStyle(
                              color: AtomColors.rose,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// One day in [AtomWeekChart].
class AtomChartDay {
  const AtomChartDay({
    required this.short,
    required this.long,
    required this.value,
  });

  /// "Wed", "Today".
  final String short;

  /// "Wednesday, 28 Oct": shown above the chart when picked.
  final String long;
  final int value;
}

/// Collected, last 7 days: bars to tap, the picked day's total above.
class AtomWeekChart extends StatefulWidget {
  const AtomWeekChart({
    super.key,
    required this.days,
    required this.format,
    this.footnote,
  });

  final List<AtomChartDay> days;
  final String Function(int value) format;
  final String? footnote;

  @override
  State<AtomWeekChart> createState() => _AtomWeekChartState();
}

class _AtomWeekChartState extends State<AtomWeekChart> {
  late int _picked = widget.days.length - 1;

  static String _short(int v) => v >= 1000 ? '${(v / 1000).round()}k' : '$v';

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    if (days.isEmpty) return const SizedBox.shrink();
    final picked = days[_picked.clamp(0, days.length - 1)];
    final max = days.fold<int>(1, (m, d) => d.value > m ? d.value : m);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AtomDecor.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(picked.long, style: AtomText.secondary)),
              Text(widget.format(picked.value), style: AtomText.money),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AtomColors.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AtomPressable(
                      onTap: () => setState(() => _picked = i),
                      selected: i == _picked,
                      scaleOnPress: false,
                      semanticLabel:
                          '${days[i].long}: ${widget.format(days[i].value)}',
                      builder: (context, _) => ExcludeSemantics(
                        child: SizedBox(
                          height: 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (i == _picked)
                                Text(
                                  _short(days[i].value),
                                  style: AtomText.tag.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Container(
                                constraints: const BoxConstraints(maxWidth: 26),
                                height: (96 * days[i].value / max).clamp(4, 96),
                                decoration: BoxDecoration(
                                  color: i == _picked
                                      ? AtomColors.primary
                                      : const Color(0xFF7890E8),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      days[i].short,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AtomText.tag.copyWith(
                        fontWeight: i == _picked
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: i == _picked ? AtomColors.ink : AtomColors.faint,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.footnote != null) ...[
            const SizedBox(height: 8),
            Text(widget.footnote!, style: AtomText.small),
          ],
        ],
      ),
    );
  }
}

/// A month in a customer's plan: the date tile, what it is and its state.
/// [now] highlights the month being collected.
class AtomScheduleRow extends StatelessWidget {
  const AtomScheduleRow({
    super.key,
    required this.month,
    required this.day,
    required this.title,
    this.subtitle,
    this.subtitleColour,
    this.trailing,
    this.now = false,
  });

  /// "NOV"
  final String month;

  /// "3"
  final String day;
  final String title;
  final String? subtitle;
  final Color? subtitleColour;
  final Widget? trailing;
  final bool now;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      color: now ? AtomColors.amberSoft : AtomColors.paper,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  month,
                  style: AtomText.small.copyWith(
                    fontWeight: FontWeight.w700,
                    color: now ? AtomColors.amberInk : AtomColors.muted,
                  ),
                ),
                Text(
                  day,
                  style: AtomText.input.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AtomText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AtomText.small.copyWith(
                      color: subtitleColour ?? AtomColors.muted,
                      fontWeight: subtitleColour == null
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null &&
              MediaQuery.textScalerOf(context).scale(10) < 15) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
    // Large text: the button or pill goes under the row.
    if (trailing == null || MediaQuery.textScalerOf(context).scale(10) < 15) {
      return row;
    }
    return ColoredBox(
      color: now ? AtomColors.amberSoft : AtomColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 0, 14, 12),
            child: Align(alignment: Alignment.centerLeft, child: trailing),
          ),
        ],
      ),
    );
  }
}
