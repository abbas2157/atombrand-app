import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'common.dart';

/// Icon in a soft-tinted circle, big number, caption (§4.5).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
    this.color = AppColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String caption;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: '$caption: $value',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: t.headlineSmall?.copyWith(fontFeatures: tabularFigures)),
            ),
            const SizedBox(height: 2),
            Text(caption, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
