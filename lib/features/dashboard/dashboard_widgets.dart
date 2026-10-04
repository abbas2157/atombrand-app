import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/dashboard.dart';
import '../../widgets/common.dart';

/// White card in the dashboard style: 16 px radius, soft shadow.
class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => AppCard(padding: padding, child: child);
}

/// Card title, 16/600.
class DashTitle extends StatelessWidget {
  const DashTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16))),
        ?trailing,
      ],
    );
  }
}

/// Soft square tile behind an icon.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, this.tone, {super.key, this.size = 36});
  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(size * 0.28)),
        child: Icon(icon, size: size * 0.55, color: tone.fg),
      );
}

/// ▲ 12% / ▼ 3 in green or red. [good] says whether the change is welcome
/// (more pending orders is not).
class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.change, this.suffix = '', this.upIsGood = true});

  final int change;
  final String suffix;
  final bool upIsGood;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final up = change > 0;
    final flat = change == 0;
    final tone = flat ? p.neutral : ((up == upIsGood) ? p.positive : p.negative);
    final text = '${change.abs()}$suffix';
    return Semantics(
      label: flat ? 'No change' : '${up ? 'Up' : 'Down'} $text',
      excludeSemantics: true,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!flat) ...[
              Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, size: 18, color: tone.fg),
              const SizedBox(width: 1),
            ],
            Text(
              flat ? '0$suffix' : text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tone.fg,
                    fontFeatures: tabularFigures,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// KPI card: icon, trend, big number, muted label. Tapping opens the list
/// behind the number.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    this.trend,
    this.onTap,
  });

  final IconData icon;
  final Tone tone;
  final String value;
  final String label;
  final Widget? trend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(icon, tone),
                const Spacer(),
                ?trend,
              ],
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: t.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: tabularFigures),
                ),
              ),
            ),
            const SizedBox(height: 2),
            ExcludeSemantics(child: Text(label, style: t.bodySmall?.copyWith(fontSize: 13, color: p.muted))),
          ],
        ),
      ),
    );
  }
}

/// One tappable "needs attention" line: icon, message, count, chevron.
class AttentionItem {
  const AttentionItem({required this.icon, required this.tone, required this.message, required this.count, this.onTap});
  final IconData icon;
  final Tone tone;
  final String message;
  final int count;
  final VoidCallback? onTap;
}

