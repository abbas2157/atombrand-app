import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../../core/app_providers.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/pdf/phone_pdf.dart';
import '../../../../l10n/app_localizations.dart';
import 'billing_repository.dart' show accountWho;

/// Reports (12.4, 12.5): `GET reports` and `GET reports/{report}`
/// (docs/BRAND_APP.md "Portal v2: Reports"). Needs `money.reports`; every
/// figure is the server's (`BrandReportService`).

/// The period chips. `custom` carries `from` and `to`.
enum ReportPeriod {
  today('today'),
  month('month'),
  year('year'),
  all('all'),
  custom('custom');

  const ReportPeriod(this.key);
  final String key;

  /// The chip's words: Today, This month, This year, All time, Choose dates.
  String label(AppLocalizations l) => switch (this) {
    today => l.acctPeriodToday,
    month => l.acctPeriodMonth,
    year => l.acctPeriodYear,
    all => l.acctPeriodAll,
    custom => l.acctPeriodCustom,
  };

  static ReportPeriod fromKey(String? key) =>
      values.where((p) => p.key == key).firstOrNull ?? month;
}

/// The filters both calls take: the period, its dates, and one outlet.
@immutable
class ReportFilter {
  const ReportFilter({
    this.period = ReportPeriod.month,
    this.from,
    this.to,
    this.outletId,
    this.method,
  });

  final ReportPeriod period;

  /// A payment method (payments report); null for any.
  final String? method;
  final DateTime? from;
  final DateTime? to;
  final int? outletId;

  Map<String, dynamic> get query => {
    'period': period.key,
    if (period == ReportPeriod.custom && from != null)
      'from': AtomDates.api(from!),
    if (period == ReportPeriod.custom && to != null) 'to': AtomDates.api(to!),
    'outlet': ?outletId,
    'method': ?method,
  };

  ReportFilter copyWith({
    ReportPeriod? period,
    DateTime? Function()? from,
    DateTime? Function()? to,
    int? Function()? outletId,
    String? Function()? method,
  }) => ReportFilter(
    period: period ?? this.period,
    from: from != null ? from() : this.from,
    to: to != null ? to() : this.to,
    outletId: outletId != null ? outletId() : this.outletId,
    method: method != null ? method() : this.method,
  );

  @override
  bool operator ==(Object other) =>
      other is ReportFilter &&
      other.period == period &&
      other.from == from &&
      other.to == to &&
      other.outletId == outletId &&
      other.method == method;

  @override
  int get hashCode => Object.hash(period, from, to, outletId, method);
}

/// The four headline numbers for one period, and the line under each.
@immutable
class ReportTotals {
  const ReportTotals({
    this.cashSales = 0,
    this.received = 0,
    this.atompayPaid = 0,
    this.bulkWon = 0,
    this.cashOrders,
    this.stillDue,
    this.atompayUnits,
    this.bulkDeals,
  });

  final int cashSales;
  final int received;
  final int atompayPaid;
  final int bulkWon;

  /// The lines under the numbers; null from a server that doesn't send them.
  final int? cashOrders;
  final int? stillDue;
  final int? atompayUnits;
  final int? bulkDeals;

  factory ReportTotals.fromJson(Object? raw) {
    final j = Json.map(raw);
    return ReportTotals(
      cashSales: Json.integer(j['cash_sales']) ?? 0,
      received: Json.integer(j['received']) ?? 0,
      atompayPaid: Json.integer(j['atompay_paid']) ?? 0,
      bulkWon: Json.integer(j['bulk_won']) ?? 0,
      cashOrders: Json.integer(j['cash_orders']),
      stillDue: Json.integer(j['still_due']),
      atompayUnits: Json.integer(j['atompay_units']),
      bulkDeals: Json.integer(j['bulk_deals']),
    );
  }
}

/// One report card (`reports[]`).
@immutable
class ReportCard {
  const ReportCard({
    required this.key,
    required this.title,
    this.description,
    this.group,
  });

  final String key;
  final String title;
  final String? description;
  final String? group;

