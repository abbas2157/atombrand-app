import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_field.dart';
import 'atom_pressable.dart';

/// How strong a new password is, 0 (empty) to 4.
///
/// One point each for: 8 or more characters, letters in both cases, a
/// digit, anything else (a symbol or a space), and 10 or more characters. Under 8 characters it is
/// never above 1, because the server refuses it anyway.
int passwordStrength(String p) {
  if (p.isEmpty) return 0;
  var score = 0;
  if (p.length >= 8) score++;
  if (RegExp('[a-z]').hasMatch(p) && RegExp('[A-Z]').hasMatch(p)) score++;
  if (RegExp(r'\d').hasMatch(p)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
  // Length counts too: board 2.3 rates "usman2026pk" Good.
  if (p.length >= 10) score++;
  if (p.length < 8) return 1;
  return score.clamp(1, 4);
}

/// A password with a lock, an eye to show it, and (for a new password) a
/// strength meter under it.
class AtomPasswordField extends StatefulWidget {
  const AtomPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.hint,
    this.placeholder,
    this.showStrength = false,
    this.labelTrailing,
    this.newPassword = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.reveal = true,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;

  /// The eye that shows the password. "Type it again" has none on the
  /// boards (2.3, 4.3).
  final bool reveal;

  /// The field's focus, when the screen moves it.
  final FocusNode? focusNode;
  final String? error;
  final String? hint;

  /// Grey text inside the empty field.
  final String? placeholder;

  /// The four-bar meter and its word, for choosing a new password.
  final bool showStrength;

  /// A link at the end of the label row ("Forgot password?").
  final Widget? labelTrailing;

  /// Autofill offers to save a new password rather than fill an old one.
  final bool newPassword;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AtomPasswordField> createState() => _AtomPasswordFieldState();
}

class _AtomPasswordFieldState extends State<AtomPasswordField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(AtomPasswordField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  void _changed() {
    if (widget.showStrength) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final strength = passwordStrength(widget.controller.text);
    final strengthWord = switch (strength) {
      1 => l.passwordWeak,
      2 => l.passwordFair,
      3 => l.passwordGood,
      _ => l.passwordStrong,
    };
    final strengthColour = switch (strength) {
      1 => AtomColors.rose,
      2 => AtomColors.amberInk,
      _ => AtomColors.green,
    };
    final showMeter =
        widget.showStrength && strength > 0 && widget.error == null;

    final box = Container(
      constraints: const BoxConstraints(minHeight: AtomSize.control),
      padding: const EdgeInsets.only(left: AtomSpace.inset),
      decoration: atomInputBox(
        focused: _focus.hasFocus,
        error: widget.error != null,
        disabled: false,
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.lock,
            size: AtomIcon.row,
            color: AtomColors.faint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: !_show,
              autofillHints: [
                widget.newPassword
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              style: AtomText.input,
              decoration: InputDecoration(
                semanticCounterText: '',
                hintText: widget.placeholder,
                hintStyle: AtomText.input.copyWith(color: AtomColors.muted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          if (!widget.reveal)
            const SizedBox(width: AtomSpace.inset)
          else
            AtomPressable(
              onTap: () => setState(() => _show = !_show),
              semanticLabel: _show
                  ? l.signInHidePassword
                  : l.signInShowPassword,
              builder: (_, _) => Icon(
                _show ? LucideIcons.eyeOff : LucideIcons.eye,
                size: AtomIcon.row,
                color: AtomColors.faint,
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AtomField(
          label: widget.label,
          error: widget.error,
          hint: showMeter ? null : widget.hint,
          labelTrailing: widget.labelTrailing,
          child: box,
        ),
        if (showMeter) ...[
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: i < strength ? strengthColour : AtomColors.line,
                        borderRadius: AtomRadius.brTag,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              strengthWord,
              style: AtomText.secondary.copyWith(
                color: strengthColour,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The 6-digit code: six boxes over one hidden field, so paste and the
/// keyboard's one-time-code suggestion fill all of them at once.
class AtomCodeInput extends StatefulWidget {
  const AtomCodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.error = false,
    this.onCompleted,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final int length;
  final bool error;
  final ValueChanged<String>? onCompleted;
  final String? semanticLabel;

  @override
  State<AtomCodeInput> createState() => _AtomCodeInputState();
}

class _AtomCodeInputState extends State<AtomCodeInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_changed);
  }

  void _changed() {
    setState(() {});
    final text = widget.controller.text;
    if (text.length == widget.length) widget.onCompleted?.call(text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(
          children: [
            // The real field: invisible, under the boxes, takes the input.
            Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: AtomSpace.s2),
                    Expanded(child: _box(i, text)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int i, String text) {
    final current =
        _focus.hasFocus &&
        (i == text.length ||
            (i == widget.length - 1 && text.length == widget.length));
    final Color border = widget.error
        ? AtomColors.rose
        : current
        ? AtomColors.primary
        : AtomColors.line2;
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brControl,
        border: Border.all(color: border),
        boxShadow: current && !widget.error
            ? const [BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3)]
            : null,
      ),
      child: Text(
        i < text.length ? text[i] : '',
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
        style: AtomText.heading.copyWith(
          fontSize: 24,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
