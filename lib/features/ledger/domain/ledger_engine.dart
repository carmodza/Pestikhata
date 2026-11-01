import '../../../core/domain/models.dart';
import '../../../core/domain/money_math.dart';

class StockLot {
  const StockLot(
    this.itemId,
    this.location,
    this.batch,
    this.expiry,
    this.quantity,
  );
  final String itemId, location, batch;
  final DateTime? expiry;
  final double quantity;
}

class PersonMovement {
  const PersonMovement(this.entry, this.delta, this.balance);
  final JournalEntry entry;
  final int delta, balance;
}

/// Pure projections of the journal. No mutable balance counters exist to drift
/// during retries, imports, edits or rate resolution.
class LedgerEngine {
  LedgerEngine(Iterable<JournalEntry> entries)
    : entries = entries.where((e) => !e.voided).toList()
        ..sort((a, b) {
          final c = a.date.compareTo(b.date);
          if (c != 0) return c;
          final created = a.createdAt.compareTo(b.createdAt);
          return created == 0 ? a.id.compareTo(b.id) : created;
        });
  final List<JournalEntry> entries;
  late final Map<String, int> _balances = _buildBalances();
  Map<String, int> _buildBalances() {
    final result = <String, int>{};
    for (final entry in entries) {
      for (final endpoint in [entry.source, entry.destination]) {
        if (endpoint.person) {
          result[endpoint.id!] =
              (result[endpoint.id!] ?? 0) + personDelta(entry, endpoint.id!);
        }
      }
    }
    return result;
  }

  late final List<StockLot> _lots = _buildStockLots();

  int cashBalance({DateTime? before}) => entries
      .where((e) => before == null || e.date.isBefore(before))
      .fold(0, (sum, e) => sum + e.cashDelta);

  int personDelta(JournalEntry e, String personId) {
    if (e.voided) return 0;
    if (e.kind == EntryKind.cash) {
      if (e.source.person && e.source.id == personId) return -e.amountPaise;
      if (e.destination.person && e.destination.id == personId) {
        return e.amountPaise;
      }
      return 0;
    }
    if (e.kind == EntryKind.diesel &&
        !e.isDirect &&
        e.destination.person &&
        e.destination.id == personId) {
      return -e.creditPaise;
    }
    if (e.source.person && e.source.id == personId) {
      return -(e.hasCropPurchase ? e.purchaseCreditPaise : e.creditPaise);
    }
    if (e.destination.person && e.destination.id == personId) {
      return e.creditPaise;
    }
    return 0;
  }

  int personBalance(String personId) => _balances[personId] ?? 0;
  List<PersonMovement> statement(String personId) {
    var balance = 0;
    return personEntries(personId).map((entry) {
      final delta = personDelta(entry, personId);
      balance += delta;
      return PersonMovement(entry, delta, balance);
    }).toList();
  }

  int stockValue(Product product) {
    final quantity = stock(product.id);
    return quantity < 0
        ? -multiplyMoney(-quantity, product.purchasePaise)
        : multiplyMoney(quantity, product.purchasePaise);
  }

  List<JournalEntry> personEntries(String id) => entries
      .where(
        (e) =>
            (e.source.person && e.source.id == id) ||
            (e.destination.person && e.destination.id == id),
      )
      .toList();

  List<StockLot> stockLots() => _lots;
  List<StockLot> _buildStockLots() {
    final lots = <String, StockLot>{};
    for (final e in entries.where((e) => e.hasStock)) {
      for (final endpoint in [e.source, e.destination]) {
        if (!endpoint.internal) continue;
        final location = endpoint.stockKey;
        for (final movement in e.stockMovements) {
          final key =
              '${e.itemId}|$location|${movement.batch}|${movement.expiry?.toIso8601String() ?? ''}';
          final delta =
              (identical(endpoint, e.source) ? -1 : 1) * movement.quantity;
          lots[key] = StockLot(
            e.itemId!,
            location,
            movement.batch,
            movement.expiry,
            (lots[key]?.quantity ?? 0) + delta,
          );
        }
      }
    }
    return lots.values.where((l) => l.quantity.abs() > 0.000001).toList();
  }

  double stock(String itemId, {String? location}) => stockLots()
      .where(
        (l) =>
            l.itemId == itemId && (location == null || l.location == location),
      )
      .fold(0, (s, l) => s + l.quantity);

