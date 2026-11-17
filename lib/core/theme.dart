import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_icons.dart';

/// A status colour pair: text/icon on a soft fill.
@immutable
class Tone {
  const Tone(this.fg, this.bg);
  final Color fg;
  final Color bg;
}

/// The app's colour tokens (DESIGN.md §2): deep indigo with an orange
/// accent on navy and soft neutrals, in a light and a dark variant. The app
/// follows the system setting; read tokens with [AppPalette.of].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette._({
    required this.brightness,
    required this.bg,
    required this.page,
    required this.card,
    required this.surface,
    required this.field,
    required this.border,
    required this.divider,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.primarySoft2,
    required this.ring,
    required this.accent,
    required this.accentInk,
    required this.danger,
    required this.dangerRing,
    required this.success,
    required this.onSuccess,
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.device,
    required this.device2,
    required this.neutral,
    required this.info,
    required this.warning,
    required this.positive,
    required this.negative,
    required this.lead,
    required this.violet,
    required this.indigo,
    required this.fieldShadow,
    required this.buttonShadow,
    required this.cardShadow,
  });

  final Brightness brightness;

  /// Auth screens' page.
  final Color bg;

  /// Signed-in screens' page, behind the cards.
  final Color page;
  final Color card;

  /// Soft panels and skeletons.
  final Color surface;
  final Color field;
  final Color border;

  /// Hairlines inside cards.
  final Color divider;
  final Color text;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color primarySoft2;

  /// 4 px halo around a focused field.
  final Color ring;

  /// Highlights only; [accentInk] is the variant that passes AA as text.
  final Color accent;
  final Color accentInk;
  final Color danger;
  final Color dangerRing;
  final Color success;
  final Color onSuccess;

  /// The navy band at the top of the signed-in screens.
  final Color header;
  final Color onHeader;
  final Color onHeaderMuted;

  /// Product shapes in the illustrations.
  final Color device;
  final Color device2;

  /// Status pills (DESIGN.md §2.2): slate, blue, amber, green, red, orange,
  /// plus indigo for icon tiles.
  final Tone neutral;
  final Tone info;
  final Tone warning;
  final Tone positive;
  final Tone negative;
  final Tone lead;

  /// Quoted (bulk pipeline).
  final Tone violet;
  final Tone indigo;
  final List<BoxShadow> fieldShadow;
  final List<BoxShadow> buttonShadow;
  final List<BoxShadow> cardShadow;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette._(
    brightness: Brightness.light,
    bg: Color(0xFFFFFFFF),
    page: Color(0xFFF5F6FA),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F6FA),
    field: Color(0xFFFFFFFF),
    border: Color(0xFFD9DCE6),
    divider: Color(0xFFEEF0F5),
    text: Color(0xFF10122B),
    muted: Color(0xFF5B6078),
    primary: Color(0xFF4136C9),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFF1F0FD),
    primarySoft2: Color(0xFFE1DEFB),
    ring: Color(0x294136C9), // 16%
    accent: Color(0xFFFF7A1A),
    accentInk: Color(0xFFB04600),
    danger: Color(0xFFC4213A),
    dangerRing: Color(0x24C4213A), // 14%
    success: Color(0xFF127A55),
    onSuccess: Color(0xFFFFFFFF),
    header: Color(0xFF10122B),
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFA6AAC2),
    device: Color(0xFF1C1E36),
    device2: Color(0xFF34385E),
    neutral: Tone(Color(0xFF475569), Color(0xFFEEF1F5)),
    info: Tone(Color(0xFF2F55B8), Color(0xFFE6EDFB)),
    warning: Tone(Color(0xFF8A4B08), Color(0xFFFDF0D5)),
    positive: Tone(Color(0xFF127A55), Color(0xFFE3F4EC)),
    negative: Tone(Color(0xFFB42318), Color(0xFFFDE7E5)),
    lead: Tone(Color(0xFFB04600), Color(0xFFFFEBDC)),
    violet: Tone(Color(0xFF6B3FA0), Color(0xFFF1E8FB)),
    indigo: Tone(Color(0xFF4136C9), Color(0xFFEEEDFD)),
    fieldShadow: [BoxShadow(color: Color(0x0F10122B), blurRadius: 2, offset: Offset(0, 1))],
    buttonShadow: [BoxShadow(color: Color(0x474136C9), blurRadius: 20, offset: Offset(0, 8))],
    cardShadow: [
      BoxShadow(color: Color(0x0A10122B), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F10122B), blurRadius: 16, offset: Offset(0, 6)),
    ],
  );

  static const dark = AppPalette._(
    brightness: Brightness.dark,
    bg: Color(0xFF0D0E1A),
    page: Color(0xFF0D0E1A),
    card: Color(0xFF171A2C),
    surface: Color(0xFF151728),
    field: Color(0xFF171A2C),
    border: Color(0xFF2D3048),
    divider: Color(0xFF242740),
    text: Color(0xFFF1F2F8),
    muted: Color(0xFFA6AAC2),
    primary: Color(0xFF8F88FF),
    onPrimary: Color(0xFF0D0E1A),
    primarySoft: Color(0xFF17163A),
    primarySoft2: Color(0xFF232055),
    ring: Color(0x388F88FF), // 22%
    accent: Color(0xFFFF9142),
    accentInk: Color(0xFFFFB07A),
    danger: Color(0xFFFF6B81),
    dangerRing: Color(0x2EFF6B81), // 18%
    success: Color(0xFF4FD3A0),
    onSuccess: Color(0xFF0D0E1A),
    header: Color(0xFF151728),
    onHeader: Color(0xFFF1F2F8),
    onHeaderMuted: Color(0xFFA6AAC2),
    device: Color(0xFF2B2E4F),
    device2: Color(0xFF3B3F68),
    neutral: Tone(Color(0xFFB5BDCB), Color(0xFF252A3D)),
    info: Tone(Color(0xFF9DB8FF), Color(0xFF1C2A4F)),
    warning: Tone(Color(0xFFF5C26B), Color(0xFF3A2C12)),
    positive: Tone(Color(0xFF4FD3A0), Color(0xFF14352A)),
    negative: Tone(Color(0xFFFF8A8A), Color(0xFF3D1A1E)),
    lead: Tone(Color(0xFFFFB07A), Color(0xFF3A2414)),
    violet: Tone(Color(0xFFD2B6FF), Color(0xFF2E2347)),
    indigo: Tone(Color(0xFFB3AEFF), Color(0xFF232055)),
    fieldShadow: [],
    buttonShadow: [],
    cardShadow: [],
  );

  static AppPalette of(BuildContext context) => Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) => (other == null || t < 0.5) ? this : other;
}

