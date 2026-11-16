import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/pdf/server_pdf.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/bulk_logic.dart';
import '../data/bulk_models.dart';
import '../data/bulk_repository.dart';
import 'bulk_parts.dart';

/// 7.4 Send a quote: lines (product and variant, colour, qty, unit price,
/// discount), delivery charge, valid until, advance, balance terms and
/// notes, with live totals. Save and send on WhatsApp, save as a draft,
/// or preview the PDF. Online only: prices are worked out by the server.
class QuoteScreen extends ConsumerWidget {
  const QuoteScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossier = ref.watch(bulkDossierProvider(id));
    final quotes = ref.watch(requestQuotesProvider(id));
    final options = ref.watch(quoteOptionsProvider);
    final error = dossier.error ?? quotes.error ?? options.error;
    if (dossier.value case final d? when quotes.hasValue && options.hasValue) {
      return _QuoteForm(
        dossier: d,
        quotes: quotes.requireValue.quotes,
        options: options.requireValue,
      );
    }
    return BulkLoadFrame(
      title: AppLocalizations.of(context).bulkSendAQuote,
      error: error,
      onRetry: () {
        ref.invalidate(bulkDossierProvider(id));
        ref.invalidate(requestQuotesProvider(id));
        ref.invalidate(quoteOptionsProvider);
      },
    );
  }
}

/// One line's boxes.
class _Line {
  _Line(this.value)
    : price = TextEditingController(
        text: value.unitPrice > 0 ? groupDigits(value.unitPrice) : '',
      ),
      disc = TextEditingController(
        text: value.discountPct == 0 ? '' : _pct(value.discountPct),
      );

  QuoteDraftLine value;
  final TextEditingController price;
  final TextEditingController disc;

  void dispose() {
    price.dispose();
    disc.dispose();
  }
}

