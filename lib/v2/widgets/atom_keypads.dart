import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../core/format/money.dart';
import '../design/design.dart';
import 'atom_pressable.dart';

/// The amount over the money keypad: `Rs 8,400` at 44/800, and the amount
/// in words under it so a missing zero is caught by ear.
class AtomAmountDisplay extends StatelessWidget {
  const AtomAmountDisplay({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final words = amountInWords(amount);
    return Semantics(
      liveRegion: true,
      label: words.isEmpty ? formatRs(0) : words,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Rs ${groupDigits(amount)}',
                  style: AtomText.keypadAmount.copyWith(
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 18),
                child: Text(
                  words,
                  textAlign: TextAlign.center,
                  style: AtomText.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Typed digits held as the amount the keypad builds.
///
/// Leading zeros are dropped and the amount is capped at [maxDigits], so a
/// slip can't make an eight-digit payment.
class MoneyKeypadValue {
  const MoneyKeypadValue([this.digits = '']);

  static const maxDigits = 7;

  final String digits;

  int get amount => digits.isEmpty ? 0 : int.parse(digits);

  MoneyKeypadValue press(String key) {
    final next = '$digits$key'.replaceFirst(RegExp(r'^0+'), '');
    return MoneyKeypadValue(
      next.length > maxDigits ? next.substring(0, maxDigits) : next,
    );
  }

  MoneyKeypadValue delete() => MoneyKeypadValue(
    digits.isEmpty ? '' : digits.substring(0, digits.length - 1),
  );

  static MoneyKeypadValue of(int amount) =>
      MoneyKeypadValue(amount <= 0 ? '' : '$amount');
}

/// The money keypad: 1–9, 00, 0, delete. 50 tall keys, 14 corners.
class AtomMoneyKeypad extends StatelessWidget {
  const AtomMoneyKeypad({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MoneyKeypadValue value;
  final ValueChanged<MoneyKeypadValue> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0'];
    return _KeyGrid(
      height: 50,
      gap: 8,
      children: [
        for (final k in keys)
          _Key(
            label: k,
            onTap: () => onChanged(value.press(k)),
            child: Text(k, style: _keyStyle),
          ),
        _Key(
          label: l.keypadDelete,
          onTap: () => onChanged(value.delete()),
          child: const Icon(
            LucideIcons.delete,
            size: 24,
            color: AtomColors.ink,
          ),
        ),
      ],
    );
  }
}

/// The four PIN dots. [error] shakes nothing (no decorative motion); it
/// turns the dots rose.
class AtomPinDots extends StatelessWidget {
  const AtomPinDots({
    super.key,
    required this.filled,
    this.length = 4,
    this.error = false,
    this.onDark = false,
  });

  final int filled;
  final int length;
  final bool error;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.pinDotsLabel(filled, length),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < length; i++)
            Container(
              margin: EdgeInsets.only(left: i == 0 ? 0 : 18),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i >= filled
                    ? Colors.transparent
                    : error
                    ? (onDark ? AtomColors.darkRose : AtomColors.rose)
                    : (onDark ? Colors.white : AtomColors.primary),
                border: Border.all(
                  width: 2,
                  color: error
                      ? (onDark ? AtomColors.darkRose : AtomColors.rose)
                      : i < filled
                      ? (onDark ? Colors.white : AtomColors.primary)
                      : (onDark ? AtomColors.darkDot : AtomColors.line2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The PIN pad (`.keys`): 62 tall keys, easy with a thumb at the shop
/// door. The bottom-left key is the fingerprint when [onBiometric] is
/// given, and blank otherwise.
class AtomPinPad extends StatelessWidget {
  const AtomPinPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.onDark = false,
    this.letters = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
  final bool onDark;

  /// ABC under the digits (`.key small`). The 2.4 and 3.1 boards show
  /// digits only.
  final bool letters;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fg = onDark ? Colors.white : AtomColors.ink;
    final bg = onDark ? AtomColors.nav2 : AtomColors.surface;
    final pressedBg = onDark ? AtomColors.nav3 : null;
    const abc = {
      '2': 'ABC', '3': 'DEF', '4': 'GHI', '5': 'JKL', '6': 'MNO',
      '7': 'PQRS', '8': 'TUV', '9': 'WXYZ', //
    };
    Widget digit(String d) => _Key(
      label: d,
      background: bg,
      pressedBackground: pressedBg,
      onTap: () => onDigit(d),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(d, style: _keyStyle.copyWith(color: fg)),
          if (letters && abc[d] != null)
            Text(
              abc[d]!,
              style: AtomText.tag.copyWith(
                letterSpacing: 1.2,
                color: onDark ? AtomColors.navMuted : AtomColors.faint,
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: _KeyGrid(
        height: AtomSize.pinKey,
        gap: 10,
        children: [
          for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
            digit(d),
          if (onBiometric != null)
            _Key(
              label: l.keypadFingerprint,
              background: Colors.transparent,
              onTap: onBiometric!,
              child: Icon(LucideIcons.fingerprint, size: 28, color: fg),
            )
          else
            const SizedBox.shrink(),
          digit('0'),
          _Key(
            label: l.keypadDelete,
            background: Colors.transparent,
            onTap: onDelete,
            child: Icon(LucideIcons.delete, size: 26, color: fg),
          ),
        ],
      ),
    );
  }
}

final _keyStyle = AtomText.heading.copyWith(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  height: 1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({
    required this.children,
    required this.height,
    required this.gap,
  });

  final List<Widget> children;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var r = 0; r < children.length; r += 3) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
          child: Row(
            children: [
              for (var c = r; c < r + 3; c++) ...[
                if (c > r) SizedBox(width: gap),
                Expanded(
                  child: SizedBox(
                    height: height,
                    child: c < children.length ? children[c] : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    // Keys keep their size at any text size: they are touch targets, and
    // the digits are read from position as much as from the glyph.
    return MediaQuery.withNoTextScaling(
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.child,
    this.background = AtomColors.surface,
    this.pressedBackground,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final Color background;

  /// The fill while pressed; the light keys' grey when null.
  final Color? pressedBackground;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      semanticLabel: label,
      focusRadius: AtomRadius.brCard,
      builder: (context, pressed) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pressed && pressedBackground != null
              ? pressedBackground
              : pressed && background != Colors.transparent
              ? const Color(0xFFE9ECF2)
              : pressed
              ? AtomColors.surface
              : background,
          borderRadius: AtomRadius.brCard,
        ),
        child: ExcludeSemantics(child: child),
      ),
    );
  }
}
