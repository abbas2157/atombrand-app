import 'package:flutter/material.dart';

import '../design/design.dart';

/// Ask Atom's mark, as on the boards: the Atomshop mark (dark circle with
/// the devices and the coloured bubbles) on white, round by default. Used
/// wherever Ask Atom is offered or answers.
class AtomAiMark extends StatelessWidget {
  const AtomAiMark({
    super.key,
    required this.size,
    this.radius,
    this.ring = false,
    this.background = Colors.white,
  });

  final double size;

  /// Rounded square corners; null for a circle.
  final BorderRadius? radius;

  /// A thin grey edge, for a white mark on a white page.
  final bool ring;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: radius,
      border: ring ? Border.all(color: AtomColors.line) : null,
    ),
    child: ExcludeSemantics(
      // 28 in a 34 circle on the boards.
      child: Image.asset(
        'assets/brand/atomshop_mark.png',
        width: size * .82,
        height: size * .82,
        cacheWidth: (size * 3).round(),
      ),
    ),
  );
}
