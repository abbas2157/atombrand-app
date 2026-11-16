import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/catalogue_logic.dart';
import '../data/catalogue_models.dart';
import '../data/catalogue_repository.dart';

/// The ⋯ sheet on Products (8.1): the product at the top, then the actions
/// the person may use. Feature and AtomPay switch in place (the change
/// goes to [onChanged]); the others close the sheet with their action for
/// the list to carry out.
Future<ProductAction?> showProductActions(
  BuildContext context, {
  required ProductRow product,
  required List<ProductAction> actions,
  required ValueChanged<ProductRow> onChanged,
}) => showAtomSheet<ProductAction>(
  context,
  useRootNavigator: true,
  builder: (_) =>
      _ActionsSheet(product: product, actions: actions, onChanged: onChanged),
);

class _ActionsSheet extends ConsumerStatefulWidget {
  const _ActionsSheet({
    required this.product,
    required this.actions,
    required this.onChanged,
  });

  final ProductRow product;
  final List<ProductAction> actions;
  final ValueChanged<ProductRow> onChanged;

  @override
  ConsumerState<_ActionsSheet> createState() => _ActionsSheetState();
}

class _ActionsSheetState extends ConsumerState<_ActionsSheet> {
  late ProductRow _p = widget.product;
  ProductAction? _busy;

  Future<void> _toggle(ProductAction action) async {
    final l = AppLocalizations.of(context);
    if (_busy != null) return;
    setState(() => _busy = action);
    final repo = ref.read(catalogueRepositoryProvider);
    final feature = action == ProductAction.feature;
    final ApiResult<bool> r = feature
        ? await repo.toggleFeature(_p.id)
        : await repo.toggleAtompay(_p.id);
    if (!mounted) return;
    setState(() => _busy = null);
    switch (r) {
      case ApiOk(:final value):
        setState(
          () => _p = feature
              ? _p.copyWith(featured: value)
              : _p.copyWith(atompay: value),
        );
        widget.onChanged(_p);
        ref
          ..invalidate(productDetailProvider(_p.id))
          ..invalidate(brandPageProvider);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: feature
              ? (value ? l.catFeaturedOn : l.catFeaturedOff)
              : (value ? l.catAtompayOn : l.catAtompayOff),
        );
      case ApiErr(:final failure):
        // AtomPay's 409: Atomshop made the whole brand eligible.
        if (!feature && failure.kind == ApiFailureKind.conflict) {
          setState(() => _p = _p.copyWith(atompayBrandWide: true));
          widget.onChanged(_p);
        }
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(AppLocalizations.of(context), failure),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = _p;
    final avail = availabilityTag(p.available, l);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtomThumb(url: p.picture, size: 44),
              const SizedBox(width: AtomSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: AtomText.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        p.isNew || p.prNumber == null
                            ? l.catNewCode
                            : p.prNumber!,
                        formatRs(p.price),
                        p.statusLabel(l),
                      ].join(' · '),
                      style: AtomText.small.copyWith(color: AtomColors.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AtomSpace.s2),
          for (final (i, a) in widget.actions.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AtomColors.surface),
            switch (a) {
              ProductAction.edit => _ActionRow(
                icon: LucideIcons.pencil,
                title: l.catEditProduct,
                note: l.catEditProductNote,
                onTap: () => Navigator.of(context).pop(a),
              ),
              ProductAction.stock => _ActionRow(
                icon: LucideIcons.package,
                title: l.catStockAndSerials,
                note: avail?.$1 ?? l.catNotInStockYet,
                onTap: () => Navigator.of(context).pop(a),
              ),
              ProductAction.feature => _ActionRow(
                icon: LucideIcons.star,
                tone: AtomTone.amber,
                title: l.catFeatureOnPage,
                note: l.catFeatureNote,
                toggled: p.featured,
                busy: _busy == a,
                onTap: () => _toggle(a),
              ),
              ProductAction.atompay => _ActionRow(
                icon: LucideIcons.creditCard,
                tone: AtomTone.blue,
                title: l.catAtompay,
                note: p.atompayBrandWide
                    ? l.catAtompayBrandWideNote
                    : l.catAtompayNote,
                toggled: p.atompayOn,
                busy: _busy == a,
                // Atomshop's brand-wide AtomPay can't be switched here.
                onTap: p.atompayBrandWide ? null : () => _toggle(a),
              ),
              ProductAction.markOut => _ActionRow(
                icon: LucideIcons.ban,
                tone: AtomTone.rose,
                title: l.catMarkOut,
                note: l.catMarkOutNote,
                onTap: () => Navigator.of(context).pop(a),
              ),
              ProductAction.backIn => _ActionRow(
                icon: LucideIcons.circleCheck,
                tone: AtomTone.green,
                title: l.catBackIn,
                note: l.catBackInNote,
                onTap: () => Navigator.of(context).pop(a),
              ),
              ProductAction.delete => _ActionRow(
                icon: LucideIcons.trash2,
                tone: AtomTone.rose,
                title: l.catDeleteProduct,
                note: l.catDeleteNote,
                danger: true,
                onTap: () => Navigator.of(context).pop(a),
              ),
            },
          ],
        ],
      ),
    );
  }
}

/// One action (`.sact`): an icon tile, the title over a grey note, and a
/// switch for the toggles.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.note,
    required this.onTap,
    this.tone = AtomTone.grey,
    this.toggled,
    this.busy = false,
    this.danger = false,
  });

  final IconData icon;
  final AtomTone tone;
  final String title;
  final String note;
  final VoidCallback? onTap;
  final bool? toggled;
  final bool busy;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap ?? (toggled == null ? null : () {}),
      toggled: toggled,
      scaleOnPress: false,
      semanticLabel: '$title, $note',
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        color: pressed ? AtomColors.head : null,
        child: ExcludeSemantics(
          child: Row(
            children: [
              AtomIconTile(icon: icon, tone: tone, size: 36),
              const SizedBox(width: AtomSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AtomText.listTitle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: danger ? AtomColors.rose : AtomColors.ink,
                      ),
                    ),
                    Text(
                      note,
                      style: AtomText.small.copyWith(color: AtomColors.faint),
                    ),
                  ],
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: AtomSpinner(size: 20),
                )
              else if (toggled != null) ...[
                const SizedBox(width: AtomSpace.s2),
                AtomSwitch(
                  value: toggled!,
                  onChanged: onTap == null ? null : (_) => onTap!(),
                  semanticLabel: title,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Back in stock without the Inventory add-on: how many units customers
/// can order (the server wants at least 1). Null when cancelled.
Future<int?> askUnits(BuildContext context) => showAtomSheet<int>(
  context,
  useRootNavigator: true,
  builder: (_) => const _UnitsSheet(),
);

class _UnitsSheet extends StatefulWidget {
  const _UnitsSheet();

  @override
  State<_UnitsSheet> createState() => _UnitsSheetState();
}

class _UnitsSheetState extends State<_UnitsSheet> {
  final _units = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _units.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final n = int.tryParse(_units.text.trim()) ?? 0;
    if (n < 1) {
      setState(() => _error = l.catUnitsError);
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtomSheetHeader(title: l.catBackInTitle),
          const SizedBox(height: AtomSpace.s2),
          Text(
            l.catBackInBody,
            style: AtomText.body.copyWith(color: AtomColors.text),
          ),
          const SizedBox(height: AtomSpace.s4),
          AtomTextField(
            label: l.catUnitsLabel,
            controller: _units,
            autofocus: true,
            error: _error,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AtomSpace.s4),
          AtomButton(label: l.commonSave, onPressed: _save),
        ],
      ),
    );
  }
}
