// AtomPay orders: the brand's step, what it may do there, and the JSON of
// AtompayOrdersController.

import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/features/atompay/data/atompay_models.dart';
import 'package:atombrand_app/v2/features/atompay/ui/atompay_detail_screen.dart';
import 'package:atombrand_app/v2/features/atompay/ui/atompay_handover_screen.dart';
import 'package:atombrand_app/v2/features/orders/data/orders_models.dart';
import 'package:atombrand_app/v2/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _item({String step = 'handover', int paid = 0}) => {
  'uuid': 'a-1',
  'id': 20931,
  'step': step,
  'step_label': 'Hand over',
  'cash_price': 179999,
  'paid': paid,
  'balance': 179999 - paid,
  'product': {'id': 3, 'title': 'Zenvo 55" 4K Smart TV', 'picture': null},
  'variant': null,
  'outlet': {'id': 1, 'label': 'Head office'},
  'seller': {
    'id': 42,
    'name': 'Madina Electronics',
    'code': 'S-1042',
    'area': 'Model Town',
    'city': 'Lahore',
  },
  'created_at': '2026-11-05 19:30:00',
};

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  test('steps read from their keys', () {
    expect(AtompayStep.fromKey('handed'), AtompayStep.handed);
    expect(AtompayStep.fromKey('cancelled').label(l), 'Not approved');
    expect(AtompayStep.fromKey('?'), AtompayStep.approving);
  });

  test('actions by step when the server sends none', () {
    expect(atompayActionsFor(AtompayStep.handover, balance: 100), [
      AtompayAction.handover,
    ]);
    expect(atompayActionsFor(AtompayStep.handed, balance: 100), [
      AtompayAction.payment,
    ]);
    expect(atompayActionsFor(AtompayStep.handed, balance: 0), [
      AtompayAction.complete,
    ]);
    expect(atompayActionsFor(AtompayStep.approving, balance: 100), isEmpty);
    expect(
      atompayActionsFor(AtompayStep.handover, balance: 1, fromServer: const []),
      isEmpty,
    );
  });

  test('a list item', () {
    final o = AtompayOrder.fromJson(_item());
    expect(o.number, '#A-20931');
    expect(o.step, AtompayStep.handover);
    expect(o.seller?.initials, 'ME');
    expect(o.seller?.place, 'Model Town, Lahore');
    expect(o.outlet?.name, 'Head office');
    expect(o.balance, 179999);
  });

  test('the detail with its actions', () {
    final d = AtompayDetail.fromJson({
      'order': _item(step: 'handed'),
      'customer': {'name': 'Kashif Mehmood', 'city': 'Lahore', 'area': null},
      'seller': {
        ..._item()['seller'] as Map<String, dynamic>,
        'contact': 'Imran Siddiqui',
        'phone': '03008841225',
        'address': '12 Link Road',
      },
      'customer_plan': {
        'months': 3,
        'monthly': 60000,
        'advance': 0,
        'markup_percent': 0,
      },
      'handover': {'at': '2026-11-06 16:05:00', 'serial': 'ZTV55-2610-00731'},
      'payments': [],
      'payment_methods': ['bank', 'cash'],
      'history': [
        {
          'status': 'Processing',
          'role': 'brand',
          'payload': {
            'handover': 'Unit handed over to the seller',
            'received_by': 'Imran Siddiqui',
            'serial': 'ZTV55-2610-00731',
          },
          'created_at': '2026-11-06 16:05:00',
        },
      ],
      'actions': ['payment'],
    });
    expect(d.allowed, [AtompayAction.payment]);
    expect(d.seller?.contact, 'Imran Siddiqui');
    expect(d.monthly, 60000);
    expect(d.serial, 'ZTV55-2610-00731');
    expect(
      atompayEventText(d.history.single, l),
      'Handed over, serial ZTV55-2610-00731, to Imran Siddiqui',
    );
    final (kind, words) = atompayNotice(d, l);
    expect(kind, AtomNoteKind.info);
    expect(words, startsWith('Handed to Madina Electronics on 6 Nov.'));
  });

  test('a hand-over needs who received it', () {
    expect(handoverProblem(receivedBy: '  ', l: l), 'Say who received it');
    expect(handoverProblem(receivedBy: 'Imran', l: l), isNull);
  });

  test('an AtomPay order on the cash endpoint says so', () {
    final o = CashOrder.fromJson({'id': 1, 'uuid': 'x', 'type': 'atompay'});
    expect(o.isAtompay, isTrue);
  });
}
