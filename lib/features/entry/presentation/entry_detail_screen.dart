import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../ledger/domain/ledger_engine.dart';

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
                        e.title.isEmpty ? context.tr(e.kind.name) : e.title,
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
                  if (e.kind != EntryKind.cash && e.kind != EntryKind.other)
                    ('quantity', '${e.quantity} ${context.tr(e.unit)}'),
                  if (e.batch.isNotEmpty) ('batch', e.batch),
                  if (e.expiry != null) ('expiryDate', context.day(e.expiry!)),
                  (
                    'rate',
                    e.ratePending
                        ? context.tr('ratePending')
                        : context.money(e.ratePaise),
                  ),
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
                  ('udhar', context.money(e.creditPaise)),
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
          if (e.isDirect) Text(context.tr('directEntryHelp')),
          if (e.hasStock &&
              !e.isTransfer &&
              !e.voided &&
              (e.ratePending ||
                  ref.watch(activeSessionProvider)!.role == AppRole.owner))
            ActionButton(
              label: context.tr(e.ratePending ? 'setRate' : 'editRate'),
              onPressed: () async {
                final rate = await askText(
                  context,
                  title: context.tr(e.ratePending ? 'setRate' : 'editRate'),
                  initial: e.ratePending ? '' : moneyInput(e.ratePaise),
                  numeric: true,
                );
                if (rate != null) {
                  await ref
                      .read(repositoryProvider)
                      .resolveRate(id, parseMoney(rate));
                }
              },
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
