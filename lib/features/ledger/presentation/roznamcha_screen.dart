import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../catalog/presentation/editors.dart';
import '../../export/data/export_service.dart';
import '../../reports/application/report_service.dart';

class RoznamchaScreen extends ConsumerStatefulWidget {
  const RoznamchaScreen({super.key});
  @override
  ConsumerState<RoznamchaScreen> createState() => _RoznamchaScreenState();
}

class _RoznamchaScreenState extends ConsumerState<RoznamchaScreen> {
  DateTime date = DateTime.now();
  EntryKind? kind;
  String? personId, itemId;
  ExportTable table(ShopSnapshot data, DailyLedger daily) => ExportTable(
    title: context.tr('roznamcha'),
    subtitle:
        '${ref.read(activeSessionProvider)!.shopName} · ${context.day(date)}',
    headers: [
      'date',
      'type',
      'title',
      'source',
      'destination',
      'total',
      'cashReceived',
      'cashPaid',
      'udhar',
    ].map(context.tr).toList(),
    rows: daily.entries
        .map(
          (e) => [
            context.day(e.date),
            context.tr(e.kind.name),
            e.title,
            endpointLabel(context, data, e.source),
            endpointLabel(context, data, e.destination),
            e.ratePending
                ? context.tr('ratePending')
                : context.money(e.totalPaise),
            context.money(e.cashInPaise),
            context.money(e.cashOutPaise),
            context.money(e.creditPaise),
          ],
        )
        .toList(),
    footer:
        '${context.tr('openingBalance')}: ${context.money(daily.opening)} · ${context.tr('closingBalance')}: ${context.money(daily.closing)}',
  );
  @override
  Widget build(BuildContext context) => ShopData(
    builder: (data) {
      final daily = DailyLedger(
        data,
        date,
        kind: kind,
        personId: personId,
        itemId: itemId,
      );
      return PageBody(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(context.day(date)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale('en'),
                      cancelText: context.tr('cancel'),
                      confirmText: context.tr('done'),
                      helpText: context.tr('date'),
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: context.tr('clearFilters'),
                icon: const Icon(Icons.filter_alt_off_outlined),
                onPressed: () => setState(() {
                  kind = null;
                  personId = null;
                  itemId = null;
                }),
              ),
            ],
          ),
          MetricGrid(
            children: [
              MetricCard(
                label: context.tr('openingBalance'),
                value: context.money(daily.opening),
                icon: Icons.login,
              ),
              MetricCard(
                label: context.tr('closingBalance'),
                value: context.money(daily.closing),
                icon: Icons.logout,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(context.tr('all')),
                selected: kind == null,
                onSelected: (_) => setState(() => kind = null),
              ),
              ...EntryKind.values.map(
                (k) => ChoiceChip(
                  label: Text(context.tr(k.name)),
                  selected: kind == k,
                  onSelected: (_) => setState(() => kind = k),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.person_search_outlined),
                label: Text(
                  personId == null
                      ? context.tr('filterPerson')
                      : data.personName(personId),
                ),
                onPressed: () async {
                  final p = await searchPick(
                    context,
                    title: context.tr('filterPerson'),
                    items: data.people,
                    label: (p) => p.name,
                  );
                  if (p != null) setState(() => personId = p.id);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  itemId == null
                      ? context.tr('filterItem')
                      : data.productName(itemId),
                ),
                onPressed: () async {
                  final p = await searchPick(
                    context,
                    title: context.tr('filterItem'),
                    items: data.products,
                    label: (p) => p.name,
                  );
                  if (p != null) setState(() => itemId = p.id);
                },
              ),
            ],
          ),
          if (ref.watch(activeSessionProvider)!.role == AppRole.owner)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ActionButton(
                  label: context.tr('exportPdf'),
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () => ExportService.sharePdf(
                    table(data, daily),
                    'roznamcha.pdf',
                  ),
                ),
                ActionButton(
                  label: context.tr('exportExcel'),
                  icon: Icons.table_chart_outlined,
                  onPressed: () =>
                      ExportService.excel(table(data, daily), 'roznamcha.xlsx'),
                ),
              ],
            ),
          Text(context.tr('dailyBalanceHelp'), style: context.fonts.bodySmall),
          if (daily.entries.isEmpty)
            EmptyState(message: context.tr('noEntries'))
          else
            GlassCard(
              child: Column(
                children: daily.entries.reversed
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
