import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import 'entry_rate_editor.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShopData(
    builder: (data) {
      final e = data.entries.where((e) => e.id == id).firstOrNull;
      if (e == null) return EmptyState(message: context.tr('noResults'));
      return PageBody(
        maxWidth: 720,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    EntryDirectionIcon(entry: e),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entryTitle(context, data, e),
                        style: context.fonts.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final pair in [
                  ('date', context.day(e.date)),
                  ('source', endpointLabel(context, data, e.source)),
                  ('destination', endpointLabel(context, data, e.destination)),
                  if (e.hasStock)
                    (
                      'productName',
                      data.productName(e.itemId).isEmpty
                          ? e.title
                          : data.productName(e.itemId),
                    ),
                  if (e.isRateBearing)
                    ('quantity', '${e.quantity} ${context.tr(e.unit)}'),
                  if (e.batch.isNotEmpty) ('batch', e.batch),
                  if (e.expiry != null) ('expiryDate', context.day(e.expiry!)),
                  if (e.isRateBearing && !e.cropPricing)
                    (
                      'rate',
                      e.ratePending
                          ? context.tr('ratePending')
                          : context.money(e.ratePaise),
                    ),
                  if (e.hasStock && !e.isTransfer && !e.cropPricing)
                    ('purchasePrice', context.money(e.purchasePaise)),
                  if (e.hasStock && !e.isTransfer && !e.cropPricing)
                    ('salePrice', context.money(e.salePaise)),
                  if (e.hasCropPurchase) ...[
                    (
                      'purchasePrice',
                      e.cropPurchasePending
                          ? context.tr('ratePending')
                          : context.money(e.purchasePaise),
                    ),
                    (
                      'purchaseTotal',
                      e.cropPurchasePending
                          ? context.tr('ratePending')
                          : context.money(e.purchaseTotalPaise),
                    ),
                    ('sellerKhata', context.money(e.purchaseCreditPaise)),
                  ],
                  if (e.hasCropSale) ...[
                    (
                      'salePrice',
                      e.ratePending
                          ? context.tr('ratePending')
                          : context.money(e.salePaise),
                    ),
                    (
                      'saleTotal',
                      e.ratePending
                          ? context.tr('ratePending')
                          : context.money(e.totalPaise),
                    ),
                    ('buyerKhata', context.money(e.creditPaise)),
                  ],
                  if (!e.cropPricing)
                    (
                      'total',
                      e.ratePending
                          ? context.tr('ratePending')
                          : context.money(e.totalPaise),
                    ),
                  (
                    'cashAmount',
                    context.money(
                      e.kind == EntryKind.cash ? e.amountPaise : e.cashPaise,
                    ),
                  ),
                  if (!e.cropPricing) ('udhar', context.money(e.creditPaise)),
                  if (e.isDirect)
                    ('cashReceived', context.money(e.cashInPaise)),
                  if (e.isDirect) ('cashPaid', context.money(e.cashOutPaise)),
                  ('note', e.note),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(context.tr(pair.$1))),
                        Expanded(
                          child: Text(pair.$2, textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
                if (e.voided)
                  Text(
                    context.tr('voided'),
                    style: TextStyle(color: context.colors.error),
                  ),
              ],
            ),
          ),
          if (e.isDirect)
            Text(
              context.tr(e.cropPricing ? 'cropCashHelp' : 'directEntryHelp'),
            ),
          if (e.isRateBearing &&
              !e.isTransfer &&
              !e.voided &&
              (e.hasPendingRate ||
                  ref.watch(activeSessionProvider)!.role == AppRole.owner))
            ActionButton(
              label: context.tr(e.hasPendingRate ? 'setRate' : 'editRate'),
              onPressed: () => editEntryRates(
                context,
                ref.read(repositoryProvider),
                e,
                owner: ref.read(activeSessionProvider)!.role == AppRole.owner,
              ),
            ),
          if (ref.watch(activeSessionProvider)!.role == AppRole.owner &&
              !e.voided)
            ActionButton(
              label: context.tr('voidEntry'),
              icon: Icons.delete_outline,
              onPressed: () async {
                if (await confirmAction(context, context.tr('voidEntryHelp'))) {
                  await ref.read(repositoryProvider).voidEntry(id);
                  if (context.mounted) {
                    context.toast(context.tr('entryVoided'));
                    context.go('/roznamcha');
                  }
                }
              },
            ),
          Text(
            context.tr('immutableEntryHelp'),
            style: context.fonts.bodySmall,
          ),
        ],
      );
    },
  );
}