  List<JournalEntry> day(DateTime date) => entries
      .where(
        (e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      )
      .toList();
  List<JournalEntry> get pendingRates =>
      entries.where((e) => e.hasPendingRate).toList();
  int profit(Iterable<JournalEntry> range) => range
      .where((e) => e.isSale && !e.hasPendingRate)
      .fold(
        0,
        (s, e) =>
            s +
            (e.isDirect && !e.cropPricing
                ? 0
                : e.totalPaise - multiplyMoney(e.quantity, e.purchasePaise)),
      );
  int expenses(Iterable<JournalEntry> range) => range
      .where(
        (e) =>
            !e.isDirect &&
            (e.kind == EntryKind.other || e.kind == EntryKind.diesel),
      )
      .fold(0, (s, e) => s + e.totalPaise);

  void validate(
    JournalEntry entry, {
    List<Product> products = const [],
    List<Person> people = const [],
    List<Godam> godams = const [],
    bool checkStock = true,
  }) {
    if (entry.title.length > 300 ||
        entry.note.length > 4000 ||
        entry.batch.length > 200) {
      throw const DomainFailure('textTooLong');
    }
    if (entry.date.year < 2000 || entry.date.year > 2100) {
      throw const DomainFailure('invalidDate');
    }
    if (entry.source.sameAs(entry.destination)) {
      throw const DomainFailure('sameEndpoints');
    }
    if (!entry.source.internal &&
        !entry.destination.internal &&
        !entry.isDirect) {
      throw const DomainFailure('personOrShopRequired');
    }
    if (entry.isTransfer && !entry.hasStock) {
      throw const DomainFailure('invalidTransfer');
    }
    if (!entry.hasStock && entry.allocations.isNotEmpty) {
      throw const DomainFailure('invalidAllocation');
    }
    for (final endpoint in [entry.source, entry.destination]) {
      if ((endpoint.kind == PartyKind.inventory ||
              endpoint.kind == PartyKind.walkIn) &&
          endpoint.id != null) {
        throw const DomainFailure('invalidTransfer');
      }
      if (endpoint.person &&
          !people.any((p) => p.id == endpoint.id && p.kind == endpoint.kind)) {
        throw const DomainFailure('selectPerson');
      }
      if (endpoint.kind == PartyKind.godam &&
          !godams.any((g) => g.id == endpoint.id)) {
        throw const DomainFailure('selectGodam');
      }
    }
    if (!entry.quantity.isFinite ||
        entry.quantity <= 0 ||
        entry.quantity > 1000000000 ||
        !entry.unitFactor.isFinite ||
        entry.unitFactor <= 0 ||
        entry.unitFactor > 1000000000) {
      throw const DomainFailure('invalidQuantity');
    }
    if ([
      entry.ratePaise,
      entry.purchasePaise,
      entry.salePaise,
      entry.cashPaise,
      entry.amountPaise,
    ].any((v) => v < 0 || v > 9000000000000)) {
      throw const DomainFailure('invalidAmount');
    }
    if (entry.totalPaise > 9000000000000) {
      throw const DomainFailure('invalidAmount');
    }
    if (entry.ratePending && !entry.isRateBearing) {
      throw const DomainFailure('invalidRatePending');
    }
    if ((entry.cropPricing && entry.kind != EntryKind.crop) ||
        (entry.purchaseRatePending &&
            (!entry.cropPricing || !entry.isDirect)) ||
        (entry.cropPricing &&
            !entry.isTransfer &&
            entry.ratePaise !=
                (entry.ratePending
                    ? 0
                    : entry.hasCropSale
                    ? entry.salePaise
                    : entry.purchasePaise)) ||
        (entry.cropPricing && !entry.hasCropSale && entry.salePaise != 0)) {
      throw const DomainFailure('invalidAmount');
    }
    if (entry.hasCropPurchase && !entry.cropPurchasePending) {
      if (entry.purchaseTotalPaise <= 0 ||
          entry.purchaseTotalPaise > 9000000000000) {
        throw const DomainFailure('invalidAmount');
      }
      if (entry.cashPaise > entry.purchaseTotalPaise) {
        throw const DomainFailure('cashExceedsTotal');
      }
    }
    if (entry.kind == EntryKind.cash && entry.cashPaise != 0) {
      throw const DomainFailure('invalidAmount');
    }
    if ((entry.kind == EntryKind.cash || entry.kind == EntryKind.other) &&
        entry.amountPaise <= 0) {
      throw const DomainFailure('invalidAmount');
    }
    if (entry.kind == EntryKind.other &&
        ((!entry.source.internal && !entry.isDirect) ||
            entry.title.trim().isEmpty ||
            entry.cashPaise != entry.amountPaise)) {
      throw const DomainFailure('invalidExpense');
    }
    if (entry.kind == EntryKind.diesel &&
        !entry.source.internal &&
        !entry.isDirect) {
      throw const DomainFailure('invalidExpense');
    }
    if (!entry.ratePending &&
        !entry.isTransfer &&
        entry.kind != EntryKind.cash &&
        entry.totalPaise <= 0) {
      throw const DomainFailure('invalidAmount');
    }
    if (!entry.ratePending && entry.cashPaise > entry.totalPaise) {
      throw const DomainFailure('cashExceedsTotal');
    }
    if (entry.isTransfer && (entry.cashPaise != 0 || entry.ratePending)) {
      throw const DomainFailure('invalidTransfer');
    }
    final external = entry.source.internal ? entry.destination : entry.source;
    if (!entry.isTransfer &&
        !external.person &&
        entry.kind != EntryKind.cash &&
        (entry.ratePending || entry.creditPaise != 0)) {
      throw const DomainFailure('creditRequiresPerson');
    }
    if (entry.hasStock) {
      final matching = products.where((p) => p.id == entry.itemId);
      if (matching.isEmpty || matching.first.kind != entry.kind) {
        throw const DomainFailure('selectProduct');
      }
      final factor = matching.first.units[entry.unit];
      if (factor == null || (factor - entry.unitFactor).abs() > 0.000001) {
        throw const DomainFailure('invalidUnit');
      }
      if (entry.kind == EntryKind.product &&
          entry.isStockReceipt &&
          entry.batch.trim().isEmpty) {
        throw const DomainFailure('batchRequired');
      }
      if (entry.expiry != null &&
          (entry.expiry!.year < 2000 || entry.expiry!.year > 2100)) {
        throw const DomainFailure('invalidDate');
      }
      if (entry.allocations.isNotEmpty &&
          (!entry.source.internal || entry.allocations.length > 1000)) {
        throw const DomainFailure('invalidAllocation');
      }
      final keys = <String>{};
      var allocated = 0.0;
      for (final movement in entry.stockMovements) {
        if (!movement.quantity.isFinite ||
            movement.quantity <= 0 ||
            movement.batch.length > 200 ||
            (entry.kind == EntryKind.product &&
                entry.source.internal &&
                movement.batch.isEmpty) ||
            (movement.expiry != null &&
                (movement.expiry!.year < 2000 ||
                    movement.expiry!.year > 2100)) ||
            !keys.add('${movement.batch}|${movement.expiry}')) {
          throw const DomainFailure('invalidAllocation');
        }
        allocated += movement.quantity;
        if (checkStock && entry.source.internal) {
          final available = stockLots()
              .where(
                (l) =>
                    l.itemId == entry.itemId &&
                    l.location == entry.source.stockKey &&
                    l.batch == movement.batch &&
                    l.expiry == movement.expiry,
              )
              .fold<double>(0, (s, l) => s + l.quantity);
          if (available + 0.000001 < movement.quantity) {
            throw const DomainFailure('insufficientStock');
          }
        }
      }
      if ((allocated - entry.baseQuantity).abs() > .000001) {
        throw const DomainFailure('invalidAllocation');
      }
    }
  }

  /// Select existing lots by earliest expiry, keeping unknown expiries last.
  /// The persisted allocation makes replay, transfers and voids deterministic.
  JournalEntry allocateStock(JournalEntry entry) {
    if (!entry.hasStock ||
        !entry.source.internal ||
        entry.allocations.isNotEmpty ||
        entry.batch.isNotEmpty ||
        entry.expiry != null) {
      return entry;
    }
    if (!entry.baseQuantity.isFinite || entry.baseQuantity <= 0) {
      throw const DomainFailure('invalidQuantity');
    }
    final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final available =
        stockLots()
            .where(
              (l) =>
                  l.itemId == entry.itemId &&
                  l.location == entry.source.stockKey &&
                  (!entry.isSale ||
                      l.expiry == null ||
                      !l.expiry!.isBefore(day)) &&
                  l.quantity > .000001,
            )
            .toList()
          ..sort((a, b) {
            final expiry = (a.expiry ?? DateTime(9999)).compareTo(
              b.expiry ?? DateTime(9999),
            );
            return expiry == 0 ? a.batch.compareTo(b.batch) : expiry;
          });
    var remaining = entry.baseQuantity;
    final allocations = <StockAllocation>[];
    for (final lot in available) {
      if (remaining <= .000001) break;
      final quantity = remaining < lot.quantity ? remaining : lot.quantity;
      allocations.add(
        StockAllocation(
          batch: lot.batch,
          expiry: lot.expiry,
          quantity: quantity,
        ),
      );
      remaining -= quantity;
    }
    if (remaining > .000001) throw const DomainFailure('insufficientStock');
    return JournalEntry.fromJson(
      entry.toJson()
        ..['allocations'] = allocations.map((a) => a.toJson()).toList(),
    );
  }
}

/// Store PKR as integer paisa; parse the decimal representation without doubles.
int parseMoney(String input) {
  final cleaned = input.trim().replaceAll(',', '');
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) {
    throw const DomainFailure('invalidAmount');
  }
  final parts = cleaned.split('.');
  final amount =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  if (amount > 9000000000000) throw const DomainFailure('invalidAmount');
  return amount;
}

String moneyInput(int paise) => (paise / 100).toStringAsFixed(2);
