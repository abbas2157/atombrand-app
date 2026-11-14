import 'package:flutter/material.dart';

import '../design/design.dart';

/// The canvas `.spin`: a thin ring with a primary arc.
///
/// A progress indicator is the one place v2 keeps moving pixels: it says the
/// app is working, it isn't decoration.
class AtomSpinner extends StatelessWidget {
  const AtomSpinner({
    super.key,
    this.size = 18,
    this.color = AtomColors.primary,
    this.track = AtomColors.line2,
  });

  final double size;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color,
        backgroundColor: track,
      ),
    );
  }
}
