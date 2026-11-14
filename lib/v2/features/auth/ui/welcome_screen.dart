import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Welcome (1.3): first open on this phone. A root screen.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AtomColors.nav,
        // The status bar stays navy; on a short phone the page scrolls
        // under it rather than through it.
        body: Padding(
          padding: EdgeInsets.only(top: top),
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The navy part is 360 tall on the board, the status
                      // bar's 44 included.
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 316),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                          child: _Preview(l: l),
                        ),
                      ),
                      Expanded(child: _Sheet(l: l)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    // A picture of the app, not live data: the figures are the canvas's.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AtomBrandTile(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.appName,
                style: AtomText.input.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _LanguageButton(l: l),
          ],
        ),
        const SizedBox(height: 26),
        // A picture of the app: it keeps its size at any text size.
        ExcludeSemantics(
          child: MediaQuery.withNoTextScaling(
            child: Column(
              children: [
                _DarkCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AtomColors.green.withValues(alpha: 0.22),
                          borderRadius: AtomRadius.brControl,
                        ),
                        child: const Icon(
                          LucideIcons.banknote,
                          size: AtomIcon.row,
                          color: AtomColors.toastOkIcon,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dimLabel(l.welcomeCollectedToday),
                            Text(
                              'Rs 48,500',
                              style: AtomText.heading.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AtomPill(
                        label: l.welcomePaidCount,
                        tone: AtomTone.green,
                        dot: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Both cards as tall as the taller one, as on the board's
                // grid; the stripe stays under "7 customers".
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _DarkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _dimLabel(l.welcomeDueToday),
                              _whiteValue(l.welcomeDueCustomers),
                              const SizedBox(height: 10),
                              // 70% of the card, as on the board.
                              const FractionallySizedBox(
                                widthFactor: 0.7,
                                alignment: AlignmentDirectional.centerStart,
                                child: AtomStepsStripe(width: double.infinity),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DarkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _dimLabel(l.welcomeNewLeads),
                              _whiteValue(l.welcomeLeadsInAreas),
                              const SizedBox(height: 6),
                              Text(
                                l.welcomeFromWebsite,
                                style: AtomText.small.copyWith(
                                  color: const Color(0xFFFFD27F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dimLabel(String s) =>
      Text(s, style: AtomText.small.copyWith(color: AtomColors.navMuted));

  Widget _whiteValue(String s) => Text(
    s,
    style: AtomText.input.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AtomColors.nav2,
      borderRadius: AtomRadius.brCard,
      border: Border.all(color: AtomColors.navLine),
    ),
    child: child,
  );
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      // One language for now; the sheet still opens so the place is known.
      onTap: () => showAtomSelect<String>(
        context,
        title: l.languageTitle,
        options: [AtomOption(value: 'en', label: l.welcomeLanguage)],
        selected: 'en',
      ),
      semanticLabel: '${l.languageTitle}, ${l.welcomeLanguage}',
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.nav2 : Colors.transparent,
          borderRadius: AtomRadius.brControl,
          border: Border.all(color: AtomColors.navLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.globe,
              size: AtomIcon.inline,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              l.welcomeLanguage,
              style: AtomText.smallButton.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    Widget feature(
      IconData icon,
      AtomTone tone,
      String bold,
      String rest, {
      CustomPainter? painter,
    }) => Padding(
      padding: const EdgeInsets.only(top: AtomSpace.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: AtomRadius.brControl,
            ),
            alignment: Alignment.center,
            child: painter == null
                ? Icon(icon, size: AtomIcon.row, color: tone.fg)
                : CustomPaint(
                    size: const Size.square(AtomIcon.row),
                    painter: painter,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AtomText.body.copyWith(
                  fontSize: 15,
                  height: AtomText.normalHeight,
                  color: AtomColors.text,
                ),
                children: [
                  TextSpan(
                    text: bold,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AtomColors.ink,
                    ),
                  ),
                  TextSpan(text: rest),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brSheetTop,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        26,
        20,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.welcomeTitle,
              style: AtomText.successTitle.copyWith(
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AtomSpace.s2),
          Text(
            l.welcomeBody,
            style: AtomText.body.copyWith(
              fontSize: 15,
              height: 1.5,
              color: AtomColors.muted,
            ),
          ),
          const SizedBox(height: 18 - AtomSpace.s3),
          feature(
            LucideIcons.shoppingBag,
            AtomTone.blue,
            l.welcomeFeaturePaymentsBold,
            l.welcomeFeaturePaymentsRest,
            painter: _BagPainter(AtomTone.blue.fg),
          ),
          feature(
            LucideIcons.funnel,
            AtomTone.amber,
            l.welcomeFeatureOfflineBold,
            l.welcomeFeatureOfflineRest,
          ),
          feature(
            LucideIcons.users,
            AtomTone.green,
            l.welcomeFeatureTeamBold,
            l.welcomeFeatureTeamRest,
          ),
          const Spacer(),
          const SizedBox(height: 18),
          AtomButton(
            label: l.welcomeSignIn,
            onPressed: () => context.push(V2Routes.signIn),
          ),
          const SizedBox(height: 10),
          AtomButton(
            label: l.welcomeBecomeSeller,
            kind: AtomButtonKind.outline,
            onPressed: () => context.push(V2Routes.apply),
          ),
        ],
      ),
    );
  }
}

/// The board's first Welcome glyph (no Lucide match): a bag with a strap
/// line, `M12 2v6` and `M5 8h14l-1 12H6z` on a 24 grid.
class _BagPainter extends CustomPainter {
  _BagPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bag = Path()
      ..moveTo(5, 8)
      ..lineTo(19, 8)
      ..lineTo(18, 20)
      ..lineTo(6, 20)
      ..close();
    canvas
      ..drawLine(const Offset(12, 2), const Offset(12, 8), paint)
      ..drawPath(bag, paint);
  }

  @override
  bool shouldRepaint(_BagPainter old) => old.color != color;
}
