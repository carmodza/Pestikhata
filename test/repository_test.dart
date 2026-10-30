import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/database/app_database.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/features/demo/data/demo_data.dart';

void main() {
  late AppDatabase db;
  late ShopRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ShopRepository(db, 'shop', 'device-a', AppRole.owner, 'owner');
  });
  tearDown(() async {
    await db.close();
  });
  test('document and outbox commit atomically', () async {
    await repo.savePerson(
      const Person(id: 'f', name: 'Ali', kind: PartyKind.farmer),
    );
    expect((await repo.snapshot()).people.single.name, 'Ali');
    expect((await repo.pending()).length, 1);
    await expectLater(
      repo.savePerson(
        const Person(id: 'bad', name: '', kind: PartyKind.farmer),
      ),
      throwsA(isA<DomainFailure>()),
    );
    expect((await repo.pending()).length, 1);
  });
  test(
    'acknowledgement of an older version cannot drop a newer local edit',
    () async {
      await repo.savePerson(
        const Person(id: 'f', name: 'Ali', kind: PartyKind.farmer),
      );
      final sent = (await repo.pending()).single;
      await repo.savePerson(
        const Person(id: 'f', name: 'Ali Raza', kind: PartyKind.farmer),
      );
      await repo.acknowledge(sent);
      expect((await repo.pending()).length, 1);
      expect((await repo.snapshot()).people.single.name, 'Ali Raza');
    },
  );
  test(
    'newer remote wins and clears obsolete outbox; duplicate pull is idempotent',
    () async {
      await repo.savePerson(
        const Person(id: 'f', name: 'Ali', kind: PartyKind.farmer),
      );
      final local = (await repo.pending()).single;
      final remote = RecordEnvelope(
        id: local.id,
        entity: local.entity,
        shopId: local.shopId,
        payload: local.payload..['name'] = 'Remote Ali',
        updatedAt: local.updatedAt + 100,
        deviceId: 'device-b',
      );
      await repo.mergeRemote(remote);
      await repo.mergeRemote(remote);
      expect((await repo.snapshot()).people.single.name, 'Remote Ali');
      expect(await repo.pending(), isEmpty);
    },
  );
  test('equal timestamp tie resolves by device ID', () async {
    await repo.savePerson(
      const Person(id: 'f', name: 'Local', kind: PartyKind.farmer),
    );
    final local = (await repo.pending()).single;
    final remote = RecordEnvelope(
      id: 'f',
      entity: 'people',
      shopId: 'shop',
      payload: local.payload..['name'] = 'Tie winner',
      updatedAt: local.updatedAt,
      deviceId: 'device-z',
    );
    await repo.mergeRemote(remote);
    expect((await repo.snapshot()).people.single.name, 'Tie winner');
  });
  test('shops never mix in local queries or remote merges', () async {
    final other = ShopRepository(
      db,
      'other',
      'device-b',
      AppRole.owner,
      'another',
    );
    await other.savePerson(
      const Person(id: 'f', name: 'Other shop', kind: PartyKind.farmer),
    );
    expect((await repo.snapshot()).people, isEmpty);
    await expectLater(
      repo.mergeRemote((await other.pending()).single),
      throwsA(isA<DomainFailure>()),
    );
  });
  test(
    'owner backup restores all entities, and rejects another shop',
    () async {
      await repo.savePerson(
        const Person(id: 'f', name: 'Ali', kind: PartyKind.farmer),
      );
      final backup = await repo.backup();
      final content = jsonDecode(backup) as Map<String, dynamic>;
      content['shopId'] = 'other';
      await expectLater(
        repo.restore(jsonEncode(content)),
        throwsA(isA<DomainFailure>()),
      );
      await repo.restore(backup);
      expect((await repo.snapshot()).people.length, 1);
    },
  );
  test('staff cannot backup, restore or void entries', () async {
    final staff = ShopRepository(
      db,
      'shop',
      'staff-device',
      AppRole.staff,
      'staff',
    );
    await expectLater(staff.backup(), throwsA(isA<DomainFailure>()));
    await expectLater(staff.restore('{}'), throwsA(isA<DomainFailure>()));
    await expectLater(staff.voidEntry('id'), throwsA(isA<DomainFailure>()));
  });
  test(
    'demo seed is idempotent and balances survive a pending-rate update',
    () async {
      final demo = ShopRepository(
        db,
        'demo-local',
        'device',
        AppRole.owner,
        'demo-owner',
      );
      await DemoData.seed(demo);
      final first = await demo.snapshot();
      await DemoData.seed(demo);
      expect((await demo.snapshot()).entries.length, first.entries.length);
      final stock = first.ledger.stock('imidacloprid');
      await demo.resolveRate('sale-pending', 110000);
      final after = await demo.snapshot();
      expect(after.ledger.stock('imidacloprid'), stock);
      expect(after.ledger.pendingRates, isEmpty);
      expect((await demo.pending()).isNotEmpty, true);
      await DemoData.clear(demo);
      expect((await demo.snapshot()).records, isEmpty);
    },
  );
  test('daily rate updates preserve old bills', () async {
    final demo = ShopRepository(
      db,
      'demo-local',
      'device',
      AppRole.owner,
      'demo-owner',
    );
    await DemoData.seed(demo);
    final before = await demo.snapshot();
    final item = before.products.firstWhere((p) => p.id == 'urea');
    await demo.saveRate(item, 500000, 600000);
    final after = await demo.snapshot();
    expect(
      after.entries.firstWhere((e) => e.id == 'sale-urea').ratePaise,
      460000,
    );
    expect(after.products.firstWhere((p) => p.id == 'urea').salePaise, 600000);
    expect(
      after.rates.single.toJson()['id'],
      after.records.firstWhere((r) => r.entity == 'rates').id,
    );
  });
  test(
    'staff can complete pending rates but only owners can correct finalized rates',
    () async {
      final demo = ShopRepository(
        db,
        'demo-local',
        'device',
        AppRole.owner,
        'demo-owner',
      );
      await DemoData.seed(demo);
      final staff = ShopRepository(
        db,
        'demo-local',
        'staff-device',
        AppRole.staff,
        'staff',
      );
      await staff.resolveRate('sale-pending', 110000);
      await expectLater(
        staff.resolveRate('sale-pending', 120000),
        throwsA(isA<DomainFailure>()),
      );
      await demo.resolveRate('sale-pending', 120000);
      expect(
        (await demo.snapshot()).entries
            .firstWhere((e) => e.id == 'sale-pending')
            .ratePaise,
        120000,
      );
    },
  );
  test('restore queues catalog dependencies before journal entries', () async {
    final demo = ShopRepository(
      db,
      'demo-local',
      'device',
      AppRole.owner,
      'demo-owner',
    );
    await DemoData.seed(demo);
    final backup = jsonDecode(await demo.backup()) as Map<String, dynamic>;
    final records = backup['records'] as List;
    records.sort(
      (a, b) => (a['entity'] == 'entries' ? 0 : 1).compareTo(
        b['entity'] == 'entries' ? 0 : 1,
      ),
    );
    await DemoData.clear(demo);
    await demo.restore(jsonEncode(backup));
    final pending = await demo.pending();
    final firstEntry = pending.indexWhere((r) => r.entity == 'entries');
    expect(firstEntry, greaterThan(0));
    expect(
      pending.skip(firstEntry).every((r) => r.entity == 'entries'),
      isTrue,
    );
  });
  test('stocked products cannot change their type or base unit', () async {
    final demo = ShopRepository(
      db,
      'demo-local',
      'device',
      AppRole.owner,
      'demo-owner',
    );
    await DemoData.seed(demo);
    final item = (await demo.snapshot()).products.firstWhere(
      (p) => p.id == 'urea',
    );
    await expectLater(
      demo.saveProduct(Product.fromJson(item.toJson()..['kind'] = 'crop')),
      throwsA(isA<DomainFailure>()),
    );
    await expectLater(
      demo.saveRate(item, 9000000000001, 9000000000001),
      throwsA(isA<DomainFailure>()),
    );
    expect(
      (await demo.snapshot()).products.firstWhere((p) => p.id == 'urea').kind,
      EntryKind.product,
    );
  });
}
