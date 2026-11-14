import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../../l10n/app_localizations.dart';
import 'billing_repository.dart' show accountWho;

/// Shop settings (18.2, owner): `GET settings` / `POST settings`
/// (`Brand::SETTINGS`, `Brand::settingsRules()`). Saving sends every key;
/// a missing `pay_*` is off.
@immutable
class ShopSettings {
  const ShopSettings({
    this.payCod = true,
    this.payBank = false,
    this.payWallet = false,
    this.bankName,
    this.bankTitle,
    this.bankIban,
    this.jazzcash,
    this.easypaisa,
    this.confirmHours = 4,
    this.lowStockAt = 3,
    this.receiptNote,
    this.idleMinutes = 30,
    this.atomLanguage = 'auto',
  });

  final bool payCod;
  final bool payBank;
  final bool payWallet;
  final String? bankName;
  final String? bankTitle;
  final String? bankIban;
  final String? jazzcash;
  final String? easypaisa;

  /// 2, 4, 8 or 24.
  final int confirmHours;

  /// 0–100.
  final int lowStockAt;

  /// Up to 200 characters, printed on receipts.
  final String? receiptNote;

  /// 15 or 30: the portal signs out after this.
  final int idleMinutes;

  /// auto, en, roman-ur or ur.
  final String atomLanguage;

  static const confirmChoices = [2, 4, 8, 24];
  static const idleChoices = [15, 30];
  static const languages = ['auto', 'en', 'roman-ur', 'ur'];

  factory ShopSettings.fromJson(Object? raw) {
    final s = Json.map(raw);
    return ShopSettings(
      payCod: s['pay_cod'] == null || Json.flag(s['pay_cod']),
      payBank: Json.flag(s['pay_bank']),
      payWallet: Json.flag(s['pay_wallet']),
      bankName: Json.str(s['bank_name']),
      bankTitle: Json.str(s['bank_title']),
      bankIban: Json.str(s['bank_iban']),
      jazzcash: Json.str(s['jazzcash']),
      easypaisa: Json.str(s['easypaisa']),
      confirmHours: Json.integer(s['confirm_hours']) ?? 4,
      lowStockAt: Json.integer(s['low_stock_at']) ?? 3,
      receiptNote: Json.str(s['receipt_note']),
      idleMinutes: Json.integer(s['idle_minutes']) ?? 30,
      atomLanguage: Json.str(s['atom_language']) ?? 'auto',
    );
  }

  Map<String, dynamic> toBody() => {
    'pay_cod': payCod,
    'pay_bank': payBank,
    'pay_wallet': payWallet,
    'bank_name': bankName,
    'bank_title': bankTitle,
    'bank_iban': bankIban,
    'jazzcash': jazzcash,
    'easypaisa': easypaisa,
    'confirm_hours': confirmHours,
    'low_stock_at': lowStockAt,
    'receipt_note': receiptNote,
    'idle_minutes': idleMinutes,
    'atom_language': atomLanguage,
  };

  ShopSettings copyWith({
    bool? payCod,
    bool? payBank,
    bool? payWallet,
    String? bankName,
    String? bankTitle,
    String? bankIban,
    String? jazzcash,
    String? easypaisa,
    int? confirmHours,
    int? lowStockAt,
    String? receiptNote,
    int? idleMinutes,
    String? atomLanguage,
  }) => ShopSettings(
    payCod: payCod ?? this.payCod,
    payBank: payBank ?? this.payBank,
    payWallet: payWallet ?? this.payWallet,
    bankName: bankName ?? this.bankName,
    bankTitle: bankTitle ?? this.bankTitle,
    bankIban: bankIban ?? this.bankIban,
    jazzcash: jazzcash ?? this.jazzcash,
    easypaisa: easypaisa ?? this.easypaisa,
    confirmHours: confirmHours ?? this.confirmHours,
    lowStockAt: lowStockAt ?? this.lowStockAt,
    receiptNote: receiptNote ?? this.receiptNote,
    idleMinutes: idleMinutes ?? this.idleMinutes,
    atomLanguage: atomLanguage ?? this.atomLanguage,
  );

  @override
  bool operator ==(Object other) =>
      other is ShopSettings &&
      other.payCod == payCod &&
      other.payBank == payBank &&
      other.payWallet == payWallet &&
      _same(other.bankName, bankName) &&
      _same(other.bankTitle, bankTitle) &&
      _same(other.bankIban, bankIban) &&
      _same(other.jazzcash, jazzcash) &&
      _same(other.easypaisa, easypaisa) &&
      other.confirmHours == confirmHours &&
      other.lowStockAt == lowStockAt &&
      _same(other.receiptNote, receiptNote) &&
      other.idleMinutes == idleMinutes &&
      other.atomLanguage == atomLanguage;

  @override
  int get hashCode => Object.hash(
    payCod,
    payBank,
    payWallet,
    confirmHours,
    lowStockAt,
    idleMinutes,
    atomLanguage,
  );

  static bool _same(String? a, String? b) =>
      (a ?? '').trim() == (b ?? '').trim();
}

/// A Pakistani IBAN: PK, two check digits, four letters (the bank), then
/// sixteen digits; spaces allowed.
final _iban = RegExp(r'^PK\d{2}[A-Z]{4}\d{16}$');

