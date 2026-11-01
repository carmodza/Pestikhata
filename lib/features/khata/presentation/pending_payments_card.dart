import 'package:flutter/material.dart';

import '../../../core/data/shop_repository.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../application/payment_summary.dart';

class PendingPaymentsCard extends StatelessWidget {
  const PendingPaymentsCard({
    super.key,
    required this.summary,
    required this.data,
  });
  final PaymentSummary summary;
  final ShopSnapshot data;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(summary.receiving ? 'pendingToReceive' : 'pendingToPay'),
          style: context.fonts.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${context.tr('outstanding')}: ${context.money(summary.duePaise)}',
          style: context.fonts.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('paymentAllocationHelp'),
          style: context.fonts.bodySmall,
        ),
        if (summary.bills.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(context.tr('noPendingPayments')),
          ),
        ...summary.bills.map(
          (bill) => EntryTile(
            entry: bill.entry,
            data: data,
            remainingPaise: bill.remainingPaise,
            personId: summary.personId,
          ),
        ),
        if (summary.unpricedEntries.isNotEmpty) ...[
          const Divider(),
          Text(
            context.tr('pendingPaymentRatesHelp'),
            style: context.fonts.bodySmall,
          ),
          ...summary.unpricedEntries.map(
            (entry) =>
                EntryTile(entry: entry, data: data, personId: summary.personId),
          ),
        ],
      ],
    ),
  );
}
