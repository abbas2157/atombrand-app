import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../core/format/money.dart';
import '../../../core/session/session.dart';
import '../../../core/session/session_controller.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/bulk_logic.dart';
import '../data/bulk_models.dart';
import '../data/bulk_repository.dart';
import 'bulk_parts.dart';

/// 7.5 Update status and 7.6 They said yes, as sheets over the request.
/// The routes (`bulk-request/{id}/status`, `/deal`) show the same sheets
/// as pages ([BulkSheetPage]).

Future<bool?> showStatusSheet(
  BuildContext context,
  int id, {
  bool declineOnly = false,
  StatusChoice? preset,
}) => showAtomSheet<bool>(
  context,
  builder: (_) => StatusSheet(id: id, declineOnly: declineOnly, preset: preset),
);

Future<bool?> showWonSheet(BuildContext context, int id) =>
    showAtomSheet<bool>(context, builder: (_) => WonSheet(id: id));

/// A route shown as a v2 bottom sheet (the grab, the dim, back closes it).
class BulkSheetPage<T> extends Page<T> {
  const BulkSheetPage({required this.child, super.key});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AtomColors.line2,
                    borderRadius: AtomRadius.brPill,
                  ),
                ),
              ),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      );
    },
  );
}

/// The sheet's title and the request it is about.
class _SheetTop extends StatelessWidget {
  const _SheetTop({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: AtomText.heading)),
      if (subtitle != null && subtitle!.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: AtomText.secondary),
      ],
    ],
  );
}

String _about(BulkDossier? d) {
  if (d == null) return '';
  final r = d.request;
  return '${r.quantity} × ${r.title} · ${r.who}';
}

// ───────────────────────────────────────────────────────────── 7.5

class StatusSheet extends ConsumerStatefulWidget {
  const StatusSheet({
    super.key,
    required this.id,
    this.declineOnly = false,
    this.preset,
  });

  final int id;

  /// A seller's request: only "Decline", with a reason.
  final bool declineOnly;
  final StatusChoice? preset;

