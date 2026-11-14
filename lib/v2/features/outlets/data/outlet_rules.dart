import '../../../../l10n/app_localizations.dart';
import 'outlet_models.dart';

/// The rules the outlet screens follow, out of the widgets so they can be
/// tested. They mirror atomshop's `BrandOutletService`.

/// [sales] as a whole percent of [total] (0 when there is no total).
int sharePercent(int sales, int total) =>
    total <= 0 ? 0 : (sales * 100 / total).round().clamp(0, 100);

/// All outlets together for the header: cash sales, delivered orders and
/// payments received.
({int sales, int delivered, int payments}) outletTotals(
  List<BrandOutlet> outlets,
) {
  var sales = 0, delivered = 0, payments = 0;
  for (final o in outlets) {
    final f = o.figures;
    if (f == null) continue;
    sales += f.sales;
    delivered += f.delivered;
    payments += f.payments;
  }
  return (sales: sales, delivered: delivered, payments: payments);
}

/// "Karachi outlet" → "Karachi", for the taken-city chips.
String shortOutletName(String name) {
  final s = name
      .replaceFirst(RegExp(r'\s+outlet$', caseSensitive: false), '')
      .trim();
  return s.isEmpty ? name : s;
}

/// The cities other outlets serve (city id → that outlet's name). A closed
/// outlet lets its cities go. [selfId] is the outlet being changed.
Map<int, String> takenCities(List<BrandOutlet> outlets, {int? selfId}) => {
  for (final o in outlets)
    if (o.id != selfId && o.status != OutletStatus.closed)
      for (final c in o.cities) c.id: o.name,
};

/// The grey line under an outlet card: who runs it, staff and orders to
/// confirm; or that it is paused or closed.
String outletCardLine(AppLocalizations l, BrandOutlet o) {
  final f = o.figures;
  return switch (o.status) {
    OutletStatus.paused => l.outletsCardPaused,
    OutletStatus.closed => l.outletsCardClosed,
    OutletStatus.open => [
      ?o.managerName,
      if (f != null) staffWords(l, f.staff),
      if (f != null && f.toConfirm > 0) l.outletsKpiOrdersNote(f.toConfirm),
    ].join(' · '),
  };
}

String staffWords(AppLocalizations l, int n) => l.outletsStaffCount(n);

// ───────────────────────────────────────────── status (11.9)

enum StatusNote { good, warning, problem }

/// What choosing [chosen] does to an outlet now [current]: the note under
/// the choice, the button's words, and whether the button works.
class StatusPlan {
  const StatusPlan({
    required this.note,
    required this.tone,
    required this.button,
    required this.canSave,
  });

  final String note;
  final StatusNote tone;
  final String button;
  final bool canSave;
}

/// The status choice on 11.9. The main outlet can't be paused or closed.
/// Closing needs no open orders and no stock ([openOrders], [units]; the
/// server also checks running bulk deals).
StatusPlan statusPlan(
  AppLocalizations l, {
  required OutletStatus current,
  required OutletStatus chosen,
  required bool isMain,
  required List<String> cities,
  int openOrders = 0,
  int? units,
}) {
  final where = cities.isEmpty
      ? l.outletsItsCities
      : cities.reduce(l.outletsAnd);
  if (isMain) {
    return StatusPlan(
      note: l.outletsPlanMainNote,
      tone: StatusNote.good,
      button: l.outletsPlanMainButton,
      canSave: false,
    );
  }
  switch (chosen) {
    case OutletStatus.open:
      return StatusPlan(
        note: l.outletsPlanOpenNote(where),
        tone: StatusNote.good,
        button: current == OutletStatus.open
            ? l.outletsKeepOpen
            : (current == OutletStatus.closed
                  ? l.outletsReopen
                  : l.outletsOpenAgain),
        canSave: current != OutletStatus.open,
      );
    case OutletStatus.paused:
      return StatusPlan(
        note: current == OutletStatus.paused
            ? l.outletsPlanPausedNote(where)
            : l.outletsPlanPausingNote(where),
        tone: StatusNote.warning,
        button: current == OutletStatus.paused
            ? l.outletsKeepPaused
            : l.outletsPause,
        canSave: current != OutletStatus.paused,
      );
    case OutletStatus.closed:
      if (current == OutletStatus.closed) {
        return StatusPlan(
          note: l.outletsPlanClosedNote,
          tone: StatusNote.problem,
          button: l.outletsStatusClosed,
          canSave: false,
        );
      }
      final why = [
        if (openOrders > 0) l.outletsWhyOrders(openOrders),
        if ((units ?? 0) > 0) l.outletsWhyUnits(units!),
      ];
      return StatusPlan(
        note: why.isEmpty
            ? l.outletsPlanCloseNote
            : l.outletsPlanCantCloseNote(why.reduce(l.outletsAnd)),
        tone: StatusNote.problem,
        button: why.isEmpty ? l.outletsCloseOutlet : l.outletsCantClose,
        canSave: why.isEmpty,
      );
  }
}

// ───────────────────────────────────────────── the form (11.8)

/// Null when the phone looks like a number the server takes
/// ("0300 1234567", "042 35761234").
String? phoneProblem(AppLocalizations l, String phone) {
  final p = phone.trim();
  if (p.isEmpty) return l.outletsPhoneEmpty;
  final digits = p.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 ||
      p.length > 20 ||
      RegExp(r'[^\d\s\-+()]').hasMatch(p)) {
    return l.outletsPhoneBad;
  }
  return null;
}

/// What still stops the outlet form from saving, as the button's words,
/// or null. The main outlet may keep its phone and address empty.
String? outletFormBlocker(
  AppLocalizations l, {
  required String name,
  required String phone,
  required int? cityId,
  required String address,
  bool isMain = false,
}) {
  final n = name.trim();
  if (n.isEmpty) return l.outletsBlockName;
  if (n.length > 40) return l.outletsBlockNameLong;
  if (!(isMain && phone.trim().isEmpty) && phoneProblem(l, phone) != null) {
    return phone.trim().isEmpty ? l.outletsBlockPhone : l.outletsBlockPhoneBad;
  }
  if (cityId == null) return l.outletsChooseCity;
  if (address.trim().isEmpty && !isMain) return l.outletsBlockAddress;
  if (address.trim().length > 250) return l.outletsBlockAddressLong;
  return null;
}