/// Shape & spacing (DESIGN.md §2.3).
class AppRadius {
  const AppRadius._();
  static const card = 16.0;
  static const control = 14.0;
}

const tabularFigures = [FontFeature.tabularFigures()];

/// The signed-in theme for one palette. `BrandApp` builds a light and a dark
/// one and lets the system choose.
ThemeData buildTheme(AppPalette p) {
  final brightness = p.brightness;
  final scheme = ColorScheme.fromSeed(seedColor: p.primary, brightness: brightness).copyWith(
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.accent,
    surface: p.card,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    surfaceContainerLowest: p.card,
    surfaceContainerLow: p.card,
    surfaceContainer: p.card,
    surfaceContainerHigh: p.card,
    surfaceContainerHighest: p.surface,
    outline: p.border,
    outlineVariant: p.divider,
    error: p.danger,
    onError: p.onPrimary,
  );

  // Pinned to google_fonts 8: v9 builds on package:material_ui, whose
  // TextTheme is not the framework's.
  final inter = GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme)
      .apply(bodyColor: p.text, displayColor: p.text);
  final text = inter.copyWith(
    headlineSmall: inter.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: inter.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium: inter.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: inter.bodyLarge?.copyWith(fontSize: 15),
    bodyMedium: inter.bodyMedium?.copyWith(fontSize: 14),
    labelLarge: inter.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: inter.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
    bodySmall: inter.bodySmall?.copyWith(fontSize: 12, color: p.muted),
  );

  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control));
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: c, width: 1.5),
      );

  return ThemeData(
    // Phosphor back / close everywhere Flutter draws them itself.
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const Icon(AppIcons.back),
      closeButtonIconBuilder: (_) => const Icon(AppIcons.close),
      drawerButtonIconBuilder: (_) => const Icon(AppIcons.more),
    ),
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.page,
    textTheme: text,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.header,
      foregroundColor: p.onHeader,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: p.onHeader),
    ),
    cardTheme: CardThemeData(
      color: p.card,
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
        foregroundColor: p.text,
        side: BorderSide(color: p.border, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: p.primary, textStyle: text.labelLarge),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      shape: controlShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(p.border),
      enabledBorder: border(p.border),
      focusedBorder: border(p.primary),
      errorBorder: border(p.danger),
      focusedErrorBorder: border(p.danger),
      hintStyle: TextStyle(color: p.muted),
      helperStyle: TextStyle(color: p.muted),
      errorStyle: TextStyle(color: p.danger),
    ),
    chipTheme: ChipThemeData(
      selectedColor: p.primarySoft2,
      backgroundColor: p.card,
      side: BorderSide(color: p.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: text.labelMedium,
      checkmarkColor: p.primary,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: p.text,
        selectedBackgroundColor: p.primarySoft2,
        selectedForegroundColor: p.primary,
        side: BorderSide(color: p.border, width: 1.5),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: p.primary,
      labelColor: p.primary,
      unselectedLabelColor: p.muted,
      dividerColor: p.divider,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.primarySoft2,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium?.copyWith(
          fontSize: 12,
          color: s.contains(WidgetState.selected) ? p.primary : p.muted,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.primary : p.muted),
      ),
    ),
    badgeTheme: BadgeThemeData(backgroundColor: p.primary, textColor: p.onPrimary),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : Colors.transparent),
      checkColor: WidgetStatePropertyAll(p.onPrimary),
      side: BorderSide(color: p.border, width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onPrimary : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : null),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.primary,
      selectionColor: p.primary.withValues(alpha: 0.25),
      selectionHandleColor: p.primary,
    ),
    dividerTheme: DividerThemeData(color: p.divider, space: 1),
    listTileTheme: ListTileThemeData(iconColor: p.muted, textColor: p.text),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    popupMenuTheme: PopupMenuThemeData(color: p.card, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.isDark ? p.surface : p.text,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.isDark ? p.text : p.bg),
      actionTextColor: p.isDark ? p.primary : p.primarySoft2,
    ),
  );
}
