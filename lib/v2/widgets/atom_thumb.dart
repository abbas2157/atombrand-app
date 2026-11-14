import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';
import 'atom_photo.dart';

/// A product's photo in a rounded square: the photo when there is one,
/// fitted whole on white so nothing is cropped or stretched; otherwise (and
/// while it loads, or if it can't be had) a grey tile with [icon], a plain
/// box, as a product can be anything from a phone to a desktop.
class AtomThumb extends StatelessWidget {
  const AtomThumb({
    super.key,
    required this.url,
    this.size = AtomSize.orderThumb,
    this.icon = LucideIcons.package,
  });

  final String? url;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final empty = Container(
      width: size,
      height: size,
      decoration: AtomDecor.tile.copyWith(color: AtomColors.surface),
      child: Icon(icon, size: AtomIcon.row, color: AtomColors.faint),
    );
    final u = url;
    if (u == null || u.isEmpty) return empty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: AtomDecor.tile,
      child: AtomPhoto(
        u,
        fit: BoxFit.contain,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => empty,
        frameBuilder: (_, child, frame, sync) =>
            frame == null && !sync ? empty : child,
      ),
    );
  }
}
