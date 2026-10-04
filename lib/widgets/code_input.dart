import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_icons.dart';

import '../core/theme.dart';

/// Six boxes backed by one hidden field, so typing auto-advances, paste works
/// and the OS can offer one-time-code autofill (§4.5).
class CodeInput extends StatefulWidget {
  const CodeInput({super.key, required this.onCompleted, this.length = 6, this.controller, this.errorText, this.enabled = true});

  final int length;
  final ValueChanged<String> onCompleted;
  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  late final TextEditingController _ctrl = widget.controller ?? TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_changed);
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});

  @override
  void dispose() {
    _ctrl.removeListener(_changed);
    if (widget.controller == null) _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    if (_ctrl.text.length == widget.length) widget.onCompleted(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    final text = _ctrl.text;
    final hasError = widget.errorText != null;
    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // The real input: invisible but focusable and autofill-aware.
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 56,
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: widget.length,
                    showCursor: false,
                    enableInteractiveSelection: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _focus.requestFocus();
                    SystemChannels.textInput.invokeMethod('TextInput.show');
                  },
                  onLongPress: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.isNotEmpty) {
                      _ctrl.text = digits.substring(0, digits.length.clamp(0, widget.length));
                    }
                  },
                  child: Row(
                    children: List.generate(widget.length, (i) {
                      final filled = i < text.length;
                      final active = _focus.hasFocus && i == text.length.clamp(0, widget.length - 1);
                      final borderColor = hasError
                          ? p.danger
                          : (active || filled)
                              ? p.primary
                              : p.border;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          height: 56,
                          margin: EdgeInsets.only(right: i == widget.length - 1 ? 0 : 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: filled && !hasError ? p.primarySoft : p.field,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 1.5),
                            boxShadow: active
                                ? [BoxShadow(color: hasError ? p.dangerRing : p.ring, spreadRadius: 4)]
                                : p.fieldShadow,
                          ),
                          child: filled
                              ? Text(
                                  text[i],
                                  style: t.headlineSmall?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: p.text,
                                    fontFeatures: tabularFigures,
                                  ),
                                )
                              : active
                                  ? Container(width: 2, height: 26, color: p.primary)
                                  : null,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.error, size: 16, color: p.danger),
                const SizedBox(width: 6),
                Expanded(child: Text(widget.errorText!, style: t.bodySmall?.copyWith(fontSize: 13, color: p.danger))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
