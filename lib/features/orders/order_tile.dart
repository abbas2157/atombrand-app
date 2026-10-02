import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models/order.dart';
import '../../widgets/common.dart';
import '../../widgets/status_badge.dart';

/// Product thumb, title, variant line, amount, status badge, date (§4.5).
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onTap, this.showPayment = true});

  final OrderSummary order;
  final VoidCallback onTap;
  final bool showPayment;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final subtitle = [order.variant, if (order.city != null) order.city].whereType<String>().join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetThumb(order.product?.picture),
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
                        order.product?.title ?? 'Order #${order.id}',
                        style: t.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.order(order.status),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(money(order.totalDealPrice), style: t.titleMedium?.copyWith(fontFeatures: tabularFigures)),
                    const SizedBox(width: 8),
                    if (showPayment) Flexible(child: StatusBadge.payment(isCash: order.isCash, tenure: order.tenure)),
                    const Spacer(),
                    Text(formatDate(order.createdAt), style: t.bodySmall),
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
