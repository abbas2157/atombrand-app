import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/pdf/server_pdf.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';

/// Pieces the Account screens share.

/// A white card holding rows with a line between each (`.card` with `.ln`
/// or `.ad` rows on 12.6).
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: AtomDecor.card,
    foregroundDecoration: AtomDecor.cardOutline,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AtomColors.line),
          c,
        ],
      ],
    ),
  );
}

/// `.ln`: one line in a card, its status pill, and a small link (PDF).
class AccountLine extends StatelessWidget {
  const AccountLine({
    super.key,
    required this.text,
    this.bold,
    this.pill,
    this.linkLabel,
    this.onLink,
    this.sub,
  });

  /// The bold start ("INV-2026-11-0042"), then [text].
  final String? bold;
  final String text;
  final String? sub;
  final AtomPill? pill;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (bold != null)
                        TextSpan(
                          text: bold,
                          style: const TextStyle(
                            color: AtomColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (bold != null && text.isNotEmpty)
                        const TextSpan(text: ' · '),
                      TextSpan(text: text),
                    ],
                  ),
                  style: AtomText.body.copyWith(color: AtomColors.text),
                ),
                if (sub != null && sub!.isNotEmpty)
                  Text(sub!, style: AtomText.small),
              ],
            ),
          ),
          if (pill != null) ...[const SizedBox(width: 8), pill!],
          if (linkLabel != null && onLink != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onLink,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                linkLabel!,
                style: AtomText.secondary.copyWith(
                  color: AtomColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A tappable card row with an icon tile, two lines and a small button or
/// chevron (`.card` rows on 12.6: Renew, the bill to pay).
class AccountActionCard extends StatelessWidget {
  const AccountActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.sub,
    this.tone = AtomTone.blue,
    this.action,
    this.border,
  });

  final IconData icon;
  final AtomTone tone;
  final String title;
  final String? sub;
  final String? action;
  final VoidCallback? onTap;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return AtomPressable(
      onTap: onTap,
      scaleOnPress: false,
      focusRadius: AtomRadius.brCard,
      semanticLabel: [title, ?sub].join(', '),
      builder: (_, pressed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: pressed ? AtomColors.head : AtomColors.paper,
          borderRadius: AtomRadius.brCard,
          border: Border.all(color: border ?? AtomColors.line),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              AtomIconTile(icon: icon, tone: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AtomText.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sub != null) Text(sub!, style: AtomText.secondary),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (action != null)
                AtomButton.small(
                  label: action!,
                  kind: border == AtomColors.amberLine
                      ? AtomButtonKind.primary
                      : AtomButtonKind.outline,
                  onPressed: onTap,
                )
              else
                const Icon(
                  LucideIcons.chevronRight,
                  size: AtomIcon.setRow,
                  color: AtomColors.chevron,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A screen's failure: "no signal" or the server's words, with Try again.
class AccountError extends StatelessWidget {
  const AccountError({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = error;
    return AtomErrorState(
      message: e is ApiFailure ? sayFailure(l, e) : null,
      onRetry: onRetry,
    );
  }
}

/// Shares a server-built PDF (a bill, a receipt), saying why when it can't.
Future<void> shareServerPdf(
  BuildContext context,
  WidgetRef ref,
  ServerPdf pdf,
) async {
  final l = AppLocalizations.of(context);
  final failure = await handOverServerPdf(ref.read(apiClientProvider), pdf);
  if (failure != null && context.mounted) {
    showAtomToast(
      context,
      kind: AtomToastKind.bad,
      message: sayFailure(l, failure),
    );
  }
}

/// The small label above a group, inside a padded page (`.lbl`).
class AccountLabel extends StatelessWidget {
  const AccountLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: AtomSectionLabel(text, page: false),
  );
}
