import 'package:flutter/material.dart';

import 'atom_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Brand Partner v2 — Type scale (Inter only)
///
///  Plan §3.5 and the "Type scale" board:
///  11 tag · 12 small/section label · 13 secondary · 14 body · 15 list title
///  · 16 input · 18 section · 20 page title · 24 success title · 28/34
///  amounts · 44 keypad amount.
///
///  Every money style sets tabular figures, so amounts line up in a column
///  and don't jitter while they load. Sizes are logical pixels; Flutter's
///  text scaler grows them up to 200%, so no widget may fix a text height.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class AtomText {
  static const String family = 'Inter';

  /// Inter's own line height, (ascender + descender) / em: what a browser
  /// uses for `line-height: normal`.
  static const double normalHeight = 1.21;

  static const _tnum = [FontFeature.tabularFigures()];

  static TextStyle _s(
    double size,
    FontWeight weight, {
    Color color = AtomColors.ink,
    double? height,
    double? letterSpacing,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? _tnum : null,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 11/700 — tags and pills.
  static final tag = _s(11, FontWeight.w700);

  /// 12/700 caps — a section label above a group ("ACCOUNT"). Uppercase the
  /// text where it is shown; the style can't, and translations decide case.
  static final section = _s(
    12,
    FontWeight.w700,
    color: AtomColors.faint,
    letterSpacing: 0.6,
  );

  /// 12 — small print and timestamps.
  static final small = _s(12, FontWeight.w400, color: AtomColors.muted);

  /// 13 — second line, hint.
  static final secondary = _s(
    13,
    FontWeight.w400,
    color: AtomColors.muted,
    height: 1.35,
  );

  /// 13/600 — the label above a field.
  static final fieldLabel = _s(13, FontWeight.w600);

  /// 13/500 rose — the error under a field.
  static final fieldError = _s(13, FontWeight.w500, color: AtomColors.rose);

  /// 13/600 — small buttons and chips.
  static final smallButton = _s(13, FontWeight.w600);

  /// 14 — body text.
  static final body = _s(14, FontWeight.w400, height: 1.45);

  /// 15/600 — a list or row title.
  static final listTitle = _s(15, FontWeight.w600, height: 1.3);

  /// 16 — what the person types, and option rows.
  static final input = _s(16, FontWeight.w400);

  /// 16/600 — full-size buttons.
  static final button = _s(16, FontWeight.w600);

  /// 18/700 — a section heading, a sheet title.
  static final heading = _s(18, FontWeight.w700, height: 1.3);

  /// 20/700 — a page title.
  static final pageTitle = _s(20, FontWeight.w700, height: 1.3);

  /// 24/700 — the title of a success screen.
  static final successTitle = _s(24, FontWeight.w700, height: 1.25);

  /// 28/800 — an amount on a card.
  static final amount = _s(28, FontWeight.w800, tabular: true);

  /// 34/800 — the hero amount.
  static final amountLg = _s(
    34,
    FontWeight.w800,
    letterSpacing: -0.6,
    tabular: true,
  );

  /// 44/800 — the amount on the money keypad.
  static final keypadAmount = _s(44, FontWeight.w800, tabular: true);

  /// Money inside a row or running text.
  static final money = _s(15, FontWeight.w600, tabular: true);

  /// The Material slots, so dialogs, pickers and typed text use Inter at the
  /// v2 sizes. Colour is left to Material.
  static TextTheme get material => TextTheme(
    displayLarge: _bare(amountLg),
    displayMedium: _bare(amount),
    displaySmall: _bare(successTitle),
    headlineLarge: _bare(successTitle),
    headlineMedium: _bare(pageTitle),
    headlineSmall: _bare(heading),
    titleLarge: _bare(pageTitle),
    titleMedium: _bare(listTitle),
    titleSmall: _bare(fieldLabel),
    bodyLarge: _bare(input),
    // The default every Text merges with: a style with no height of its own
    // (12 small print, 16 input, the 34 hero amount…) gets Inter's normal
    // line height, as on the boards (CSS `normal`), not body's 1.45.
    bodyMedium: _bare(body).copyWith(height: normalHeight),
    bodySmall: _bare(secondary),
    labelLarge: _bare(button),
    labelMedium: _bare(smallButton),
    labelSmall: _bare(tag),
  );

  static TextStyle _bare(TextStyle s) => TextStyle(
    fontFamily: s.fontFamily,
    fontSize: s.fontSize,
    fontWeight: s.fontWeight,
    height: s.height,
    // 0, not left empty: Material's own spacing (0.25, 0.5…) would stay.
    letterSpacing: s.letterSpacing ?? 0,
    fontFeatures: s.fontFeatures,
  );
}
