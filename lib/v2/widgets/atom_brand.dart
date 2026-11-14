import 'package:flutter/material.dart';

import '../design/design.dart';

/// The Brand Partner (Atombrand) mark on a white tile, as on the splash, the welcome bar
/// and the state screens.
class AtomBrandTile extends StatelessWidget {
  const AtomBrandTile({
    super.key,
    this.size = 96,
    this.shadow = false,
    this.onLight = false,
  });

  final double size;

  /// The lifted tile on dark screens.
  final bool shadow;

  /// The tile on a white page (Sign in): a hairline and a soft shadow, so
  /// a white tile on `AtomColors.paper` still reads as a tile. The same
  /// treatment as the About card (19.13).
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          size >= 64 ? 20 : AtomRadius.control,
        ),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ]
            : onLight
            ? const [
                BoxShadow(
                  color: Color(0x1F101828),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                BoxShadow(color: AtomColors.line, spreadRadius: 1),
              ]
            : null,
      ),
      child: Image.asset(
        'assets/brand/mark.png',
        width: size * 0.75,
        height: size * 0.75,
        semanticLabel: 'Brand Partner',
      ),
    );
  }
}

/// The logo colours as a short striped bar: the only place amber, coral and
/// purple appear together (splash and loaders).
class AtomStepsStripe extends StatelessWidget {
  const AtomStepsStripe({super.key, this.width = 72, this.height = 4});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AtomRadius.brTag,
        child: SizedBox(
          width: width,
          height: height,
          // Stretch: an empty ColoredBox otherwise takes no height.
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: ColoredBox(color: AtomColors.amber)),
              Expanded(child: ColoredBox(color: AtomColors.coral)),
              Expanded(child: ColoredBox(color: AtomColors.purple)),
            ],
          ),
        ),
      ),
    );
  }
}
