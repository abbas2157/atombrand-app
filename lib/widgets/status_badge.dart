import 'package:flutter/material.dart';

import '../core/theme.dart';

enum BadgeTone {
  neutral(AppColors.neutralFg, AppColors.neutralBg),
  warning(AppColors.warningFg, AppColors.warningBg),
  info(AppColors.infoFg, AppColors.infoBg),
  success(AppColors.successFg, AppColors.successBg),
  danger(AppColors.dangerFg, AppColors.dangerBg);

  const BadgeTone(this.fg, this.bg);
  final Color fg;
  final Color bg;
}

/// Pill badge identical to the web portal (§4.4). Never wraps.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, this.tone, {super.key});

  /// Order statuses. `Varification` is the real value; it shows as "Verification".
  factory StatusBadge.order(String status) => StatusBadge(orderStatusLabel(status), switch (status) {
        'Varification' || 'Processing' => BadgeTone.warning,
        'Delivered' || 'Instalments' => BadgeTone.info,
        'Completed' => BadgeTone.success,
        'Cancelled' => BadgeTone.danger,
        _ => BadgeTone.neutral,
      });

  factory StatusBadge.bulk(String status) => StatusBadge(status, switch (status) {
        'New Lead' => BadgeTone.warning,
        'Contacted' || 'Quoted' => BadgeTone.info,
        'Won' => BadgeTone.success,
        'Lost' => BadgeTone.danger,
        _ => BadgeTone.neutral,
      });

  factory StatusBadge.product(String status) => StatusBadge(productStatusLabel(status), switch (status) {
        'Published' => BadgeTone.success,
        'Pending' => BadgeTone.warning,
        'Out of Stock' => BadgeTone.danger,
        _ => BadgeTone.neutral,
      });

  /// Payment pill for retail orders.
  factory StatusBadge.payment({required bool isCash, required int tenure}) => isCash
      ? const StatusBadge('Paid in full', BadgeTone.info)
      : StatusBadge('$tenure-month plan', BadgeTone.neutral);

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tone.fg, fontSize: 12, fontWeight: FontWeight.w600),
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
