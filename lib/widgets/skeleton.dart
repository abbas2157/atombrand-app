import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Grey placeholder block that shimmers while a [Shimmer] is above it.
class Bone extends StatelessWidget {
  const Bone({super.key, this.width, this.height = 14, this.radius = 6});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = _ShimmerScope.of(context);
    final base = p.border.withValues(alpha: p.isDark ? 0.6 : 0.45);
    final hi = p.isDark ? p.border : p.surface;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-3 + 4 * t, 0),
          end: Alignment(-1 + 4 * t, 0),
          colors: [base, hi, base],
        ),
      ),
    );
  }
}

/// Drives the [Bone]s below it. Still when the system asks for less motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ShimmerScope(notifier: _c, child: widget.child);
}

class _ShimmerScope extends InheritedNotifier<AnimationController> {
  const _ShimmerScope({required super.notifier, required super.child});

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.notifier?.value ?? 0.5;
}

/// An order card's skeleton (orders list, dashboard).
class OrderTileBone extends StatelessWidget {
  const OrderTileBone({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: p.cardShadow),
      child: const Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(width: 56, height: 56, radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Bone()), SizedBox(width: 8), Bone(width: 70, height: 22, radius: 999)]),
                    SizedBox(height: 10),
                    Bone(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Bone(width: 96, height: 16),
              SizedBox(width: 8),
              Bone(width: 72, height: 22, radius: 999),
              Spacer(),
              Bone(width: 70, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
