import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_icons.dart';

import '../../core/images.dart';
import '../../core/theme.dart';
import '../../data/models/order.dart';
import '../../widgets/feedback.dart';

/// What a status bottom sheet collected for one `actions[]` entry.
class StatusInput {
  StatusInput({this.receivedBy, this.picture, this.reason, this.flags = const {}});
  final String? receivedBy;
  final PickedImage? picture;
  final String? reason;
  final Set<String> flags;
}

const _flagLabels = {
  'customer_verification_failed': 'Customer verification failed',
  'installment_plan_rejected': 'Instalment plan rejected',
  'product_unavailable': 'Product unavailable',
};

/// Collects an action's `fields` (§3.3): the photo picker for
/// `delivered_pictrue`, reason + checkboxes for cancel.
Future<StatusInput?> showStatusSheet(BuildContext context, OrderAction action) {
  return showModalBottomSheet<StatusInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StatusSheet(action),
  );
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet(this.action);
  final OrderAction action;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  final _receivedBy = TextEditingController();
  final _reason = TextEditingController();
  final _flags = <String>{};
  PickedImage? _picture;
  bool _picking = false;

  List<String> get _fields => widget.action.fields;

  @override
  void dispose() {
    _receivedBy.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final img = await pickImage(source: source);
      if (!mounted) return;
      if (img == null) return;
      setState(() => _picture = img);
    } catch (_) {
      if (mounted) showToast(context, "Couldn't use that photo. Try another one.");
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = widget.action;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(a.label, style: t.titleLarge),
            const SizedBox(height: 16),
            if (_fields.contains('recieved_by')) ...[
              TextField(
                controller: _receivedBy,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Received by', hintText: 'Who signed for it?'),
              ),
              const SizedBox(height: 8),
            ],
            if (_fields.contains('delivered_pictrue')) ...[
              Text('Proof of delivery photo', style: t.labelMedium),
              const SizedBox(height: 8),
              if (_picture != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      child: Image.memory(_picture!.bytes, height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filledTonal(
                        tooltip: 'Remove photo',
                        icon: const Icon(AppIcons.close),
                        onPressed: () => setState(() => _picture = null),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _picking ? null : () => _pick(ImageSource.camera),
                        icon: const Icon(AppIcons.camera),
                        label: const Text('Take photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                        icon: const Icon(AppIcons.gallery),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
            if (_fields.contains('reason')) ...[
              TextField(
                controller: _reason,
                maxLength: 1000,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
              ),
            ],
            for (final f in _fields.where(_flagLabels.containsKey))
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _flags.contains(f),
                title: Text(_flagLabels[f]!),
                onChanged: (v) => setState(() => v == true ? _flags.add(f) : _flags.remove(f)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              style: a.isCancel ? FilledButton.styleFrom(backgroundColor: AppPalette.of(context).danger, foregroundColor: AppPalette.of(context).onPrimary) : null,
              onPressed: _picking
                  ? null
                  : () => Navigator.pop(
                        context,
                        StatusInput(
                          receivedBy: _receivedBy.text.trim(),
                          picture: _picture,
                          reason: _reason.text.trim(),
                          flags: Set.of(_flags),
                        ),
                      ),
              child: Text(a.isCancel ? 'Cancel order' : a.label),
            ),
          ],
        ),
      ),
    );
  }
}
