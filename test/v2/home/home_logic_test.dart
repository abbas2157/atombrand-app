// Home's rules: where tasks lead, which banner shows, the first-day steps,
// the offline counts, search of the copy and the dashboard's parsing.

import 'package:atombrand_app/v2/app/routes.dart';
import 'package:atombrand_app/v2/core/access/access.dart';
import 'package:atombrand_app/v2/core/session/session.dart';
import 'package:atombrand_app/v2/design/design.dart';
import 'package:atombrand_app/v2/features/home/data/home_logic.dart';
import 'package:atombrand_app/v2/features/home/data/home_models.dart';
import 'package:atombrand_app/v2/features/home/ui/quick_actions_sheet.dart';
import 'package:atombrand_app/v2/features/notifications/data/notifications_repository.dart'
    show Notice;
import 'package:atombrand_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final l = lookupAppLocalizations(const Locale('en'));

HomeTask task(String key, [Map<String, dynamic> target = const {}]) =>
    HomeTask(key: key, title: key, target: target);

const member = Who(
  isOwner: false,
  roleName: 'Order handler',
  permissions: {'orders.view', 'orders.status', 'orders.payment'},
);

void main() {
  group('task routes', () {
    test('order tasks switch to the Orders tab', () {
      expect(taskRoute(task('confirm')), (
        path: '/orders?status=Pending',
        tab: true,
      ));
      expect(taskRoute(task('record')), (
        path: '/orders?status=Delivered',
        tab: true,
      ));
      expect(taskRoute(task('hand_over')), (
        path: V2Routes.atompayOrders,
        tab: true,
      ));
    });

    test('a seller request with an id opens that request', () {
      expect(taskRoute(task('sourcing', {'bulk_request_id': 88})), (
        path: V2Routes.sellerRequestOf(88),
        tab: false,
      ));
      expect(taskRoute(task('sourcing_change', {'bulk_request_id': '12'})), (
        path: V2Routes.sellerRequestOf(12),
        tab: false,
      ));
    });

    test('seller requests without an id open the Seller requests tab', () {
      expect(taskRoute(task('sourcing', {'from': 'sellers'})), (
        path: V2Routes.bulkTab('sellers'),
        tab: true,
      ));
    });

    test('website bulk requests, quotes, products and stock', () {
      expect(taskRoute(task('bulk')), (
        path: V2Routes.bulkTab('website'),
        tab: true,
      ));
      expect(taskRoute(task('quotes')), (path: V2Routes.bulk, tab: true));
      expect(taskRoute(task('on_hold')), (
        path: '/products?status=On+hold',
        tab: true,
      ));
      expect(taskRoute(task('stock')), (
        path: V2Routes.stockList(show: 'out'),
        tab: false,
      ));
    });

    test('stock without the add-on, and unknown keys, have no button', () {
      expect(taskRoute(task('stock'), stockOn: false), isNull);
      expect(taskRoute(task('something_new')), isNull);
    });

    test('tones follow the server', () {
      expect(taskTone('t-rose'), AtomTone.rose);
      expect(taskTone('t-amber'), AtomTone.amber);
      expect(taskTone('t-green'), AtomTone.green);
      expect(taskTone(null), AtomTone.blue);
    });
  });

  group('banners', () {
    final today = DateTime(2026, 11, 7);
    const message = HomeActivity(
      notice: Notice(
        id: 9,
        type: 'brand_admin_message',
        title: 'From Atomshop',
        body: 'Inverter ACs are in demand.',
        read: false,
      ),
    );
    final trial = BillingGlance(
      addons: [
        AddonEnd(
          key: 'inventory',
          name: 'Inventory',
          state: 'trial',
          endsOn: DateTime(2026, 11, 10),
        ),
      ],
      openBills: [
        OpenBill(
          number: 'INV-1',
          due: 4500,
          coversFrom: DateTime(2026, 12, 1),
          dueOn: DateTime(2026, 11, 30),
        ),
      ],
    );

    test('read-only beats everything for the owner', () {
      final b = pickBanner(
        owner: true,
        access: const AccessState(
          account: AccountStatus.readOnly,
          daysLate: 16,
          due: 4500,
        ),
        billing: trial,
        activity: const [message],
        today: today,
        l: l,
      );
      expect(b!.kind, HomeBannerKind.readOnly);
      expect(b.amount, 4500);
      expect(b.bill, 'INV-1');
      expect(b.body, contains('16 days late'));
      expect(b.dismissable, isFalse);
    });

    test('then a late bill, then a message, then a trial, then a bill', () {
      HomeBannerKind? kind(AccountStatus s, {Set<String> hidden = const {}}) =>
          pickBanner(
            owner: true,
            access: AccessState(account: s, daysLate: 3),
            billing: trial,
            activity: const [message],
            hidden: hidden,
            today: today,
            l: l,
          )?.kind;
      expect(kind(AccountStatus.late), HomeBannerKind.late);
      expect(kind(AccountStatus.overdue), HomeBannerKind.late);
      expect(kind(AccountStatus.ok), HomeBannerKind.message);
      expect(kind(AccountStatus.ok, hidden: {'msg:9'}), HomeBannerKind.trial);
      expect(
        kind(AccountStatus.ok, hidden: {'msg:9', 'trial:inventory:2026-11-10'}),
        HomeBannerKind.billDue,
      );
    });

    test('the trial banner says when and what happens', () {
      final b = pickBanner(
        owner: true,
        access: const AccessState(),
        billing: trial,
        today: today,
        l: l,
      )!;
      expect(b.title, 'Inventory trial ends in 3 days');
      expect(b.body, contains('before 10 Nov'));
      expect(b.addon, Addon.inventory);
      expect(b.dismissable, isTrue);
    });

    test('a trial more than a week away shows no banner', () {
      final b = pickBanner(
        owner: true,
        access: const AccessState(),
        billing: BillingGlance(
          addons: [
            AddonEnd(
              key: 'team',
              name: 'Roles management',
              state: 'trial',
              endsOn: DateTime(2026, 11, 30),
            ),
          ],
        ),
        today: today,
        l: l,
      );
      expect(b, isNull);
    });

    test('the bill due banner names the month and the amount', () {
      final b = pickBanner(
        owner: true,
        access: const AccessState(account: AccountStatus.due),
        billing: BillingGlance(openBills: trial.openBills),
        today: today,
        l: l,
      )!;
      expect(b.title, 'December bill is ready');
      expect(b.body, 'INV-1 · Rs 4,500 · due 30 Nov');
    });

    test('team members see no billing banners', () {
      final b = pickBanner(
        owner: false,
        access: const AccessState(account: AccountStatus.readOnly),
        billing: trial,
        today: today,
        l: l,
      );
      expect(b, isNull);
      final m = pickBanner(
        owner: false,
        access: const AccessState(account: AccountStatus.late),
        activity: const [message],
        today: today,
        l: l,
      );
      expect(m!.kind, HomeBannerKind.message);
    });

    test('a restriction shows to everyone, with the server words', () {
      final b = pickBanner(
        owner: false,
        access: const AccessState(
          account: AccountStatus.restricted,
          message: 'Paused for a review.',
        ),
        today: today,
        l: l,
      )!;
      expect(b.kind, HomeBannerKind.restricted);
      expect(b.body, 'Paused for a review.');
    });

    test('a read message is not a banner', () {
      final b = pickBanner(
        owner: true,
        access: const AccessState(),
        activity: [HomeActivity(notice: message.notice.markedRead())],
        today: today,
        l: l,
      );
      expect(b, isNull);
    });
  });

  group('first day', () {
    test('a brand with nothing live and no orders, owner only', () {
      const fresh = HomeDashboard(catalogueTotal: 2);
      expect(isFirstDay(owner: true, home: fresh), isTrue);
      expect(isFirstDay(owner: false, home: fresh), isFalse);
      expect(
        isFirstDay(
          owner: true,
          home: const HomeDashboard(cataloguePublished: 1),
        ),
        isFalse,
      );
      expect(
        isFirstDay(owner: true, home: const HomeDashboard(ordersTotal: 1)),
        isFalse,
      );
    });

    test('steps are done from what is known; team only with the add-on', () {
      final steps = firstSteps(
        hasPin: true,
        products: 2,
        hasLogo: true,
        paymentsChosen: false,
        teamOn: false,
        teamMembers: 0,
        l: l,
      );
      expect(steps.map((s) => s.id), ['pin', 'products', 'page', 'pay']);
      expect(steps.where((s) => s.done).map((s) => s.id), ['pin', 'page']);
      final withTeam = firstSteps(
        hasPin: false,
        products: 3,
        hasLogo: false,
        paymentsChosen: true,
        teamOn: true,
        teamMembers: 1,
        l: l,
      );
      expect(withTeam.length, 5);
      expect(withTeam.where((s) => s.done).map((s) => s.id), [
        'products',
        'pay',
        'team',
      ]);
    });

    test('payments count as chosen with a bank or wallet', () {
      expect(
        paymentsChosenFrom({
          'payment_methods': ['cod'],
        }),
        isFalse,
      );
      expect(
        paymentsChosenFrom({
          'settings': {'pay_bank': true},
          'payment_methods': ['cod'],
        }),
        isTrue,
      );
      expect(
        paymentsChosenFrom({
          'payment_methods': ['cod', 'wallet'],
        }),
        isTrue,
      );
    });
  });

  group('offline Home', () {
    test('counts from the copy, money owed less payments', () {
      final f = offlineHomeFrom(
        orders: [
          {'id': 1, 'status': 'Pending', 'total_deal_price': 1000},
          {'id': 2, 'status': 'Pending', 'total_deal_price': 1000},
          {'id': 3, 'status': 'Processing', 'total_deal_price': 1000},
          {'id': 4, 'status': 'Delivered', 'total_deal_price': 149999},
          {'id': 5, 'status': 'Delivered', 'total_deal_price': 74999},
          {'id': 6, 'status': 'Delivered', 'total_deal_price': 5000},
          {'id': 7, 'status': 'Completed', 'total_deal_price': 5000},
        ],
        payments: [
          {'order_id': 5, 'amount': 10000},
          {'order_id': 6, 'amount': 5000},
        ],
        atompay: [
          {'id': 10, 'step': 'handover'},
          {'id': 11, 'step': 'handed'},
        ],
        requests: [
          {'id': 1, 'status': 'New Lead'},
          {'id': 2, 'status': null},
          {'id': 3, 'status': 'Quoted'},
        ],
      );
      expect(f.toConfirm, 2);
      expect(f.toDeliver, 1);
      expect(f.unpaidOrders, 2);
      expect(f.unpaidAmount, 149999 + 64999);
      expect(f.toHandOver, 1);
      expect(f.newRequests, 2);
    });

    test('search of the copy follows the role', () {
      final r = searchCopy(
        'inverter',
        who: member,
        orders: [
          {
            'id': 48219,
            'uuid': 'a',
            'status': 'Pending',
            'product_title': 'Zenvo Inverter AC',
          },
          {
            'id': 48220,
            'uuid': 'b',
            'status': 'Pending',
            'product_title': 'Fridge',
          },
        ],
        atompay: [
          {'id': 1, 'uuid': 'c', 'product_title': 'Inverter AC 1 ton'},
        ],
        products: [
          {'id': 5, 'title': 'Zenvo Inverter AC'},
        ],
        requests: [
          {'id': 9, 'product_title': 'Inverter AC'},
        ],
      );
      expect(r.fromCopy, isTrue);
      expect(r.orders!.items.map((o) => o.id), [48219]);
      // no atompay.view, catalogue.view or bulk.view
      expect(r.products, isNull);
      expect(r.requests, isNull);
    });

    test('search by order number and caps at five', () {
      final r = searchCopy(
        '#48219',
        who: const Who.owner(),
        orders: [
          {'id': 48219, 'uuid': 'a', 'status': 'Pending'},
        ],
      );
      expect(r.orders!.items.single.id, 48219);
      final many = searchCopy(
        'tv',
        who: const Who.owner(),
        products: [
          for (var i = 0; i < 7; i++) {'id': i, 'title': 'TV $i'},
        ],
      );
      expect(many.products!.items.length, 5);
      expect(many.products!.more, isTrue);
    });
  });

  group('figures', () {
    test('compact amounts for the chart tag', () {
      expect(compactAmount(4644500), '4.6m');
      expect(compactAmount(5000000), '5m');
      expect(compactAmount(820000), '820k');
      expect(compactAmount(950), '950');
    });

    test('chart heights share one scale', () {
      final h = chartHeights(const [
        ChartMonth(label: 'Jun', sales: 500, paid: 250),
        ChartMonth(label: 'Jul', sales: 1000, paid: 1000),
      ]);
      expect(h, [(0.5, 0.25), (1.0, 1.0)]);
      expect(chartHeights(const [ChartMonth(label: 'Jun')]), [(0.0, 0.0)]);
    });

    test('greeting by the hour', () {
      expect(greetingFor(DateTime(2026, 1, 1, 9), l), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 13), l), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 20), l), 'Good evening');
    });
  });

  group('dashboard parsing', () {
    test('reads the v2 home, and keeps hidden sections null', () {
      final d = HomeDashboard.fromJson({
        'catalogue': {'total': 64, 'published': 52},
        'orders': {'total': 702},
        'home': {
          'hero': {
            'orders_to_confirm': 4,
            'atompay_to_hand_over': 2,
            'bulk_requests_waiting': 1,
            'seller_requests_waiting': 2,
          },
          'tasks': [
            {
              'key': 'sourcing',
              'title': 'Quote 2 seller requests',
              'count': 2,
              'urgent': true,
              'target': {'from': 'sellers'},
            },
          ],
          'periods': {
            'today': {'cash_sales': 486500, 'orders': 7},
            'month': {
              'cash_sales': 4644500,
              'payments_received': 4129000,
              'still_due': 515500,
              'live': 52,
              'catalogue_total': 64,
            },
          },
          'chart': {
            'months': [
              {'label': 'Jun', 'sales': 2810000, 'paid': 2650000},
            ],
          },
          'pipeline': null,
          'bulk': {'new': 3, 'won': 7, 'delivering': null},
          'outlets': [],
          'latest_orders': null,
          'activity': [
            {
              'id': 3,
              'type': 'brand_new_order',
              'title': 'New order received',
              'body': 'New order for X',
              'screen': 'order',
              'data': {'order_uuid': 'u'},
              'is_read': false,
              'created_at': '2026-11-14 10:02:11',
              'time_ago': '2 minutes ago',
            },
          ],
          'plan': {
            'package': {'name': 'Basic package'},
            'paid_until': '2026-11-30',
            'addons': [
              {'key': 'inventory', 'name': 'Inventory', 'state': 'trial'},
              {'key': 'team', 'name': 'Roles management', 'state': 'off'},
            ],
          },
        },
      });
      expect(d.hero.total, 9);
      expect(d.hero.requestsWaiting, 3);
      expect(d.tasks.single.target['from'], 'sellers');
      expect(d.periods.keys, ['today', 'month']);
      expect(d.periods['month']!.liveShare, closeTo(0.8125, 0.0001));
      expect(d.chart!.single.sales, 2810000);
      expect(d.pipeline, isNull);
      expect(d.latestOrders, isNull);
      expect(d.bulk!.delivering, isNull);
      expect(d.activity.single.timeAgo, '2 minutes ago');
      expect(d.activity.single.notice.data['screen'], 'order');
      expect(d.plan!.addonsOn, ['Inventory']);
      expect(d.cataloguePublished, 52);
      expect(d.ordersTotal, 702);
      expect(d.hasTotals, isTrue);
    });

    test('a team member without totals has no periods', () {
      final d = HomeDashboard.fromJson({
        'home': {
          'hero': {'orders_to_confirm': 2, 'bulk_requests_waiting': null},
          'sales': null,
          'periods': null,
          'chart': null,
        },
      });
      expect(d.hasTotals, isFalse);
      expect(d.chart, isNull);
      expect(d.hero.requestsWaiting, isNull);
      expect(d.hero.total, 2);
      expect(d.plan, isNull);
    });

    test('outlet list leaves closed outlets out and adds up', () {
      final l = OutletList.fromJson({
        'outlet_limit': 5,
        'used': 3,
        'outlets': [
          {
            'id': 1,
            'name': 'Head office',
            'is_main': true,
            'status': 'open',
            'figures': {'sales': 100, 'to_confirm': 2},
          },
          {
            'id': 2,
            'name': 'Karachi',
            'status': 'paused',
            'figures': {'sales': 50, 'to_confirm': 1},
          },
          {
            'id': 3,
            'name': 'Old',
            'status': 'closed',
            'figures': {'sales': 9},
          },
        ],
      });
      expect(l.outlets.map((o) => o.id), [1, 2]);
      expect(l.totalSales, 150);
      expect(l.totalToConfirm, 3);
      expect(l.canAdd, isTrue);
      expect(l.outlets[1].paused, isTrue);
    });

    test('search results keep sections the role cannot see null', () {
      final r = SearchResults.fromJson({
        'q': 'oxy',
        'orders': {
          'items': [
            {
              'uuid': 'u',
              'id': 901,
              'type': 'atompay',
              'status': 'Pending',
              'total': 60000,
              'product': {'title': 'OXY'},
            },
          ],
          'more': false,
        },
        'products': null,
        'bulk_requests': {
          'items': [
            {'id': 88, 'status': 'New Lead', 'from': 'seller', 'quantity': 12},
          ],
          'more': true,
        },
      });
      expect(r.orders!.items.single.atompay, isTrue);
      expect(r.products, isNull);
      expect(r.requests!.items.single.fromSeller, isTrue);
      expect(r.requests!.more, isTrue);
      expect(r.total, 2);
    });
  });

  group('quick actions', () {
    test('the owner with every add-on sees all six', () {
      final a = quickActionsFor(
        const Who.owner(),
        const AccessState(
          addonStates: {
            Addon.inventory: AddonState.active,
            Addon.askAtom: AddonState.trial,
          },
        ),
        l,
      );
      expect(a.map((x) => x.id), [
        'product',
        'stock',
        'payment',
        'quote',
        'handover',
        'ask',
      ]);
    });

    test('add-ons off and a narrow role leave actions out', () {
      final a = quickActionsFor(member, const AccessState(addonStates: {}), l);
      expect(a.map((x) => x.id), ['payment']);
    });
  });
}
