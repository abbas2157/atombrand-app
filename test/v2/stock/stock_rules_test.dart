import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_models.dart';
import 'package:atombrand_app/v2/features/stock/data/stock_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = lookupAppLocalizations(const Locale('en'));

const _wh = StockWarehouse(id: 1, name: 'Factory store', outlet: 'Lahore');
const _serialVariant = VariantOption(
  id: 5,
  productId: 2,
  product: 'Zenvo TV',
  variant: 'Black',
);
const _autoVariant = VariantOption(
  id: 6,
  productId: 3,
  product: 'Zenvo AC',
  variant: 'White',
  tracking: Tracking.auto,
  nextAutoNumber: 'ZNVAC-0042',
);

StockMove _move(String type, {String? serial, int qty = 1, DateTime? date}) =>
    StockMove(id: 1, type: type, serial: serial, qty: qty, date: date);

void main() {
  group('serials', () {
    test('split one per line and by commas, trimmed, blanks out', () {
      expect(splitSerials(' A1 \n\nB2,C3\r\n  '), ['A1', 'B2', 'C3']);
    });

    test('repeats, bad IMEIs and numbers in stock are flagged', () {
      final lines = checkSerials(_l,
        ['490154203237518', '490154203237519', '12345', '490154203237518'],
        Tracking.imei,
      );
      expect(lines.map((l) => l.problem).toList(), [
        null,
        'Last digit doesn’t match',
        'IMEI should be 15 digits',
        'Entered twice',
      ]);
      expect(goodSerials(lines), ['490154203237518']);
    });

    test('a serial already in stock is flagged, case-blind', () {
      final lines = checkSerials(_l,
        ['zn-1', 'ZN-2', 'x'],
        Tracking.serial,
        inStock: {'ZN-1'},
      );
      expect(lines[0].problem, 'Already in stock');
      expect(lines[1].problem, isNull);
      expect(lines[2].problem, 'Should be 3 to 60 characters');
    });

    test('repeats are case-blind as on the server', () {
      final lines = checkSerials(_l, ['abc-1', 'ABC-1'], Tracking.serial);
      expect(lines[1].problem, 'Entered twice');
    });
  });

  group('stock in', () {
    test('needs a warehouse, a product and units', () {
      expect(
        stockInProblem(_l, warehouse: null, variant: _serialVariant, serials: const [], autoQty: 0, max: 200),
        'Choose the warehouse',
      );
      expect(
        stockInProblem(_l, warehouse: _wh, variant: null, serials: const [], autoQty: 0, max: 200),
        'Choose the product',
      );
      expect(
        stockInProblem(_l, warehouse: _wh, variant: _serialVariant, serials: const [], autoQty: 0, max: 200),
        'Scan or type each unit’s serial number',
      );
      final good = checkSerials(_l, ['SN-001'], Tracking.serial);
      expect(
        stockInProblem(_l, warehouse: _wh, variant: _serialVariant, serials: good, autoQty: 0, max: 200),
        isNull,
      );
    });

    test('auto numbered products take a count within the limit', () {
      expect(
        stockInProblem(_l, warehouse: _wh, variant: _autoVariant, serials: const [], autoQty: 0, max: 200),
        'Enter how many units arrived',
      );
      expect(
        stockInProblem(_l, warehouse: _wh, variant: _autoVariant, serials: const [], autoQty: 201, max: 200),
        'Add up to 200 units at a time',
      );
      expect(
        stockInProblem(_l, warehouse: _wh, variant: _autoVariant, serials: const [], autoQty: 3, max: 200),
        isNull,
      );
    });

    test('previews the auto numbers from the next one', () {
      expect(autoNumbersPreview(_l, 'ZNVAC-0042', 1), 'ZNVAC-0042');
      expect(autoNumbersPreview(_l, 'ZNVAC-0042', 2), 'ZNVAC-0042, ZNVAC-0043');
      expect(autoNumbersPreview(_l, 'ZNVAC-0098', 3), 'ZNVAC-0098 to ZNVAC-0100');
      expect(autoNumbersPreview(_l, null, 3), isNull);
    });
  });

  group('levels', () {
    test('bar parts are fractions of the widest row, capped', () {
      final b = levelBar(5, 2, 10);
      expect(b.available, 0.5);
      expect(b.held, 0.2);
      expect(levelBar(30, 0, 10).available, 1.0);
      expect(levelBar(0, 0, 0).available, 0.0);
    });

    test('where: by outlet with several, else by warehouse', () {
      const whs = [
        StockWarehouse(id: 1, name: 'Factory store', outlet: 'Lahore'),
        StockWarehouse(id: 2, name: 'Godown', outlet: 'Lahore'),
        StockWarehouse(id: 3, name: 'Karachi godown', outlet: 'Karachi'),
      ];
      const v = StockVariant(
        id: 1,
        name: 'White',
        byWarehouse: [
          (warehouseId: 1, onHand: 10, reserved: 0),
          (warehouseId: 2, onHand: 4, reserved: 1),
          (warehouseId: 3, onHand: 6, reserved: 0),
        ],
      );
      expect(whereLine(_l, v, whs, byOutlet: true), 'Lahore 14 · Karachi 6');
      expect(
        whereLine(_l, v, whs, byOutlet: false),
        'Factory store 10 · Godown 4 · Karachi godown 6',
      );
      expect(
        whereLine(_l, const StockVariant(id: 2, name: ''), whs, byOutlet: true),
        'None in stock',
      );
    });

    test('available online counts only warehouses that sell online', () {
      const whs = [
        StockWarehouse(id: 1, name: 'A', sellsOnline: true),
        StockWarehouse(id: 2, name: 'B'),
      ];
      const v = StockVariant(
        id: 1,
        name: '',
        byWarehouse: [
          (warehouseId: 1, onHand: 5, reserved: 2),
          (warehouseId: 2, onHand: 9, reserved: 0),
        ],
      );
      expect(availableOnline(v, whs), 3);
    });
  });

  group('history', () {
    test('signs and labels by type', () {
      expect(moveChange(_move('stock_in', qty: 3)), '+3');
      expect(moveChange(_move('sale_out', qty: -1)), '−1');
      expect(moveChange(_move('transfer_out', qty: 5)), '5');
      expect(moveChange(_move('adjust_out')), '−1');
      expect(moveChange(_move('adjust_in')), '+1');
      expect(moveLabel(_l, _move('opening_stock')), 'Stock in');
      expect(moveLabel(_l, _move('adjust_in')), 'Adjusted');
    });

    test('day headings', () {
      final today = DateTime(2026, 11, 13, 15);
      expect(historyDay(_l, DateTime(2026, 11, 13), today), 'Today');
      expect(historyDay(_l, DateTime(2026, 11, 12), today), 'Yesterday · 12 Nov');
      expect(historyDay(_l, DateTime(2026, 11, 10), today), 'Tue 10 Nov');
      expect(historyDay(_l, DateTime(2025, 11, 10), today), '10 Nov 2025');
    });

    test('groups consecutive rows by day', () {
      final today = DateTime(2026, 11, 13);
      final groups = groupByDay(_l, [
        _move('stock_in', date: DateTime(2026, 11, 13)),
        _move('sale_out', date: DateTime(2026, 11, 13)),
        _move('stock_in', date: DateTime(2026, 11, 12)),
      ], today);
      expect(groups.map((g) => (g.day, g.rows.length)).toList(), [
        ('Today', 2),
        ('Yesterday · 12 Nov', 1),
      ]);
    });
  });

  group('looking up a serial', () {
    const unit = UnitOption(
      id: 9,
      serial: 'ZNV-1',
      variantId: 5,
      warehouseId: 1,
      warehouse: 'Factory store',
    );

    test('in stock wins, with its stock-in row', () {
      final found = lookUnit('znv-1', [unit], [
        _move('transfer_in', serial: 'ZNV-1'),
        _move('stock_in', serial: 'ZNV-1'),
      ]);
      expect(found.found, UnitFound.inStock);
      expect(found.unit, unit);
      expect(found.cameIn?.type, 'stock_in');
    });

    test('the latest row says delivered or removed', () {
      expect(
        lookUnit('ZNV-2', [unit], [
          _move('sale_out', serial: 'ZNV-2'),
          _move('stock_in', serial: 'ZNV-2'),
        ]).found,
        UnitFound.delivered,
      );
      expect(
        lookUnit('ZNV-2', const [], [_move('adjust_out', serial: 'ZNV-2')]).found,
        UnitFound.removed,
      );
    });

    test('rows for other serials are ignored; nothing is not found', () {
      final found = lookUnit('ZNV-3', [unit], [_move('sale_out', serial: 'ZNV-30')]);
      expect(found.found, UnitFound.notFound);
      expect(found.serial, 'ZNV-3');
    });
  });

  group('adjust, move and warehouses', () {
    test('adjust out needs a unit, a reason and a note', () {
      String? out({UnitOption? unit, String? reason = 'Damaged', String note = 'x'}) =>
          adjustProblem(_l,
            out: true,
            unit: unit,
            variant: null,
            warehouse: null,
            serial: '',
            reason: reason,
            note: note,
          );
      const u = UnitOption(id: 1, serial: 'A');
      expect(out(), 'Choose the unit to remove');
      expect(out(unit: u, reason: null), 'Choose a reason');
      expect(out(unit: u, note: '  '), 'Write a note: what happened?');
      expect(out(unit: u), isNull);
    });

    test('adjust in needs a serial unless numbered for you', () {
      String? inn(VariantOption v, String serial) => adjustProblem(_l,
        out: false,
        unit: null,
        variant: v,
        warehouse: _wh,
        serial: serial,
        reason: 'Found',
        note: 'In the back',
      );
      expect(inn(_serialVariant, ''), 'Enter the serial number');
      expect(inn(_serialVariant, 'SN-9'), isNull);
      expect(inn(_autoVariant, ''), isNull);
      const imei = VariantOption(id: 7, productId: 1, product: 'P', variant: '', tracking: Tracking.imei);
      expect(inn(imei, '123'), 'Check the IMEI: 15 digits');
      expect(inn(imei, '490154203237518'), isNull);
    });

    test('move needs two different places and ticked units', () {
      const other = StockWarehouse(id: 2, name: 'Godown');
      expect(moveProblem(_l, from: _wh, to: null, picked: 1), 'Choose where it goes');
      expect(moveProblem(_l, from: _wh, to: _wh, picked: 1), 'Choose a different warehouse');
      expect(moveProblem(_l, from: _wh, to: other, picked: 0), 'Tick the units to move');
      expect(moveProblem(_l, from: _wh, to: other, picked: 3), isNull);
    });

    test('warehouse and prefix checks', () {
      expect(warehouseProblem(_l, name: ' ', outletId: 1), 'Give the warehouse a name');
      expect(warehouseProblem(_l, name: 'Godown', outletId: null), 'Choose the outlet');
      expect(warehouseProblem(_l, name: 'Godown', outletId: 1), isNull);
      expect(prefixProblem(_l, 'Z'), isNotNull);
      expect(prefixProblem(_l, 'ZNV-TV'), isNotNull);
      expect(prefixProblem(_l, 'ZNVTV'), isNull);
    });
  });
}
