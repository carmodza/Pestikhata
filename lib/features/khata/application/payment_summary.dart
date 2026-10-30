import 'dart:collection';

import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';

class PendingBill {
  const PendingBill(this.entry, this.remainingPaise);
  final JournalEntry entry;
  final int remainingPaise;
}

class _OpenMovement {
  _OpenMovement(this.entry, this.remaining);
  final JournalEntry entry;
  int remaining;
}

/// Opposite khata movements settle the oldest open amount first, including
/// advances paid before a bill. This projection never edits historical bills.
class PaymentSummary {
  PaymentSummary(
    ShopSnapshot data,
    String personId, {
    required this.receiving,
  }) {
    balance = data.ledger.personBalance(personId);
    duePaise = receiving
        ? (balance > 0 ? balance : 0)
        : (balance < 0 ? -balance : 0);
    final open = Queue<_OpenMovement>();
    for (final movement in data.ledger.statement(personId)) {
      var remaining = movement.delta;
      while (remaining != 0 &&
          open.isNotEmpty &&
          remaining.isNegative != open.first.remaining.isNegative) {
        final first = open.first;
        final settled = remaining.abs() < first.remaining.abs()
            ? remaining.abs()
            : first.remaining.abs();
        first.remaining += first.remaining.isNegative ? settled : -settled;
        remaining += remaining.isNegative ? settled : -settled;
        if (first.remaining == 0) open.removeFirst();
      }
      if (remaining != 0) open.add(_OpenMovement(movement.entry, remaining));
    }
    bills = open
        .where(
          (m) =>
              !m.entry.ratePending &&
              (receiving ? m.remaining > 0 : m.remaining < 0),
        )
        .map((m) => PendingBill(m.entry, m.remaining.abs()))
        .toList();
    unpricedEntries = data.ledger
        .personEntries(personId)
        .where((e) => e.ratePending)
        .toList();
  }

  final bool receiving;
  late final int balance, duePaise;
  late final List<PendingBill> bills;
  late final List<JournalEntry> unpricedEntries;
}
