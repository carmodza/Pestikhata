import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/features/khata/application/payment_summary.dart';

void main() {
  const shop = Endpoint(PartyKind.inventory),
      farmer = Endpoint(PartyKind.farmer, 'f'),
      supplier = Endpoint(PartyKind.supplier, 's');
  final date = DateTime(2026, 10, 30);
  JournalEntry bill(
    String id,
    int amount, {
    int day = 0,
    bool purchase = false,
    bool pending = false,
  }) => JournalEntry(
    id: id,
    kind: EntryKind.product,
    source: purchase ? supplier : shop,
    destination: purchase ? shop : farmer,
    date: date.add(Duration(days: day)),
    ratePaise: amount,
    ratePending: pending,
  );
  JournalEntry payment(
    String id,
    int amount, {
    int day = 0,
    bool giving = false,
  }) => JournalEntry(
    id: id,
    kind: EntryKind.cash,
    source: giving ? shop : farmer,
    destination: giving ? supplier : shop,
    date: date.add(Duration(days: day)),
    amountPaise: amount,
  );
  ShopSnapshot snapshot(List<JournalEntry> entries) => ShopSnapshot(
    entries
        .map(
          (e) => RecordEnvelope(
            id: e.id,
            entity: 'entries',
            shopId: 'shop',
            payload: e.toJson(),
            updatedAt: 1,
            deviceId: 'd',
          ),
        )
        .toList(),
  );

  test(
    'received payments settle the oldest bill and show the remaining part of the next',
    () {
      final data = snapshot([
        bill('first', 10000),
        bill('second', 20000, day: 1),
        payment('receipt', 15000, day: 2),
      ]);
      final summary = PaymentSummary(data, 'f', receiving: true);
      expect(summary.duePaise, 15000);
      expect(summary.bills.single.entry.id, 'second');
      expect(summary.bills.single.remainingPaise, 15000);
    },
  );
  test(
    'cash advances before a bill reduce that bill without losing its identity',
    () {
      final summary = PaymentSummary(
        snapshot([payment('advance', 5000), bill('bill', 15000, day: 1)]),
        'f',
        receiving: true,
      );
      expect(summary.balance, 10000);
      expect(summary.bills.single.entry.id, 'bill');
      expect(summary.bills.single.remainingPaise, 10000);
    },
  );
  test(
    'supplier payments reduce payables and receiving direction has no false due',
    () {
      final data = snapshot([
        bill('purchase', 20000, purchase: true),
        payment('paid', 5000, giving: true, day: 1),
      ]);
      final payable = PaymentSummary(data, 's', receiving: false);
      expect(payable.duePaise, 15000);
      expect(payable.bills.single.remainingPaise, 15000);
      expect(PaymentSummary(data, 's', receiving: true).duePaise, 0);
      expect(PaymentSummary(data, 's', receiving: true).bills, isEmpty);
    },
  );
  test(
    'unpriced bills are visible separately and voids do not appear as pending bills',
    () {
      final summary = PaymentSummary(
        snapshot([
          bill('voided', 10000).voidEntry(),
          bill('pending', 0, pending: true),
        ]),
        'f',
        receiving: true,
      );
      expect(summary.duePaise, 0);
      expect(summary.bills, isEmpty);
      expect(summary.unpricedEntries.single.id, 'pending');
    },
  );
}
