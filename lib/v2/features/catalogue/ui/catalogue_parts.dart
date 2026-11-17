import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/catalogue_logic.dart';
import '../data/catalogue_models.dart';

/// Pieces Products, the product form and the brand page share.

/// The status pill's colours (`.st` on 8.1): Live green, In review blue,
/// Out of stock amber, On hold and Closed rose.
AtomTone statusTone(String status) => switch (status) {
  ProductStatus.published => AtomTone.green,
  ProductStatus.pending => AtomTone.blue,
  ProductStatus.outOfStock => AtomTone.amber,
  ProductStatus.onHold || ProductStatus.closed => AtomTone.rose,
  _ => AtomTone.grey,
};

AtomTone tagTone(TagTone t) => switch (t) {
  TagTone.green => AtomTone.green,
  TagTone.amber => AtomTone.amber,
  TagTone.rose => AtomTone.rose,
};

/// A small square tag under a product (`.tag`): availability, AtomPay on,
/// Featured, variants.
class ProductTag extends StatelessWidget {
  const ProductTag(this.label, {super.key, this.tone = AtomTone.grey});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: tone.bg, borderRadius: AtomRadius.brTag),
    child: Text(
      label,
      style: AtomText.tag.copyWith(
        color: tone == AtomTone.grey ? AtomColors.text : tone.fg,
      ),
    ),
  );
}

/// The rounded status pill (`.st`).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final AtomTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: tone.bg,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: AtomText.tag.copyWith(fontSize: 12, color: tone.fg),
    ),
  );
}

/// A white form card (`.fs` on 8.2, `.fcard` on 8.3): a heading, then the
/// fields 14 apart. [number] draws the round step number, green when
/// [done].
class FormCard extends StatelessWidget {
  const FormCard({
    super.key,
    required this.title,
    required this.children,
    this.number,
    this.done = false,
    this.trailing,
  });

  final String title;
  final int? number;
  final bool done;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tone = done ? AtomTone.green : AtomTone.blue;
    return Container(
      decoration: AtomDecor.card,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (number != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: AtomText.tag.copyWith(fontSize: 12, color: tone.fg),
                  ),
                ),
                const SizedBox(width: AtomSpace.s2),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AtomText.listTitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Shares the row without pushing the title off it.
              if (trailing case final t?)
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    widthFactor: 1,
                    child: t,
                  ),
                ),
            ],
          ),
          for (final c in children) ...[const SizedBox(height: 14), c],
        ],
      ),
    );
  }
}

/// Small grey print (`p.tiny`).
class Tiny extends StatelessWidget {
  const Tiny(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: AtomText.small.copyWith(color: AtomColors.faint),
  );
}

/// The white bar at the foot of a form (`.bottombar`).
class FormBottomBar extends StatelessWidget {
  const FormBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(top: BorderSide(color: AtomColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, safe > 14 ? safe + 12 : 20),
      child: child,
    );
  }
}

/// Asks where a photo comes from: the camera or the gallery.
Future<ImageSource?> askPhotoSource(BuildContext context) =>
    showAtomSheet<ImageSource>(
      context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (icon, label, source) in [
              (
                LucideIcons.camera,
                AppLocalizations.of(context).catPickCamera,
                ImageSource.camera,
              ),
              (
                LucideIcons.image,
                AppLocalizations.of(context).catPickGallery,
                ImageSource.gallery,
              ),
            ])
              AtomPressable(
                onTap: () => Navigator.of(context).pop(source),
                semanticLabel: label,
                scaleOnPress: false,
                builder: (context, pressed) => Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  color: pressed ? AtomColors.head : null,
                  child: Row(
                    children: [
                      AtomIconTile(icon: icon, tone: AtomTone.grey, size: 36),
                      const SizedBox(width: AtomSpace.s3),
                      Text(
                        label,
                        style: AtomText.listTitle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
