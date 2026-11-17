import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/tour_due.dart';

/// The first-time tour (17.7): the last step on the way in, once per phone.
///
/// Four steps, as on the FirstTour board: confirming orders, bulk deals,
/// working without signal and Ask Atom. Skip and Start end it; the guards
/// then open Home.
class FirstTourScreen extends ConsumerStatefulWidget {
  const FirstTourScreen({super.key});

  @override
  ConsumerState<FirstTourScreen> createState() => _FirstTourScreenState();
}

class _FirstTourScreenState extends ConsumerState<FirstTourScreen> {
  int _i = 0;

  void _finish() => ref.read(tourDueProvider.notifier).done();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slides = <Widget>[
      _ArtSlide(
        icon: LucideIcons.package,
        title: l.tourOrdersTitle,
        text: l.tourOrdersText,
        chip1: l.tourOrdersChip1,
        chip2: l.tourOrdersChip2,
      ),
      _ArtSlide(
        icon: LucideIcons.funnel,
        title: l.tourBulkTitle,
        text: l.tourBulkText,
        chip1: l.tourBulkChip1,
        chip2: l.tourBulkChip2,
      ),
      _ArtSlide(
        icon: LucideIcons.wifiOff,
        title: l.tourOfflineTitle,
        text: l.tourOfflineText,
        chip1: l.tourOfflineChip1,
        chip2: l.tourOfflineChip2,
      ),
      _ArtSlide(
        title: l.tourAtomTitle,
        text: l.tourAtomText,
        chip1: l.tourAtomChip1,
        chip2: l.tourAtomChip2,
      ),
    ];
    final i = _i.clamp(0, slides.length - 1);
    final last = i == slides.length - 1;
    final pad = MediaQuery.paddingOf(context);

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AtomColors.nav,
          body: Padding(
            padding: EdgeInsets.only(top: pad.top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Only Skip, at the end (16.7).
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 16,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        _SkipButton(label: l.tourSkip, onTap: _finish),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                            child: slides[i],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 34 + pad.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: l.tourStep(i + 1, slides.length),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var k = 0; k < slides.length; k++)
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                    start: k == 0 ? 0 : 8,
                                  ),
                                  width: k == i ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: k == i
                                        ? Colors.white
                                        : AtomColors.darkDot,
                                    borderRadius: AtomRadius.brPill,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AtomButton(
                        label: last ? l.tourStart : l.tourNext,
                        kind: AtomButtonKind.light,
                        onPressed: last
                            ? _finish
                            : () => setState(() => _i = i + 1),
                      ),
                    ],
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

/// `.btn-ghost-dark`, 38 tall, 14 text; 48 tap area.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (_, pressed) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AtomSize.tapTarget),
        child: Center(
          widthFactor: 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: pressed ? AtomColors.nav2 : Colors.transparent,
              borderRadius: AtomRadius.brControl,
              border: Border.all(color: AtomColors.navLine),
            ),
            child: Text(
              label,
              style: AtomText.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- slides

/// One step of the tour, as on the FirstTour board: a round picture with a
/// white tile in the middle and two chips showing the thing in use, then
/// the title and one line.
class _ArtSlide extends StatelessWidget {
  const _ArtSlide({
    required this.title,
    required this.text,
    required this.chip1,
    required this.chip2,
    this.icon,
  });

  final String title;
  final String text;
  final String chip1;
  final String chip2;

  /// The glyph in the tile; null shows Ask Atom's mark.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 280,
          height: 240,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AtomColors.nav2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AtomColors.navLine),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: icon == null
                      ? const AtomAiMark(size: 92)
                      : Icon(icon, size: 56, color: AtomColors.primary),
                ),
              ),
              PositionedDirectional(top: 26, start: 2, child: _Chip(chip1)),
              PositionedDirectional(bottom: 34, end: 0, child: _Chip(chip2)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AtomText.successTitle.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AtomText.body.copyWith(
            color: AtomColors.navText,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// `.art .chip`: a white pill floating on the picture.
class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AtomRadius.brPill,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: AtomText.secondary.copyWith(
          color: AtomColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
