import 'dart:math' as math;
import '../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/google_auth.dart';
import '../../core/push.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/feedback.dart';
import 'auth_scaffold.dart';

/// Google, Apple and Facebook as three equal icon buttons (DESIGN.md §3.4).
/// Only Google is wired to the backend; Apple and Facebook say so when tapped.
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key, this.verb = 'Continue'});

  /// "Continue" on Sign in, "Sign up" on Sign up; used in the button labels.
  final String verb;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    void notYet(String provider) =>
        showToast(context, "$verb with $provider isn't available yet. Use your email, or Google.");
    return Row(
      children: [
        Expanded(child: GoogleSignInButton(semanticLabel: '$verb with Google')),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: '$verb with Apple',
            onPressed: () => notYet('Apple'),
            child: Icon(AppIcons.apple, size: 24, color: p.text),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: '$verb with Facebook',
            onPressed: () => notYet('Facebook'),
            child: const Icon(AppIcons.facebook, size: 24, color: Color(0xFF1877F2)),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.onPressed, required this.child});
  final String label;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AuthTheme.radius), boxShadow: p.fieldShadow),
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), padding: EdgeInsets.zero),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// "Continue with Google" as an icon button: picks a Google account, then
/// `POST auth/google` signs in the brand account with that email (BRAND_APP.md §6.1).
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key, this.semanticLabel = 'Continue with Google'});

  final String semanticLabel;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final idToken = await GoogleAuth.idToken();
      if (idToken == null || !mounted) return;
      final fcm = await ref.read(pushServiceProvider).currentToken();
      final session = await ref.read(authRepositoryProvider).loginWithGoogle(idToken, fcmToken: fcm);
      await ref.read(sessionProvider.notifier).signIn(session);
    } on GoogleAuthUnavailable catch (e) {
      if (mounted) showToast(context, e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Signed-out 401/403s are silenced by showApiError, but here they carry
      // the reason (no brand account for that email, account blocked).
      switch (e.statusCode) {
        case 404:
          showToast(context, "Google sign-in isn't available yet. Please sign in with your password.");
        case 401 || 403:
          showToast(context, e.message);
        default:
          await showApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      label: widget.semanticLabel,
      onPressed: _busy ? null : _signIn,
      child: _busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
          : const GoogleLogo(size: 20),
    );
  }
}

/// The four-colour Google "G", drawn so no image asset is needed.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: CustomPaint(size: Size.square(size), painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final r = (size.width - stroke) / 2;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);
    double rad(double deg) => deg * math.pi / 180;
    Paint p(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Clockwise from the crossbar (east); the gap is the G's opening.
    canvas.drawArc(rect, rad(0), rad(48), false, p(_blue));
    canvas.drawArc(rect, rad(48), rad(90), false, p(_green));
    canvas.drawArc(rect, rad(138), rad(80), false, p(_yellow));
    canvas.drawArc(rect, rad(218), rad(97), false, p(_red));
    canvas.drawRect(
      Rect.fromLTRB(c.dx - stroke * 0.1, c.dy - stroke / 2, c.dx + r + stroke / 2, c.dy + stroke / 2),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
