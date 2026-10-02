import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'auth_scaffold.dart';
import 'partner_content.dart';

/// Small uppercase heading between landing sections.
class AuthSectionTitle extends StatelessWidget {
  const AuthSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
      ),
    );
  }
}

/// Charcoal card with the marketplace numbers, in a 2 × 2 grid.
class PartnerStatsCard extends StatelessWidget {
  const PartnerStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const stats = PartnerContent.stats;
    Widget cell(int i) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats[i].value,
                style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(stats[i].label, style: t.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('AtomShop today', style: t.labelMedium?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [cell(0), const SizedBox(width: 16), cell(1)]),
          const SizedBox(height: 18),
          Row(children: [cell(2), const SizedBox(width: 16), cell(3)]),
        ],
      ),
    );
  }
}

class BenefitRow extends StatelessWidget {
  const BenefitRow({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthIconBadge(icon, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                const SizedBox(height: 3),
                Text(body, style: t.bodySmall?.copyWith(fontSize: 13, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Numbered steps joined by a thin line: Apply → Review → Go live.
class PartnerSteps extends StatelessWidget {
  const PartnerSteps({super.key, this.steps = PartnerContent.steps, this.current});

  final List<({String title, String body})> steps;

  /// Steps before this index show as done (a tick instead of a number).
  final int? current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      _Dot(index: i, done: current != null && i < current!),
                      if (i < steps.length - 1)
                        Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.line)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 4, bottom: i < steps.length - 1 ? 20 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].title, style: t.titleMedium),
                        const SizedBox(height: 3),
                        Text(steps[i].body, style: t.bodySmall?.copyWith(fontSize: 13, height: 1.45)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index, required this.done});
  final int index;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: done ? AppColors.successFg : AppColors.primary, shape: BoxShape.circle),
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
    );
  }
}

/// Soft pill, e.g. a live brand or an eligible business type.
class SoftPill extends StatelessWidget {
  const SoftPill(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.ink)),
        ],
      ),
    );
  }
}

class CheckLine extends StatelessWidget {
  const CheckLine(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.successFg),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}
