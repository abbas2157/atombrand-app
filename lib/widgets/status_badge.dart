import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Pill colours (DESIGN.md §2.2). [plan] is the outlined neutral pill used
/// for payment plans.
enum BadgeTone { neutral, info, warning, success, danger, lead, violet, plan }

/// Status pill (§4.4). Never wraps or truncates.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, this.tone, {super.key});

  /// Order statuses. `Varification` is the real value; it shows as "Verification".
  factory StatusBadge.order(String status) => StatusBadge(orderStatusLabel(status), switch (status) {
        'Varification' || 'Instalments' => BadgeTone.info,
        'Processing' => BadgeTone.warning,
        'Delivered' || 'Completed' => BadgeTone.success,
        'Cancelled' => BadgeTone.danger,
        _ => BadgeTone.neutral,
      });

  factory StatusBadge.bulk(String status) => StatusBadge(status, switch (status) {
        'New Lead' => BadgeTone.lead,
        'Contacted' => BadgeTone.info,
        'Quoted' => BadgeTone.violet,
        'Won' => BadgeTone.success,
        'Lost' => BadgeTone.neutral,
        _ => BadgeTone.neutral,
      });

  factory StatusBadge.product(String status) => StatusBadge(productStatusLabel(status), switch (status) {
        'Published' => BadgeTone.success,
        'Pending' => BadgeTone.info,
        'Out of Stock' => BadgeTone.danger,
        'On hold' => BadgeTone.warning,
        _ => BadgeTone.neutral,
      });

  /// Payment plan: "Paid in full" (green) or "3 mo plan" (outlined).
  factory StatusBadge.payment({required bool isCash, int? tenure}) => isCash
      ? const StatusBadge('Paid in full', BadgeTone.success)
      : StatusBadge(tenure == null ? 'Instalment plan' : '$tenure mo plan', BadgeTone.plan);

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (fg, bg) = switch (tone) {
      BadgeTone.neutral => (p.neutral.fg, p.neutral.bg),
      BadgeTone.info => (p.info.fg, p.info.bg),
      BadgeTone.warning => (p.warning.fg, p.warning.bg),
      BadgeTone.success => (p.positive.fg, p.positive.bg),
      BadgeTone.danger => (p.negative.fg, p.negative.bg),
      BadgeTone.lead => (p.lead.fg, p.lead.bg),
      BadgeTone.violet => (p.violet.fg, p.violet.bg),
      BadgeTone.plan => (p.text, p.card),
    };
    // No `alignment` here: it would stretch the pill to the full width
    // inside Wraps and Columns.
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: tone == BadgeTone.plan ? Border.all(color: p.border) : null,
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

String orderStatusLabel(String status) => status == 'Varification' ? 'Verification' : status;

String productStatusLabel(String status) => switch (status) {
      'Published' => 'Live',
      'Pending' => 'In review',
      'Out of Stock' => 'Out of stock',
      _ => status,
    };
