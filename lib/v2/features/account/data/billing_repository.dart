import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/pdf/server_pdf.dart';
import '../../../core/session/session_controller.dart';
import 'billing_models.dart';

/// Plan & billing calls (owner only, docs/brand-app-billing.md).
abstract interface class BillingRepository {
  /// `GET billing`.
  Future<ApiResult<BillingOverview>> overview();

  /// `POST billing/quote`: what [months] and [addons] come to.
  Future<ApiResult<PlanQuote>> quote(int months, Set<String> addons);

  /// `POST billing/checkout`: one bill for the period ("Get my bill").
  Future<ApiResult<Invoice>> checkout(int months, Set<String> addons);

  /// `POST billing/addons/{key}`: on or off. Answers the add-on's status
  /// (off, trial or active) and any bill it made.
  Future<ApiResult<({String status, Invoice? invoice})>> switchAddon(
    String key,
    bool on,
  );

  /// `POST billing/pay` (multipart): "I've paid", with the screenshot.
  Future<ApiResult<void>> pay({
    required int amount,
    required String method,
    required DateTime paidOn,
    required File screenshot,
    int? invoiceId,
    String? reference,
  });
}

class ApiBillingRepository implements BillingRepository {
  const ApiBillingRepository(this._api);
  final ApiClient _api;

  @override
  Future<ApiResult<BillingOverview>> overview() =>
      _api.get('billing', parse: BillingOverview.fromJson);

  @override
  Future<ApiResult<PlanQuote>> quote(int months, Set<String> addons) =>
      _api.post(
        'billing/quote',
        body: {'period': months, 'addons': addons.toList()},
        parse: PlanQuote.fromJson,
      );

  @override
  Future<ApiResult<Invoice>> checkout(int months, Set<String> addons) =>
      _api.post(
        'billing/checkout',
        body: {'period': months, 'addons': addons.toList()},
        parse: (data) => Invoice.fromJson(Json.map(data)['invoice']),
      );

  @override
  Future<ApiResult<({String status, Invoice? invoice})>> switchAddon(
    String key,
    bool on,
  ) => _api.post(
    'billing/addons/$key',
    body: {'on': on},
    parse: (data) {
      final d = Json.map(data);
      return (
        status: Json.str(d['status']) ?? '',
        invoice: d['invoice'] is Map ? Invoice.fromJson(d['invoice']) : null,
      );
    },
  );

  @override
  Future<ApiResult<void>> pay({
    required int amount,
    required String method,
    required DateTime paidOn,
    required File screenshot,
    int? invoiceId,
    String? reference,
  }) => _api.postForm(
    'billing/pay',
    fields: {
      'invoice_id': ?invoiceId,
      'amount': amount,
      'method': method,
      'paid_on': AtomDates.api(paidOn),
      'reference': ?reference,
    },
    files: {'screenshot': screenshot},
    parse: (_) {},
  );
}

/// A bill as a PDF (`GET billing/bills/{number}`).
ServerPdf billPdf(String number) =>
    ServerPdf('billing/bills/$number', filename: '$number.pdf');

/// A receipt as a PDF (`GET billing/receipts/{number}`), once received.
ServerPdf receiptPdf(String number) =>
    ServerPdf('billing/receipts/$number', filename: '$number.pdf');

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => ApiBillingRepository(ref.read(apiClientProvider)),
);

/// Who is signed in, so a provider starts again for someone else.
Object? accountWho(Ref ref) => ref.watch(
  sessionProvider.select(
    (s) => s is SignedIn ? (s.session.userId, s.session.brandId) : null,
  ),
);

/// `GET billing`.
final billingProvider = FutureProvider.autoDispose<BillingOverview>((
  ref,
) async {
  accountWho(ref);
  return switch (await ref.read(billingRepositoryProvider).overview()) {
    ApiOk(:final value) => value,
    ApiErr(:final failure) => throw failure,
  };
});
