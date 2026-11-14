import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../design/design.dart';

enum AtomToastKind {
  /// Saved and sent: "Payment saved".
  ok,

  /// Saved on the phone, not sent yet: "Saved · waiting to send".
  wait,

  /// It didn't work: "Didn't save".
  bad,
}

/// Shows a toast: a dark bar at the bottom with an icon, a message and an
/// optional link ("Receipt", "See", "Why?").
///
/// Built on the app's [ScaffoldMessenger], so it is announced to screen
/// readers, one toast replaces the last, and it sits above the tab bar.
void showAtomToast(
  BuildContext context, {
  required AtomToastKind kind,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AtomColors.ink,
      elevation: 6,
      duration: AtomMotion.toast,
      margin: const EdgeInsets.fromLTRB(
        AtomSpace.gutter,
        0,
        AtomSpace.gutter,
        AtomSpace.s4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: const RoundedRectangleBorder(borderRadius: AtomRadius.brCard),
      content: _ToastBody(
        kind: kind,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
      ),
    ),
  );
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final AtomToastKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color colour) = switch (kind) {
      AtomToastKind.ok => (LucideIcons.check, AtomColors.toastOkIcon),
      AtomToastKind.wait => (LucideIcons.clock3, Colors.white),
      AtomToastKind.bad => (LucideIcons.circleAlert, Colors.white),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: colour),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: AtomText.body.copyWith(color: Colors.white),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AtomColors.toastLink,
              minimumSize: const Size(AtomSize.tapTarget, AtomSize.tapTarget),
              padding: const EdgeInsets.symmetric(horizontal: AtomSpace.s2),
              textStyle: AtomText.body.copyWith(fontWeight: FontWeight.w600),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
