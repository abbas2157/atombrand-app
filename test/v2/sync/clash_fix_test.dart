import 'package:atombrand_app/v2/core/db/atom_db.dart';
import 'package:atombrand_app/v2/core/db/outbox_actions.dart';
import 'package:atombrand_app/v2/core/db/outbox_db.dart';
import 'package:atombrand_app/v2/core/db/sync_store.dart';
import 'package:atombrand_app/v2/features/sync/data/clash_fix.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fix a serial clash (10.4): the outbox is put right without losing the
/// rest of the stock in, and keeps its order.
void main() {
  late AtomDb db;
  late OutboxDb outbox;
  late SyncStore store;
  var n = 0;
  String newId() => 'new-${++n}';

  setUp(() {
    n = 0;
    db = AtomDb(NativeDatabase.memory());
    outbox = OutboxDb(NativeDatabase.memory());
    store = SyncStore(db, outbox);
  });

  tearDown(() async {
    await db.close();
    await outbox.close();
  });

  Future<OutboxEntry> clashed(List<String> serials, {String id = 'si'}) async {
    await store.addToOutbox(
      id: 'before',
      action: 'order.payment',
      data: const {},
      at: DateTime(2026),
    );
    final a = OfflineAction.stockIn(
      variantId: 5,
      warehouseId: 2,
      qty: serials.length,
      serials: serials,
    );
    await store.addToOutbox(
      id: id,
      action: a.action,
      data: a.data,
      at: DateTime(2026),
    );
    await store.addToOutbox(
      id: 'after',
      action: 'order.status',
      data: const {},
      at: DateTime(2026),
    );
    await store.markNeedsAttention(id, reason: 'serial_clash');
    await store.keepAnswer(id, {
      'details': {'serials': serials.take(1).toList()},
    });
    return (await store.entry(id))!;
  }

  test('Drop mine sends the other units again, in the same place', () async {
    final e = await clashed(['SN-1', 'SN-2', 'SN-3']);

    final fixed = await fixClash(
      store,
      e,
      clashing: ['sn-1'],
      choice: ClashChoice.dropMine,
      newId: newId,
    );

    expect(fixed.discarded, isFalse);
    expect(fixed.kept, ['SN-2', 'SN-3']);
    final waiting = await store.waiting();
    expect(waiting.map((r) => r.id), ['before', 'new-1', 'after']);
    final revised = waiting[1];
    expect(revised.action, 'stock.in');
    expect(revised.data, contains('"qty":2'));
    expect(revised.data, isNot(contains('SN-1')));
    expect(await store.needingAttention(), isEmpty);
    expect(await store.answerOf('si'), isNull);
  });

  test('Move it here also queues a transfer of the server\'s unit', () async {
    final e = await clashed(['SN-1', 'SN-2']);

    final fixed = await fixClash(
      store,
      e,
      clashing: ['SN-1'],
      choice: ClashChoice.moveHere,
      newId: newId,
    );

    expect(fixed.transferId, isNotNull);
    final waiting = await store.waiting();
    final move = waiting.last;
    expect(move.action, 'stock.transfer');
    expect(move.data, contains('"serials":["SN-1"]'));
    expect(move.data, contains('"to_warehouse_id":2'));
  });

  test('a stock in that was only the clashing unit is discarded', () async {
    final e = await clashed(['SN-1']);

    final fixed = await fixClash(
      store,
      e,
      clashing: ['SN-1'],
      choice: ClashChoice.dropMine,
      newId: newId,
    );

    expect(fixed.discarded, isTrue);
    expect(await store.entry('si'), isNull);
    expect((await store.waiting()).map((r) => r.id), ['before', 'after']);
  });

  test('a delivery with a taken serial can only be given up', () {
    expect(clashChoices('order.status'), [ClashChoice.discard]);
    expect(clashChoices('deal.deliver'), [ClashChoice.discard]);
    expect(clashChoices('stock.in'), hasLength(3));
  });
}
