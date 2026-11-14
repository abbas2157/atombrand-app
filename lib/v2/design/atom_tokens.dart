import 'package:flutter/widgets.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Brand Partner v2 — Layout tokens
///
///  Spacing, corners and sizes from the canvas `app.css` and the style guide
///  boards. Use these instead of numbers in widgets.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class AtomSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;

  /// Padding inside a card or row.
  static const double inset = 14;

  /// Left and right page margin.
  static const double gutter = 16;
}

abstract final class AtomRadius {
  static const double tag = 6;
  static const double control = 10;
  static const double card = 14;
  static const double sheet = 20;
  static const double pill = 999;

  static const BorderRadius brTag = BorderRadius.all(Radius.circular(tag));
  static const BorderRadius brControl = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius brCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius brSheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

abstract final class AtomSize {
  /// Buttons, inputs and the dropdown field.
  static const double control = 50;

  /// The search input at the top of a sheet.
  static const double sheetSearch = 46;

  /// A compact button: a sheet's footer, an empty list's action (14.1).
  static const double compactButton = 46;

  /// The art circle on an empty list (14.1) and its icon tile.
  static const double emptyArt = 120;
  static const double emptyTile = 64;

  /// The icon tile on an error or state page (14.6, 14.7).
  static const double stateTile = 80;

  /// Small buttons. Their tap area is still [tapTarget].
  static const double small = 36;

  /// The smallest tap area (Android and WCAG: 48×48dp).
  static const double tapTarget = 48;

  /// A settings / navigation row, at the default text size.
  static const double row = 60;

  /// An option row in the dropdown sheet.
  static const double optionRow = 52;

  /// The icon tile at the start of a navigation row.
  static const double rowTile = 36;

  static const double switchWidth = 46;
  static const double switchHeight = 28;

  /// A PIN key (`.key`).
  static const double pinKey = 62;

  /// The splash tile (1.1) and its mark; the returning splash (1.2) is
  /// smaller.
  static const double splashTile = 112;
  static const double splashMark = 84;
  static const double splashTileReturning = 96;

  /// The tile on the lock screens (3.0) and the avatar on the PIN (3.1).
  static const double lockTile = 64;
  static const double lockAvatar = 68;

  /// The fingerprint circle on 3.0.
  static const double fingerprintCircle = 112;

  /// The art circle on the tour (17.7) and the tile inside it.
  static const double tourArt = 240;
  static const double tourTile = 120;

  /// The avatar at the top of the menu (13.1) and the icon tile on its rows
  /// and on the Reports rows (13.5).
  static const double menuAvatar = 52;
  static const double menuTile = 34;

  /// The Atomshop.pk partner logo under the menu (13.1).
  static const double partnerLogo = 30;

  /// Ask Atom's avatar in its header (13.10) and beside an answer.
  static const double atomAvatar = 40;
  static const double atomAvatarSmall = 28;

  /// The round mic and send buttons and the pill input on Ask Atom.
  static const double atomInput = 48;

  /// Forms never get wider than this, even on a tablet.
  static const double formMaxWidth = 560;

  /// From here the app shows a rail instead of the tab bar.
  static const double tabletBreakpoint = 600;

  /// From here a list and its detail sit side by side (tablet landscape,
  /// large tablets).
  static const double splitBreakpoint = 840;

  /// 8.2 `.big-ini`: the customer's initials on the profile header.
  static const double bigInitials = 56;

  /// 8.3 `.card-frame`: where the CNIC goes in the camera view.
  static const double cnicFrameWidth = 330;
  static const double cnicFrameHeight = 208;

  /// 8.3 `.shutter`.
  static const double shutter = 72;

  /// 9.2 `.ph`: the product picture on the take-a-lead sheet.
  static const double leadPhoto = 64;

  /// 9.7 `.thumb`: the product tile on a website order row.
  static const double orderThumb = 44;

  /// 5.1 the Ask Atom bar on Home's navy header.
  static const double askBar = 46;

  /// 5.1 `.hero .acts .btn`: the hero's buttons (15px label).
  static const double heroButton = 44;

  /// 6.3 `.k2 button`: a key of the payment keypad (56 on a tablet).
  static const double payKey = 50;
  static const double payKeyWide = 56;

  /// 15.1 `.rail`: the tablet's navigation rail.
  static const double railWidth = 96;

  /// 10.5 `.strip`: the navy "point at each box" scan strip.
  static const double scanStrip = 110;

  /// 10.8 / 10.10 `.scanbtn`: the navy "Keep scanning" button.
  static const double scanButton = 54;

  /// 10.4 `.cam`: the camera area above a scan's result.
  static const double scanCamera = 300;
}

/// Lucide icon sizes and the stroke each one takes.
abstract final class AtomIcon {
  static const double inline = 16;
  static const double row = 20;
  static const double bar = 22;
  static const double plus = 24;

  /// The icon on a settings row's tile and its chevron (`.set-item`).
  static const double setRow = 18;
}

/// The only motion v2 has: the system page transition and the switch knob.
abstract final class AtomMotion {
  static const Duration knob = Duration(milliseconds: 150);
  static const Duration toast = Duration(seconds: 4);
}
