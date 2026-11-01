import 'package:flutter/material.dart';

import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../ledger/domain/ledger_engine.dart';

/// Uses the same editor from Home and entry details. A direct crop trade may
/// price either side first; committing both prices is one local transaction.
Future<void> editEntryRates(
  BuildContext context,
  ShopRepository repository,
  JournalEntry entry, {
  required bool owner,
}) async {
  try {
    if (entry.cropPricing && entry.isDirect) {
      final prices = await showDialog<({int? rate, int? purchase})>(
        context: context,
        builder: (_) => _CropRateDialog(entry: entry, owner: owner),
      );
      if (prices == null) return;
      await repository.resolveEntryRates(
        entry.id,
        rate: prices.rate,
        purchase: prices.purchase,
      );
    } else {
      final rate = await askText(
        context,
        title: context.tr(
          entry.cropPricing
              ? (entry.hasCropSale ? 'salePrice' : 'purchasePrice')
              : entry.ratePending
              ? 'setRate'
              : 'editRate',
        ),
        initial: entry.ratePending ? '' : moneyInput(entry.ratePaise),
        numeric: true,
      );
      if (rate == null) return;
      await repository.resolveRate(entry.id, parseMoney(rate));
    }
    if (context.mounted) context.toast(context.tr('rateUpdated'));
  } catch (error) {
    if (context.mounted) context.toast(context.failure(error));
  }
}

class _CropRateDialog extends StatefulWidget {
  const _CropRateDialog({required this.entry, required this.owner});
  final JournalEntry entry;
  final bool owner;
  @override
  State<_CropRateDialog> createState() => _CropRateDialogState();
}

class _CropRateDialogState extends State<_CropRateDialog> {
  late final purchase = TextEditingController(
    text: widget.entry.purchaseRatePending
        ? ''
        : moneyInput(widget.entry.purchasePaise),
  );
  late final sale = TextEditingController(
    text: widget.entry.ratePending ? '' : moneyInput(widget.entry.ratePaise),
  );
  String? error;
  @override
  void dispose() {
    purchase.dispose();
    sale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('cropRates')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${context.tr('unit')}: ${context.tr(widget.entry.unit)}'),
          Text(context.tr('keepRatePending')),
          if (widget.owner || widget.entry.purchaseRatePending)
            TextField(
              controller: purchase,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.tr('purchasePrice'),
              ),
            ),
          if (widget.owner || widget.entry.ratePending)
            TextField(
              controller: sale,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: context.tr('salePrice')),
            ),
          if (error != null)
            Text(
              context.tr(error!),
              style: TextStyle(color: context.colors.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('cancel')),
      ),
      FilledButton(
        onPressed: () {
          try {
            final p =
                (widget.owner || widget.entry.purchaseRatePending) &&
                    purchase.text.trim().isNotEmpty
                ? parseMoney(purchase.text)
                : null;
            final s =
                (widget.owner || widget.entry.ratePending) &&
                    sale.text.trim().isNotEmpty
                ? parseMoney(sale.text)
                : null;
            if ((p == null && s == null) || p == 0 || s == 0) {
              throw const DomainFailure('invalidAmount');
            }
            Navigator.pop(context, (rate: s, purchase: p));
          } on DomainFailure catch (failure) {
            setState(() => error = failure.code);
          }
        },
        child: Text(context.tr('save')),
      ),
    ],
  );
}
