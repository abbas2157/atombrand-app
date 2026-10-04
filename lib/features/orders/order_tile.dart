import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/order.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';

/// Order card (DESIGN.md §4.3): thumb, name and status; order # and city;
/// price, plan and date; a recovery bar when the server sends one. A red
/// stripe on the left marks orders that wait on the brand.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap, this.onLongPress});

  final OrderSummary order;
  final VoidCallback onTap;

  /// Quick actions (orders list).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    final o = order;
    final name = o.product?.title ?? 'Order #${o.id}';
    final meta = ['#${o.id}', ?o.city].join(' · ');
    final recovery = o.recoveryPercent;
    final showRecovery = recovery != null && !o.isCash && o.status != 'Cancelled';
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      label: [
        name,
        money(o.totalDealPrice),
        orderStatusLabel(o.status),
        o.isCash ? 'Paid in full' : (o.tenure == null ? 'instalment plan' : '${o.tenure} month plan'),
        formatDate(o.createdAt),
        if (o.needsAction) 'needs action',
      ].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: p.card, borderRadius: radius, boxShadow: p.cardShadow),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              children: [
                if (o.needsAction)
                  Positioned(
                    left: 0,
                    top: 14,
                    bottom: 14,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: p.danger,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NetThumb(o.product?.picture, size: 56, radius: 12),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge.order(o.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(meta, style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            money(o.totalDealPrice),
                            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontFeatures: tabularFigures),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge.payment(isCash: o.isCash, tenure: o.tenure),
                          const Spacer(),
                          const SizedBox(width: 8),
                          Text(formatDate(o.createdAt), style: t.bodySmall?.copyWith(color: p.muted)),
                        ],
                      ),
                      if (showRecovery) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: recovery.clamp(0, 100) / 100,
                                  minHeight: 4,
                                  color: p.primary,
                                  backgroundColor: p.divider,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Recovered $recovery%',
                              style: t.bodySmall?.copyWith(color: p.muted, fontFeatures: tabularFigures),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