class AttentionCard extends StatelessWidget {
  const AttentionCard({super.key, required this.items});
  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return DashCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: DashTitle('Needs attention')),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconTile(Icons.check_rounded, p.positive),
                  const SizedBox(width: 12),
                  Expanded(child: Text("You're all caught up.", style: t.bodyMedium)),
                ],
              ),
            ),
          for (final (i, a) in items.indexed) ...[
            if (i > 0) const Divider(indent: 64),
            Semantics(
              button: a.onTap != null,
              label: '${a.message}, ${a.count}',
              excludeSemantics: true,
              child: InkWell(
                onTap: a.onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    child: Row(
                      children: [
                        IconTile(a.icon, a.tone),
                        const SizedBox(width: 12),
                        Expanded(child: Text(a.message, style: t.bodyMedium)),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 24),
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: a.tone.bg, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            count(a.count),
                            style: t.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: a.tone.fg,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: p.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Today / 7 days / 30 days.
class PeriodSwitch extends StatelessWidget {
  const PeriodSwitch({super.key, required this.keys, required this.selected, required this.onChanged});

  final List<String> keys;
  final String selected;
  final ValueChanged<String> onChanged;

  static String label(String key) => switch (key) {
        'today' => 'Today',
        '7d' => '7 days',
        '30d' => '30 days',
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (final k in keys)
            Expanded(
              child: Semantics(
                selected: k == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: k == selected ? p.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: k == selected && !p.isDark
                          ? const [BoxShadow(color: Color(0x1F10122B), blurRadius: 3, offset: Offset(0, 1))]
                          : null,
                    ),
                    child: Text(
                      label(k),
                      style: t.labelLarge?.copyWith(
                        color: k == selected ? p.text : p.muted,
                        fontWeight: k == selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Total for the period, its trend, and one bar per [DashPeriod.series]
/// point; the latest bar is highlighted.
class SalesChartCard extends StatelessWidget {
  const SalesChartCard({super.key, required this.period, required this.periodLabel});
  final DashPeriod period;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final series = period.series;
    final maxV = series.fold<int>(0, (m, s) => math.max(m, s.value));
    final dense = series.length > 12;
    final gap = dense ? 3.0 : 10.0;
    final labelStyle = t.bodySmall?.copyWith(color: p.muted);
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue · $periodLabel', style: labelStyle),
                    const SizedBox(height: 2),
                    Text(
                      money(period.revenue),
                      style: t.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: tabularFigures),
                    ),
                  ],
                ),
              ),
              if (period.revenueChangePct != null) TrendChip(change: period.revenueChangePct!, suffix: '%'),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Revenue chart, $periodLabel: ${money(period.revenue)}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.divider))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, s) in series.indexed) ...[
                        if (i > 0) SizedBox(width: gap),
                        Expanded(
                          child: Container(
                            height: maxV == 0 ? 4 : math.max(4, 112 * s.value / maxV),
                            decoration: BoxDecoration(
                              color: i == series.length - 1 ? p.primary : p.primarySoft2,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(dense ? 3 : 6),
                                bottom: const Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!dense)
                  Row(
                    children: [
                      for (final (i, s) in series.indexed) ...[
                        if (i > 0) SizedBox(width: gap),
                        Expanded(child: Text(s.label, textAlign: TextAlign.center, style: labelStyle, maxLines: 1, softWrap: false)),
                      ],
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final i in {0, series.length ~/ 3, series.length * 2 ~/ 3, series.length - 1})
                        Text(series[i].label, style: labelStyle),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ranked best sellers with a thin bar relative to the top one.
class TopProductsCard extends StatelessWidget {
  const TopProductsCard({super.key, required this.products, required this.onTap});
  final List<TopProduct> products;
  final ValueChanged<TopProduct> onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final top = products.fold<int>(0, (m, x) => math.max(m, x.units));
    return DashCard(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: DashTitle('Top products')),
          const SizedBox(height: 4),
          for (final (i, x) in products.indexed)
            Semantics(
              button: true,
              label: 'Number ${i + 1}, ${x.title}, ${count(x.units)} sold',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onTap(x),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text('${i + 1}', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: p.muted)),
                      ),
                      NetThumb(x.picture, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(x.title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                                const SizedBox(width: 8),
                                Text(
                                  '${count(x.units)} sold',
                                  style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: top == 0 ? 0 : x.units / top,
                                minHeight: 4,
                                color: p.primary,
                                backgroundColor: p.divider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Financed vs recovered, with a ring and the overdue instalments.
class RecoveryCard extends StatelessWidget {
  const RecoveryCard({super.key, required this.recovery, this.onOverdueTap});
  final Recovery recovery;
  final VoidCallback? onOverdueTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final pct = (recovery.ratio * 100).round();
    Widget figure(String label, int value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.bodySmall?.copyWith(color: p.muted)),
            const SizedBox(height: 2),
            Text(money(value), style: t.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700, fontFeatures: tabularFigures)),
          ],
        );
    return DashCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashTitle('Instalment recovery'),
          const SizedBox(height: 16),
          Row(
            children: [
              Semantics(
                label: '$pct% of the financed amount recovered',
                excludeSemantics: true,
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: recovery.ratio,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        color: p.primary,
                        backgroundColor: p.divider,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$pct%', style: t.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('recovered', style: t.bodySmall?.copyWith(color: p.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    figure('Total financed', recovery.financed),
                    const SizedBox(height: 12),
                    figure('Recovered so far', recovery.recovered),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recovery.overdue > 0) ...[
            const Divider(),
            InkWell(
              onTap: onOverdueTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: p.negative.fg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${count(recovery.overdue)} ${recovery.overdue == 1 ? 'instalment' : 'instalments'} overdue',
                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: p.negative.fg),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// An open carton with a TV and a washing machine (new-seller empty state).
class EmptyStoreIllustration extends StatelessWidget {
  const EmptyStoreIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: 'An open box with a TV and a washing machine',
      image: true,
      child: SizedBox(
        width: 200,
        height: 150,
        child: CustomPaint(painter: _EmptyStorePainter(p)),
      ),
    );
  }
}

class _EmptyStorePainter extends CustomPainter {
  const _EmptyStorePainter(this.p);
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round;
    RRect rr(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
    const carton = Color(0xFFE3A86B);
    const cartonLight = Color(0xFFF0BE88);
    const cartonEdge = Color(0xFFC98A4D);

    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 132), width: 156, height: 16), fill(p.divider));
    canvas.drawCircle(const Offset(100, 72), 64, fill(p.primarySoft2));

    // TV.
    canvas.drawRRect(rr(58, 26, 58, 38, 4), fill(p.device));
    canvas.drawRRect(rr(61.5, 29.5, 51, 31, 2), fill(const Color(0xFF34407A)));
    canvas.drawPath(
      Path()
        ..moveTo(61.5, 60.5)
        ..lineTo(90, 29.5)
        ..lineTo(112.5, 29.5)
        ..lineTo(84, 60.5)
        ..close(),
      fill(const Color(0x994C5BA3)),
    );

    // Washing machine.
    canvas.drawRRect(rr(106, 38, 38, 48, 6), fill(Colors.white));
    canvas.drawRRect(rr(106, 38, 38, 48, 6), stroke(const Color(0xFFC9CDD8), 2));
    canvas.drawLine(const Offset(106, 48), const Offset(144, 48), stroke(const Color(0xFFC9CDD8), 2));
    canvas.drawCircle(const Offset(125, 67), 11, fill(const Color(0xFFE6EDFB)));
    canvas.drawCircle(const Offset(125, 67), 11, stroke(const Color(0xFF9BB6E6), 2.5));

    // Carton.
    final box = Path()
      ..moveTo(44, 78)
      ..lineTo(156, 78)
      ..lineTo(146, 130)
      ..lineTo(54, 130)
      ..close();
    canvas.drawPath(box, fill(carton));
    canvas.drawPath(box, stroke(cartonEdge, 2));
    for (final flap in [
      Path()
        ..moveTo(44, 78)
        ..lineTo(30, 62)
        ..lineTo(80, 56)
        ..lineTo(100, 78)
        ..close(),
      Path()
        ..moveTo(156, 78)
        ..lineTo(170, 62)
        ..lineTo(120, 56)
        ..lineTo(100, 78)
        ..close(),
    ]) {
      canvas.drawPath(flap, fill(cartonLight));
      canvas.drawPath(flap, stroke(cartonEdge, 2));
    }
    canvas.drawRRect(rr(84, 94, 32, 10, 3), fill(Colors.white.withValues(alpha: 0.7)));

    Path sparkle(Offset c, double r) {
      final k = r * 0.375;
      return Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + k, c.dy - k)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx + k, c.dy + k)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - k, c.dy + k)
        ..lineTo(c.dx - r, c.dy)
        ..lineTo(c.dx - k, c.dy - k)
        ..close();
    }

    canvas.drawPath(sparkle(const Offset(162, 39), 9), fill(p.accent));
    canvas.drawPath(sparkle(const Offset(36, 47), 7), fill(p.primary));
  }

  @override
  bool shouldRepaint(covariant _EmptyStorePainter old) => old.p != p;
}
