import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

/// Shared layout for the signed-out screens (DESIGN.md §3): back button, an
/// optional icon badge, the title block, then the form. [bottom] is pinned
/// under the scrolling content and rides above the keyboard, so the primary
/// action stays visible while typing.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.footer,
    this.bottom,
    this.bottomDivider = false,
    this.compactHeader = false,
    this.showBack = true,
    this.showLogo = false,
  });

  final String? title;
  final String? subtitle;

  /// Shown in a soft indigo tile above the title.
  final IconData? icon;
  final List<Widget> children;

  /// Pushed to the bottom of the scrolling content, e.g. "Don't have an account?".
  final Widget? footer;

  /// Pinned below the scrolling content (and above the keyboard).
  final Widget? bottom;

  /// Hairline above [bottom], for long forms that scroll under it.
  final bool bottomDivider;

  /// Puts the title next to the back button instead of below it, to give
  /// long forms more room.
  final bool compactHeader;
  final bool showBack;

  /// Centres the logo in the top bar, beside the back button.
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return AuthTheme(
      child: Builder(builder: (context) {
        final p = AppPalette.of(context);
        final canPop = showBack && context.canPop();
        final head = <Widget>[
          if (compactHeader)
            Row(
              children: [
                if (canPop) ...[const AuthBackButton(), const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) Text(title!, style: authTitleStyle(context)?.copyWith(fontSize: 22)),
                      if (subtitle != null) Text(subtitle!, style: authSubtitleStyle(context)?.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: 48,
              child: showLogo && canPop
                  ? const Row(
                      children: [
                        AuthBackButton(),
                        Expanded(child: Center(child: BrandLogo.inline(height: 28))),
                        SizedBox(width: 48),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: canPop ? const AuthBackButton() : const BrandLogo.inline(height: 28),
                    ),
            ),
            const SizedBox(height: 20),
            if (icon != null) ...[
              Align(alignment: Alignment.centerLeft, child: AuthIconBadge(icon!)),
              const SizedBox(height: 20),
            ],
            if (title != null) Text(title!, style: authTitleStyle(context)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: authSubtitleStyle(context)),
            ],
          ],
          const SizedBox(height: 24),
        ];

        return Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            sliver: SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ...head,
                                  ...children,
                                  if (footer != null) ...[
                                    const Spacer(),
                                    const SizedBox(height: 16),
                                    footer!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bottom != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                        decoration: BoxDecoration(
                          color: p.bg,
                          border: bottomDivider ? Border(top: BorderSide(color: p.border)) : null,
                        ),
                        child: bottom,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

TextStyle? authTitleStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .headlineSmall
    ?.copyWith(fontSize: 28, height: 1.2, letterSpacing: -0.5, fontWeight: FontWeight.w700, color: AppPalette.of(context).text);

TextStyle? authSubtitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.47, color: AppPalette.of(context).muted);

/// The signed-out variant of the app theme: Poppins, white (or dark) page,
/// taller controls. Uses the palette the app theme picked for the system
/// light/dark setting.
class AuthTheme extends StatelessWidget {
  const AuthTheme({super.key, required this.child});
  final Widget child;

  static const radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = p.isDark;
    final brightness = p.brightness;

    final scheme = ColorScheme.fromSeed(seedColor: p.primary, brightness: brightness).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      surface: p.bg,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      outline: p.border,
      outlineVariant: p.border,
      error: p.danger,
      onError: p.onPrimary,
    );

    // Pinned to google_fonts 8 (see buildTheme).
    final poppins = GoogleFonts.poppinsTextTheme(ThemeData(brightness: brightness).textTheme)
        .apply(bodyColor: p.text, displayColor: p.text);
    final text = poppins.copyWith(
      headlineSmall: poppins.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: poppins.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: poppins.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: poppins.bodyLarge?.copyWith(fontSize: 15),
      bodyMedium: poppins.bodyMedium?.copyWith(fontSize: 14),
      labelLarge: poppins.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: poppins.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      bodySmall: poppins.bodySmall?.copyWith(fontSize: 12, color: p.muted),
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c, width: 1.5),
        );

    final data = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      textTheme: text,
      extensions: [p],
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.25),
        selectionHandleColor: p.primary,
      ),
      // For controls that aren't AuthFields (e.g. dropdowns on Apply).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(p.primary),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger),
        hintStyle: TextStyle(color: p.muted),
        helperStyle: TextStyle(color: p.muted),
        errorStyle: TextStyle(color: p.danger),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: shape,
          elevation: 0,
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          // Busy buttons keep their colour and show a spinner instead.
          disabledBackgroundColor: p.primary,
          disabledForegroundColor: p.onPrimary,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: shape,
          backgroundColor: p.field,
          foregroundColor: p.text,
          side: BorderSide(color: p.border, width: 1.5),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: p.primary,
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 46),
          foregroundColor: p.text,
          selectedBackgroundColor: p.primarySoft2,
          selectedForegroundColor: p.primary,
          side: BorderSide(color: p.border, width: 1.5),
          textStyle: text.labelMedium,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.error) ? p.danger : p.border, width: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      dialogTheme: DialogThemeData(backgroundColor: p.bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: p.bg,
      ),
      child: Theme(data: data, child: child),
    );
  }
}

