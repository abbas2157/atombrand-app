import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens from BRAND_APP.md §4.1 (AtomBrands logo: red + charcoal).
class AppColors {
  const AppColors._();

  static const primary = Color(0xFFBE1E2D);
  static const primarySoft = Color(0x1ABE1E2D); // 10%
  static const accent = Color(0xFF1B1C1E);
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1C1E);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);

  static const successFg = Color(0xFF15803D);
  static const successBg = Color(0x1F16A34A); // 12%
  static const warningFg = Color(0xFFB45309);
  static const warningBg = Color(0x29FAA53A); // 16%
  static const dangerFg = Color(0xFFB91C1C);
  static const dangerBg = Color(0x1ADC2626); // 10%
  static const neutralFg = Color(0xFF64748B);
  static const neutralBg = Color(0xFFF1F5F9);
  static const infoFg = Color(0xFF3D5DAB);
  static const infoBg = Color(0x1A3D5DAB); // 10%
}

/// Shape & spacing from §4.3.
class AppRadius {
  const AppRadius._();
  static const card = 16.0;
  static const control = 12.0;
}

const cardShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2)),
];

const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.dangerFg,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  // Pinned to google_fonts 8: v9 builds on package:material_ui, whose
  // TextTheme is not the framework's.
  final inter = GoogleFonts.interTextTheme(base.textTheme);
  final text = inter.copyWith(
    headlineSmall: inter.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
    titleLarge: inter.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
    titleMedium: inter.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
    bodyLarge: inter.bodyLarge?.copyWith(fontSize: 15, color: AppColors.ink),
    bodyMedium: inter.bodyMedium?.copyWith(fontSize: 14, color: AppColors.ink),
    labelLarge: inter.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: inter.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
    bodySmall: inter.bodySmall?.copyWith(fontSize: 12, color: AppColors.muted),
  );

  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control));
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: c),
      );

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: controlShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: controlShape,
        side: const BorderSide(color: AppColors.line),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(44, 44), textStyle: text.labelLarge),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.primary),
      errorBorder: border(AppColors.dangerFg),
      focusedErrorBorder: border(AppColors.dangerFg),
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: text.labelMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySoft,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
    ),
  );
}