/// A JazzCash or Easypaisa number: 03XX XXXXXXX.
final _wallet = RegExp(r'^03\d{9}$');

/// Field → problem, by the server's rules, so the person sees them before
/// saving. Empty when it can be saved.
Map<String, String> shopSettingsProblems(AppLocalizations l, ShopSettings s) {
  final out = <String, String>{};
  String clean(String? v) => (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
  if (!s.payCod && !s.payBank && !s.payWallet) {
    out['pay'] = l.acctShopNeedOnePay;
  }
  if (s.payBank) {
    if ((s.bankName ?? '').trim().isEmpty) {
      out['bank_name'] = l.acctShopNeedBankName;
    }
    if ((s.bankTitle ?? '').trim().isEmpty) {
      out['bank_title'] = l.acctShopNeedBankTitle;
    }
    final iban = clean(s.bankIban).toUpperCase();
    if (iban.isEmpty) {
      out['bank_iban'] = l.acctShopNeedIban;
    } else if (!_iban.hasMatch(iban)) {
      out['bank_iban'] = l.acctShopBadIban;
    }
  }
  if (s.payWallet) {
    final jc = clean(s.jazzcash), ep = clean(s.easypaisa);
    if (jc.isEmpty && ep.isEmpty) {
      out['jazzcash'] = l.acctShopNeedWallet;
    }
    if (jc.isNotEmpty && !_wallet.hasMatch(jc)) {
      out['jazzcash'] = l.acctShopBadMobile;
    }
    if (ep.isNotEmpty && !_wallet.hasMatch(ep)) {
      out['easypaisa'] = l.acctShopBadMobile;
    }
  }
  if (!ShopSettings.confirmChoices.contains(s.confirmHours)) {
    out['confirm_hours'] = l.acctShopPickHours;
  }
  if (s.lowStockAt < 0 || s.lowStockAt > 100) {
    out['low_stock_at'] = l.acctShopLowStockRange;
  }
  if ((s.receiptNote ?? '').length > 200) {
    out['receipt_note'] = l.acctShopNoteTooLong;
  }
  if (!ShopSettings.idleChoices.contains(s.idleMinutes)) {
    out['idle_minutes'] = l.acctShopPickMinutes;
  }
  return out;
}

/// Brand account (`account` in `GET settings`): set by Atomshop, read-only.
@immutable
class BrandAccount {
  const BrandAccount({
    this.brand,
    this.slug,
    this.status,
    this.accountType = 'single',
    this.outletLimit = 0,
    this.outletsUsed = 0,
    this.atompayWholeBrand = false,
    this.inventoryState,
    this.inventoryLabel,
    this.inventoryDaysLeft,
    this.partnerSince,
  });

  final String? brand;
  final String? slug;
  final String? status;
  final String accountType;
  final int outletLimit;
  final int outletsUsed;
  final bool atompayWholeBrand;
  final String? inventoryState;
  final String? inventoryLabel;
  final int? inventoryDaysLeft;
  final DateTime? partnerSince;

  bool get multi => accountType == 'multi';

  factory BrandAccount.fromJson(Object? raw) {
    final a = Json.map(raw);
    final inv = Json.map(a['inventory']);
    return BrandAccount(
      brand: Json.str(a['brand']),
      slug: Json.str(a['slug']),
      status: Json.str(a['status']),
      accountType: Json.str(a['account_type']) ?? 'single',
      outletLimit: Json.integer(a['outlet_limit']) ?? 0,
      outletsUsed: Json.integer(a['outlets_used']) ?? 0,
      atompayWholeBrand: Json.flag(a['atompay_whole_brand']),
      inventoryState: Json.str(inv['state']),
      inventoryLabel: Json.str(inv['label']),
      inventoryDaysLeft: Json.integer(inv['days_left']),
      partnerSince: AtomDates.parse(a['partner_since']),
    );
  }
}

/// `GET settings`: the settings and the brand account.
typedef ShopSettingsPage = ({ShopSettings settings, BrandAccount account});

abstract interface class ShopSettingsRepository {
  Future<ApiResult<ShopSettingsPage>> load();
  Future<ApiResult<ShopSettings>> save(ShopSettings s);
}

class ApiShopSettingsRepository implements ShopSettingsRepository {
  const ApiShopSettingsRepository(this._api);
  final ApiClient _api;

  @override
  Future<ApiResult<ShopSettingsPage>> load() => _api.get(
    'settings',
    parse: (data) => (
      settings: ShopSettings.fromJson(Json.map(data)['settings']),
      account: BrandAccount.fromJson(Json.map(data)['account']),
    ),
  );

  @override
  Future<ApiResult<ShopSettings>> save(ShopSettings s) => _api.post(
    'settings',
    body: s.toBody(),
    parse: (data) => ShopSettings.fromJson(Json.map(data)['settings']),
  );
}

final shopSettingsRepositoryProvider = Provider<ShopSettingsRepository>(
  (ref) => ApiShopSettingsRepository(ref.read(apiClientProvider)),
);

/// `GET settings` (owner).
final shopSettingsProvider = FutureProvider.autoDispose<ShopSettingsPage>((
  ref,
) async {
  accountWho(ref);
  return switch (await ref.read(shopSettingsRepositoryProvider).load()) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});
