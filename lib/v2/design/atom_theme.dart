import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'atom_colors.dart';
import 'atom_text.dart';
import 'atom_tokens.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  Brand Partner v2 — Theme
///
///  Material is configured so that anything it draws on its own (dialogs,
///  the date picker, text selection, scroll glow) already matches the canvas.
///  The v2 components in `lib/v2/widgets` do not rely on Material's button,
///  chip or switch themes; they draw the canvas shapes directly.
/// ─────────────────────────────────────────────────────────────────────────
abstract final class AtomTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AtomColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AtomColors.primarySoft,
      onPrimaryContainer: AtomColors.primary,
      secondary: AtomColors.primary,
      onSecondary: Colors.white,
      error: AtomColors.rose,
      onError: Colors.white,
      surface: AtomColors.paper,
      onSurface: AtomColors.ink,
      onSurfaceVariant: AtomColors.muted,
      surfaceContainerHighest: AtomColors.surface,
      outline: AtomColors.line2,
      outlineVariant: AtomColors.line,
      scrim: AtomColors.scrim,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AtomText.family,
      textTheme: AtomText.material,
      scaffoldBackgroundColor: AtomColors.surface,
      canvasColor: AtomColors.paper,
      dividerColor: AtomColors.line,
      // No ink splash: the canvas has pressed fills, not ripples (plan §3.5,
      // "no decorative animation").
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // Only the system page transition is allowed.
      pageTransitionsTheme: const PageTransitionsTheme(),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: AtomColors.paper,
        foregroundColor: AtomColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AtomText.pageTitle,
        iconTheme: const IconThemeData(
          color: AtomColors.ink,
          size: AtomIcon.bar,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      iconTheme: const IconThemeData(
        color: AtomColors.text,
        size: AtomIcon.row,
      ),

      dividerTheme: const DividerThemeData(
        color: AtomColors.line,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AtomColors.paper,
        modalBackgroundColor: AtomColors.paper,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AtomColors.scrim,
        shape: RoundedRectangleBorder(borderRadius: AtomRadius.brSheetTop),
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AtomColors.paper,
        surfaceTintColor: Colors.transparent,
        barrierColor: AtomColors.scrim,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AtomRadius.sheet)),
        ),
        titleTextStyle: AtomText.heading,
        contentTextStyle: AtomText.body.copyWith(color: AtomColors.text),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AtomColors.primary,
        circularTrackColor: AtomColors.line2,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AtomColors.primary,
        selectionHandleColor: AtomColors.primary,
        selectionColor: AtomColors.primary.withValues(alpha: 0.2),
      ),

      // Text fields. AtomTextField draws its own label, hint and error
      // outside the box, as the canvas does, so the decoration here is only
      // the box itself.
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AtomColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.inset,
          vertical: 15,
        ),
        hintStyle: AtomText.input.copyWith(color: AtomColors.placeholder),
        border: _box(AtomColors.line2),
        enabledBorder: _box(AtomColors.line2),
        focusedBorder: _box(AtomColors.primary),
        errorBorder: _box(AtomColors.rose),
        focusedErrorBorder: _box(AtomColors.rose),
        disabledBorder: _box(AtomColors.line2),
        prefixIconColor: AtomColors.faint,
        suffixIconColor: AtomColors.faint,
      ),
    );
  }

  static OutlineInputBorder _box(Color color) => OutlineInputBorder(
    borderRadius: AtomRadius.brControl,
    borderSide: BorderSide(color: color),
  );
}
