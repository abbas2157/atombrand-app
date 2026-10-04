import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Headphones, a phone showing the AB mark, and a smartwatch, on a soft indigo
/// card (Welcome). Drawn on a 327 × 300 grid and scaled to fit.
class ProductsIllustration extends StatelessWidget {
  const ProductsIllustration({super.key, this.height = 300});
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: 'Headphones, a smartphone showing the AtomBrands logo, and a smartwatch',
      image: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: p.primarySoft, borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: FittedBox(
          child: SizedBox(
            width: 327,
            height: 300,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _ProductsPainter(p))),
                // The AB mark on the phone's screen.
                Positioned(
                  left: 141,
                  top: 92,
                  width: 60,
                  height: 50,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Image.asset('assets/brand/mark.png', filterQuality: FilterQuality.medium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An envelope with a green tick (password reset code sent).
class InboxIllustration extends StatelessWidget {
  const InboxIllustration({super.key, this.width = 220});
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: 'Envelope with a check mark',
      image: true,
      child: SizedBox(
        width: width,
        child: FittedBox(child: CustomPaint(size: const Size(220, 190), painter: _InboxPainter(p))),
      ),
    );
  }
}

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

RRect _rr(double x, double y, double w, double h, double r) =>
    RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

/// Four-point sparkle centred on [c] with arm length [r].
Path _sparkle(Offset c, double r) {
  final k = r * 0.375;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + k, c.dy - k)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx + k, c.dy + k)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - k, c.dy + k)
    ..lineTo(c.dx - r, c.dy)
    ..lineTo(c.dx - k, c.dy - k)
    ..close();
}

class _ProductsPainter extends CustomPainter {
  const _ProductsPainter(this.p);
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(const Offset(163, 156), 118, _fill(p.primarySoft2));

    // Headphones, partly behind the phone.
    final band = Path()
      ..moveTo(38, 192)
      ..lineTo(38, 162)
      ..arcToPoint(const Offset(138, 162), radius: const Radius.circular(50))
      ..lineTo(138, 192);
    canvas.drawPath(band, _stroke(p.device2, 10));
    canvas.drawRRect(_rr(24, 176, 30, 56, 13), _fill(p.device));
    canvas.drawRRect(_rr(29, 188, 6, 32, 3), _fill(p.accent));
    canvas.drawRRect(_rr(122, 176, 30, 56, 13), _fill(p.device));

    // Phone; the logo tile on its screen is laid over in ProductsIllustration.
    canvas.drawRRect(_rr(118, 48, 106, 206, 20), _fill(p.device));
    canvas.drawRRect(_rr(124, 54, 94, 194, 15), _fill(p.primary));
    canvas.drawRRect(_rr(153, 61, 36, 9, 4.5), _fill(p.device));
    canvas.drawRRect(_rr(137, 164, 68, 8, 4), _fill(Colors.white.withValues(alpha: 0.85)));
    canvas.drawRRect(_rr(147, 180, 48, 6, 3), _fill(Colors.white.withValues(alpha: 0.45)));
    canvas.drawRRect(_rr(137, 206, 68, 24, 12), _fill(p.accent));

    // Smartwatch.
    canvas.drawRRect(_rr(250, 94, 36, 154, 14), _fill(p.device2));
    canvas.drawRRect(_rr(236, 134, 64, 74, 20), _fill(p.device));
    canvas.drawRRect(_rr(243, 141, 50, 60, 14), _fill(const Color(0xFF0B0C18)));
    const face = Offset(268, 171);
    canvas.drawArc(Rect.fromCircle(center: face, radius: 17), -math.pi / 2, 2 * math.pi * 80 / 107, false, _stroke(p.accent, 4));
    canvas.drawCircle(face, 9, _stroke(const Color(0xFF8F88FF), 3));
    canvas.drawRRect(_rr(299, 160, 5, 16, 2.5), _fill(p.device2));

    // Sparkles.
    canvas.drawPath(_sparkle(const Offset(66, 75), 11), _fill(p.accent));
    canvas.drawPath(_sparkle(const Offset(290, 54), 8), _fill(p.primary));
    canvas.drawCircle(const Offset(52, 122), 4, _fill(p.primary.withValues(alpha: 0.35)));
    canvas.drawCircle(const Offset(300, 258), 5, _fill(p.accent.withValues(alpha: 0.6)));
  }

  @override
  bool shouldRepaint(covariant _ProductsPainter old) => old.p != p;
}

class _InboxPainter extends CustomPainter {
  const _InboxPainter(this.p);
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(const Offset(110, 98), 86, _fill(p.primarySoft));
    canvas.drawCircle(const Offset(110, 98), 62, _fill(p.primarySoft2));

    final envelope = _rr(52, 62, 116, 80, 12);
    canvas.drawRRect(envelope, _fill(p.field));
    canvas.drawRRect(envelope, _stroke(p.primary, 3));
    canvas.drawPath(
      Path()
        ..moveTo(56, 68)
        ..lineTo(110, 108)
        ..lineTo(164, 68),
      _stroke(p.primary, 3),
    );
    final folds = _stroke(p.primary.withValues(alpha: 0.35), 2);
    canvas
      ..drawLine(const Offset(58, 136), const Offset(94, 106), folds)
      ..drawLine(const Offset(162, 136), const Offset(126, 106), folds);

    canvas.drawCircle(const Offset(164, 62), 22, _fill(p.success));
    canvas.drawPath(
      Path()
        ..moveTo(154, 62)
        ..lineTo(161, 69)
        ..lineTo(174, 55),
      _stroke(p.onSuccess, 3.5),
    );

    canvas.drawPath(_sparkle(const Offset(38, 51), 11), _fill(p.accent));
    canvas.drawPath(_sparkle(const Offset(190, 135), 7), _fill(p.accent));
    canvas.drawCircle(const Offset(30, 140), 4, _fill(p.primary.withValues(alpha: 0.35)));
  }

  @override
  bool shouldRepaint(covariant _InboxPainter old) => old.p != p;
}
