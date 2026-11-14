import 'package:atombrand_app/v2/core/api/api_result.dart';
import 'package:atombrand_app/v2/core/db/atom_db.dart';
import 'package:atombrand_app/v2/core/db/outbox_actions.dart';
import 'package:atombrand_app/v2/core/db/outbox_db.dart';
import 'package:atombrand_app/v2/core/db/sync_store.dart';
import 'package:atombrand_app/v2/features/sync/data/sync_engine.dart';
import 'package:atombrand_app/v2/features/sync/data/sync_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_sync.dart';

void main() {
  late AtomDb db;
  late OutboxDb outbox;
  late SyncStore store;
  late FakeSync server;
  late SyncEngine engine;
  late List<SyncProgress> progress;

  setUp(() {
    db = AtomDb(NativeDatabase.memory());
    outbox = OutboxDb(NativeDatabase.memory());
    store = SyncStore(db, outbox);
    server = FakeSync();
    progress = [];
    engine = SyncEngine(
      repository: server,
      store: store,
      onProgress: progress.add,
      clock: () => DateTime(2026, 11, 14, 10),
    );
  });

  tearDown(() async {
    await db.close();
    await outbox.close();
  });

  Future<void> queue(String id, {OfflineAction? action, String? tempId}) {
    final a =
        action ??
        OfflineAction.orderPayment(
          orderUuid: 'u-$id',
          amount: 100,
          method: 'cash',
        );
    return store.addToOutbox(
      id: id,
      action: a.action,
      data: a.data,
      seen: a.seen,
      at: DateTime.utc(2026, 11, 14, 4),
      tempId: tempId,
    );
  }

  OutboxSent answers(List<Map<String, dynamic>> results) =>
      OutboxSent.fromJson({'results': results});

  group('the outbox goes up (POST sync)', () {
    test('in order, with the real time in UTC and nothing else', () async {
      await queue('a');
      await queue('b');

      final out = await engine.run(shopId: 0);

      expect(out.ok, isTrue);
      expect(out.sent, 2);
      expect(server.sent.single.map((a) => a.id), ['a', 'b']);
      final json = server.sent.single.first.toJson();
      expect(json.keys.toSet(), {'id', 'action', 'data', 'seen', 'at'});
      expect(json['at'], '2026-11-14T04:00:00.000Z');
      expect(json['action'], 'order.payment');
      expect(await store.waitingCount(), 0);
    });

    test('at most 100 actions a call', () async {
      for (var i = 0; i < 130; i++) {
        await queue('id-${i.toString().padLeft(3, '0')}');
      }

      await engine.run(shopId: 0);

      expect(server.sent.map((b) => b.length), [100, 30]);
      expect(await store.waitingCount(), 0);
    });

    test('done_with_changes leaves the outbox too', () async {
      await queue(
        'a',
        action: OfflineAction.stockIn(variantId: 1, warehouseId: 2, qty: 2),
      );
      server.sendAnswers = [
        ApiOk(
          answers([
            {
              'id': 'a',
              'action': 'stock.in',
              'status': 'done_with_changes',
              'changes': {
                'serials': ['AUTO-1', 'AUTO-2'],
              },
            },
          ]),
        ),
      ];

      final out = await engine.run(shopId: 0);

      expect(out.sent, 1);
      expect(await store.waitingCount(), 0);
    });

    test('a serial clash waits for the person, with its answer kept', () async {
      await queue(
        'a',
        action: OfflineAction.stockIn(
          variantId: 1,
          warehouseId: 2,
          qty: 2,
          serials: ['SN-1', 'SN-2'],
        ),
      );
      server.sendAnswers = [
        ApiOk(
          answers([
            {
              'id': 'a',
              'action': 'stock.in',
              'status': 'needs_attention',
              'reason': 'serial_clash',
              'message': 'Serial number SN-1 is already in your stock.',
              'details': {
                'serials': ['SN-1'],
              },
              'retry': false,
              'conflict': true,
            },
          ]),
        ),
      ];

      final out = await engine.run(shopId: 0);

      expect(out.needsAttention, 1);
      final rows = await store.needingAttention();
      expect(rows.single.reason, 'serial_clash');
      expect(rows.single.message, contains('SN-1'));
      final answer = await store.answerOf('a');
      expect(answer?['details'], {
        'serials': ['SN-1'],
      });
      expect(answer?['conflict'], isTrue);
    });

    test(
      'server_error and busy stay waiting, and are counted as tried',
      () async {
        await queue('a');
        await queue('b');
        server.sendAnswers = [
          ApiOk(
            answers([
              {
                'id': 'a',
                'status': 'needs_attention',
                'reason': 'busy',
                'retry': true,
              },
              // An old answer without `retry`: the reason decides.
              {
                'id': 'b',
                'status': 'needs_attention',
                'reason': 'server_error',
              },
            ]),
          ),
        ];

        final out = await engine.run(shopId: 0);

        expect(out.needsAttention, 0);
        final waiting = await store.waiting();
        expect(waiting.map((r) => r.id), ['a', 'b']);
        expect(waiting.every((r) => r.tries == 1), isTrue);
        // Every answer said "later": the run doesn't loop on them.
        expect(server.sent, hasLength(1));
      },
    );

    test('a row made on this phone goes once its action is applied', () async {
      await store.addLocalRow(
        'stock_units',
        tempId: 't-1',
        fields: {'serial': 'SN-1'},
        shopId: 0,
      );
      await queue(
        'a',
        tempId: 't-1',
        action: OfflineAction.stockIn(
          variantId: 1,
          warehouseId: 2,
          qty: 1,
          serials: ['SN-1'],
        ),
      );

      await engine.run(shopId: 0);

      expect(await store.rows('stock_units', shopId: 0), isEmpty);
    });

    test('no signal keeps everything for the next run', () async {
      await queue('a');
      server.sendAnswers = [const ApiErr(ApiFailure(ApiFailureKind.offline))];

      final out = await engine.run(shopId: 0);

      expect(out.stop, SyncStop.offline);
      expect(await store.waitingCount(), 1);
    });

    test('Sending… is told the steps by kind', () async {
      await queue('a');
      await queue(
        'b',
        action: OfflineAction.stockIn(variantId: 1, warehouseId: 2, qty: 1),
      );
      await queue(
        'c',
        action: OfflineAction.dealPayment(dealId: 1, amount: 5, method: 'cash'),
      );

      await engine.run(shopId: 0);

      final last = progress.lastWhere((p) => p.phase == SyncPhase.sending);
      expect(last.toSendBy, {
        SyncGroup.ordersAndPayments: 1,
        SyncGroup.stock: 1,
        SyncGroup.bulk: 1,
      });
      expect(last.sentBy, last.toSendBy);
    });
  });

  group('sync/check decides first', () {
    test('wipe clears the copy and sends nothing', () async {
      await store.upsert('orders', [
        {'id': 1, 'uuid': 'u'},
      ], shopId: 0);
      await queue('a');
      server.checkAnswer = ApiOk(
        SyncCheck.fromJson({
          'allowed': false,
          'wipe': true,
          'reason': 'Your access to this brand was switched off.',
        }),
      );

      final out = await engine.run(shopId: 0);

      expect(out.stop, SyncStop.wiped);
      expect(out.message, contains('switched off'));
      expect(await store.rows('orders', shopId: 0), isEmpty);
      expect(server.sent, isEmpty);
    });

    test('drop_copy sends the outbox, then deletes the copy', () async {
      await store.upsert('orders', [
        {'id': 1, 'uuid': 'u'},
      ], shopId: 0);
      await queue('a');
      server.checkAnswer = ApiOk(
        SyncCheck.fromJson(
          FakeSync.checkJson({
            'offline': {'allowed': false, 'drop_copy': true, 'addon': 'lapsed'},
          }),
        ),
      );

      final out = await engine.run(shopId: 0);

      expect(out.stop, SyncStop.offlineEnded);
      expect(out.sent, 1);
      expect(await store.rows('orders', shopId: 0), isEmpty);
    });

    test('an app too old keeps the outbox', () async {
      await queue('a');
      server.checkAnswer = ApiOk(
        SyncCheck.fromJson(
          FakeSync.checkJson({
            'app': {'update_needed': true, 'latest_version': '2.2.0'},
          }),
        ),
      );

      final out = await engine.run(shopId: 0);

      expect(out.stop, SyncStop.updateNeeded);
      expect(out.check?.latestVersion, '2.2.0');
      expect(await store.waitingCount(), 1);
      expect(server.sent, isEmpty);
    });

    test('the unsent count goes with the check', () async {
      await queue('a');
      await queue('b');
      await engine.run(shopId: 0);
      expect(server.lastUnsent, 2);
    });
  });

  group('the copy comes down', () {
    test(
      'first the snapshot, then changes since its first server_time',
      () async {
        server.snapshotPages = [
          page(
            'orders',
            rows: [
              {'id': 1, 'uuid': 'u1', 'status': 'Pending'},
            ],
            nextTable: 'order_payments',
            nextAfter: 0,
            serverTime: '2026-11-14T09:10:05+05:00',
          ),
          page(
            'order_payments',
            rows: [
              {'id': 7, 'order_id': 1, 'amount': 100},
            ],
            serverTime: '2026-11-14T09:11:00+05:00',
          ),
        ];

        await engine.run(shopId: 0);

        expect(await store.rows('orders', shopId: 0), hasLength(1));
        expect(
          await store.meta(SyncEngine.sinceKey, shopId: 0),
          '2026-11-14T04:10:05.000Z',
        );

        await engine.run(shopId: 0);
        expect(
          server.changesCalls.single.since,
          DateTime.utc(2026, 11, 14, 4, 10, 5),
        );
      },
    );

    test('a deleted order takes its payments and history with it', () async {
      await store.upsert('orders', [
        {'id': 1, 'uuid': 'u1'},
        {'id': 2, 'uuid': 'u2'},
      ], shopId: 0);
      await store.upsert('order_payments', [
        {'id': 10, 'order_id': 1},
        {'id': 11, 'order_id': 2},
      ], shopId: 0);
      await store.upsert('order_history', [
        {'id': 20, 'order_id': 1},
      ], shopId: 0);
      await store.upsert('deals', [
        {'id': 5},
      ], shopId: 0);
      await store.upsert('deliveries', [
        {'id': 50, 'deal_id': 5},
      ], shopId: 0);

      await store.deleteRow('orders', 1, shopId: 0);
      await store.deleteRow('deals', 5, shopId: 0);

      expect((await store.rows('orders', shopId: 0)).map((r) => r['id']), [2]);
      expect(
        (await store.rows('order_payments', shopId: 0)).map((r) => r['id']),
        [11],
      );
      expect(await store.rows('order_history', shopId: 0), isEmpty);
      expect(await store.rows('deliveries', shopId: 0), isEmpty);
    });

    test(
      'a 403 on the snapshot (add-on just ended) stops as not allowed',
      () async {
        server.snapshotPages = [
          const ApiErr(ApiFailure(ApiFailureKind.featureOff)),
        ];

        final out = await engine.run(shopId: 0);

        expect(out.stop, SyncStop.notAllowed);
      },
    );
  });

  group('the store', () {
    test('revise keeps the place in the order under a new id', () async {
      await queue('a');
      await queue('b');
      await queue('c');
      await store.markNeedsAttention('b', reason: 'serial_clash');
      await store.keepAnswer('b', {'reason': 'serial_clash'});

      await store.revise('b', newId: 'b2', data: {'x': 1});

      expect((await store.waiting()).map((r) => r.id), ['a', 'b2', 'c']);
      expect(await store.answerOf('b'), isNull);
    });

    test('forgetOutbox drops only this person\'s rows', () async {
      final mine = SyncStore(db, outbox, userId: 1);
      final theirs = SyncStore(db, outbox, userId: 2);
      await mine.addToOutbox(
        id: 'm',
        action: 'order.payment',
        data: {},
        at: DateTime(2026),
      );
      await theirs.addToOutbox(
        id: 't',
        action: 'order.payment',
        data: {},
        at: DateTime(2026),
      );

      expect(await mine.forgetOutbox(), ['m']);
      expect((await theirs.waiting()).map((r) => r.id), ['t']);
    });
  });

  test('check parses the brand answer', () {
    final c = SyncCheck.fromJson(
      FakeSync.checkJson({
        'plan': {
          'state': 'readonly',
          'paid_until': '2027-01-13',
          'read_only': true,
        },
        'outlet_ids': [3, 4],
        'device': {
          'id': 7,
          'name': 'Samsung A55',
          'this_device': true,
          'unsent_count': 2,
        },
        'access': {'is_owner': true},
      }),
    );
    expect(c.allowed, isTrue);
    expect(c.offline.addon, 'active');
    expect(c.offline.until, isNotNull);
    expect(c.readOnly, isTrue);
    expect(c.planState, 'readonly');
    expect(c.outletIds, [3, 4]);
    expect(c.device?.unsent, 2);
    expect(c.isOwner, isTrue);
    expect(c.versionMismatch, isFalse);
  });
}
