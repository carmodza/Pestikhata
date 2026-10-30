import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/database/app_database.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/features/reports/application/report_service.dart';

void main() {
  late AppDatabase db;
  late ShopRepository repo;
  const shop = Endpoint(PartyKind.inventory),
      farmer = Endpoint(PartyKind.farmer, 'f'),
      supplier = Endpoint(PartyKind.supplier, 's'),
      godam = Endpoint(PartyKind.godam, 'g');
  final date = DateTime(2026, 10, 30);
  JournalEntry goods(
    String id, {
    Endpoint source = supplier,
    Endpoint destination = shop,
    double quantity = 1,
    int cash = 0,
    bool pending = false,
    String batch = '',
    DateTime? expiry,
  }) => JournalEntry(
    id: id,
    kind: EntryKind.product,
    source: source,
    destination: destination,
    date: date,
    itemId: 'p',
    quantity: quantity,
    unit: 'piece',
    ratePaise: pending ? 0 : 10000,
    purchasePaise: 5000,
    salePaise: 10000,
    cashPaise: cash,
    ratePending: pending,
    batch: batch,
    expiry: expiry,
  );
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ShopRepository(db, 'shop', 'device', AppRole.owner, 'owner');
    for (final person in [
      const Person(id: 'f', name: 'Ali', kind: PartyKind.farmer),
      const Person(id: 's', name: 'Supply', kind: PartyKind.supplier),
      const Person(id: 's2', name: 'Supply 2', kind: PartyKind.supplier),
    ]) {
      await repo.savePerson(person);
    }
    await repo.saveProduct(
      const Product(
        id: 'p',
        name: 'Seed',
        purchasePaise: 5000,
        salePaise: 10000,
      ),
    );
    await repo.saveGodam(const Godam(id: 'g', name: 'Main'));
  });
  tearDown(() async => db.close());

  test(
    'automatic sales skip expired stock while godam transfers can move it',
    () async {
      await repo.saveEntry(
        goods(
          'expired',
          quantity: 2,
          batch: 'EXPIRED',
          expiry: DateTime(2026, 1, 1),
        ),
      );
      await repo.saveEntry(
        goods('fresh', quantity: 1, batch: 'FRESH', expiry: DateTime(2027)),
      );
      await repo.saveEntry(goods('sale', source: shop, destination: farmer));
      expect(
        (await repo.snapshot()).entries
            .firstWhere((e) => e.id == 'sale')
            .allocations
            .single
            .batch,
        'FRESH',
      );
      await expectLater(
        repo.saveEntry(goods('no-fresh', source: shop, destination: farmer)),
        throwsA(isA<DomainFailure>()),
      );
      await repo.saveEntry(
        goods('move-expired', source: shop, destination: godam, quantity: 2),
      );
      expect((await repo.snapshot()).ledger.stock('p', location: 'g'), 2);
    },
  );

  test(
    'allocation totals and duplicate lots are validated before committing',
    () async {
      await repo.saveEntry(goods('receipt', quantity: 5, batch: 'A'));
      final pending = (await repo.pending()).length;
      for (final allocations in [
        [const StockAllocation(batch: 'A', quantity: 1)],
        [
          const StockAllocation(batch: 'A', quantity: 1),
          const StockAllocation(batch: 'A', quantity: 1),
        ],
      ]) {
        final entry = JournalEntry.fromJson(
          goods(
              'invalid',
              source: shop,
              destination: farmer,
              quantity: 2,
            ).toJson()
            ..['allocations'] = allocations.map((a) => a.toJson()).toList(),
        );
        await expectLater(repo.saveEntry(entry), throwsA(isA<DomainFailure>()));
      }
      expect((await repo.pending()).length, pending);
      expect((await repo.snapshot()).ledger.stock('p'), 5);
    },
  );

  test('receipts generate distinct batches and can omit expiry', () async {
    await repo.saveEntry(goods('receipt-1', quantity: 2));
    await repo.saveEntry(goods('receipt-2', quantity: 3, destination: godam));
    final data = await repo.snapshot();
    expect(data.entries.map((e) => e.batch).toSet().length, 2);
    expect(
      data.entries.every((e) => e.batch.startsWith('B-') && e.expiry == null),
      isTrue,
    );
    expect(data.ledger.stock('p'), 5);
    expect(data.ledger.stock('p', location: 'g'), 3);
  });
  test(
    'one sale spans lots by expiry without duplicating cash or khata; void restores all lots',
    () async {
      await repo.saveEntry(
        goods('early', quantity: 2, batch: 'EARLY', expiry: DateTime(2027)),
      );
      await repo.saveEntry(
        goods('late', quantity: 3, batch: 'LATE', expiry: DateTime(2028)),
      );
      await repo.saveEntry(goods('unknown', quantity: 4, batch: 'UNKNOWN'));
      await repo.saveEntry(
        goods(
          'sale',
          source: shop,
          destination: farmer,
          quantity: 4,
          cash: 10000,
        ),
      );
      var data = await repo.snapshot();
      final sale = data.entries.firstWhere((e) => e.id == 'sale');
      expect(sale.allocations.map((a) => a.batch), ['EARLY', 'LATE']);
      expect(sale.allocations.map((a) => a.quantity), [2, 2]);
      expect(sale.totalPaise, 40000);
      expect(data.ledger.cashBalance(), 10000);
      expect(data.ledger.personBalance('f'), 30000);
      expect(data.ledger.stock('p'), 5);
      await repo.resolveRate('sale', 12000);
      expect((await repo.snapshot()).ledger.stock('p'), 5);
      await repo.voidEntry('sale');
      data = await repo.snapshot();
      expect(data.ledger.stock('p'), 9);
      expect(data.ledger.personBalance('f'), 0);
      expect(data.ledger.cashBalance(), 0);
    },
  );
  test(
    'automatic godam transfers preserve every lot and can transfer back',
    () async {
      await repo.saveEntry(
        goods('a', quantity: 2, batch: 'A', expiry: DateTime(2027)),
      );
      await repo.saveEntry(goods('b', quantity: 3, batch: 'B'));
      await repo.saveEntry(
        goods('transfer', source: shop, destination: godam, quantity: 4),
      );
      var data = await repo.snapshot();
      expect(data.ledger.stock('p'), 5);
      expect(data.ledger.stock('p', location: 'g'), 4);
      expect(data.ledger.cashBalance(), 0);
      await repo.saveEntry(
        goods('return', source: godam, destination: shop, quantity: 3),
      );
      data = await repo.snapshot();
      expect(data.ledger.stock('p', location: 'g'), 1);
      expect(data.ledger.stock('p', location: 'inventory'), 4);
      expect(
        data.ledger
            .stockLots()
            .firstWhere((l) => l.location == 'inventory' && l.batch == 'A')
            .expiry,
        DateTime(2027),
      );
    },
  );
  test(
    'direct supplier to farmer updates both khatas and gross cash with no shop stock/profit',
    () async {
      await repo.saveEntry(
        goods(
          'direct',
          source: supplier,
          destination: farmer,
          quantity: 10,
          cash: 30000,
        ),
      );
      final data = await repo.snapshot(), entry = data.entries.single;
      expect(entry.direction, EntryDirection.direct);
      expect(data.ledger.personBalance('s'), -70000);
      expect(data.ledger.personBalance('f'), 70000);
      expect(data.ledger.stock('p'), 0);
      expect(data.ledger.cashBalance(), 0);
      expect(data.ledger.profit(data.entries), 0);
      final dashboard = DashboardSummary(data, date);
      expect(dashboard.cashIn, 30000);
      expect(dashboard.cashOut, 30000);
      expect(dashboard.sales, 100000);
      expect(DailyLedger(data, date).closing, 0);
    },
  );
  test(
    'supplier-to-supplier cash passes through shop and balances both people',
    () async {
      await repo.saveEntry(
        JournalEntry(
          id: 'payment',
          kind: EntryKind.cash,
          source: supplier,
          destination: const Endpoint(PartyKind.supplier, 's2'),
          date: date,
          amountPaise: 50000,
        ),
      );
      final data = await repo.snapshot();
      expect(data.ledger.personBalance('s'), -50000);
      expect(data.ledger.personBalance('s2'), 50000);
      expect(data.ledger.cashBalance(), 0);
      expect(DashboardSummary(data, date).cashIn, 50000);
      expect(DashboardSummary(data, date).cashOut, 50000);
    },
  );
  test(
    'pending direct rate resolves both khatas without adding stock',
    () async {
      await repo.saveEntry(
        goods(
          'pending',
          source: supplier,
          destination: farmer,
          quantity: 2,
          cash: 2000,
          pending: true,
        ),
      );
      expect((await repo.snapshot()).ledger.personBalance('f'), -2000);
      await repo.resolveRate('pending', 12000);
      final data = await repo.snapshot();
      expect(data.ledger.personBalance('f'), 22000);
      expect(data.ledger.personBalance('s'), -22000);
      expect(data.ledger.stock('p'), 0);
      expect(data.ledger.cashBalance(), 0);
    },
  );
  test(
    'insufficient automatic stock rolls back the complete entry and outbox',
    () async {
      await repo.saveEntry(goods('receipt', quantity: 2));
      final pending = (await repo.pending()).length;
      await expectLater(
        repo.saveEntry(
          goods('sale', source: shop, destination: farmer, quantity: 3),
        ),
        throwsA(isA<DomainFailure>()),
      );
      expect((await repo.snapshot()).entries.length, 1);
      expect((await repo.pending()).length, pending);
    },
  );
  test(
    'backup restore preserves allocated multi-lot stock and the single cash movement',
    () async {
      await repo.saveEntry(goods('a', quantity: 2));
      await repo.saveEntry(goods('b', quantity: 3));
      await repo.saveEntry(
        goods(
          'sale',
          source: shop,
          destination: farmer,
          quantity: 4,
          cash: 10000,
        ),
      );
      final backup = await repo.backup();
      final restoredDb = AppDatabase(NativeDatabase.memory());
      try {
        final restored = ShopRepository(
          restoredDb,
          'shop',
          'restored-device',
          AppRole.owner,
          'owner',
        );
        await restored.restore(backup);
        final data = await restored.snapshot();
        expect(data.ledger.stock('p'), 1);
        expect(data.ledger.cashBalance(), 10000);
        expect(
          data.entries.firstWhere((e) => e.id == 'sale').allocations.length,
          2,
        );
      } finally {
        await restoredDb.close();
      }
    },
  );
}