String _pct(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class _QuoteForm extends ConsumerStatefulWidget {
  const _QuoteForm({
    required this.dossier,
    required this.quotes,
    required this.options,
  });

  final BulkDossier dossier;
  final List<Quote> quotes;
  final QuoteOptions options;

  @override
  ConsumerState<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends ConsumerState<_QuoteForm> {
  final _lines = <_Line>[];
  final _delivery = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _validUntil;
  int _advance = 30;
  String _terms = 'before_each';
  Map<String, String> _problems = const {};
  bool _dirty = false;

  /// 'send', 'draft' or 'pdf' while saving.
  String? _saving;

  BulkRequest get _request => widget.dossier.request;

  @override
  void initState() {
    super.initState();
    final today = AtomDates.now();
    final rev = nextRevision(widget.quotes);
    final from = rev.draft ?? rev.replaces;
    if (from != null) {
      for (final l in from.items) {
        _lines.add(
          _Line(
            QuoteDraftLine(
              productId: l.productId,
              memoryId: l.memoryId,
              colorId: l.colorId,
              qty: l.qty,
              unitPrice: l.unitPrice,
              discountPct: l.discountPct,
            ),
          ),
        );
      }
      _delivery.text = from.deliveryCharge > 0
          ? groupDigits(from.deliveryCharge)
          : '';
      _notes.text = from.notes ?? '';
      _advance = from.advancePct;
      _terms = from.balanceTerms;
      final until = from.validUntil;
      _validUntil = until != null && !until.isBefore(_day(today))
          ? until
          : _day(today).add(const Duration(days: 7));
    } else {
      final s = widget.dossier.sourcing;
      final productId = s?.productId ?? _request.productId;
      final product = widget.options.product(productId);
      _lines.add(
        _Line(
          QuoteDraftLine(
            productId: product?.id,
            qty: (s?.quantity ?? _request.quantity).clamp(1, maxQty),
            unitPrice: product?.price ?? 0,
          ),
        ),
      );
      _validUntil = _day(today).add(const Duration(days: 7));
    }
    if (_lines.isEmpty) _lines.add(_Line(const QuoteDraftLine()));
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _delivery.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _changed(VoidCallback f) => setState(() {
    f();
    _dirty = true;
    if (_problems.isNotEmpty) _problems = const {};
  });

  List<QuoteDraftLine> get _values => [for (final l in _lines) l.value];

  int get _deliveryCharge => parseRupees(_delivery.text);

  QuoteTotals get _totals =>
      quoteTotals(_values, delivery: _deliveryCharge, advancePct: _advance);

  /// The product-and-variant choices: one per storage option, or the
  /// product alone.
  List<AtomOption<String>> get _productOptions => [
    for (final p in widget.options.products)
      if (p.memories.isEmpty)
        AtomOption(
          value: '${p.id}:',
          label: p.title,
          subtitle: formatRs(p.price),
        )
      else
        for (final m in p.memories)
          AtomOption(
            value: '${p.id}:${m.id}',
            label: '${p.title} · ${m.title}',
            subtitle: formatRs(m.price ?? p.price),
            keywords: [p.title],
          ),
  ];

  String? _productLabel(QuoteDraftLine l) {
    final p = widget.options.product(l.productId);
    if (p == null) return null;
    final m = p.memories.where((m) => m.id == l.memoryId).firstOrNull;
    return m == null ? p.title : '${p.title} · ${m.title}';
  }

  void _pickProduct(_Line line, String value) {
    final parts = value.split(':');
    final p = widget.options.product(int.tryParse(parts[0]));
    if (p == null) return;
    final mId = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final m = p.memories.where((m) => m.id == mId).firstOrNull;
    final price = m?.price ?? p.price;
    _changed(() {
      line.value = line.value.copyWith(
        productId: () => p.id,
        memoryId: () => m?.id,
        colorId: () => p.colors.any((c) => c.id == line.value.colorId)
            ? line.value.colorId
            : null,
        unitPrice: price,
      );
      line.price.text = price > 0 ? groupDigits(price) : '';
    });
  }

  void _addLine() {
    if (_lines.length >= maxQuoteLines) return;
    final last = _lines.isEmpty ? null : _lines.last.value;
    _changed(
      () => _lines.add(
        _Line(
          QuoteDraftLine(
            productId: last?.productId,
            memoryId: last?.memoryId,
            unitPrice: last?.unitPrice ?? 0,
          ),
        ),
      ),
    );
  }

  void _removeLine(int i) {
    final l = _lines[i];
    _changed(() => _lines.removeAt(i));
    WidgetsBinding.instance.addPostFrameCallback((_) => l.dispose());
  }

  Future<void> _pickValidUntil() async {
    final today = _day(AtomDates.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil.isBefore(today) ? today : _validUntil,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: AppLocalizations.of(context).bulkValidUntilLabel,
    );
    if (picked != null) _changed(() => _validUntil = picked);
  }

  /// Saves the quote; [mode] is `send`, `draft` or `pdf` (a draft, then
  /// its PDF).
  Future<void> _save(String mode) async {
    final l = AppLocalizations.of(context);
    final problems = quoteProblems(
      l,
      lines: _values,
      delivery: _deliveryCharge,
      validUntil: _validUntil,
      today: AtomDates.now(),
      advancePct: _advance,
      notes: _notes.text,
    );
    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      showAtomToast(
        context,
        kind: AtomToastKind.bad,
        message: problems.values.first,
      );
      return;
    }
    // A sent quote can't be previewed by saving a draft: share its PDF.
    final rev = nextRevision(widget.quotes);
    setState(() => _saving = mode);
    final repo = ref.read(bulkRepositoryProvider);
    final r = await repo.saveQuote(
      _request.id,
      lines: _values,
      deliveryCharge: _deliveryCharge,
      validUntil: _validUntil,
      advancePct: _advance,
      balanceTerms: _terms,
      notes: _notes.text,
      send: mode == 'send',
    );
    if (!mounted) return;
    switch (r) {
      case ApiOk(:final value):
        refreshRequest(ref, _request.id);
        _dirty = false;
        if (mode == 'pdf') {
          final failure = await handOverServerPdf(
            ref.read(apiClientProvider),
            repo.quotePdf(value),
          );
          if (!mounted) return;
          setState(() => _saving = null);
          if (failure != null) {
            showAtomToast(
              context,
              kind: AtomToastKind.bad,
              message: sayPdfFailure(l, failure),
            );
          } else {
            showAtomToast(
              context,
              kind: AtomToastKind.ok,
              message: l.bulkSavedAsDraft(value.name),
            );
          }
          return;
        }
        setState(() => _saving = null);
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: mode == 'send'
              ? l.bulkQuoteSentToast(value.name)
              : rev.draft == null
              ? l.bulkDraftSaved
              : l.bulkDraftSavedName(value.name),
        );
        Navigator.of(context).pop();
        if (mode == 'send' && value.whatsappLink != null) {
          await openWhatsApp(link: value.whatsappLink);
        }
      case ApiErr(:final failure):
        setState(() {
          _saving = null;
          _problems = {
            for (final e in failure.fieldErrors.entries)
              _fieldKey(e.key): e.value,
          };
        });
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: sayFailure(l, failure),
        );
    }
  }

  /// The server's `items.2.qty` is this screen's `line.2`.
  static String _fieldKey(String server) {
    final m = RegExp(r'^items\.(\d+)').firstMatch(server);
    return m == null ? server : 'line.${m.group(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _request;
    final rev = nextRevision(widget.quotes);
    final t = _totals;
    final s = widget.dossier.sourcing;
    final target = s?.targetPrice ?? r.targetPrice;
    final title = s?.title ?? r.title;
    final qty = s?.quantity ?? r.quantity;
    final busy = _saving != null;

    return AtomUnsavedGuard(
      dirty: _dirty && !busy,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          children: [
            AtomFlowBar(title: l.bulkQuoteFor(r.who), oneLine: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: l.bulkTheyAskedFor),
                        TextSpan(
                          text: '$qty × $title',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AtomColors.ink,
                          ),
                        ),
                        if (target != null)
                          TextSpan(text: l.bulkHopingForTail(formatRs(target))),
                        TextSpan(
                          text: rev.draft != null
                              ? l.bulkChangingDraft('${rev.revision}')
                              : rev.replaces != null
                              ? l.bulkSendingMakesRev(
                                  '${rev.revision}',
                                  '${rev.replaces!.revision}',
                                )
                              : '.',
                        ),
                      ],
                    ),
                    style: AtomText.secondary,
                  ),
                  if (s?.typed ?? false) ...[
                    const SizedBox(height: 10),
                    AtomNote(
                      kind: AtomNoteKind.info,
                      compact: true,
                      message: l.bulkTypedNote,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.bulkLinesHeader, style: AtomText.section),
                      ),
                      Text(l.bulkUpTo('$maxQuoteLines'), style: AtomText.small),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BulkCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _lines.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AtomColors.line),
                          _lineEditor(i),
                        ],
                        if (_lines.length < maxQuoteLines)
                          AtomPressable(
                            onTap: _addLine,
                            semanticLabel: l.bulkAddLine,
                            scaleOnPress: false,
                            builder: (_, _) => Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AtomColors.line),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.plus,
                                    size: 18,
                                    color: AtomColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      l.bulkAddLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AtomText.body.copyWith(
                                        color: AtomColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_problems['lines'] case final p?) ...[
                    const SizedBox(height: 6),
                    AtomFieldError(p),
                  ],
                  const SizedBox(height: 14),
                  Text(l.bulkTermsHeader, style: AtomText.section),
                  const SizedBox(height: 8),
                  BulkCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AtomTextField(
                                label: l.bulkDeliveryCharge,
                                controller: _delivery,
                                placeholder: '0',
                                prefix: Text('Rs', style: AtomText.secondary),
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  RupeesInputFormatter(maxDigits: 7),
                                ],
                                error:
                                    _problems['delivery'] ??
                                    _problems['delivery_charge'],
                                onChanged: (_) => _changed(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AtomField(
                                label: l.bulkValidUntilLabel,
                                error: _problems['valid_until'],
                                child: AtomSelectBox(
                                  text: AtomDates.day(_validUntil),
                                  onTap: _pickValidUntil,
                                  semanticLabel: l.bulkValidUntilLabel,
                                  error: _problems['valid_until'] != null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AtomField(
                          label: l.bulkPayAdvance,
                          error:
                              _problems['advance'] ?? _problems['advance_pct'],
                          child: AtomChoiceGrid<int>(
                            choices: [
                              for (final a in advanceChoices)
                                AtomSegment(a, a == 0 ? l.bulkNone : '$a%'),
                            ],
                            selected: _advance,
                            onChanged: (v) => _changed(() => _advance = v),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AtomField(
                          label: l.bulkBalance,
                          child: AtomSegmented<String>(
                            segments: [
                              for (final k in const [
                                'before_each',
                                'before_last',
                              ])
                                AtomSegment(
                                  k,
                                  widget.options.balanceTerms
                                          .where((b) => b.key == k)
                                          .firstOrNull
                                          ?.label ??
                                      balanceTermsLabel(l, k),
                                ),
                            ],
                            selected: _terms,
                            onChanged: (v) => _changed(() => _terms = v),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AtomTextField(
                          label: l.bulkNotes,
                          labelNote: l.bulkNotesNote,
                          controller: _notes,
                          placeholder: l.bulkNotesHint,
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(maxNotes),
                          ],
                          error: _problems['notes'],
                          onChanged: (_) => _changed(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AtomButton(
                    label: l.bulkPreviewPdf,
                    savingLabel: l.bulkGettingPdf,
                    icon: LucideIcons.fileText,
                    kind: AtomButtonKind.outline,
                    saving: _saving == 'pdf',
                    onPressed: busy ? null : () => _save('pdf'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.bulkPdfDraftNote,
                    style: AtomText.small.copyWith(color: AtomColors.faint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _Totals(
              totals: t,
              busy: _saving,
              onDraft: busy ? null : () => _save('draft'),
              onSend: busy ? null : () => _save('send'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineEditor(int i) {
    final l = AppLocalizations.of(context);
    final line = _lines[i];
    final v = line.value;
    final product = widget.options.product(v.productId);
    final colours = product?.colors ?? const <QuoteVariant>[];
    final problem = _problems['line.$i'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AtomSelectField<String>(
                  label: l.bulkProductVariant,
                  value: v.productId == null
                      ? null
                      : '${v.productId}:${v.memoryId ?? ''}',
                  valueLabel: _productLabel(v),
                  placeholder: l.bulkChooseProduct,
                  sheetTitle: l.bulkProductVariant,
                  searchHint: l.bulkSearchProducts,
                  options: _productOptions,
                  error: problem != null && v.productId == null
                      ? problem
                      : null,
                  onChanged: (value) => _pickProduct(line, value),
                ),
              ),
              if (_lines.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: AtomIconButton(
                    icon: LucideIcons.trash2,
                    label: l.bulkRemoveLine(i + 1),
                    color: AtomColors.faint,
                    onTap: () => _removeLine(i),
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Grid3(
              children: [
                // Colour, Qty, Discount % (`.g3`): the colour lists the
                // product's colours; a product with none quotes Any.
                AtomSelectField<int>(
                  label: l.bulkColour,
                  value: v.colorId,
                  valueLabel: colours
                      .where((c) => c.id == v.colorId)
                      .firstOrNull
                      ?.title,
                  placeholder: l.bulkAny,
                  sheetTitle: l.bulkColour,
                  options: [
                    for (final c in colours)
                      AtomOption(value: c.id, label: c.title),
                  ],
                  onChanged: colours.isEmpty
                      ? null
                      : (c) => _changed(
                          () => line.value = line.value.copyWith(
                            colorId: () => c,
                          ),
                        ),
                ),
                AtomField(
                  label: l.bulkQty,
                  child: _Stepper(
                    value: v.qty,
                    onChanged: (q) => _changed(
                      () => line.value = line.value.copyWith(qty: q),
                    ),
                  ),
                ),
                AtomTextField(
                  label: l.bulkDiscountPct,
                  controller: line.disc,
                  placeholder: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,3}(\.\d{0,2})?'),
                    ),
                  ],
                  onChanged: (t) => _changed(
                    () => line.value = line.value.copyWith(
                      discountPct: (double.tryParse(t) ?? 0).clamp(0, 100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AtomTextField(
                    label: l.bulkUnitPrice,
                    controller: line.price,
                    placeholder: '0',
                    prefix: Text('Rs', style: AtomText.secondary),
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupeesInputFormatter()],
                    onChanged: (t) => _changed(
                      () => line.value = line.value.copyWith(
                        unitPrice: parseRupees(t),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded: right-aligned at the card's edge, as the board.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l.bulkLineTotal, style: AtomText.small),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatRs(v.total),
                            style: AtomText.money.copyWith(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (problem != null && v.productId != null) ...[
            const SizedBox(height: 6),
            AtomFieldError(problem),
          ],
        ],
      ),
    );
  }
}

/// `.g3`: three fields side by side; at large text, one under another.
class _Grid3 extends StatelessWidget {
  const _Grid3({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(10) >= 14) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            c,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, c) in children.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: c),
        ],
      ],
    );
  }
}

/// `.stepper`: − qty +.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  static const min = 1;
  static const max = maxQty;

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        // `.stepper button` is 36 wide; in a third of a narrow card the
        // buttons give room to the number, down to 28.
        final w = box.maxWidth.isFinite ? box.maxWidth : 140.0;
        final bw = ((w - 2 - 28) / 2).clamp(28.0, 48.0);
        Widget button(IconData icon, String label, int? next) => SizedBox(
          width: bw,
          height: AtomSize.control - 2,
          child: AtomPressable(
            onTap: next == null ? null : () => onChanged(next),
            semanticLabel: label,
            builder: (_, _) => Icon(
              icon,
              size: 18,
              color: next == null ? AtomColors.line2 : AtomColors.ink,
            ),
          ),
        );
        return Container(
          height: AtomSize.control,
          decoration: BoxDecoration(
            color: AtomColors.paper,
            borderRadius: AtomRadius.brControl,
            border: Border.all(color: AtomColors.line2),
          ),
          child: Row(
            children: [
              button(
                LucideIcons.minus,
                l.bulkLess,
                value > min ? value - 1 : null,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: AtomText.money,
                  ),
                ),
              ),
              button(
                LucideIcons.plus,
                l.bulkMore,
                value < max ? value + 1 : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The figures pinned under the quote (`.tot`) and its two buttons.
class _Totals extends StatelessWidget {
  const _Totals({
    required this.totals,
    required this.busy,
    required this.onDraft,
    required this.onSend,
  });

  final QuoteTotals totals;
  final String? busy;
  final VoidCallback? onDraft;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = totals;
    // `.tot .r`: 13px rows, kept tight so the panel stays compact.
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AtomText.secondary.copyWith(fontSize: 13, height: 1.3),
            ),
          ),
          // Right-aligned: a bare Flexible text sat mid-row.
          Flexible(
            child: Align(
              heightFactor: 1,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AtomText.money.copyWith(fontSize: 13, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      decoration: const BoxDecoration(
        color: AtomColors.paper,
        border: Border(top: BorderSide(color: AtomColors.line)),
        boxShadow: [AtomShadow.float],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l.bulkQuoteTotal,
                    style: AtomText.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Expanded, so the total sits at the right edge (a loose
                // Flexible left it mid-row).
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      formatRs(t.total),
                      style: AtomText.money.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // The breakdown never takes more than a fifth of the screen: at
          // large text it scrolls, and the buttons stay in view.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .2,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row(l.bulkUnitsSubtotal(t.units), formatRs(t.gross)),
                  row(
                    l.bulkDiscountDelivery,
                    '−${formatRs(t.discount)} · +${formatRs(t.delivery)}',
                  ),
                  row(
                    t.advancePct == 0
                        ? l.bulkAdvanceNone
                        : l.bulkAdvanceRow(t.advancePct),
                    formatRs(t.advance),
                  ),
                  row(l.bulkBalance, formatRs(t.balance)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: AtomButton(
                  label: l.bulkSaveDraft,
                  kind: AtomButtonKind.outline,
                  saving: busy == 'draft',
                  oneLine: true,
                  padding: 8,
                  onPressed: onDraft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 17,
                child: AtomButton(
                  label: l.bulkSaveSendWhatsApp,
                  icon: AtomBrandIcons.whatsapp,
                  kind: AtomButtonKind.whatsapp,
                  saving: busy == 'send',
                  oneLine: true,
                  padding: 8,
                  onPressed: onSend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