  @override
  ConsumerState<StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends ConsumerState<StatusSheet> {
  StatusChoice? _choice;
  String? _reason;
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _choice = widget.declineOnly ? StatusChoice.lost : widget.preset;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(BulkDossier? d) async {
    final l = AppLocalizations.of(context);
    final choice = _choice;
    if (choice == null) {
      setState(() => _error = l.bulkChooseStatus);
      return;
    }
    final problem = statusProblem(l, choice, _reason);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await ref
        .read(bulkRepositoryProvider)
        .setStatus(
          widget.id,
          choice.status,
          reason: _reason,
          comments: _note.text,
          seen: d?.request.status,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (saved) {
      case SavedOnServer():
        refreshRequest(ref, widget.id);
        Navigator.of(context).pop(true);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: widget.declineOnly
              ? l.bulkRequestDeclined
              : l.bulkStatusSaved,
        );
      case SavedHere():
        refreshRequest(ref, widget.id);
        Navigator.of(context).pop(true);
        showSavedHereToast(context);
      case SaveFailed(:final failure):
        setState(() => _error = sayFailure(l, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(bulkDossierProvider(widget.id)).value;
    final status = d?.request.status ?? RequestStatus.fresh;
    final choices = statusChoicesFor(status);
    final reasons = ref.watch(quoteOptionsProvider).value?.lostReasons;
    final lostReasonList = reasons == null || reasons.isEmpty
        ? lostReasons
        : reasons;
    final isLost = _choice == StatusChoice.lost;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTop(
            title: widget.declineOnly ? l.bulkDeclineTitle : l.bulkUpdateStatus,
            subtitle: _about(d),
          ),
          const SizedBox(height: 16),
          if (!widget.declineOnly) ...[
            // `.stats`: three equal buttons in a row.
            Row(
              children: [
                for (final (i, c) in choices.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _StatusOption(
                      label: c.label(l),
                      colour: switch (c) {
                        StatusChoice.contacted => AtomColors.purpleInk,
                        StatusChoice.lost => AtomColors.rose,
                        StatusChoice.backToNew => AtomColors.primary,
                      },
                      on: _choice == c,
                      onTap: () => setState(() {
                        _choice = c;
                        _error = null;
                      }),
                    ),
                  ),
                ],
                for (var i = choices.length; i < 3; i++) ...[
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (isLost) ...[
            // `.chips`: the board's five reasons as pills; a longer list
            // from the server keeps the searchable picker.
            if (lostReasonList.length >= 2 && lostReasonList.length <= 5)
              AtomField(
                label: widget.declineOnly ? l.bulkWhyDeclining : l.bulkWhyLost,
                child: AtomChips<String>(
                  chips: [for (final r in lostReasonList) AtomChip(r, r)],
                  selected: _reason,
                  onChanged: (r) => setState(() {
                    _reason = r;
                    _error = null;
                  }),
                ),
              )
            else
              AtomSelectField<String>(
                label: widget.declineOnly ? l.bulkWhyDeclining : l.bulkWhyLost,
                value: _reason,
                valueLabel: _reason,
                placeholder: l.bulkChooseReason,
                sheetTitle: l.bulkReason,
                options: [
                  for (final r in lostReasonList)
                    AtomOption(value: r, label: r),
                ],
                onChanged: (r) => setState(() {
                  _reason = r;
                  _error = null;
                }),
              ),
            if (widget.declineOnly) ...[
              const SizedBox(height: 8),
              Text(l.bulkDeclineNote, style: AtomText.small),
            ],
            const SizedBox(height: 14),
          ],
          if (_choice == StatusChoice.contacted) ...[
            Text(l.bulkContactedHint, style: AtomText.small),
            const SizedBox(height: 14),
          ],
          AtomTextField(
            label: l.bulkNote,
            labelNote: l.bulkOptional,
            controller: _note,
            placeholder: widget.declineOnly
                ? l.bulkNoteSellerHint
                : l.bulkNoteBuyerHint,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            inputFormatters: const [],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            AtomFieldError(_error!),
          ],
          const SizedBox(height: 16),
          AtomButton(
            label: widget.declineOnly ? l.bulkDeclineRequest : l.commonSave,
            kind: widget.declineOnly
                ? AtomButtonKind.danger
                : AtomButtonKind.primary,
            saving: _saving,
            onPressed: _saving ? null : () => _save(d),
          ),
        ],
      ),
    );
  }
}

/// `.stats button`: a status with its colour dot.
class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.colour,
    required this.on,
    required this.onTap,
  });

  final String label;
  final Color colour;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    selected: on,
    semanticLabel: label,
    focusRadius: AtomRadius.brControl,
    builder: (_, _) => Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? AtomColors.primarySoft : AtomColors.paper,
        borderRadius: AtomRadius.brControl,
        border: Border.all(
          color: on ? AtomColors.primary : AtomColors.line2,
          width: on ? 2 : 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              style: AtomText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: on ? AtomColors.primary : AtomColors.text,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ───────────────────────────────────────────────────────────── 7.6

class WonSheet extends ConsumerStatefulWidget {
  const WonSheet({super.key, required this.id});

  final int id;

  @override
  ConsumerState<WonSheet> createState() => _WonSheetState();
}

class _WonSheetState extends ConsumerState<WonSheet> {
  int? _quoteId;
  int? _outletId;
  bool _saving = false;
  String? _error;

  Future<void> _save(List<Quote> sendable) async {
    final l = AppLocalizations.of(context);
    final quoteId = _quoteId ?? (sendable.isEmpty ? null : sendable.first.id);
    if (quoteId == null) {
      setState(() => _error = l.bulkWonNeedQuote);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(bulkRepositoryProvider)
        .won(widget.id, quoteId: quoteId, outletId: _outletId);
    if (!mounted) return;
    setState(() => _saving = false);
    switch (r) {
      case ApiOk(:final value):
        final router = GoRouter.of(context);
        refreshRequest(ref, widget.id);
        showAtomToast(
          context,
          kind: value.stockWarning.isEmpty
              ? AtomToastKind.ok
              : AtomToastKind.wait,
          message: value.stockWarning.isEmpty
              ? l.bulkDealMade(value.number)
              : l.bulkDealMadeShort(
                  value.number,
                  value.stockWarning.join(', '),
                ),
        );
        Navigator.of(context).pop(true);
        router.push(V2Routes.dealOf(value.id));
      case ApiErr(:final failure):
        setState(() => _error = sayFailure(l, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(bulkDossierProvider(widget.id)).value;
    final quotes = ref.watch(requestQuotesProvider(widget.id));
    final session = ref.watch(
      sessionProvider.select((s) => s is SignedIn ? s.session : null),
    );
    final outlets = [
      for (final o in session?.outlets ?? const <Outlet>[])
        if (o.active && (session?.who.worksIn(o.id) ?? false)) o,
    ];
    final outletId =
        _outletId ??
        session?.outletId ??
        (outlets.where((o) => o.isMain).firstOrNull ?? outlets.firstOrNull)?.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: quotes.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: AtomSpinner()),
        ),
        error: (e, _) => AtomErrorState(
          onRetry: () => ref.invalidate(requestQuotesProvider(widget.id)),
        ),
        data: (q) {
          final sendable = [
            for (final x in q.quotes)
              if (x.status.live) x,
          ];
          final picked = sendable
              .where((x) => x.id == (_quoteId ?? sendable.firstOrNull?.id))
              .firstOrNull;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetTop(
                title: l.bulkSaidYes,
                subtitle: d == null
                    ? null
                    : '${d.request.who} · ${d.request.quantity} × ${d.request.title}',
              ),
              const SizedBox(height: 16),
              if (q.deal != null)
                AtomNote(
                  kind: AtomNoteKind.info,
                  message: l.bulkAlreadyDeal(q.deal!.number),
                )
              else if (sendable.isEmpty)
                AtomNote(
                  kind: AtomNoteKind.warning,
                  message: l.bulkWonNeedQuoteBusiness,
                )
              else ...[
                AtomField(
                  label: l.bulkAcceptedQuote,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final x in sendable) ...[
                        _QuoteOption(
                          title: x.name,
                          line: [
                            if (x.sentAt != null)
                              l.bulkSentWhen(bulkWhen(l, x.sentAt)),
                            if (x.advancePct > 0)
                              l.bulkAdvancePct(x.advancePct),
                          ].join(' · '),
                          total: formatRs(x.total),
                          on: x.id == picked?.id,
                          onTap: () => setState(() => _quoteId = x.id),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                if (outlets.length > 1) ...[
                  const SizedBox(height: 8),
                  AtomSelectField<int>(
                    label: l.bulkDeliverFrom,
                    value: outletId,
                    valueLabel: outlets
                        .where((o) => o.id == outletId)
                        .firstOrNull
                        ?.name,
                    sheetTitle: l.bulkDeliverFrom,
                    options: [
                      for (final o in outlets)
                        AtomOption(
                          value: o.id,
                          label: o.name,
                          subtitle: o.city,
                        ),
                    ],
                    onChanged: (v) => setState(() => _outletId = v),
                  ),
                ],
                const SizedBox(height: 12),
                AtomNote(
                  kind: AtomNoteKind.info,
                  compact: true,
                  icon: LucideIcons.info,
                  message:
                      l.bulkWonInfo +
                      ((picked?.advancePct ?? 0) > 0
                          ? l.bulkWonInfoAdvance(picked!.advancePct)
                          : ''),
                  bold: [l.bulkStatusWon],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                AtomFieldError(_error!),
              ],
              const SizedBox(height: 16),
              if (q.deal != null)
                AtomButton(
                  label: l.bulkOpenDealNumber(q.deal!.number),
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push(V2Routes.dealOf(q.deal!.id));
                  },
                )
              else
                AtomButton(
                  label: l.bulkMarkWon,
                  saving: _saving,
                  onPressed: sendable.isEmpty || _saving
                      ? null
                      : () {
                          _outletId ??= outlets.length > 1 ? outletId : null;
                          _save(sendable);
                        },
                ),
            ],
          );
        },
      ),
    );
  }
}

/// `.opt`: one quote to accept — its name and line, the total, and the
/// radio on the right.
class _QuoteOption extends StatelessWidget {
  const _QuoteOption({
    required this.title,
    required this.line,
    required this.total,
    required this.on,
    required this.onTap,
  });

  final String title;
  final String line;
  final String total;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtomPressable(
    onTap: onTap,
    selected: on,
    semanticLabel: '$title, $total',
    focusRadius: AtomRadius.brCard,
    builder: (_, _) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: on ? 13 : 14,
        vertical: on ? 11 : 12,
      ),
      decoration: BoxDecoration(
        color: AtomColors.paper,
        borderRadius: AtomRadius.brCard,
        border: Border.all(
          color: on ? AtomColors.primary : AtomColors.line,
          width: on ? 2 : 1,
        ),
        boxShadow: on
            ? const [BoxShadow(color: AtomColors.primarySoft, spreadRadius: 3)]
            : null,
      ),
      child: Row(
        children: [
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
                if (line.isNotEmpty) Text(line, style: AtomText.secondary),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(total, style: AtomText.money.copyWith(fontSize: 15)),
          const SizedBox(width: 12),
          AtomRadio(on: on),
        ],
      ),
    ),
  );
}