  factory ReportCard.fromJson(Object? raw) {
    final j = Json.map(raw);
    return ReportCard(
      key: Json.str(j['key']) ?? '',
      title: Json.str(j['title']) ?? '',
      description: Json.str(j['description']),
      group: Json.str(j['group']),
    );
  }
}

/// `GET reports`.
@immutable
class ReportsHome {
  const ReportsHome({
    this.periods = const {},
    this.labels = const {},
    this.months = const [],
    this.outlets = const [],
    this.reports = const [],
  });

  /// today, month, year (and custom when asked) → totals.
  final Map<String, ReportTotals> periods;

  /// today → "Saturday, 31 Oct 2026", month → "October 2026", year.
  final Map<String, String> labels;

  /// The last 6 months: label, cash sales, received.
  final List<({String label, int cashSales, int received})> months;

  /// The outlets to filter by; empty for a single-outlet brand.
  final List<({int id, String name})> outlets;
  final List<ReportCard> reports;

  /// The cards by their group, in the server's order ('' for no group).
  List<(String, List<ReportCard>)> get groups {
    final out = <String, List<ReportCard>>{};
    for (final r in reports) {
      (out[r.group ?? ''] ??= []).add(r);
    }
    return [for (final e in out.entries) (e.key, e.value)];
  }

  factory ReportsHome.fromJson(Object? data) {
    final d = Json.map(data);
    return ReportsHome(
      periods: {
        for (final e in Json.map(d['periods']).entries)
          e.key: ReportTotals.fromJson(e.value),
      },
      labels: {
        for (final e in Json.map(d['period_labels']).entries)
          e.key: ?Json.str(e.value),
      },
      months: [
        for (final m in Json.list(d['months']))
          (
            label: Json.str(Json.map(m)['label']) ?? '',
            cashSales: Json.integer(Json.map(m)['cash_sales']) ?? 0,
            received: Json.integer(Json.map(m)['received']) ?? 0,
          ),
      ],
      outlets: [
        for (final o in Json.list(d['outlets']))
          (
            id: Json.integer(Json.map(o)['id']) ?? 0,
            name: Json.str(Json.map(o)['name']) ?? '',
          ),
      ],
      reports: [
        for (final r in Json.list(d['reports'])) ReportCard.fromJson(r),
      ],
    );
  }
}

/// A column's kind: text, money, int, num or date.
enum ColumnType { text, money, int, num, date }

ColumnType columnType(String? t) =>
    ColumnType.values.where((c) => c.name == t).firstOrNull ?? ColumnType.text;

/// A value as its column shows it: money `Rs 12,345`, a date `30 Oct`, a
/// number with one decimal.
String formatCell(Object? value, ColumnType type) {
  if (value == null) return '';
  switch (type) {
    case ColumnType.money:
      final n = value is num ? value.round() : Json.integer(value);
      return n == null ? '$value' : formatRs(n);
    case ColumnType.int:
      final n = value is num ? value.round() : Json.integer(value);
      return n == null ? '$value' : groupDigits(n);
    case ColumnType.num:
      final n = value is num ? value : num.tryParse('$value');
      return n == null ? '$value' : n.toStringAsFixed(1);
    case ColumnType.date:
      final d = AtomDates.parse(value);
      return d == null ? '$value' : AtomDates.shortOrYear(d);
    case ColumnType.text:
      return '$value';
  }
}

@immutable
class ReportColumn {
  const ReportColumn(this.key, this.label, this.type);
  final String key;
  final String label;
  final ColumnType type;
}

