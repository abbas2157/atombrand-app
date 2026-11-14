import 'package:flutter/widgets.dart';

/// Brand marks the Lucide set doesn't have.
abstract final class AtomBrandIcons {
  /// WhatsApp's mark: next to every "WhatsApp" button, link and row. The
  /// glyph is FontAwesomeIcons.whatsapp from font_awesome_flutter (its
  /// font ships with that package), written out so it stays const.
  static const IconData whatsapp = IconData(
    0xf232,
    fontFamily: 'FontAwesomeBrands',
    fontPackage: 'font_awesome_flutter',
  );
}
