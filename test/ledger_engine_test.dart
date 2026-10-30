import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/core/domain/money_math.dart';
import 'package:pestikhata/features/ledger/domain/ledger_engine.dart';

void main() {
  const farmer = Person(id: 'f', name: 'Ali', kind: PartyKind.farmer);
  const supplier = Person(id: 's', name: 'Supply', kind: PartyKind.supplier);
  const product = Product(
    id: 'p',
    name: 'Urea',
    baseUnit: 'bag',
    units: {'bag': 1, 'carton': 10},
  );
  const crop = Product(
    id: 'w',
    name: 'Wheat',
    kind: EntryKind.crop,
    baseUnit: 'kg',
    units: {'kg': 1, 'maan': 40, 'quintal': 100, 'bori': 50, 'ton': 1000},
  );
  final expiry = DateTime(2027, 12, 1), date = DateTime(2026, 10, 29);
  JournalEntry purchase({double qty = 20}) => JournalEntry(
    id: 'buy',
    kind: EntryKind.product,
    source: const Endpoint(PartyKind.supplier, 's'),
    destination: const Endpoint(PartyKind.inventory),
    date: date,
    itemId: 'p',
    quantity: qty,
    unit: 'bag',
    batch: 'A',
    expiry: expiry,
    ratePaise: 10000,
    purchasePaise: 10000,
    cashPaise: 0,
  );
  JournalEntry sale({double qty = 3, int cash = 10000, bool pending = false}) =>
      JournalEntry(
        id: 'sell',
        kind: EntryKind.product,
        source: const Endpoint(PartyKind.inventory),
        destination: const Endpoint(PartyKind.farmer, 'f'),
        date: date,
        itemId: 'p',
        quantity: qty,
        unit: 'bag',
        batch: 'A',
        expiry: expiry,
        ratePaise: 15000,
        purchasePaise: 10000,
        cashPaise: cash,
        ratePending: pending,
      );
  void validate(LedgerEngine ledger, JournalEntry entry) => ledger.validate(
    entry,
    products: [product, crop],
    people: [farmer, supplier],
    godams: [const Godam(id: 'g', name: 'Main')],
  );
  test('money parser keeps exact paisa and rejects malformed inputs', () {
    expect(parseMoney('1,234.56'), 123456);
    expect(parseMoney('0.1'), 10);
    expect(parseMoney('0'), 0);
    for (final s in ['-1', '1.234', 'NaN', '', '1e8']) {
      expect(() => parseMoney(s), throwsA(isA<DomainFailure>()));
    }
  });
  test('fractional quantities use decimal half-up rounding', () {
    expect(multiplyMoney(.145, 100), 15);
    expect(multiplyMoney(.144, 100), 14);
    expect(multiplyMoney(1e-7, 10000000), 1);
    expect(multiplyMoney(2.5, 12345), 30863);
  });
  test('purchase and sale project cash, stock and both khatas', () {
    final ledger = LedgerEngine([purchase(), sale()]);
    expect(ledger.stock('p'), 17);
    expect(ledger.personBalance('s'), -200000);
    expect(ledger.personBalance('f'), 35000);
    expect(ledger.cashBalance(), 10000);
    expect(ledger.profit(ledger.entries), 15000);
  });
  test('payment received reduces farmer receivable', () {
    final payment = JournalEntry(
      id: 'pay',
      kind: EntryKind.cash,
      source: const Endpoint(PartyKind.farmer, 'f'),
      destination: const Endpoint(PartyKind.inventory),
      date: date,
      amountPaise: 35000,
    );
    final ledger = LedgerEngine([purchase(), sale(), payment]);
    expect(ledger.personBalance('f'), 0);
    expect(ledger.cashBalance(), 45000);
    expect(payment.creditPaise, 0);
  });
  test('cash-paid stock purchase reduces cash, sale increases cash', () {
    final paid = JournalEntry.fromJson(
      purchase().toJson()..['cashPaise'] = 50000,
    );
    expect(paid.cashDelta, -50000);
    expect(sale().cashDelta, 10000);
    expect(LedgerEngine([paid, sale()]).cashBalance(), -40000);
  });
  test('business and expiry calendar dates are timezone-free', () {
    final json = purchase().toJson();
    expect(json['date'], '2026-10-29');
    expect(json['expiry'], '2027-12-01');
    final restored = JournalEntry.fromJson(json);
    expect(restored.date, DateTime(2026, 10, 29));
    expect(restored.expiry, DateTime(2027, 12, 1));
  });
  test('supplier payment reduces payable', () {
    final payment = JournalEntry(
      id: 'pay',
      kind: EntryKind.cash,
      source: const Endpoint(PartyKind.inventory),
      destination: const Endpoint(PartyKind.supplier, 's'),
      date: date,
      amountPaise: 30000,
    );
    expect(LedgerEngine([purchase(), payment]).personBalance('s'), -170000);
  });
  test(
    'pending rate moves stock and tracks a cash advance without pricing',
    () {
      final pending = sale(pending: true);
      final ledger = LedgerEngine([purchase(), pending]);
      expect(ledger.stock('p'), 17);
      expect(ledger.personBalance('f'), -10000);
      expect(ledger.pendingRates.length, 1);
      expect(ledger.profit(ledger.entries), 0);
      final resolved = LedgerEngine([purchase(), pending.withRate(16000)]);
      expect(resolved.stock('p'), 17);
      expect(resolved.personBalance('f'), 38000);
      expect(resolved.pendingRates, isEmpty);
    },
  );
  test('godam transfer changes locations but not total stock or cash', () {
    final transfer = JournalEntry(
      id: 'transfer',
      kind: EntryKind.product,
      source: const Endpoint(PartyKind.inventory),
      destination: const Endpoint(PartyKind.godam, 'g'),
      date: date,
      itemId: 'p',
      quantity: 1,
      unit: 'carton',
      unitFactor: 10,
      batch: 'A',
      expiry: expiry,
    );
    validate(LedgerEngine([purchase()]), transfer);
    final ledger = LedgerEngine([purchase(), transfer]);
    expect(ledger.stock('p'), 20);
    expect(ledger.stock('p', location: 'inventory'), 10);
    expect(ledger.stock('p', location: 'g'), 10);
    expect(transfer.totalPaise, 0);
    expect(transfer.cashDelta, 0);
  });
  test('maan and bori are snapshotted conversion factors', () {
    final receipt = JournalEntry(
      id: 'crop',
      kind: EntryKind.crop,
      source: const Endpoint(PartyKind.farmer, 'f'),
      destination: const Endpoint(PartyKind.inventory),
      date: date,
      itemId: 'w',
      quantity: 2,
      unit: 'maan',
      unitFactor: 40,
      ratePaise: 300000,
      cashPaise: 100000,
    );
    validate(LedgerEngine([]), receipt);
    expect(LedgerEngine([receipt]).stock('w'), 80);
    expect(LedgerEngine([receipt]).personBalance('f'), -500000);
    final malformed = JournalEntry.fromJson(
      receipt.toJson()..['unitFactor'] = 50,
    );
    expect(
      () => validate(LedgerEngine([]), malformed),
      throwsA(isA<DomainFailure>()),
    );
  });
  test('cash cannot exceed settled entry total', () {
    expect(
      () => validate(LedgerEngine([purchase()]), sale(cash: 999999)),
      throwsA(isA<DomainFailure>()),
    );
  });
  test('batch availability is checked exactly', () {
    final ledger = LedgerEngine([purchase()]);
    expect(
      () => validate(ledger, sale(qty: 21)),
      throwsA(isA<DomainFailure>()),
    );
    expect(
      () => validate(
        ledger,
        JournalEntry.fromJson(sale().toJson()..['batch'] = 'B'),
      ),
      throwsA(isA<DomainFailure>()),
    );
    validate(ledger, sale(qty: 20));
  });
  test('walk-in cannot carry udhar or a pending rate', () {
    final walkIn = JournalEntry.fromJson(
      sale().toJson()
        ..['destination'] = const Endpoint(PartyKind.walkIn).toJson(),
    );
    expect(
      () => validate(LedgerEngine([purchase()]), walkIn),
      throwsA(isA<DomainFailure>()),
    );
  });
  test('diesel on credit creates a supplier payable', () {
    final diesel = JournalEntry(
      id: 'd',
      kind: EntryKind.diesel,
      source: const Endpoint(PartyKind.inventory),
      destination: const Endpoint(PartyKind.supplier, 's'),
      date: date,
      quantity: 10,
      unit: 'liter',
      ratePaise: 25000,
      cashPaise: 50000,
    );
    validate(LedgerEngine([]), diesel);
    final ledger = LedgerEngine([diesel]);
    expect(ledger.personBalance('s'), -200000);
    expect(ledger.cashBalance(), -50000);
    expect(ledger.expenses(ledger.entries), 250000);
  });
  test(
    'voided entry reverses every projection while preserving the record',
    () {
      final ledger = LedgerEngine([purchase(), sale().voidEntry()]);
      expect(ledger.stock('p'), 20);
      expect(ledger.personBalance('f'), 0);
      expect(ledger.cashBalance(), 0);
    },
  );
  test('LWW uses deterministic device ordering for equal timestamps', () {
    RecordEnvelope record(int time, String device) => RecordEnvelope(
      id: 'x',
      entity: 'people',
      shopId: 'shop',
      payload: {},
      updatedAt: time,
      deviceId: device,
    );
    expect(record(5, 'b').newerThan(record(5, 'a')), true);
    expect(record(4, 'z').newerThan(record(5, 'a')), false);
    expect(record(5, 'a').newerThan(record(5, 'a')), false);
  });
  test('opening balance uses entries strictly before the selected day', () {
    final prior = JournalEntry(
      id: 'prior',
      kind: EntryKind.cash,
      source: const Endpoint(PartyKind.walkIn),
      destination: const Endpoint(PartyKind.inventory),
      date: date.subtract(const Duration(days: 1)),
      amountPaise: 5000,
    );
    expect(LedgerEngine([prior, sale()]).cashBalance(before: date), 5000);
  });
}