@immutable
class ReportTable {
  const ReportTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.key = '',
    this.phone,
    this.totals,
  });

  final String key;
  final String title;
  final List<ReportColumn> columns;

  /// The three columns a phone shows (12.5); null to pick them here.
  final List<ReportColumn>? phone;

  /// What a phone shows: the server's three, else the first three.
  List<ReportColumn> get phoneColumns =>
      phone ?? columns.take(3).toList(growable: false);
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic>? totals;

  factory ReportTable.fromJson(Object? raw) {
    final j = Json.map(raw);
    List<ReportColumn> cols(Object? list) => [
      for (final c in Json.list(list))
        ReportColumn(
          Json.str(Json.map(c)['key']) ?? '',
          Json.str(Json.map(c)['label']) ?? '',
          columnType(Json.str(Json.map(c)['type'])),
        ),
    ];
    final phone = j['phone'] is List ? cols(j['phone']) : null;
    return ReportTable(
      key: Json.str(j['key']) ?? '',
      title: Json.str(j['title']) ?? '',
      columns: cols(j['columns']),
      phone: phone == null || phone.isEmpty ? null : phone,
      rows: [for (final r in Json.list(j['rows'])) Json.map(r)],
      totals: j['totals'] is Map ? Json.map(j['totals']) : null,
    );
  }
}

/// One chart: bars by label, the first series.
@immutable
class ReportChart {
  const ReportChart({
    required this.label,
    required this.type,
    required this.labels,
    required this.values,
  });

  final String label;

  /// bar, hbar, line…: drawn as bars, sideways for `hbar`.
  final String type;
  final List<String> labels;
  final List<num> values;

  bool get horizontal => type == 'hbar';

  factory ReportChart.fromJson(Object? raw) {
    final j = Json.map(raw);
    final spec = Json.map(j['spec']);
    final series = Json.list(spec['series']);
    final data = series.isEmpty
        ? const []
        : Json.list(Json.map(series.first)['data']);
    return ReportChart(
      label: Json.str(j['label']) ?? '',
      type: Json.str(spec['type']) ?? 'bar',
      labels: [for (final l in Json.list(spec['labels'])) '$l'],
      values: [for (final v in data) v is num ? v : (num.tryParse('$v') ?? 0)],
    );
  }
}

/// `GET reports/{report}`.
@immutable
class ReportData {
  const ReportData({
    required this.key,
    required this.title,
    this.description,
    this.periodKey,
    this.periodLabel,
    this.outletName,
    this.summary = const [],
    this.charts = const [],
    this.tables = const [],
    this.note,
    this.madeAt,
    this.phoneTable,
    this.methods = const {},
    this.method,
  });

  final String key;
  final String title;
  final String? description;

  /// The table a phone shows (`phone_table`); the first when not sent.
  final String? phoneTable;

  /// Payment methods to filter by (payments report): key → label.
  final Map<String, String> methods;

  /// The method chosen, as the server applied it.
  final String? method;

  ReportTable? get phoneTableData =>
      tables.where((t) => t.key == phoneTable).firstOrNull ??
      tables.firstOrNull;
  final String? periodKey;
  final String? periodLabel;
  final String? outletName;

  /// label → value as shown.
  final List<({String label, String value})> summary;
  final List<ReportChart> charts;
  final List<ReportTable> tables;
  final String? note;
  final String? madeAt;

  factory ReportData.fromJson(Object? data) {
    final d = Json.map(data);
    final period = Json.map(d['period']);
    return ReportData(
      key: Json.str(d['key']) ?? '',
      title: Json.str(d['title']) ?? '',
      description: Json.str(d['description']),
      periodKey: Json.str(period['key']),
      periodLabel: Json.str(period['label']),
      outletName: Json.str(Json.map(d['outlet'])['name']),
      summary: [
        for (final s in Json.list(d['summary']))
          (
            label: Json.str(Json.map(s)['label']) ?? '',
            value: formatCell(
              Json.map(s)['value'],
              columnType(Json.str(Json.map(s)['type'])),
            ),
          ),
      ],
      charts: [for (final c in Json.list(d['charts'])) ReportChart.fromJson(c)],
      tables: [for (final t in Json.list(d['tables'])) ReportTable.fromJson(t)],
      note: Json.str(d['note']),
      madeAt: Json.str(d['made_at']),
      phoneTable: Json.str(d['phone_table']),
      methods: {
        for (final e in Json.map(d['methods']).entries)
          e.key: ?Json.str(e.value),
      },
      method: Json.str(d['method']),
    );
  }
}

