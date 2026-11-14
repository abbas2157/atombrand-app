import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';
import '../../../core/api/api_result.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../../orders/data/orders_providers.dart';
import '../../orders/ui/order_parts.dart';
import '../../orders/ui/order_scanner.dart';
import '../../sync/data/offline_saves.dart';
import '../../sync/ui/saved_here_sheet.dart';
import '../data/atompay_models.dart';
import '../data/atompay_repository.dart';

/// What stops "Save hand-over" (6.10), or null: the person from the
/// seller's shop who took the unit is required.
String? handoverProblem({
  required String receivedBy,
  required AppLocalizations l,
}) => receivedBy.trim().isEmpty ? l.ordersSayWhoReceived : null;

/// Hand over the unit (6.10): the serial (scanned or typed), who from the
/// seller's shop took it, a note and a photo.
class AtompayHandoverScreen extends ConsumerStatefulWidget {
  const AtompayHandoverScreen({super.key, required this.uuid});
  final String uuid;

  @override
  ConsumerState<AtompayHandoverScreen> createState() =>
      _AtompayHandoverScreenState();
}

class _AtompayHandoverScreenState extends ConsumerState<AtompayHandoverScreen> {
  bool? _fits;
  bool _reread = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.invalidate(atompayDetailProvider(widget.uuid));
      setState(() => _reread = true);
    });
  }

  Widget _page(Widget child) => Scaffold(
    backgroundColor: AtomColors.paper,
    body: Column(
      children: [
        const AtomFlowBar(leading: AtomFlowLeading.close),
        Expanded(child: child),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final order = ref.watch(atompayDetailProvider(widget.uuid));
    final d = order.value;
    if (d == null || (_fits == null && (!_reread || order.isLoading))) {
      if (order.hasError && !order.isLoading) {
        final e = order.error;
        return _page(
          AtomErrorState(
            message: e is ApiFailure ? sayOrderFailure(e, l) : null,
            onRetry: () => ref.invalidate(atompayDetailProvider(widget.uuid)),
          ),
        );
      }
      return _page(const Center(child: AtomSpinner(size: 28)));
    }
    if (!(_fits ??= d.allowed.contains(AtompayAction.handover))) {
      return _page(
        AtomMessageState(
          icon: LucideIcons.listChecks,
          title: l.atompayNothingToHand,
          body: l.atompayAtStepNow(d.order.stepName(l)),
          actionLabel: l.ordersOpenOrder,
          onAction: () => context.canPop()
              ? context.pop()
              : context.go(V2Routes.atompayOf(widget.uuid)),
        ),
      );
    }
    return _HandoverForm(detail: d);
  }
}

class _HandoverForm extends ConsumerStatefulWidget {
  const _HandoverForm({required this.detail});
  final AtompayDetail detail;

  @override
  ConsumerState<_HandoverForm> createState() => _HandoverFormState();
}

class _HandoverFormState extends ConsumerState<_HandoverForm> {
  final _serial = TextEditingController();
  late final _receivedBy = TextEditingController(text: _defaultReceiver());
  final _note = TextEditingController();
  File? _photo;
  bool _saving = false;
  String? _error;

  String _defaultReceiver() {
    final s = widget.detail.seller;
    if (s?.contact case final c? when c.isNotEmpty) return '$c (${s!.name})';
    return '';
  }

  @override
  void dispose() {
    _serial.dispose();
    _receivedBy.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await scanSerial(context);
    if (code == null || !mounted) return;
    setState(() => _serial.text = code);
  }

  Future<void> _save() async {
    final d = widget.detail;
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref
        .read(atompayRepositoryProvider)
        .handover(
          d.uuid,
          receivedBy: _receivedBy.text,
          serial: _serial.text,
          note: _note.text,
          photo: _photo,
        );
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    switch (r) {
      case SavedOnServer():
        refreshAtompay(ref, d.uuid);
        refreshOrder(ref, d.uuid);
        Navigator.of(context).pop();
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.atompayHandoverSaved,
        );
      case SavedHere():
        refreshAtompay(ref, d.uuid);
        Navigator.of(context).pop();
        showSavedHereToast(context);
      case SaveFailed(:final failure):
        setState(() {
          _saving = false;
          _error =
              failure.fieldErrors['serial'] ??
              failure.fieldErrors['received_by'] ??
              sayOrderFailure(failure, l);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.detail;
    final serial = _serial.text.trim();
    final problem = handoverProblem(receivedBy: _receivedBy.text, l: l);
    const gap = SizedBox(height: 16);
    return AtomUnsavedGuard(
      dirty:
          !_saving &&
          (_photo != null || serial.isNotEmpty || _note.text.isNotEmpty),
      child: OrderFormPage(
        title: l.atompayHandOverUnit,
        subtitle: [
          d.order.number,
          d.order.productTitle,
          if (d.seller != null) l.atompayEvTo(d.seller!.name),
        ].join(' · '),
        body: [
          ScanTile(
            scanned: serial.isNotEmpty,
            onTap: _scan,
            caption: serial.isNotEmpty ? l.atompayScanRead : l.ordersScanPoint,
          ),
          gap,
          AtomTextField(
            label: l.ordersSerial,
            controller: _serial,
            placeholder: l.atompaySerialHint,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
          ),
          gap,
          AtomTextField(
            label: l.ordersReceivedBy,
            controller: _receivedBy,
            hint: l.atompayReceivedHint,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            onChanged: (_) => setState(() {}),
          ),
          gap,
          AtomTextField(
            label: l.atompayNote,
            labelNote: l.ordersOptional,
            labelNoteInline: true,
            controller: _note,
            minLines: 3,
            placeholder: l.atompayNoteHint,
            inputFormatters: [LengthLimitingTextInputFormatter(300)],
            onChanged: (_) => setState(() {}),
          ),
          gap,
          FieldLabel(l.atompayPhoto),
          PhotoBox(
            label: l.atompayPhotoHint,
            done: _photo != null,
            onTap: () async {
              final f = await takeOrderPhoto();
              if (f != null && mounted) setState(() => _photo = f);
            },
          ),
        ],
        bottom: [
          if (_error != null) ...[
            AtomNote(kind: AtomNoteKind.problem, message: _error!),
            const SizedBox(height: 10),
          ],
          AtomButton(
            label: problem ?? l.atompaySaveHandover,
            saving: _saving,
            onPressed: problem == null ? _save : null,
          ),
        ],
      ),
    );
  }
}
