import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';

/// An error under a field (`.err`): a 14 alert icon, then 13/500 rose.
class AtomFieldError extends StatelessWidget {
  const AtomFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Centres the 14 icon on the first line of 13px text.
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            LucideIcons.circleAlert,
            size: 14,
            color: AtomText.fieldError.color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AtomText.fieldError)),
      ],
    );
  }
}

/// A field's frame: the label above, the control, then a hint or an error.
///
/// From the "Inputs" board: label 13/600; a note beside the label in grey
/// ("can't change"); hint 13 grey; error 13 rose, which replaces the hint.
class AtomField extends StatelessWidget {
  const AtomField({
    super.key,
    required this.label,
    required this.child,
    this.labelNote,
    this.labelTrailing,
    this.hint,
    this.error,
    this.labelNoteInline = false,
    this.countHint = false,
  });

  final String label;
  final Widget child;

  /// [hint] is a character count (`.count`): 12px and flush right.
  final bool countHint;

  /// Grey text at the end of the label row.
  final String? labelNote;

  /// [labelNote] right after the label (`<label>Email <span class="opt">`)
  /// instead of at the end of the row (`.flabel`).
  final bool labelNoteInline;

  /// A widget at the end of the label row, such as a link.
  final Widget? labelTrailing;
  final String? hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final below = error ?? hint;
    final scaler = MediaQuery.textScalerOf(context);
    // A link beside the label ("Forgot password?") keeps its 48-tall tap
    // area without making the label row 48 tall (`.flabel` is one text
    // line): it hangs over the row, centred on the label. At large text it
    // shares the row with the label instead.
    if (labelTrailing != null && labelNote == null && scaler.scale(10) < 15) {
      final line = (TextPainter(
        text: TextSpan(text: label, style: AtomText.fieldLabel),
        textScaler: scaler,
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout()).height;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _column(Text(label, style: AtomText.fieldLabel), below),
          PositionedDirectional(
            end: 0,
            top: line / 2 - AtomSize.tapTarget / 2,
            height: AtomSize.tapTarget,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: labelTrailing,
            ),
          ),
        ],
      );
    }
    if (labelNoteInline && labelNote != null && labelTrailing == null) {
      return _column(
        Text.rich(
          TextSpan(
            text: '$label ',
            children: [
              TextSpan(
                text: labelNote,
                style: AtomText.fieldLabel.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AtomColors.faint,
                ),
              ),
            ],
          ),
          style: AtomText.fieldLabel,
        ),
        below,
      );
    }
    return _column(
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: AtomText.fieldLabel)),
          // Shares the row with the label at large text sizes.
          // Flush right, as on the boards ("Forgot password?").
          if (labelTrailing != null)
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: labelTrailing!,
              ),
            ),
          // Wraps under itself at large text instead of running off.
          // Flush right, like the trailing link (`.flabel` is
          // space-between).
          if (labelNote != null)
            Flexible(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  labelNote!,
                  textAlign: TextAlign.end,
                  style: AtomText.fieldLabel.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AtomColors.faint,
                  ),
                ),
              ),
            ),
        ],
      ),
      below,
    );
  }

  Widget _column(Widget labelRow, String? below) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // An empty label (a search box with a placeholder only) has no row.
        if (label.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: labelRow),
        child,
        if (below != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: error != null,
              child: error == null
                  ? Text(
                      below,
                      textAlign: countHint ? TextAlign.end : TextAlign.start,
                      style: AtomText.secondary.copyWith(
                        color: AtomColors.faint,
                        fontSize: countHint ? 12 : null,
                      ),
                    )
                  : AtomFieldError(below),
            ),
          ),
      ],
    );
  }
}

/// The box shared by text inputs and the dropdown field: 50 tall, 10
/// corners, a 3px soft ring when focused (rose when in error).
BoxDecoration atomInputBox({
  required bool focused,
  required bool error,
  required bool disabled,
}) {
  final Color border = error
      ? AtomColors.rose
      : focused
      ? AtomColors.primary
      : AtomColors.line2;
  final Color? ring = error
      ? AtomColors.roseSoft
      : focused
      ? AtomColors.primarySoft
      : null;
  return BoxDecoration(
    color: disabled ? AtomColors.surface : AtomColors.paper,
    borderRadius: AtomRadius.brControl,
    border: Border.all(color: border),
    boxShadow: ring == null
        ? null
        : [BoxShadow(color: ring, spreadRadius: 3, blurRadius: 0)],
  );
}

/// A labelled text input.
class AtomTextField extends StatefulWidget {
  const AtomTextField({
    super.key,
    required this.label,
    this.controller,
    this.placeholder,
    this.labelNote,
    this.hint,
    this.error,
    this.enabled = true,
    this.prefix,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.autofillHints,
    this.minLines,
    this.boxHeight = AtomSize.control,
    this.labelNoteInline = false,
    this.countHint = false,
  });

  /// [labelNote] right after the label, as [AtomField.labelNoteInline].
  final bool labelNoteInline;

  /// [hint] is a character count, as [AtomField.countHint].
  final bool countHint;

  /// A text area (`.ta`): at least this many lines, growing as typed.
  /// Null is one line.
  final int? minLines;

  /// The box's height at the default text size: 50, or 46 / 48 where a
  /// board has a tighter form.
  final double boxHeight;

  final String label;
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelNote;
  final String? hint;
  final String? error;
  final bool enabled;

  /// Shown inside the box before the text, e.g. "Rs".
  final Widget? prefix;

  /// Shown inside the box after the text, e.g. a show-password button.
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Given, the keyboard's action key no longer closes the keyboard (the
  /// field keeps its focus), for typing several codes in a row.
  final VoidCallback? onEditingComplete;
  final Iterable<String>? autofillHints;

  @override
  State<AtomTextField> createState() => _AtomTextFieldState();
}

class _AtomTextFieldState extends State<AtomTextField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AtomTextField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _own)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    return AtomField(
      label: widget.label,
      labelNote: widget.labelNote,
      labelNoteInline: widget.labelNoteInline,
      hint: widget.hint,
      countHint: widget.countHint,
      error: widget.error,
      child: Container(
        constraints: BoxConstraints(minHeight: widget.boxHeight),
        padding: const EdgeInsets.symmetric(horizontal: AtomSpace.inset),
        decoration: atomInputBox(
          focused: _focus.hasFocus,
          error: hasError,
          disabled: !widget.enabled,
        ),
        child: Row(
          crossAxisAlignment: widget.minLines == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (widget.prefix != null) ...[
              DefaultTextStyle(
                // `.input` is faint; a "Rs" before the amount inherits it.
                style: AtomText.input.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AtomColors.faint,
                ),
                child: IconTheme(
                  data: const IconThemeData(
                    color: AtomColors.faint,
                    size: AtomIcon.row,
                  ),
                  child: widget.prefix!,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                inputFormatters: widget.inputFormatters,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                onEditingComplete: widget.onEditingComplete,
                autofillHints: widget.autofillHints,
                minLines: widget.minLines,
                maxLines: widget.minLines == null ? 1 : null,
                style: AtomText.input.copyWith(
                  color: widget.enabled ? AtomColors.ink : AtomColors.muted,
                ),
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  // The box is drawn by the Container, so the field itself
                  // has no border, fill or padding of its own.
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: widget.minLines != null
                        ? 12
                        // The box (border included) is boxHeight: the
                        // text line is 24 (16 at Material's 1.5).
                        : (widget.boxHeight - 2 - 24) / 2,
                  ),
                  semanticCounterText: '',
                ),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}
