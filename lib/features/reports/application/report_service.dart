import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../ledger/domain/ledger_engine.dart';

class DailyLedger {
  DailyLedger(
    ShopSnapshot data,
    DateTime day, {
    EntryKind? kind,
    String? personId,
    String? itemId,
  }) {
    final ledger = data.ledger;
    final start = DateTime(day.year, day.month, day.day);
    opening = ledger.cashBalance(before: start);
    all = ledger.day(day);
    closing = opening + all.fold(0, (s, e) => s + e.cashDelta);
    entries = all
        .where(
          (e) =>
              (kind == null || e.kind == kind) &&
              (personId == null ||
                  e.source.id == personId ||
                  e.destination.id == personId) &&
              (itemId == null || e.itemId == itemId),
        )
        .toList();
  }
  late final int opening, closing;
  late final List<JournalEntry> all, entries;
}

class DashboardSummary {
  DashboardSummary(ShopSnapshot data, DateTime now) {
    final ledger = data.ledger;
    final today = ledger.day(now);
    cashIn = today.fold(0, (s, e) => s + e.cashInPaise);
    cashOut = today.fold(0, (s, e) => s + e.cashOutPaise);
    sales = today.where((e) => e.isSale).fold(0, (s, e) => s + e.totalPaise);
    given = today
        .where((e) => e.isSale && e.creditPaise > 0)
        .fold(0, (s, e) => s + e.creditPaise);
    received = today
        .where(
          (e) =>
              e.kind == EntryKind.cash &&
              e.source.person &&
              (e.destination.internal || e.isDirect),
        )
        .fold(0, (s, e) => s + e.amountPaise);
    low = data.products.where((p) => ledger.stock(p.id) <= p.lowStock).toList();
    expiring = ledger
        .stockLots()
        .where(
          (l) =>
              l.quantity > 0 &&
              l.expiry != null &&
              l.expiry!.isBefore(now.add(const Duration(days: 90))),
        )
        .toList();
    negative = ledger.stockLots().where((l) => l.quantity < -.000001).toList();
  }
  late final int cashIn, cashOut, sales, given, received;
  late final List<Product> low;
  late final List<StockLot> expiring, negative;
}

class ReportSummary {
  ReportSummary(ShopSnapshot data, DateTime from, DateTime until) {
    final ledger = data.ledger;
    entries = ledger.entries
        .where((e) => !e.date.isBefore(from) && e.date.isBefore(until))
        .toList();
    sales = entries.where((e) => e.isSale).fold(0, (s, e) => s + e.totalPaise);
    grossProfit = ledger.profit(entries);
    expenses = ledger.expenses(entries);
    netProfit = grossProfit - expenses;
    cropProfit = ledger.profit(entries.where((e) => e.kind == EntryKind.crop));
    pending = entries.where((e) => e.hasPendingRate).length;
    receivable = 0;
    payable = 0;
    for (final person in data.people) {
      final balance = ledger.personBalance(person.id);
      if (balance > 0) {
        receivable += balance;
      } else {
        payable -= balance;
      }
    }
    for (final e in entries.where(
      (e) =>
          !e.isDirect &&
          (e.kind == EntryKind.other || e.kind == EntryKind.diesel),
    )) {
      final key = e.kind == EntryKind.diesel ? 'diesel' : e.expenseCategory;
      expenseCategories[key] = (expenseCategories[key] ?? 0) + e.totalPaise;
    }
    for (final product in data.products) {
      stockValue += ledger.stockValue(product);
    }
  }
  late final List<JournalEntry> entries;
  late final int sales, grossProfit, expenses, netProfit, cropProfit, pending;
  int receivable = 0, payable = 0, stockValue = 0;
  final expenseCategories = <String, int>{};
}
