import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// What a save says when it went to this phone's outbox instead of the
/// server (11.3).
///
/// It is deliberately not the ordinary "Saved" tick. The server has not
/// run its rules on this yet: there is no receipt number, no id, and the
/// server may still refuse it. Saying "Saved" and showing a receipt would
/// be telling the seller something that has not happened, so this sheet
/// says where the change actually is and where to watch it.
Future<void> showSavedHere(
  BuildContext context, {

  /// What was saved, in the seller's words ("Payment recorded on this
  /// phone").
  required String what,

  /// A payment's receipt, an order's number: things that only exist once
  /// the server has it.
  String? waitingFor,
}) async {
  final l = AppLocalizations.of(context);
  await showAtomSheet<void>(
    context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AtomColors.amberSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.clock,
                size: 28,
                color: AtomColors.amberInk,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              l.savedHereTitle,
              textAlign: TextAlign.center,
              style: AtomText.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(what, textAlign: TextAlign.center, style: AtomText.secondary),
          const SizedBox(height: 10),
          Text(
            l.savedHereBody,
            textAlign: TextAlign.center,
            style: AtomText.small.copyWith(color: AtomColors.muted),
          ),
          if (waitingFor != null) ...[
            const SizedBox(height: 6),
            Text(
              waitingFor,
              textAlign: TextAlign.center,
              style: AtomText.small.copyWith(color: AtomColors.muted),
            ),
          ],
          const SizedBox(height: 18),
          AtomButton(
            label: l.savedHereDone,
            onPressed: () => Navigator.of(sheet).pop(),
          ),
          const SizedBox(height: 8),
          AtomButton(
            kind: AtomButtonKind.outline,
            label: l.savedHereSee,
            onPressed: () {
              Navigator.of(sheet).pop();
              context.push(V2Routes.syncWaiting);
            },
          ),
        ],
      ),
    ),
  );
}

/// The toast a smaller save shows when it went to the outbox.
///
/// A payment gets the sheet above, because the seller is standing in
/// front of a customer and has to know there is no receipt yet. A note,
/// a step or an edit only needs to say where it went.
void showSavedHereToast(BuildContext context) => showAtomToast(
  context,
  kind: AtomToastKind.ok,
  message: AppLocalizations.of(context).savedHereToast,
);
