import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'auth_scaffold.dart';

/// Labelled text field for the signed-out screens (DESIGN.md §3.3): label
/// above, 1.5 px border, indigo border and halo on focus, and the error in
/// red with an icon underneath. [validator] runs on the field's text when the
/// enclosing [Form] validates; [errorText] shows a server-side error.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.labelSuffix,
    this.icon,
    this.hint,
    this.helper,
    this.validator,
    this.errorText,
    this.successText,
    this.password = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autofocus = false,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.scrollPadding = const EdgeInsets.all(20),
    this.onChanged,
    this.onSubmitted,
    this.below,
  });

  final String label;

  /// Muted text after the label, e.g. "(optional)".
  final String? labelSuffix;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final String? helper;
  final String? Function(String value)? validator;
  final String? errorText;

  /// Green confirmation under the field when there is no error.
  final String? successText;

  /// Obscures the text and adds a show/hide toggle.
  final bool password;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final bool enabled;
  final int? minLines;
  final int? maxLines;

  /// How much room to keep clear below the field when it scrolls into view;
  /// make it larger to reveal the action under it too.
  final EdgeInsets scrollPadding;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Extra content under the field, e.g. a password strength meter.
  final Widget? below;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final _focus = FocusNode();
  late bool _obscure = widget.password;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return FormField<String>(
      validator: widget.validator == null ? null : (_) => widget.validator!(widget.controller.text),
      builder: (field) {
        final error = field.errorText ?? widget.errorText;
        final focused = _focus.hasFocus;
        final borderColor = error != null
            ? p.danger
            : focused
                ? p.primary
                : p.border;
        final halo = error != null
            ? [BoxShadow(color: p.dangerRing, spreadRadius: 4)]
            : focused
                ? [BoxShadow(color: p.ring, spreadRadius: 4)]
                : p.fieldShadow;
        final iconColor = focused ? p.primary : p.muted;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFieldLabel(widget.label, suffix: widget.labelSuffix),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: widget.enabled ? p.field : p.surface,
                borderRadius: BorderRadius.circular(AuthTheme.radius),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: halo,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                obscureText: _obscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                autofillHints: widget.autofillHints,
                minLines: widget.minLines,
                maxLines: widget.password ? 1 : widget.maxLines,
                scrollPadding: widget.scrollPadding,
                style: t.bodyLarge?.copyWith(color: p.text, letterSpacing: _obscure ? 1.5 : null),
                onChanged: (v) {
                  field.didChange(v);
                  widget.onChanged?.call(v);
                },
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: t.bodyLarge?.copyWith(color: p.muted, letterSpacing: 0),
                  contentPadding: EdgeInsets.fromLTRB(widget.icon == null ? 14 : 0, 15, widget.password ? 0 : 14, 15),
                  prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20, color: iconColor),
                  prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 48),
                  suffixIcon: widget.password
                      ? IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: 20,
                            color: _obscure ? p.muted : p.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            if (error != null)
              AuthFieldMessage(error, color: p.danger, icon: Icons.error_outline_rounded)
            else if (widget.successText != null)
              AuthFieldMessage(widget.successText!, color: p.success, icon: Icons.check_circle_outline_rounded)
            else if (widget.helper != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(widget.helper!, style: t.bodySmall?.copyWith(color: p.muted)),
              ),
            if (widget.below != null) ...[const SizedBox(height: 8), widget.below!],
          ],
        );
      },
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key, this.suffix});
  final String text;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text),
        if (suffix != null) TextSpan(text: ' $suffix', style: TextStyle(color: p.muted, fontWeight: FontWeight.w400)),
      ]),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.text),
    );
  }
}

/// One line under a field: an icon and a message in [color].
class AuthFieldMessage extends StatelessWidget {
  const AuthFieldMessage(this.text, {super.key, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

/// 0 (empty) to 4 (strong), plus the next thing to fix.
({int score, String hint}) passwordStrength(String pw) {
  if (pw.isEmpty) return (score: 0, hint: 'Use 8+ characters with a mix of types');
  final checks = [
    pw.length >= 8,
    RegExp('[A-Z]').hasMatch(pw) && RegExp('[a-z]').hasMatch(pw),
    RegExp('[0-9]').hasMatch(pw),
    RegExp('[^A-Za-z0-9]').hasMatch(pw),
  ];
  final score = checks.where((c) => c).length.clamp(1, 4);
  final hint = !checks[0]
      ? 'Use at least 8 characters'
      : !checks[1]
          ? 'Mix upper and lower case letters'
          : !checks[2]
              ? 'Add a number'
              : !checks[3]
                  ? 'Add a symbol to make it stronger'
                  : 'Great password';
  return (score: score, hint: hint);
}

/// Four bars plus a label (Weak / Fair / Good / Strong) that follow
/// [controller] as the user types.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = passwordStrength(controller.text);
        final (label, ink, bar) = switch (s.score) {
          1 => ('Weak', p.danger, p.danger),
          2 => ('Fair', p.accentInk, p.accent),
          3 => ('Good', p.primary, p.primary),
          4 => ('Strong', p.success, p.success),
          _ => ('', p.muted, p.border),
        };
        return Semantics(
          label: label.isEmpty ? null : 'Password strength: $label',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i < s.score ? bar : p.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(child: Text(s.hint, style: t.bodySmall?.copyWith(color: p.muted))),
                    Text(label, style: t.bodySmall?.copyWith(color: ink, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
