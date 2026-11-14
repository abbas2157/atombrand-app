import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design/design.dart';
import 'atom_button.dart';

/// Asks a yes/no question. Returns true only when the person confirms.
///
/// For a destructive action (Sign out, Close the account, Discard) pass
/// [destructive]: the confirm button is red. Destructive actions are always
/// confirmed.
Future<bool> showAtomConfirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  String? cancelLabel,
  bool destructive = false,
  bool sideBySide = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = AppLocalizations.of(context);
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.s6,
          vertical: AtomSpace.s6,
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        actionsPadding: const EdgeInsets.all(20),
        // `.dlg` is 24 from each side whatever its text: full width, not
        // the dialog's narrower intrinsic width for a short question.
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AtomText.heading),
              ),
              if (body != null) ...[
                const SizedBox(height: AtomSpace.s3),
                Text(
                  body,
                  style: AtomText.body.copyWith(color: AtomColors.text),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // `.dlg .acts`: Cancel, then the action, side by side (19.4);
          // stacked when large text would squeeze them.
          if (sideBySide && MediaQuery.textScalerOf(context).scale(10) <= 13)
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: AtomButton(
                    label: cancelLabel ?? l.commonCancel,
                    kind: AtomButtonKind.outline,
                    compact: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 13,
                  child: AtomButton(
                    label: confirmLabel,
                    kind: destructive
                        ? AtomButtonKind.danger
                        : AtomButtonKind.primary,
                    compact: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AtomButton(
                  label: confirmLabel,
                  kind: destructive
                      ? AtomButtonKind.danger
                      : AtomButtonKind.primary,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
                AtomButton(
                  label: cancelLabel ?? l.commonCancel,
                  kind: AtomButtonKind.outline,
                  compact: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
        ],
      );
    },
  );
  return result ?? false;
}

/// "Leave without saving?" — Discard / Keep editing.
///
/// Returns true when the person chooses Discard.
///
/// [body] replaces the general line with what changed ("You changed the
/// shop address…", 19.11).
///
/// As on the Business details board (19.11, the rule in 19.17): Discard
/// (outline) and Keep editing (primary) side by side; stacked, Keep
/// editing first, when large text would squeeze them.
Future<bool> confirmLeaveWithoutSaving(
  BuildContext context, {
  String? body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l = AppLocalizations.of(context);
      final discard = AtomButton(
        label: l.leaveDiscard,
        kind: AtomButtonKind.outline,
        compact: true,
        // Two halves of a 360dp phone: "Keep editing" stays one line.
        padding: 12,
        onPressed: () => Navigator.of(context).pop(true),
      );
      final keep = AtomButton(
        label: l.leaveKeepEditing,
        compact: true,
        padding: 12,
        onPressed: () => Navigator.of(context).pop(false),
      );
      final row = MediaQuery.textScalerOf(context).scale(10) <= 13;
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AtomSpace.s6,
          vertical: AtomSpace.s6,
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        actionsPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(l.leaveTitle, style: AtomText.heading),
              ),
              const SizedBox(height: AtomSpace.s3),
              Text(
                body ?? l.leaveBody,
                style: AtomText.body.copyWith(color: AtomColors.text),
              ),
            ],
          ),
        ),
        actions: [
          if (row)
            Row(
              children: [
                Expanded(child: discard),
                const SizedBox(width: 10),
                Expanded(child: keep),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [keep, const SizedBox(height: 10), discard],
            ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Whether the pages under an [AtomUnsavedScope] have unsaved changes.
///
/// Each [AtomUnsavedGuard] below the scope reports its `dirty` here, so a
/// screen that swaps a page in place (Settings on a wide tablet, 19.19) can
/// ask "Leave without saving?" before it drops the page.
class AtomUnsavedTracker {
  final _dirty = <Object>{};

  /// True while any guard below the scope is dirty.
  bool get dirty => _dirty.isNotEmpty;

  void _report(Object guard, bool dirty) =>
      dirty ? _dirty.add(guard) : _dirty.remove(guard);
}

/// Hands an [AtomUnsavedTracker] to the [AtomUnsavedGuard]s below it.
///
/// Routes pushed from inside it are not below it, so they don't report.
class AtomUnsavedScope extends InheritedWidget {
  const AtomUnsavedScope({
    super.key,
    required this.tracker,
    required super.child,
  });

  final AtomUnsavedTracker tracker;

  static AtomUnsavedTracker? _of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AtomUnsavedScope>()?.tracker;

  @override
  bool updateShouldNotify(AtomUnsavedScope oldWidget) =>
      tracker != oldWidget.tracker;
}

/// Asks "Leave without saving?" when the pages under [tracker] have unsaved
/// changes. Returns true when there are none, or the person chose Discard.
Future<bool> confirmDropUnsaved(
  BuildContext context,
  AtomUnsavedTracker tracker,
) async => !tracker.dirty || await confirmLeaveWithoutSaving(context);

/// Guards a screen with unsaved changes.
///
/// While [dirty] is true, Back, the back gesture and any pop through the
/// navigator ask "Leave without saving?" first. Wrap the screen's body; the
/// X and ‹ buttons should call `Navigator.maybePop` so they go through the
/// same question. Inside an [AtomUnsavedScope] it also reports [dirty] to
/// the scope's tracker.
class AtomUnsavedGuard extends StatefulWidget {
  const AtomUnsavedGuard({
    super.key,
    required this.dirty,
    required this.child,
    this.body,
  });

  final bool dirty;
  final Widget child;

  /// What the question says changed; null keeps the general line.
  final String? body;

  @override
  State<AtomUnsavedGuard> createState() => _AtomUnsavedGuardState();
}

class _AtomUnsavedGuardState extends State<AtomUnsavedGuard> {
  AtomUnsavedTracker? _tracker;

  @override
  void dispose() {
    _tracker?._report(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracker = AtomUnsavedScope._of(context);
    if (tracker != _tracker) _tracker?._report(this, false);
    _tracker = tracker?.._report(this, widget.dirty);
    return PopScope<Object?>(
      canPop: !widget.dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmLeaveWithoutSaving(context, body: widget.body)) {
          // Pop past this guard now that the person said yes.
          navigator.pop(result);
        }
      },
      child: widget.child,
    );
  }
}
