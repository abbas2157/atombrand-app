import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';

/// The press, focus and disabled behaviour every v2 control shares.
///
/// The canvas has no ripple. A pressed control shrinks to 98% and its owner
/// darkens its fill; a keyboard-focused control gets a 2px primary ring.
/// This widget tracks those two states and hands them to [builder], so each
/// component only decides what the states look like.
///
/// The tap area is never smaller than 48×48, even for a 36-tall small button.
class AtomPressable extends StatefulWidget {
  const AtomPressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.semanticLabel,
    this.isButton = true,
    this.selected,
    this.toggled,
    this.focusRadius = AtomRadius.brControl,
    this.scaleOnPress = true,
  });

  /// Null makes the control disabled.
  final VoidCallback? onTap;

  final Widget Function(BuildContext context, bool pressed) builder;
  final String? semanticLabel;
  final bool isButton;
  final bool? selected;
  final bool? toggled;
  final BorderRadius focusRadius;
  final bool scaleOnPress;

  @override
  State<AtomPressable> createState() => _AtomPressableState();
}

class _AtomPressableState extends State<AtomPressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _enabled && _pressed;
    Widget child = widget.builder(context, pressed);

    if (widget.scaleOnPress) {
      child = Transform.scale(scale: pressed ? 0.98 : 1, child: child);
    }

    child = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.focusRadius,
        border: _focused ? Border.all(color: AtomColors.focus, width: 2) : null,
      ),
      child: child,
    );

    return Semantics(
      button: widget.isButton,
      enabled: _enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap?.call(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: _enabled
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                }
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AtomSize.tapTarget,
              minHeight: AtomSize.tapTarget,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
