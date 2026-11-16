import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_pressable.dart';
import 'atom_spinner.dart';

enum AtomButtonKind {
  primary,
  outline,
  danger,
  whatsapp,

  /// White on a navy screen.
  light,

  /// A navy-line outline on a navy screen.
  ghostDark,
}

/// The v2 button: full width and 50 tall, or small (36 tall, 48 tap area).
///
/// States, from the "Buttons" board:
/// - pressed: 98% and a darker fill;
/// - disabled: grey fill, with the reason in an [AtomButtonReason] note
///   above the button ("Enter an amount"); the label stays the action;
/// - [saving]: a spinner and "Saving…", and taps are ignored.
class AtomButton extends StatelessWidget {
  const AtomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AtomButtonKind.primary,
    this.icon,
    this.saving = false,
    this.savingLabel,
    this.small = false,
    this.expand = true,
    this.iconColor,
    this.compact = false,
    this.padding,
    this.oneLine = false,
    this.fontSize,
  });

  const AtomButton.small({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AtomButtonKind.outline,
    this.icon,
    this.saving = false,
    this.savingLabel,
    this.iconColor,
  }) : small = true,
       expand = false,
       compact = false,
       padding = null,
       oneLine = false,
       fontSize = null;

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AtomButtonKind kind;
  final IconData? icon;

  /// The icon's colour when it isn't the label's (2.1's primary
  /// fingerprint on an outline button).
  final Color? iconColor;
  final bool saving;

  /// Defaults to "Saving…".
  final String? savingLabel;
  final bool small;

  /// Full-size buttons fill the width by default.
  final bool expand;

  /// 46 tall with a 15px label: the buttons inside a sheet's footer and on
  /// an empty list (`.btn` at height 46, 15px; 14.1, 19.18).
  final bool compact;

  /// Side padding for a button that hugs its label (14.1: 22).
  final double? padding;

  /// The label stays on one line, shrinking a little on a narrow phone
  /// ("WhatsApp Atomshop · +92 333 1214955", 17.2). Large text still
  /// wraps.
  final bool oneLine;

  /// The label's size when a board sets its own (`.hb .btn`: 14).
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !saving;
    final text = saving
        ? (savingLabel ?? AppLocalizations.of(context).commonSaving)
        : label;
    // A WhatsApp button always carries WhatsApp's mark.
    final icon =
        this.icon ??
        (kind == AtomButtonKind.whatsapp ? AtomBrandIcons.whatsapp : null);

    return AtomPressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: text,
      builder: (context, pressed) {
        final s = _style(pressed, disabled: onPressed == null && !saving);
        final textStyle = (small ? AtomText.smallButton : AtomText.button)
            .copyWith(color: s.fg, fontSize: fontSize ?? (compact ? 15 : null));

        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (saving)
              Padding(
                padding: const EdgeInsets.only(right: AtomSpace.s2),
                child: AtomSpinner(
                  size: small ? 14 : 18,
                  color: s.spinner,
                  track: s.spinnerTrack,
                ),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: AtomSpace.s2),
                child: Icon(
                  icon,
                  size: small ? AtomIcon.inline : AtomIcon.row,
                  color: iconColor ?? s.fg,
                ),
              ),
            Flexible(
              child:
                  oneLine && MediaQuery.textScalerOf(context).scale(1) <= 1.15
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: textStyle,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    )
                  : Text(text, style: textStyle, textAlign: TextAlign.center),
            ),
          ],
        );

        final box = Container(
          constraints: BoxConstraints(
            minHeight: small
                ? AtomSize.small
                : compact
                ? AtomSize.compactButton
                : AtomSize.control,
            minWidth: expand ? double.infinity : 0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: padding ?? (small ? AtomSpace.s3 : 18),
            // A compact button is 44 tall like the boards' `height:44px`
            // even when its label takes two lines (15px x2 = 36).
            vertical: compact ? 4 : AtomSpace.s2,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: s.border),
          ),
          child: content,
        );
        return Opacity(
          opacity: saving ? 0.85 : 1,
          // A button that doesn't fill the width hugs its label (`.mini`,
          // 14.1's action) instead of stretching to what it is given.
          child: expand ? box : IntrinsicWidth(child: box),
        );
      },
    );
  }

  _ButtonStyle _style(bool pressed, {required bool disabled}) {
    if (disabled) {
      return const _ButtonStyle(
        bg: AtomColors.disabledFill,
        fg: AtomColors.disabledText,
        border: Colors.transparent,
      );
    }
    switch (kind) {
      case AtomButtonKind.primary:
        return _ButtonStyle(
          bg: pressed ? AtomColors.primaryPressed : AtomColors.primary,
          fg: Colors.white,
          border: Colors.transparent,
          spinner: Colors.white,
          spinnerTrack: Colors.white38,
        );
      case AtomButtonKind.outline:
        return _ButtonStyle(
          bg: pressed ? AtomColors.surface : AtomColors.paper,
          fg: AtomColors.ink,
          border: AtomColors.line2,
        );
      case AtomButtonKind.danger:
        return _ButtonStyle(
          bg: pressed ? AtomColors.noteRoseText : AtomColors.rose,
          fg: Colors.white,
          border: Colors.transparent,
          spinner: Colors.white,
          spinnerTrack: Colors.white38,
        );
      case AtomButtonKind.whatsapp:
        return _ButtonStyle(
          bg: pressed ? AtomColors.noteGreenText : AtomColors.whatsapp,
          fg: Colors.white,
          border: Colors.transparent,
          spinner: Colors.white,
          spinnerTrack: Colors.white38,
        );
      case AtomButtonKind.ghostDark:
        return _ButtonStyle(
          bg: pressed ? AtomColors.nav2 : Colors.transparent,
          fg: Colors.white,
          border: AtomColors.navLine,
          spinner: Colors.white,
          spinnerTrack: Colors.white38,
        );
      case AtomButtonKind.light:
        return _ButtonStyle(
          bg: pressed ? const Color(0xFFEEF1F7) : Colors.white,
          fg: AtomColors.nav,
          border: Colors.transparent,
        );
    }
  }
}

/// Why the button under it is off ("Type the customer's name"), as a short
/// line above it. The button keeps its own short label, so at large text it
/// stays one line instead of growing to fit the reason. Screen readers hear
/// the reason when it changes, and again just before the button.
class AtomButtonReason extends StatelessWidget {
  const AtomButtonReason({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AtomSpace.s2),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1, right: 6),
              child: Icon(
                LucideIcons.info,
                size: AtomIcon.inline,
                color: AtomColors.muted,
              ),
            ),
            Expanded(child: Text(reason, style: AtomText.secondary)),
          ],
        ),
      ),
    );
  }
}

class _ButtonStyle {
  const _ButtonStyle({
    required this.bg,
    required this.fg,
    required this.border,
    this.spinner = AtomColors.primary,
    this.spinnerTrack = AtomColors.line2,
  });

  final Color bg;
  final Color fg;
  final Color border;
  final Color spinner;
  final Color spinnerTrack;
}
