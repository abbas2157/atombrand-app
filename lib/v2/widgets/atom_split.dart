import 'package:flutter/material.dart';

import '../design/design.dart';

/// Whether there is room for a list and its detail side by side (15.x).
/// Phones and small tablets in portrait show one at a time.
bool atomTwoPane(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AtomSize.splitBreakpoint;

/// A list beside its detail on a wide screen (15.2, 15.3, 19.19): the list
/// keeps [listWidth], the detail takes the rest, a hairline between them.
/// [detail] null shows [empty] (or nothing) on the right.
///
/// On a narrow screen only [list] is shown; the screen opens the detail as
/// its own page instead, as on a phone.
class AtomSplitView extends StatelessWidget {
  const AtomSplitView({
    super.key,
    required this.list,
    this.detail,
    this.empty,
    this.listWidth = 380,
  });

  final Widget list;
  final Widget? detail;
  final Widget? empty;
  final double listWidth;

  @override
  Widget build(BuildContext context) {
    if (!atomTwoPane(context)) return list;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: listWidth, child: list),
        const VerticalDivider(width: 1, thickness: 1, color: AtomColors.line),
        Expanded(
          child: ColoredBox(
            color: AtomColors.surface,
            child: detail ?? empty ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Keeps a form or a page of text readable on a tablet: at most
/// [AtomSize.formMaxWidth] wide, centred. On a phone it changes nothing.
class AtomReadableWidth extends StatelessWidget {
  const AtomReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = AtomSize.formMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Marks the row whose detail is open beside the list (15.x): a 3px bar on
/// the leading edge, and "selected" for screen readers.
class AtomSelectedRow extends StatelessWidget {
  const AtomSelectedRow({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The same widgets whether selected or not, so picking a row doesn't
    // rebuild it from scratch (which dropped keyboard focus from it).
    // Rows that aren't picked say nothing extra to screen readers.
    return Semantics(
      selected: selected ? true : null,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: selected
            ? const BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: AtomColors.primary, width: 3),
                ),
              )
            : const BoxDecoration(),
        child: child,
      ),
    );
  }
}
