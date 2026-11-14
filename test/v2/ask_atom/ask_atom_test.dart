import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/features/ask_atom/data/ask_atom_questions.dart';
import 'package:atombrand_app/v2/features/ask_atom/data/ask_atom_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an answer reads the server\'s shape', () {
    final a = AtomAnswer.fromJson({
      'kind': 'confirm',
      'key': 'product_out_of_stock',
      'text': 'Zenvo Refrigerator 14 cft: **Out of stock**.',
      'rows': [
        ['#48209 · AC 1.5 ton', 'Rs 149,999'],
        ['bad'],
      ],
      'actions': [
        ['Open orders', 'https://atomshop.pk/brand-portal/orders'],
      ],
      'confirm': {'token': 'tok', 'label': 'Confirm'},
      'handover': true,
      'id': 42,
      'lang': {'code': 'roman-ur', 'label': 'Roman Urdu'},
    });
    expect(a.kind, 'confirm');
    expect(a.rows, [('#48209 · AC 1.5 ton', 'Rs 149,999')]);
    expect(a.actions.single.$1, 'Open orders');
    expect(a.confirmToken, 'tok');
    expect(a.handover, isTrue);
    expect(a.id, 42);
    expect(a.langLabel, 'Roman Urdu');
  });

  test('the context pairs shown questions with the prompts sent', () {
    final c = AtomContext.fromJson({
      'notices': [
        {'kind': 'problem', 'notice': '2 orders waiting longer than 4 hours'},
      ],
      'questions': ['Is mahine kitni sales hui?', 'Low stock'],
      'prompts': ['Sales this month', ''],
    });
    expect(c.notices.single.notice, contains('2 orders'));
    expect(c.questions, [
      ('Is mahine kitni sales hui?', 'Sales this month'),
      ('Low stock', 'Low stock'),
    ]);
  });

  test('history keeps the last 12 turns', () {
    final turns = [for (var i = 0; i < 15; i++) (mine: i.isEven, text: '$i')];
    final h = ApiAskAtomRepository.history(turns);
    expect(h, hasLength(12));
    expect(h.first, {'role': 'bot', 'text': '3'});
    expect(h.last, {'role': 'user', 'text': '14'});
  });

  group('brand questions follow the role', () {
    final l = lookupAppLocalizations(const Locale('en'));
    test('the owner with Inventory gets all five', () {
      expect(brandQuestions(l, const Who.owner(), inventory: true), [
        'Which orders are waiting to be confirmed?',
        'Which quotes run out this week?',
        'What is running low?',
        'Sales this month',
        'Which seller requests are new?',
      ]);
    });

    test('no low stock without Inventory', () {
      expect(
        brandQuestions(l, const Who.owner(), inventory: false),
        isNot(contains('What is running low?')),
      );
    });

    test('a member sees only what their role can answer', () {
      const member = Who(
        isOwner: false,
        roleKey: 'dispatch',
        permissions: {BrandPermission.ordersView},
      );
      expect(brandQuestions(l, member, inventory: true), [
        'Which orders are waiting to be confirmed?',
      ]);
    });
  });
}
