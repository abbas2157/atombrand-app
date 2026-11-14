import 'package:flutter/widgets.dart';

import 'atom_colors.dart';
import 'atom_tokens.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Brand Partner v2 — Surfaces
///
///  The card and tile looks every screen shares, so a card is never built
///  by hand: a white fill, the 14 corner and a 1px line. Shadows are rare
///  and soft (dense business software, not a storefront).
/// ─────────────────────────────────────────────────────────────────────────
abstract final class AtomShadow {
  /// A tile that sits on its own on the grey page (an order's step card,
  /// a payment row, the Ask Atom button): 0 2 6, ink at 8%.
  static const BoxShadow tile = BoxShadow(
    color: Color(0x14101828),
    offset: Offset(0, 2),
    blurRadius: 6,
  );

  /// A panel that floats above the page (the receipt, a preview): 0 10 30,
  /// ink at 12%.
  static const BoxShadow float = BoxShadow(
    color: Color(0x1F101828),
    offset: Offset(0, 10),
    blurRadius: 30,
  );
}

abstract final class AtomDecor {
  static const BorderSide _line = BorderSide(color: AtomColors.line);

  /// The card: white, 14 corners, a 1px line. Lists, figures, forms.
  static const BoxDecoration card = BoxDecoration(
    color: AtomColors.paper,
    borderRadius: AtomRadius.brCard,
    border: Border.fromBorderSide(_line),
  );

  /// The card's line alone, for a `foregroundDecoration`: a card of rows
  /// draws its line over them, as each row's own white would otherwise
  /// hide it at the rounded corners. Pair it with 1px padding.
  static const BoxDecoration cardOutline = BoxDecoration(
    borderRadius: AtomRadius.brCard,
    border: Border.fromBorderSide(_line),
  );

  /// The card lifted off the page: [card] plus [AtomShadow.tile].
  static const BoxDecoration raisedCard = BoxDecoration(
    color: AtomColors.paper,
    borderRadius: AtomRadius.brCard,
    border: Border.fromBorderSide(_line),
    boxShadow: [AtomShadow.tile],
  );

  /// A small control-sized tile (a filter, a step, a quick action): white,
  /// 10 corners, a 1px line.
  static const BoxDecoration tile = BoxDecoration(
    color: AtomColors.paper,
    borderRadius: AtomRadius.brControl,
    border: Border.fromBorderSide(_line),
  );
}
