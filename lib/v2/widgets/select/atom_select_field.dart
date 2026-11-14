import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/app_localizations.dart';
import '../../design/design.dart';
import '../atom_field.dart';
import '../atom_pressable.dart';
import 'atom_select_filter.dart';
import 'atom_select_sheet.dart';

/// A labelled dropdown that opens the searchable sheet.
///
/// Use this for every list choice: city, area, category, brand, product,
/// manager, relation, collection day, the lock timer. Never a plain
/// dropdown and never a typed field (owner rule, 4 Nov).
///
/// The field shows [valueLabel], which the caller keeps with the value; it
/// can't be looked up here because the options may only be loaded when the
/// sheet opens.
class AtomSelectField<T> extends StatelessWidget {
  const AtomSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
    this.options,
    this.load,
    this.sheetTitle,
    this.searchHint,
    this.mineLabel,
    this.othersLabel,
    this.placeholder,
    this.hint,
    this.error,
    this.labelNote,
    this.offline = false,
  });

  final String label;
  final T? value;
  final String? valueLabel;

  /// Null disables the field; say why in [hint] or [labelNote].
  final ValueChanged<T>? onChanged;
  final List<AtomOption<T>>? options;
  final AtomOptionLoader<T>? load;

  /// Defaults to [label].
  final String? sheetTitle;
  final String? searchHint;
  final String? mineLabel;
  final String? othersLabel;

  /// Defaults to "Choose".
  final String? placeholder;
  final String? hint;
  final String? error;
  final String? labelNote;
  final bool offline;

  Future<void> _open(BuildContext context) async {
    final picked = await showAtomSelect<T>(
      context,
      title: sheetTitle ?? label,
      options: options,
      load: load,
      selected: value,
      searchHint: searchHint,
      mineLabel: mineLabel,
      othersLabel: othersLabel,
      offline: offline,
    );
    if (picked != null && picked != value) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AtomField(
      label: label,
      labelNote: labelNote,
      hint: hint,
      error: error,
      child: AtomSelectBox(
        text: valueLabel,
        placeholder: placeholder,
        semanticLabel: label,
        error: error != null,
        onTap: onChanged == null ? null : () => _open(context),
      ),
    );
  }
}

/// A labelled dropdown for several choices.
class AtomMultiSelectField<T> extends StatelessWidget {
  const AtomMultiSelectField({
    super.key,
    required this.label,
    required this.values,
    required this.summary,
    required this.onChanged,
    this.options,
    this.load,
    this.sheetTitle,
    this.searchHint,
    this.mineLabel,
    this.othersLabel,
    this.placeholder,
    this.hint,
    this.error,
    this.offline = false,
  });

  final String label;
  final Set<T> values;

  /// What the closed field shows, e.g. "Model Town" or "3 areas".
  final String? summary;
  final ValueChanged<Set<T>>? onChanged;
  final List<AtomOption<T>>? options;
  final AtomOptionLoader<T>? load;
  final String? sheetTitle;
  final String? searchHint;
  final String? mineLabel;
  final String? othersLabel;
  final String? placeholder;
  final String? hint;
  final String? error;
  final bool offline;

  Future<void> _open(BuildContext context) async {
    final picked = await showAtomMultiSelect<T>(
      context,
      title: sheetTitle ?? label,
      options: options,
      load: load,
      selected: values,
      searchHint: searchHint,
      mineLabel: mineLabel,
      othersLabel: othersLabel,
      offline: offline,
    );
    if (picked != null) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AtomField(
      label: label,
      hint: hint,
      error: error,
      child: AtomSelectBox(
        text: values.isEmpty ? null : summary,
        placeholder: placeholder,
        semanticLabel: label,
        error: error != null,
        onTap: onChanged == null ? null : () => _open(context),
      ),
    );
  }
}

/// The closed dropdown: the value, or a grey placeholder, and a ▾.
/// Also used on its own for the ▾ filters above lists.
class AtomSelectBox extends StatelessWidget {
  const AtomSelectBox({
    super.key,
    required this.text,
    required this.onTap,
    this.placeholder,
    this.semanticLabel,
    this.error = false,
  });

  final String? text;
  final VoidCallback? onTap;
  final String? placeholder;
  final String? semanticLabel;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final big = MediaQuery.textScalerOf(context).scale(10) >= 15;
    final shown =
        text ?? placeholder ?? AppLocalizations.of(context).commonChoose;
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      semanticLabel: semanticLabel == null ? shown : '$semanticLabel, $shown',
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: AtomSize.control),
        padding: const EdgeInsets.fromLTRB(AtomSpace.inset, 12, 12, 12),
        decoration:
            atomInputBox(
              focused: false,
              error: error,
              disabled: disabled,
            ).copyWith(
              border: pressed && !error
                  ? Border.all(color: AtomColors.chevron)
                  : null,
            ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                // One line with "…" as the board's `.select .v`; at large
                // text it wraps so nothing is lost. The full value is read
                // out from the label.
                child: Text(
                  shown,
                  maxLines: big ? null : 1,
                  overflow: big ? null : TextOverflow.ellipsis,
                  style: AtomText.input.copyWith(
                    color: text == null
                        ? AtomColors.placeholder
                        : disabled
                        ? AtomColors.muted
                        : AtomColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                LucideIcons.chevronDown,
                size: AtomIcon.row,
                color: AtomColors.chevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