/// Reports with no dates (`stock`) or that default to all time (`cod-due`).
bool reportIgnoresDates(String key) => key == 'stock';
ReportPeriod reportDefaultPeriod(String key) =>
    key == 'cod-due' || key == 'stock' ? ReportPeriod.all : ReportPeriod.month;

/// The file format of a report download.
enum ReportFormat { pdf, excel }

/// The report as the PDF lays it out on the phone (`buildReportPdf`): the
/// summary, every table with its totals row, the note.
ReportSheet reportSheet(AppLocalizations l, ReportData r, {String? brand}) =>
    ReportSheet(
      title: r.title,
      subtitle: [
        ?brand,
        if (!reportIgnoresDates(r.key)) ?r.periodLabel,
        r.outletName ?? l.outletAll,
      ].join(' · '),
      summary: [for (final s in r.summary) (s.label, s.value)],
      tables: [
        for (final t in r.tables)
          if (t.rows.isNotEmpty)
            ReportSheetTable(
              title: r.tables.length > 1 ? t.title : '',
              head: [for (final c in t.columns) c.label],
              numeric: [
                for (final c in t.columns)
                  c.type != ColumnType.text && c.type != ColumnType.date,
              ],
              rows: [
                for (final row in t.rows)
                  [for (final c in t.columns) formatCell(row[c.key], c.type)],
                if (t.totals case final totals?)
                  [
                    for (final c in t.columns)
                      totals.containsKey(c.key)
                          ? formatCell(totals[c.key], c.type)
                          : (c == t.columns.first ? l.acctTotal : ''),
                  ],
              ],
            ),
      ],
      note: r.note,
      footer: r.madeAt == null ? 'Atombrand' : l.acctPdfFooterMade(r.madeAt!),
    );

abstract interface class ReportsRepository {
  Future<ApiResult<ReportsHome>> home(ReportFilter filter);
  Future<ApiResult<ReportData>> report(String key, ReportFilter filter);

  /// `GET reports/{report}/export?format=excel` (`money.export`). Not on
  /// the server yet: a 404 means "download it on the brand portal". The PDF
  /// is laid out on the phone from the report's data ([reportSheet]).
  Future<ApiResult<({Uint8List bytes, String? filename})>> export(
    String key,
    ReportFilter filter,
    ReportFormat format,
  );
}

class ApiReportsRepository implements ReportsRepository {
  const ApiReportsRepository(this._api);
  final ApiClient _api;

  @override
  Future<ApiResult<ReportsHome>> home(ReportFilter filter) =>
      _api.get('reports', query: filter.query, parse: ReportsHome.fromJson);

  @override
  Future<ApiResult<ReportData>> report(String key, ReportFilter filter) =>
      _api.get('reports/$key', query: filter.query, parse: ReportData.fromJson);

  @override
  Future<ApiResult<({Uint8List bytes, String? filename})>> export(
    String key,
    ReportFilter filter,
    ReportFormat format,
  ) async {
    final query = {...filter.query, 'format': format.name};
    if (format == ReportFormat.pdf) {
      return _api.getPdf('reports/$key/export', query: query);
    }
    final uri = Uri(
      path: 'reports/$key/export',
      queryParameters: {for (final e in query.entries) e.key: '${e.value}'},
    );
    return switch (await _api.getBytes(uri.toString())) {
      ApiOk(:final value) => ApiOk((
        bytes: Uint8List.fromList(value),
        filename: '$key.xlsx',
      )),
      ApiErr(:final failure) => ApiErr(failure),
    };
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ApiReportsRepository(ref.read(apiClientProvider)),
);

final reportsHomeProvider = FutureProvider.autoDispose
    .family<ReportsHome, ReportFilter>((ref, filter) async {
      accountWho(ref);
      return switch (await ref.read(reportsRepositoryProvider).home(filter)) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });

final reportProvider = FutureProvider.autoDispose
    .family<ReportData, (String, ReportFilter)>((ref, q) async {
      accountWho(ref);
      final r = await ref.read(reportsRepositoryProvider).report(q.$1, q.$2);
      return switch (r) {
        ApiOk(:final value) => value,
        ApiErr(:final failure) => throw failure,
      };
    });
