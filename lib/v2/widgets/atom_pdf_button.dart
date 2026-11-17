import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../core/api/api_result.dart';
import 'atom_button.dart';
import 'atom_toast.dart';

/// Why a PDF from seller admin didn't come, as one sentence. When the
/// server couldn't make it (500), it sends a `ref` for the seller to quote
/// to Atomshop, and the sentence carries it.
String sayPdfFailure(AppLocalizations l, ApiFailure f) {
  if (f.kind case ApiFailureKind.offline || ApiFailureKind.timeout) {
    return l.pdfOffline;
  }
  final message = f.message ?? l.commonSomethingWrong;
  final ref = f.body?['ref'];
  return ref == null || '$ref'.trim().isEmpty
      ? message
      : l.pdfFailedRef(message, '$ref'.trim());
}

/// An [AtomButton] that gets a PDF from seller admin and hands it over.
///
/// [onPressed] fetches and hands over the PDF, then answers the failure, or
/// null once it is handed over (see `handOverServerPdf`). Meanwhile the
/// button says "Getting the PDF…" and can't be tapped twice; a failure is
/// said in a toast. Null disables the button (the data isn't loaded yet).
class AtomPdfButton extends StatefulWidget {
  const AtomPdfButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AtomButtonKind.outline,
    this.icon,
    this.compact = false,
    this.padding,
    this.fontSize,
  });

  final String label;
  final Future<ApiFailure?> Function()? onPressed;
  final AtomButtonKind kind;
  final IconData? icon;
  final bool compact;
  final double? padding;

  /// See [AtomButton.fontSize].
  final double? fontSize;

  @override
  State<AtomPdfButton> createState() => _AtomPdfButtonState();
}

class _AtomPdfButtonState extends State<AtomPdfButton> {
  bool _getting = false;

  Future<void> _go() async {
    final l = AppLocalizations.of(context);
    setState(() => _getting = true);
    try {
      final failure = await widget.onPressed!();
      if (failure != null && mounted) {
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayPdfFailure(l, failure),
        );
      }
    } finally {
      if (mounted) setState(() => _getting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AtomButton(
      label: widget.label,
      kind: widget.kind,
      icon: widget.icon,
      compact: widget.compact,
      padding: widget.padding,
      fontSize: widget.fontSize,
      saving: _getting,
      savingLabel: l.liveBPdfGetting,
      onPressed: widget.onPressed == null || _getting ? null : _go,
    );
  }
}
