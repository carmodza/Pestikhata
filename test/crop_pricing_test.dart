import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/database/app_database.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/features/entry/application/entry_service.dart';
import 'package:pestikhata/features/khata/application/payment_summary.dart';
import 'package:pestikhata/features/ledger/domain/ledger_engine.dart';
import 'package:pestikhata/features/reports/application/report_service.dart';

void main() {
  const farmer = Endpoint(PartyKind.farmer, 'seller');
  const buyer = Endpoint(PartyKind.farmer, 'buyer');
  const supplierBuyer = Endpoint(PartyKind.supplier, 'supplier');
  const shop = Endpoint(PartyKind.inventory);
  const godam = Endpoint(PartyKind.godam, 'g');
  const rice = Product(
    id: 'rice',
    name: 'Rice',
    kind: EntryKind.crop,
    baseUnit: 'kg',
    units: {'kg': 1, 'maan': 40, 'bori': 50},
    purchasePaise: 7000,
    salePaise: 8000,
  );
  late AppDatabase db;
  late ShopRepository repo;

  EntryInput draft({Endpoint source = farmer, Endpoint destination = shop}) {
    final input = EntryInput()
      ..kind = EntryKind.crop
      ..source = source
      ..destination = destination
      ..quantity = '10';
    EntryService.selectProduct(input, rice);
    return input;
  }

  Future<JournalEntry> save(EntryInput input, String id) async {
    await repo.saveEntry(EntryService.preview(input, id: id));
    return (await repo.snapshot()).entries.firstWhere((e) => e.id == id);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = ShopRepository(db, 'shop', 'device', AppRole.owner, 'owner');
    await repo.saveProduct(rice);
    await repo.saveGodam(const Godam(id: 'g', name: 'Main'));
    for (final p in [
      const Person(id: 'seller', name: 'Rice farmer', kind: PartyKind.farmer),
      const Person(id: 'buyer', name: 'Rice buyer', kind: PartyKind.farmer),
      const Person(id: 'supplier', name: 'Trader', kind: PartyKind.supplier),
    ]) {
      await repo.savePerson(p);
    }
  });
  tearDown(() => db.close());

  test(
    '10 maan at Rs2800 adds Rs28000 payable, 400kg stock and no sale price',
    () async {
      for (final location in [shop, godam]) {
        final input = draft(destination: location);
        expect(input.unit, 'maan');
        EntryService.editPrice(input, 'purchase', '2800');
        final entry = await save(input, location.stockKey);
        expect(entry.purchaseTotalPaise, 2800000);
        expect(entry.salePaise, 0);
        expect(entry.hasCropSale, false);
        expect(entry.isSale, false);
        final data = await repo.snapshot();
        expect(data.ledger.stock('rice', location: location.stockKey), 400);
      }
      final data = await repo.snapshot();
      expect(data.ledger.personBalance('seller'), -5600000);
      expect(DashboardSummary(data, DateTime.now()).sales, 0);
      expect(data.ledger.cashBalance(), 0);
      final due = PaymentSummary(data, 'seller', receiving: false);
      expect(due.bills.length, 2);
      expect(due.duePaise, 5600000);
    },
  );

  test(
    'selling stored rice charges the buyer and does not bill the farmer twice',
    () async {
      await save(draft(destination: godam), 'buy');
      final sale = draft(source: godam, destination: buyer)
        ..quantity = '6'
        ..cash = '2000';
      EntryService.editPrice(sale, 'sale', '3200');
      await save(sale, 'sell');
      final data = await repo.snapshot();
      expect(data.ledger.personBalance('seller'), -2800000);
      expect(data.ledger.personBalance('buyer'), 1720000);
      expect(data.ledger.stock('rice', location: 'g'), 160);
      expect(data.ledger.cashBalance(), 200000);
      expect(data.ledger.profit(data.entries), 240000);
    },
  );

  test(
    'direct crop trade uses independent khatas and keeps shared cash through Shop',
    () async {
      final input = draft(destination: supplierBuyer)..cash = '5000';
      EntryService.editPrice(input, 'purchase', '2800');
      EntryService.editPrice(input, 'sale', '3200');
      final entry = await save(input, 'direct');
      final data = await repo.snapshot();
      expect(entry.purchaseTotalPaise, 2800000);
      expect(entry.totalPaise, 3200000);
      expect(data.ledger.personBalance('seller'), -2300000);
      expect(data.ledger.personBalance('supplier'), 2700000);
      expect(data.ledger.stock('rice'), 0);
      expect(data.ledger.cashBalance(), 0);
      expect(entry.cashInPaise, 500000);
      expect(entry.cashOutPaise, 500000);
      expect(data.ledger.profit(data.entries), 400000);
      expect(DashboardSummary(data, DateTime.now()).sales, 3200000);
      await repo.voidEntry(entry.id);
      final voided = await repo.snapshot();
      expect(voided.ledger.personBalance('seller'), 0);
      expect(voided.ledger.personBalance('supplier'), 0);
    },
  );

  test(
    'known purchase posts farmer khata while direct sale rate remains pending',
    () async {
      final input = draft(destination: buyer)
        ..ratePending = true
        ..cash = '1000';
      await save(input, 'pending-sale');
      var data = await repo.snapshot();
      expect(data.ledger.personBalance('seller'), -2700000);
      expect(data.ledger.personBalance('buyer'), -100000);
      expect(PaymentSummary(data, 'seller', receiving: false).bills.length, 1);
      expect(
        PaymentSummary(data, 'seller', receiving: false).unpricedEntries,
        isEmpty,
      );
      expect(
        PaymentSummary(data, 'buyer', receiving: true).unpricedEntries.length,
        1,
      );
      final staff = ShopRepository(
        db,
        'shop',
        'staff-device',
        AppRole.staff,
        'staff',
      );
      await staff.resolveRate('pending-sale', 320000);
      data = await repo.snapshot();
      expect(data.ledger.personBalance('seller'), -2700000);
      expect(data.ledger.personBalance('buyer'), 3100000);
      expect(data.ledger.pendingRates, isEmpty);
      expect(data.ledger.cashBalance(), 0);
      await expectLater(
        staff.resolveRate('pending-sale', 330000),
        throwsA(isA<DomainFailure>()),
      );
    },
  );

  test(
    'either direct rate may remain pending and both can resolve atomically',
    () async {
      final input = draft(destination: buyer)..purchaseRatePending = true;
      await save(input, 'pending-buy');
      var data = await repo.snapshot();
      expect(data.entries.single.ratePending, false);
      expect(data.ledger.pendingRates.length, 1);
      expect(data.ledger.personBalance('seller'), 0);
      expect(data.ledger.personBalance('buyer'), 3200000);
      expect(data.ledger.profit(data.entries), 0);
      final staff = ShopRepository(
        db,
        'shop',
        'staff-device',
        AppRole.staff,
        'staff',
      );
      await staff.resolveRate('pending-buy', 280000, purchase: true);
      data = await repo.snapshot();
      expect(data.ledger.personBalance('seller'), -2800000);
      expect(data.ledger.personBalance('buyer'), 3200000);
      expect(data.ledger.pendingRates, isEmpty);
      expect(data.ledger.profit(data.entries), 400000);
      await expectLater(
        staff.resolveRate('pending-buy', 270000, purchase: true),
        throwsA(isA<DomainFailure>()),
      );

      await save(
        draft(destination: buyer)
          ..purchaseRatePending = true
          ..ratePending = true,
        'both',
      );
      final count = (await repo.pending()).length;
      await staff.resolveEntryRates('both', purchase: 280000, rate: 320000);
      expect((await repo.pending()).length, count);
      expect((await repo.snapshot()).ledger.pendingRates, isEmpty);
    },
  );

  test(
    'stored pending purchase resolves only its purchase rate without moving stock again',
    () async {
      await save(
        draft()
          ..ratePending = true
          ..cash = '1000',
        'pending-receipt',
      );
      expect((await repo.snapshot()).ledger.personBalance('seller'), 100000);
      await repo.resolveRate('pending-receipt', 280000);
      final data = await repo.snapshot();
      expect(data.entries.single.purchasePaise, 280000);
      expect(data.entries.single.salePaise, 0);
      expect(data.ledger.personBalance('seller'), -2700000);
      expect(data.ledger.stock('rice'), 400);
      expect(data.ledger.cashBalance(), -100000);
    },
  );

  test(
    'manual rates survive person/location changes and convert with crop units',
    () {
      final input = draft();
      EntryService.editPrice(input, 'purchase', '2800');
      EntryService.changeEndpoint(input, false, godam);
      expect(input.purchase, '2800');
      EntryService.changeEndpoint(input, false, buyer);
      expect(input.purchase, '2800');
      EntryService.editPrice(input, 'sale', '3300');
      EntryService.changeUnit(input, 'bori');
      expect(input.purchase, '3500.00');
      expect(input.sale, '4125.00');
      EntryService.changeUnit(input, 'kg');
      expect(input.purchase, '70.00');
      expect(input.sale, '82.50');
    },
  );

  test(
    'direct cash must fit both known crop totals and failed updates roll back',
    () async {
      await expectLater(
        save(draft(destination: buyer)..cash = '30000', 'too-much'),
        throwsA(isA<DomainFailure>()),
      );
      expect((await repo.snapshot()).entries, isEmpty);
      await save(
        draft(destination: buyer)
          ..purchaseRatePending = true
          ..ratePending = true
          ..cash = '1000',
        'pending',
      );
      await expectLater(
        repo.resolveEntryRates('pending', purchase: 1, rate: 320000),
        throwsA(isA<DomainFailure>()),
      );
      final entry = (await repo.snapshot()).entries.single;
      expect(entry.ratePending, true);
      expect(entry.purchaseRatePending, true);
    },
  );

  test(
    'legacy crop bills retain their previous khata values and serialization',
    () {
      final json = JournalEntry(
        id: 'legacy',
        kind: EntryKind.crop,
        source: farmer,
        destination: buyer,
        date: DateTime(2026),
        quantity: 10,
        ratePaise: 320000,
        purchasePaise: 280000,
        salePaise: 320000,
      ).toJson();
      final legacy = JournalEntry.fromJson(json);
      expect(legacy.toJson(), json);
      expect(json.containsKey('cropPricing'), false);
      expect(legacy.cropPricing, false);
      final data = LedgerEngine([legacy]);
      expect(data.personBalance('seller'), -3200000);
      expect(data.personBalance('buyer'), 3200000);
    },
  );
}
