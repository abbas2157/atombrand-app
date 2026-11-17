import 'package:flutter/material.dart';

import '../design/design.dart';
import 'atom_pressable.dart';

/// One choice in [AtomChips].
class AtomChip<T> {
  const AtomChip(this.value, this.label, {this.disabled = false});

  final T value;
  final String label;

  /// A disabled chip is dashed and grey; say why in its [label]
  /// ("Gulberg · taken").
  final bool disabled;
}

/// Two to five fixed choices, picked by tapping (2.3's five share chips).
///
/// For anything longer, or any list that comes from data, use
/// [AtomSelectField]: every list choice has a search box (owner rule).
class AtomChips<T> extends StatelessWidget {
  const AtomChips({
    super.key,
    required this.chips,
    required this.selected,
    required this.onChanged,
  }) : assert(
         chips.length >= 2 && chips.length <= 5,
         'Chips are for 2–5 fixed choices; use AtomSelectField for lists.',
       );

  final List<AtomChip<T>> chips;
  final T? selected;

  /// Null disables every chip.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AtomSpace.s2,
      // Four chips can take two rows at 320dp; without this they touch.
      runSpacing: AtomSpace.s2,
      children: [
        for (final chip in chips)
          _Chip(
            label: chip.label,
            on: chip.value == selected,
            onTap: chip.disabled || onChanged == null
                ? null
                : () => onChanged!(chip.value),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return AtomPressable(
      onTap: onTap,
      selected: on,
      semanticLabel: label,
      focusRadius: AtomRadius.brPill,
      builder: (context, pressed) {
        final Color bg, fg, border;
        if (disabled) {
          bg = AtomColors.surface;
          fg = AtomColors.chevron;
          border = AtomColors.line2;
        } else if (on) {
          bg = AtomColors.primarySoft;
          fg = AtomColors.primary;
          border = AtomColors.primary;
        } else {
          bg = pressed ? AtomColors.surface : AtomColors.paper;
          fg = AtomColors.text;
          border = AtomColors.line2;
        }
        return Container(
          constraints: const BoxConstraints(minHeight: AtomSize.small),
          // The 2px outline when on takes 1 from the padding, so the chip
          // keeps its size.
          padding: on
              ? const EdgeInsets.symmetric(horizontal: 13, vertical: 5)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AtomRadius.brPill,
            // The canvas draws a selected chip's 2px outline as a 1px border
            // plus a 1px inset shadow.
            border: Border.all(color: border, width: on ? 2 : 1),
          ),
          // `widthFactor` keeps the chip the width of its label: a
          // Container told to align its child fills whatever width it is
          // offered instead, which inside the Wrap is the whole row.
          child: Center(
            widthFactor: 1,
            child: Text(label, style: AtomText.smallButton.copyWith(color: fg)),
          ),
        );
      },
    );
  }
}
