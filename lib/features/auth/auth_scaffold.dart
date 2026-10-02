import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

/// Shared layout for the signed-out screens (DESIGN.md §3): a slim top bar
/// with the AB mark, an optional icon badge, the title block, then the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.footer,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;

  /// Shown in a soft red tile above the title.
  final IconData? icon;
  final List<Widget> children;

  /// Sits below the form, e.g. the "Become a partner" link.
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canPop = showBack && context.canPop();
    return AuthTheme(
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        SizedBox(width: 48, child: canPop ? const AuthBackButton() : null),
                        const Expanded(child: Center(child: BrandLogo.mark(height: 26))),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (icon != null) ...[
                          Align(alignment: Alignment.centerLeft, child: AuthIconBadge(icon!)),
                          const SizedBox(height: 20),
                        ],
                        Text(title, style: authTitleStyle(t)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(subtitle!, style: authSubtitleStyle(t)),
                        ],
                        const SizedBox(height: 28),
                        ...children,
                        if (footer != null) ...[
                          const SizedBox(height: 28),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle? authTitleStyle(TextTheme t) =>
    t.headlineSmall?.copyWith(fontSize: 26, height: 1.2, letterSpacing: -0.4, fontWeight: FontWeight.w700);

TextStyle? authSubtitleStyle(TextTheme t) => t.bodyMedium?.copyWith(fontSize: 15, height: 1.5, color: AppColors.muted);

/// Softer controls for the signed-out screens: filled fields, taller buttons.
class AuthTheme extends StatelessWidget {
  const AuthTheme({super.key, required this.child});
  final Widget child;

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: c, width: w),
        );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: border(Colors.transparent),
          enabledBorder: border(Colors.transparent),
          focusedBorder: border(AppColors.primary, 1.6),
          errorBorder: border(AppColors.dangerFg),
          focusedErrorBorder: border(AppColors.dangerFg, 1.6),
          prefixIconColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.focused) ? AppColors.primary : AppColors.muted,
          ),
          suffixIconColor: AppColors.muted,
          labelStyle: const TextStyle(color: AppColors.muted),
          hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.7)),
          helperStyle: const TextStyle(color: AppColors.muted),
          floatingLabelStyle: WidgetStateTextStyle.resolveWith(
            (s) => TextStyle(
              color: s.contains(WidgetState.error) ? AppColors.dangerFg : AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 54),
            shape: shape,
            textStyle: base.textTheme.labelLarge?.copyWith(fontSize: 15),
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
            disabledForegroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 54),
            shape: shape,
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.line),
            textStyle: base.textTheme.labelLarge?.copyWith(fontSize: 15),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            minimumSize: const Size(0, 46),
            foregroundColor: AppColors.ink,
            selectedBackgroundColor: AppColors.primarySoft,
            selectedForegroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.line),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// The AtomBrands logo. [BrandLogo.mark] is the AB monogram; [BrandLogo.lockup]
/// adds the wordmark and "Connect. Sell. Grow." Transparent PNGs; use them on
/// light surfaces only (the A and wordmark are charcoal).
class BrandLogo extends StatelessWidget {
  const BrandLogo.mark({super.key, this.height = 32}) : _asset = 'assets/brand/mark.png';
  const BrandLogo.lockup({super.key, this.height = 140}) : _asset = 'assets/brand/lockup.png';

  final double height;
  final String _asset;

  @override
  Widget build(BuildContext context) =>
      Image.asset(_asset, height: height, filterQuality: FilterQuality.medium, semanticLabel: 'AtomBrands');
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => context.pop(),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
    );
  }
}

class AuthIconBadge extends StatelessWidget {
  const AuthIconBadge(
    this.icon, {
    super.key,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.29)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// "or" between password sign-in and Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: Theme.of(context).textTheme.bodySmall),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// "New to AtomShop? Become a partner".
class PartnerLink extends StatelessWidget {
  const PartnerLink({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('New to AtomShop?', style: t.bodyMedium?.copyWith(color: AppColors.muted)),
        TextButton(
          onPressed: () => context.push('/apply'),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
          child: const Text('Become a partner'),
        ),
      ],
    );
  }
}

String? requiredValidator(String? v, [String label = 'This field']) =>
    (v == null || v.trim().isEmpty) ? '$label is required.' : null;

/// Email or Pakistani mobile in any common format (§6.1).
String? loginValidator(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Enter your email or phone number.';
  if (s.contains('@')) return null;
  final digits = s.replaceAll(RegExp(r'[\s\-()+]'), '');
  if (RegExp(r'^(0|92)?3\d{9}$').hasMatch(digits)) return null;
  return 'Enter a valid email or mobile number (e.g. 0300 1234567).';
}

String? phoneValidator(String? v) {
  final digits = (v ?? '').trim().replaceAll(RegExp(r'[\s\-()+]'), '');
  if (digits.isEmpty) return 'Phone is required.';
  return RegExp(r'^(0|92)?3\d{9}$').hasMatch(digits) ? null : 'Enter a valid mobile number (e.g. 0300 1234567).';
}

String? emailValidator(String? v, {bool required = true}) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return required ? 'Email is required.' : null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s) ? null : 'Enter a valid email address.';
}

String? passwordValidator(String? v) =>
    (v == null || v.length < 8) ? 'Use at least 8 characters.' : null;
