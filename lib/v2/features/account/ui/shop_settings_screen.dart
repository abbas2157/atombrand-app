import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/access/access.dart';
import '../../../core/access/access_controller.dart';
import '../../../core/api/api_result.dart';
import '../../../core/net/network_status.dart';
import '../../../design/design.dart';
import '../../../widgets/widgets.dart';
import '../data/shop_settings.dart';
import 'account_parts.dart';

/// Shop settings (18.2, owner): how customers pay you, how fast to confirm
/// orders, when the portal signs out, the low-stock number, Atom's
/// language and the receipt note. The same fields as the brand portal.
class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  ShopSettings? _loaded;
  late ShopSettings _s;
  final _bankName = TextEditingController();
  final _bankTitle = TextEditingController();
  final _iban = TextEditingController();
  final _jazzcash = TextEditingController();
  final _easypaisa = TextEditingController();
  final _lowStock = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  bool _tried = false;
  Map<String, String> _serverErrors = const {};

  List<TextEditingController> get _fields => [
    _bankName,
    _bankTitle,
    _iban,
    _jazzcash,
    _easypaisa,
    _lowStock,
    _note,
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _fields) {
      c.addListener(_typed);
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(ShopSettings s) {
    if (_loaded != null) return;
    _loaded = s;
    _s = s;
    _bankName.text = s.bankName ?? '';
    _bankTitle.text = s.bankTitle ?? '';
    _iban.text = s.bankIban ?? '';
    _jazzcash.text = s.jazzcash ?? '';
    _easypaisa.text = s.easypaisa ?? '';
    _lowStock.text = '${s.lowStockAt}';
    _note.text = s.receiptNote ?? '';
  }

  void _typed() {
    if (_loaded == null) return;
    setState(() {
      _s = _s.copyWith(
        bankName: _bankName.text,
        bankTitle: _bankTitle.text,
        bankIban: _iban.text,
        jazzcash: _jazzcash.text,
        easypaisa: _easypaisa.text,
        lowStockAt: int.tryParse(_lowStock.text) ?? -1,
        receiptNote: _note.text,
      );
      _serverErrors = const {};
    });
  }

  void _set(ShopSettings s) => setState(() {
    _s = s;
    _serverErrors = const {};
  });

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _tried = true);
    if (shopSettingsProblems(l, _s).isNotEmpty) return;
    setState(() => _saving = true);
    final r = await ref.read(shopSettingsRepositoryProvider).save(_s);
    if (!mounted) return;
    switch (r) {
      case ApiOk(:final value):
        _loaded = null;
        _fill(value);
        ref.invalidate(shopSettingsProvider);
        setState(() {
          _saving = false;
          _tried = false;
        });
        showAtomToast(
          context,
          kind: AtomToastKind.ok,
          message: l.acctShopSaved,
        );
      case ApiErr(:final failure):
        setState(() {
          _saving = false;
          _serverErrors = failure.fieldErrors;
        });
        showAtomToast(
          context,
          kind: AtomToastKind.bad,
          message: failure.fieldErrors.isNotEmpty
              ? failure.fieldErrors.values.first
              : sayFailure(l, failure),
          actionLabel: failure.fieldErrors.isEmpty ? l.commonTryAgain : null,
          onAction: failure.fieldErrors.isEmpty ? _save : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(shopSettingsProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final page = data.value;
    if (page != null) _fill(page.settings);
    final dirty = _loaded != null && _s != _loaded;
    return AtomUnsavedGuard(
      dirty: dirty && !_saving,
      child: Scaffold(
        backgroundColor: AtomColors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtomFlowBar(title: l.menuShopSettings),
            Expanded(
              child: switch (data) {
                _ when _loaded != null => _form(),
                AsyncError(:final error) => AccountError(
                  error: error,
                  onRetry: () => ref.invalidate(shopSettingsProvider),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(16),
                  child: AtomLoadingRows(count: 6),
                ),
              },
            ),
            if (_loaded != null)
              Container(
                color: AtomColors.paper,
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!online)
                      AtomButtonReason(reason: l.syncNeedsInternet)
                    else if (_tried && shopSettingsProblems(l, _s).isNotEmpty)
                      AtomButtonReason(
                        reason: shopSettingsProblems(l, _s).values.first,
                      ),
                    AtomButton(
                      label: l.commonSave,
                      saving: _saving,
                      onPressed: online && dirty ? _save : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _error(String field) =>
      _serverErrors[field] ??
      (_tried
          ? shopSettingsProblems(AppLocalizations.of(context), _s)[field]
          : null);

  Widget _form() {
    final l = AppLocalizations.of(context);
    final s = _s;
    final access = ref.watch(accessProvider);
    final inventory = access.has(Addon.inventory);
    final atom = access.has(Addon.askAtom);
    Widget toggle(String label, String sub, bool on, ValueChanged<bool> set) =>
        _ToggleRow(label: label, sub: sub, value: on, onChanged: set);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        AccountLabel(l.acctShopHowPaid),
        AccountCard(
          children: [
            toggle(
              l.acctShopCod,
              l.acctShopCodSub,
              s.payCod,
              (v) => _set(s.copyWith(payCod: v)),
            ),
            toggle(
              l.acctShopBank,
              l.acctShopBankSub,
              s.payBank,
              (v) => _set(s.copyWith(payBank: v)),
            ),
            toggle(
              l.acctShopWallet,
              l.acctShopWalletSub,
              s.payWallet,
              (v) => _set(s.copyWith(payWallet: v)),
            ),
          ],
        ),
        if (_error('pay') case final e?) ...[
          const SizedBox(height: 6),
          AtomFieldError(e),
        ],
        if (s.payBank) ...[
          const SizedBox(height: 12),
          AtomTextField(
            label: l.acctBankName,
            controller: _bankName,
            error: _error('bank_name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AtomTextField(
            label: l.acctAccountTitle,
            controller: _bankTitle,
            error: _error('bank_title'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AtomTextField(
            label: l.acctIban,
            controller: _iban,
            placeholder: 'PK36 MEZN 0002 4501 0123 4567',
            error: _error('bank_iban'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 ]')),
              _UpperCase(),
            ],
          ),
        ],
        if (s.payWallet) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AtomTextField(
                  label: l.acctJazzCash,
                  controller: _jazzcash,
                  placeholder: '0300 1234567',
                  error: _error('jazzcash'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AtomTextField(
                  label: l.acctEasypaisa,
                  controller: _easypaisa,
                  placeholder: '0345 1234567',
                  error: _error('easypaisa'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
                  ],
                ),
              ),
            ],
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
          child: Text(l.acctShopCashAlways, style: AtomText.small),
        ),
        // The board's `.lbl` sits 18 below the note above it.
        const SizedBox(height: 12),
        AccountLabel(l.acctShopOrdersPortal),
        Text(l.acctShopConfirmWithin, style: AtomText.fieldLabel),
        const SizedBox(height: 6),
        AtomChips<int>(
          chips: [
            for (final h in ShopSettings.confirmChoices)
              AtomChip(h, l.acctHours(h)),
          ],
          selected: s.confirmHours,
          onChanged: (h) => _set(s.copyWith(confirmHours: h)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Text(l.acctShopConfirmNote, style: AtomText.small),
        ),
        Text(l.acctShopIdle, style: AtomText.fieldLabel),
        const SizedBox(height: 6),
        AtomChips<int>(
          chips: [
            for (final m in ShopSettings.idleChoices)
              AtomChip(m, l.acctMinutes(m)),
          ],
          selected: s.idleMinutes,
          onChanged: (m) => _set(s.copyWith(idleMinutes: m)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
          child: Text(l.acctShopIdleNote, style: AtomText.small),
        ),
        // Running low at and Atom language: side by side as on 18.2; a
        // narrow phone or large text stacks them, so the label and its
        // "0–100 units" note never squeeze into a half-width column.
        if (inventory || atom) ...[
          const SizedBox(height: 12),
          _PairOrStack(
            children: [
              if (inventory)
                AtomTextField(
                  label: l.acctShopLowAt,
                  labelNote: l.acctShopLowAtNote,
                  controller: _lowStock,
                  error: _error('low_stock_at'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
              if (atom)
                AtomSelectField<String>(
                  label: l.acctShopAtomLanguage,
                  value: s.atomLanguage,
                  valueLabel: _language(l, s.atomLanguage),
                  sheetTitle: l.acctShopAtomAnswersIn,
                  options: [
                    for (final code in ShopSettings.languages)
                      AtomOption(value: code, label: _language(l, code)),
                  ],
                  onChanged: (code) => _set(s.copyWith(atomLanguage: code)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        AtomTextField(
          label: l.acctShopReceiptNote,
          labelNote: l.acctShopReceiptNoteLimit,
          controller: _note,
          placeholder: l.acctShopReceiptHint,
          error: _error('receipt_note'),
          minLines: 2,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
        ),
      ],
    );
  }
}

/// Two fields side by side (18.2's `.two`) from 340 wide at normal text
/// size (a 390 phone and up), else one
/// under the other, 12 apart.
class _PairOrStack extends StatelessWidget {
  const _PairOrStack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.textScalerOf(context).scale(10) > 12;
    return LayoutBuilder(
      builder: (context, box) {
        if (children.length < 2 || box.maxWidth < 340 || big) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 10),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}

String _language(AppLocalizations l, String code) => switch (code) {
  'en' => l.acctLangEnglish,
  'roman-ur' => l.acctLangRomanUrdu,
  'ur' => 'اردو',
  _ => l.acctLangAuto,
};

/// `.tg`: a label, a line under it and a switch.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AtomText.listTitle),
                    if (sub.isNotEmpty) Text(sub, style: AtomText.small),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AtomSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
