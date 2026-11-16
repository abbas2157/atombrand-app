import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../core/api/api_result.dart';
import '../design/design.dart';
import 'atom_brand.dart';
import 'atom_button.dart';
import 'atom_pressable.dart';

/// Grey placeholder rows while a list loads: a circle and two lines, still
/// (no shimmer — v2 has no decorative animation).
class AtomLoadingRows extends StatelessWidget {
  const AtomLoadingRows({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).commonLoading,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AtomSpace.gutter,
                  0,
                  AtomSpace.gutter,
                  AtomSpace.s2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AtomSpace.inset,
                  vertical: AtomSpace.s3,
                ),
                decoration: AtomDecor.card,
                child: Row(
                  children: [
                    const _Bone(width: 40, height: 40, circle: true),
                    const SizedBox(width: AtomSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          FractionallySizedBox(
                            widthFactor: 0.7,
                            child: _Bone(height: 12),
                          ),
                          SizedBox(height: 6),
                          FractionallySizedBox(
                            widthFactor: 0.45,
                            child: _Bone(height: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    this.width,
    required this.height,
    this.circle = false,
    this.radius,
  });

  final double? width;
  final double height;
  final bool circle;

  /// Corners other than the 6 of a list row's lines.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AtomColors.skeleton,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle
            ? null
            : radius == null
            ? AtomRadius.brTag
            : BorderRadius.circular(radius!),
      ),
    );
  }
}

/// A whole-area message, drawn as the "Empty lists" board (14.1): a white
/// circle with the icon tile and the logo stripe under it, a heading, a
/// line of explanation, the action as a primary button that hugs its label
/// and an optional second action as a link. Used for empty lists and for
/// errors ([AtomErrorState] draws the error board's tile instead).
class AtomMessageState extends StatelessWidget {
  const AtomMessageState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.tone = AtomTone.grey,
    this.secondaryLabel,
    this.onSecondary,
    this.art = true,
    this.bottomSpace = 0,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AtomTone tone;

  /// A second action under the button, as a link ("Import from Excel").
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// The empty board's circle (true), or the error board's 80 tile with
  /// its 24 title and 15 body (false, 14.7).
  final bool art;

  /// Room kept under the message (the board's 90 above the tab bar).
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final iconColor = tone == AtomTone.grey ? AtomColors.muted : tone.fg;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          32,
          AtomSpace.s6,
          32,
          AtomSpace.s6 + bottomSpace,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (art)
                _EmptyArt(icon: icon, tone: tone, color: iconColor)
              else
                ExcludeSemantics(
                  child: Container(
                    width: AtomSize.stateTile,
                    height: AtomSize.stateTile,
                    decoration: BoxDecoration(
                      color: tone.bg,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AtomRadius.sheet),
                      ),
                    ),
                    child: Icon(icon, size: 36, color: iconColor),
                  ),
                ),
              SizedBox(height: art ? 14 : 14),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: art ? AtomText.heading : AtomText.successTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              if (body != null) ...[
                SizedBox(height: art ? AtomSpace.s3 : 14),
                Text(
                  body!,
                  style: AtomText.body.copyWith(
                    fontSize: art ? 14 : 15,
                    height: 1.5,
                    color: AtomColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: art ? AtomSpace.s3 : AtomSpace.s5),
                AtomButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  expand: false,
                  compact: art,
                  padding: art ? 22 : null,
                ),
              ],
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: AtomSpace.s1),
                AtomTextLink(label: secondaryLabel!, onTap: onSecondary!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.art`: a 120 white circle with a line, the 64 icon tile, and the logo
/// stripe over its bottom edge.
class _EmptyArt extends StatelessWidget {
  const _EmptyArt({
    required this.icon,
    required this.tone,
    required this.color,
  });

  final IconData icon;
  final AtomTone tone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: AtomSize.emptyArt,
        height: AtomSize.emptyArt + 6,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: AtomSize.emptyArt,
              height: AtomSize.emptyArt,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AtomColors.paper,
                shape: BoxShape.circle,
                border: Border.all(color: AtomColors.line),
              ),
              child: Container(
                width: AtomSize.emptyTile,
                height: AtomSize.emptyTile,
                decoration: BoxDecoration(
                  color: tone.bg,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AtomRadius.sheet),
                  ),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
            ),
            const Positioned(bottom: 0, child: AtomStepsStripe(width: 64)),
          ],
        ),
      ),
    );
  }
}

/// A plain blue link (`a` on the boards: 14px, primary) with a 44 tap area.
class AtomTextLink extends StatelessWidget {
  const AtomTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      semanticLabel: label,
      scaleOnPress: false,
      builder: (_, pressed) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AtomSpace.s2),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AtomText.body.copyWith(
                color: pressed ? AtomColors.primaryPressed : AtomColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Something went wrong" with Try again, drawn as the error board (14.7):
/// the rose tile, a 24 title, and Try again as the main button.
class AtomErrorState extends StatelessWidget {
  const AtomErrorState({
    super.key,
    required this.onRetry,
    this.message,
    this.error,
  });

  final VoidCallback onRetry;

  /// A plain explanation; defaults to "Something went wrong".
  final String? message;

  /// The failure itself, when the screen has it: a 403 (not in your role)
  /// then shows 13.3's "Your role doesn't include this" instead of an
  /// error with Try again.
  final Object? error;

  /// What a 403 shows (13.3), set by `features/states` when the router is
  /// built; null falls back to the error.
  static Widget Function(BuildContext context, ApiFailure failure)? roleRefusal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final refusal = roleRefusal;
    final f = error;
    if (refusal != null &&
        f is ApiFailure &&
        (f.kind == ApiFailureKind.notInRole ||
            f.kind == ApiFailureKind.ownerOnly)) {
      return refusal(context, f);
    }
    return AtomMessageState(
      icon: LucideIcons.circleAlert,
      tone: AtomTone.rose,
      art: false,
      title: message ?? l.commonSomethingWrong,
      actionLabel: l.commonTryAgain,
      onAction: onRetry,
    );
  }
}

/// The loading board's list card (14.2): one card, rows split by a line,
/// each a 40 rounded tile and two grey lines.
class AtomLoadingCard extends StatelessWidget {
  const AtomLoadingCard({super.key, this.count = 3});

  final int count;

  static const _widths = [(0.7, 0.45), (0.6, 0.4), (0.75, 0.5)];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).commonLoading,
      child: ExcludeSemantics(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: AtomDecor.card,
          // Over the children too, so their fill doesn't hide it at the
          // rounded corners.
          foregroundDecoration: AtomDecor.cardOutline,
          child: Column(
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  padding: const EdgeInsets.all(AtomSpace.inset),
                  decoration: i == 0
                      ? null
                      : const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AtomColors.line),
                          ),
                        ),
                  child: Row(
                    children: [
                      const _Bone(
                        width: 40,
                        height: 40,
                        radius: AtomRadius.control,
                      ),
                      const SizedBox(width: AtomSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FractionallySizedBox(
                              widthFactor: _widths[i % 3].$1,
                              child: const _Bone(
                                height: 12,
                                radius: AtomRadius.control,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FractionallySizedBox(
                              widthFactor: _widths[i % 3].$2,
                              child: const _Bone(
                                height: 10,
                                radius: AtomRadius.control,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The logo stripe and a short caption under a loading screen ("Getting
/// today's work…", 14.2).
class AtomLoadingCaption extends StatelessWidget {
  const AtomLoadingCaption({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AtomStepsStripe(),
          const SizedBox(height: AtomSpace.s2),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AtomText.small.copyWith(color: AtomColors.faint),
          ),
        ],
      ),
    );
  }
}
