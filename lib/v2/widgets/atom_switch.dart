import 'package:flutter/material.dart';

import '../design/design.dart';
import 'atom_pressable.dart';

/// The one v2 switch: 46×28, green when on, grey when off.
///
/// The knob slide is one of only two animations v2 allows. Disabled draws at
/// 45%; put the reason in the row's second line ("Needs internet").
class AtomSwitch extends StatelessWidget {
  const AtomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return AtomPressable(
      onTap: enabled ? () => onChanged!(!value) : null,
      isButton: false,
      toggled: value,
      semanticLabel: semanticLabel,
      scaleOnPress: false,
      focusRadius: AtomRadius.brPill,
      builder: (context, _) => Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: AtomSize.switchWidth,
          height: AtomSize.switchHeight,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AtomColors.green : AtomColors.line2,
            borderRadius: AtomRadius.brPill,
          ),
          child: AnimatedAlign(
            duration: AtomMotion.knob,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33101828),
                    blurRadius: 2,
                    offset: Offset(0, 1),
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
