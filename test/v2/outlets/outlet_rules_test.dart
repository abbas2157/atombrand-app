// Outlets (11.7–11.9): shares, taken cities, the status choice and the
// form's checks, and the server's shapes.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/outlets/data/outlet_models.dart';
import 'package:atombrand_app/v2/features/outlets/data/outlet_rules.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final l = lookupAppLocalizations(const Locale('en'));

BrandOutlet _outlet(
  int id,
  String name, {
  OutletStatus status = OutletStatus.open,
  List<City> cities = const [],
  int sales = 0,
}) => BrandOutlet(
  id: id,
  name: name,
  status: status,
  cities: cities,
  figures: OutletFigures(sales: sales, delivered: 1, payments: sales ~/ 2),
);

void main() {
  test('share of sales, and all outlets together', () {
    expect(sharePercent(615500, 2184500), 28);
    expect(sharePercent(10, 0), 0);
    final t = outletTotals([
      _outlet(1, 'A', sales: 100),
      _outlet(2, 'B', sales: 300),
    ]);
    expect(t, (sales: 400, delivered: 2, payments: 200));
  });

  test('cities served elsewhere are taken; a closed outlet lets go', () {
    final outlets = [
      _outlet(1, 'Head office', cities: const [(id: 1, title: 'Lahore')]),
      _outlet(2, 'Karachi outlet', cities: const [(id: 2, title: 'Karachi')]),
      _outlet(
        3,
        'Old outlet',
        status: OutletStatus.closed,
        cities: const [(id: 3, title: 'Jhang')],
      ),
    ];
    expect(takenCities(outlets), {1: 'Head office', 2: 'Karachi outlet'});
    expect(takenCities(outlets, selfId: 2), {1: 'Head office'});
    expect(shortOutletName('Karachi outlet'), 'Karachi');
    expect(shortOutletName('Head office'), 'Head office');
  });

  group('status choice', () {
    StatusPlan plan(
      OutletStatus current,
      OutletStatus chosen, {
      int open = 0,
      int? units,
      bool main = false,
    }) => statusPlan(
      l,
      current: current,
      chosen: chosen,
      isMain: main,
      cities: const ['Karachi', 'Hyderabad'],
      openOrders: open,
      units: units,
    );

    test('the same status saves nothing', () {
      final p = plan(OutletStatus.open, OutletStatus.open);
      expect(p.button, 'Keep it open');
      expect(p.canSave, isFalse);
      expect(p.note, 'Open: takes new orders for Karachi and Hyderabad.');
    });

    test('pause and open again', () {
      expect(plan(OutletStatus.open, OutletStatus.paused).button, 'Pause');
      expect(plan(OutletStatus.open, OutletStatus.paused).canSave, isTrue);
      expect(
        plan(OutletStatus.paused, OutletStatus.open).button,
        'Open it again',
      );
      expect(
        plan(OutletStatus.closed, OutletStatus.open).button,
        'Reopen outlet',
      );
    });

    test('closing waits for open orders and stock', () {
      final blocked = plan(
        OutletStatus.open,
        OutletStatus.closed,
        open: 2,
        units: 1,
      );
      expect(blocked.canSave, isFalse);
      expect(blocked.button, 'Can’t close yet');
      expect(
        blocked.note,
        contains('2 orders are still open and 1 unit is still in stock'),
      );
      final free = plan(OutletStatus.paused, OutletStatus.closed, units: 0);
      expect(free.canSave, isTrue);
      expect(free.button, 'Close outlet');
    });

    test('the main outlet can’t change status', () {
      expect(
        plan(OutletStatus.open, OutletStatus.paused, main: true).canSave,
        isFalse,
      );
    });
  });

  group('the form', () {
    test('phone', () {
      expect(phoneProblem(l, '0300 1234567'), isNull);
      expect(phoneProblem(l, '042 35761234'), isNull);
      expect(phoneProblem(l, '0300'), isNotNull);
      expect(phoneProblem(l, '0300-123456x'), isNotNull);
    });

    test('the button says what is missing', () {
      String? b({
        String name = 'Faisalabad outlet',
        String phone = '0322 4410 908',
        int? city = 5,
        String address = 'Plot 12',
        bool main = false,
      }) => outletFormBlocker(
        l,
        name: name,
        phone: phone,
        cityId: city,
        address: address,
        isMain: main,
      );
      expect(b(), isNull);
      expect(b(name: ' '), 'Give the outlet a name');
      expect(b(name: 'x' * 41), 'Keep the name to 40 letters');
      expect(b(phone: ''), 'Enter the phone number');
      expect(b(phone: '0322'), 'Check the phone number');
      expect(b(city: null), 'Choose the city');
      expect(b(address: ''), 'Enter the address');
      expect(
        b(phone: '', address: '', main: true),
        isNull,
        reason: 'the main outlet may keep them empty',
      );
    });

    test('the body sends the opening date and a manager only when given', () {
      final draft = OutletDraft(
        name: 'F',
        phone: '0322',
        cityId: 5,
        address: 'A',
        cityIds: const [5, 6],
        openedOn: DateTime(2026, 12, 1),
        managerId: 7,
      );
      expect(draft.toBody(), {
        'name': 'F',
        'phone': '0322',
        'city_id': 5,
        'address': 'A',
        'city_ids': [5, 6],
        'opened_on': '2026-12-01',
      });
      final withManager = OutletDraft(
        name: 'F',
        phone: '0',
        cityId: 5,
        address: 'A',
        cityIds: const [],
        managerId: 7,
        sendManager: true,
      );
      expect(withManager.toBody()['manager_id'], 7);
    });
  });

  test('server shapes', () {
    final list = OutletList.fromJson({
      'account_type': 'multi',
      'outlet_limit': 4,
      'used': 3,
      'outlets': [
        {
          'id': 9,
          'name': 'Karachi outlet',
          'is_main': false,
          'status': 'paused',
          'city': {'id': 2, 'title': 'Karachi'},
          'cities': [
            {'id': 2, 'title': 'Karachi'},
          ],
          'manager': {'id': 77, 'name': 'Usman Ali'},
          'opened_on': '2026-08-02',
          'figures': {
            'sales': 615500,
            'orders': 5,
            'bulk_won': null,
            'units': 96,
            'to_confirm': 1,
            'staff': 2,
          },
        },
      ],
    });
    expect(list.canAdd, isTrue);
    final o = list.outlets.single;
    expect(o.status, OutletStatus.paused);
    expect(o.city?.title, 'Karachi');
    expect(o.managerUserId, 77);
    expect(o.figures?.bulkWon, isNull);
    expect(o.figures?.units, 96);
    expect(outletCardLine(l, o), 'Paused · no new orders');
    expect(
      outletCardLine(
        l,
        BrandOutlet(
          id: 1,
          name: 'H',
          managerName: 'Asad',
          figures: const OutletFigures(staff: 3, toConfirm: 2),
        ),
      ),
      'Asad · 3 staff · 2 to confirm',
    );
    expect(
      const OutletList(
        outlets: [],
        accountType: 'multi',
        limit: 3,
        used: 3,
      ).canAdd,
      isFalse,
    );
    expect(
      const OutletList(outlets: [], accountType: 'single').canAdd,
      isFalse,
    );
  });
}
