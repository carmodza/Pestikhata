import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers.dart';
import '../../../l10n/strings.dart';
import '../../catalog/presentation/editors.dart';
import '../../export/data/export_service.dart';

class KhataScreen extends ConsumerStatefulWidget {
  const KhataScreen({super.key});
  @override
  ConsumerState<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends ConsumerState<KhataScreen> {
  PartyKind kind = PartyKind.farmer;
  String query = '';
  @override
  Widget build(BuildContext context) => ShopData(
    builder: (data) {
      final people = data.people
          .where(
            (p) =>
                p.kind == kind &&
                '${p.name} ${p.phone} ${p.village}'.toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
      return PageBody(
        children: [
          SegmentedButton<PartyKind>(
            segments: [
              ButtonSegment(
                value: PartyKind.farmer,
                label: Text(context.tr('farmerKhata')),
              ),
              ButtonSegment(
                value: PartyKind.supplier,
                label: Text(context.tr('supplierKhata')),
              ),
            ],
            selected: {kind},
            onSelectionChanged: (v) => setState(() => kind = v.first),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: context.tr('search'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (q) => setState(() => query = q),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: Text(context.tr('addNew')),
            onPressed: () => editPerson(context, ref, kind),
          ),
          Text(context.tr('balanceSignHelp'), style: context.fonts.bodySmall),
          if (people.isEmpty)
            EmptyState(message: context.tr('noPeople'))
          else
            GlassCard(
              child: Column(
                children: people.map((p) {
                  final balance = data.ledger.personBalance(p.id);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    leading: CircleAvatar(child: Text(p.name.substring(0, 1))),
                    title: Text(p.name, style: context.fonts.titleMedium),
                    subtitle: Text('${p.village}\n${p.phone}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.money(balance.abs()),
                          style: context.fonts.titleMedium,
                        ),
                        Text(
                          context.tr(
                            balance > 0
                                ? 'receivable'
                                : balance < 0
                                ? 'payable'
                                : 'settled',
                          ),
                          style: context.fonts.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () => context.push('/khata/${p.id}'),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    },
  );
}

class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShopData(
    builder: (data) {
      final person = data.people.where((p) => p.id == id).firstOrNull;
      if (person == null) return EmptyState(message: context.tr('noResults'));
      final ledger = data.ledger,
          balance = ledger.personBalance(id),
          entries = ledger.personEntries(id);
      final statementRows = ledger.statement(id).map((movement) {
        final e = movement.entry;
        return [
          context.day(e.date),
          '${entryTitle(context, data, e)}${e.isRateBearing ? '\n${entryQuantity(context, e)}' : ''}',
          e.ratePending
              ? '${context.tr('ratePending')} (${context.money(movement.delta)})'
              : context.money(movement.delta),
          context.money(movement.balance),
        ];
      }).toList();
      final table = ExportTable(
        title: '${context.tr('statement')} · ${person.name}',
        subtitle:
            '${ref.watch(activeSessionProvider)!.shopName} · ${person.phone} · ${person.village}',
        headers: [
          'date',
          'title',
          'amount',
          'balance',
        ].map(context.tr).toList(),
        rows: statementRows,
        footer: '${context.tr('balance')}: ${context.money(balance)}',
      );
      return PageBody(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        person.name,
                        style: context.fonts.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('edit'),
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editPerson(
                        context,
                        ref,
                        person.kind,
                        existing: person,
                      ),
                    ),
                  ],
                ),
                Text('${person.phone}\n${person.village}'),
                if (person.kind == PartyKind.farmer)
                  Text(
                    '${person.acres} ${context.tr('acres')} · ${person.crops}',
                  ),
                const Divider(height: 28),
                Text(
                  context.money(balance.abs()),
                  style: context.fonts.headlineMedium,
                ),
                Text(
                  context.tr(
                    balance > 0
                        ? 'receivable'
                        : balance < 0
                        ? 'payable'
                        : 'settled',
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.south_west),
                label: Text(context.tr('receivePayment')),
                onPressed: () =>
                    context.push('/entry/cash?person=$id&receive=true'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.north_east),
                label: Text(context.tr('givePayment')),
                onPressed: () =>
                    context.push('/entry/cash?person=$id&receive=false'),
              ),
              ActionButton(
                label: context.tr('shareStatement'),
                icon: Icons.share_outlined,
                onPressed: () =>
                    ExportService.sharePdf(table, 'khata-${person.id}.pdf'),
              ),
            ],
          ),
          Text(context.tr('whatsappShareHelp'), style: context.fonts.bodySmall),
          SectionTitle(context.tr('ledger')),
          if (entries.isEmpty)
            EmptyState(message: context.tr('noEntries'))
          else
            GlassCard(
              child: Column(
                children: entries.reversed
                    .map(
                      (e) => EntryTile(
                        entry: e,
                        data: data,
                        onTap: () => context.push('/entry-detail/${e.id}'),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      );
    },
  );
}