/// The AtomBrands logo (DESIGN.md §1). [BrandLogo.mark] is the AB monogram,
/// [BrandLogo.inline] sets "AtomBrands" beside it, and [BrandLogo.lockup] adds
/// the stacked wordmark and "Connect. Sell. Grow.". The PNGs are charcoal and
/// red, so in dark mode they sit on a white tile.
class BrandLogo extends StatelessWidget {
  const BrandLogo.mark({super.key, this.height = 32}) : _asset = _markAsset, _wordmark = false;
  const BrandLogo.inline({super.key, this.height = 32}) : _asset = _markAsset, _wordmark = true;
  const BrandLogo.lockup({super.key, this.height = 140}) : _asset = 'assets/brand/lockup.png', _wordmark = false;

  static const _markAsset = 'assets/brand/mark.png';

  final double height;
  final String _asset;
  final bool _wordmark;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget logo = Image.asset(_asset, height: height, filterQuality: FilterQuality.medium);
    if (p.isDark) {
      logo = Container(
        padding: EdgeInsets.all(height * 0.16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(height * 0.28)),
        child: logo,
      );
    }
    if (_wordmark) {
      logo = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          SizedBox(width: height * 0.32),
          Text(
            'AtomBrands',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: height * 0.62,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: p.text,
                ),
          ),
        ],
      );
    }
    return Semantics(label: 'AtomBrands', image: true, child: ExcludeSemantics(child: logo));
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return IconButton(
      tooltip: 'Back',
      onPressed: () => context.pop(),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        foregroundColor: p.text,
        side: BorderSide(color: p.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AuthTheme.radius)),
      ),
      icon: const Icon(Icons.chevron_left_rounded, size: 28),
    );
  }
}

class AuthIconBadge extends StatelessWidget {
  const AuthIconBadge(this.icon, {super.key, this.color, this.background, this.size = 56});

  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background ?? p.primarySoft2, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: color ?? p.primary, size: size * 0.48),
    );
  }
}

/// Full-width primary action. While [busy] it keeps its colour and shows a
/// spinner with [busyLabel].
class AuthButton extends StatelessWidget {
  const AuthButton({super.key, required this.label, required this.onPressed, this.busy = false, this.busyLabel});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AuthTheme.radius), boxShadow: p.buttonShadow),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: p.onPrimary,
                        backgroundColor: p.onPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(busyLabel ?? label),
                  ],
                )
              : Text(label),
        ),
      ),
    );
  }
}

/// Hairline – caption – hairline, e.g. "or continue with".
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.text = 'or'});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: p.muted)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// "Don't have an account? Sign up".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.prompt, required this.action, required this.onPressed});

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.muted)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
          child: Text(action),
        ),
      ],
    );
  }
}

/// Tinted message box for screen-level errors and notices.
class AuthBanner extends StatelessWidget {
  const AuthBanner(this.text, {super.key, this.icon = Icons.error_outline_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.dangerRing, borderRadius: BorderRadius.circular(AuthTheme.radius)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: p.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.text, height: 1.4))),
        ],
      ),
    );
  }
}

String? requiredValidator(String? v, [String label = 'This field']) =>
    (v == null || v.trim().isEmpty) ? '$label is required.' : null;

/// Email or Pakistani mobile in any common format (§6.1).
String? loginValidator(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Enter your email or phone number.';
  if (s.contains('@')) return emailValidator(s);
  final digits = s.replaceAll(RegExp(r'[\s\-()+]'), '');
  if (RegExp(r'^(0|92)?3\d{9}$').hasMatch(digits)) return null;
  return 'Enter a valid email or mobile number (e.g. 0300 1234567).';
}

String? phoneValidator(String? v, {bool required = true}) {
  final digits = (v ?? '').trim().replaceAll(RegExp(r'[\s\-()+]'), '');
  if (digits.isEmpty) return required ? 'Phone is required.' : null;
  return RegExp(r'^(0|92)?3\d{9}$').hasMatch(digits) ? null : 'Enter a valid mobile number (e.g. 0300 1234567).';
}

String? emailValidator(String? v, {bool required = true}) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return required ? 'Email is required.' : null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Enter a valid email, like name@example.com.';
}

String? passwordValidator(String? v) =>
    (v == null || v.length < 8) ? 'Use at least 8 characters.' : null;
