import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets.dart';
import '../../../core/providers.dart';
import '../../../l10n/strings.dart';
import '../../export/data/export_service.dart';
import '../application/report_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.expensesOnly = false});
  final bool expensesOnly;
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTimeRange range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month),
    end: DateTime.now(),
  );
  String report = 'profit';
  @override
  Widget build(BuildContext context) => ShopData(
    builder: (data) {
      final summary = ReportSummary(
        data,
        range.start,
        DateTime(range.end.year, range.end.month, range.end.day + 1),
      );
      final metrics = [
        ('sales', summary.sales, Icons.shopping_bag_outlined),
        ('grossProfit', summary.grossProfit, Icons.trending_up),
        ('expenses', summary.expenses, Icons.receipt_long_outlined),
        ('netProfit', summary.netProfit, Icons.account_balance_outlined),
        ('cropProfit', summary.cropProfit, Icons.grass),
        ('receivable', summary.receivable, Icons.south_west),
        ('payable', summary.payable, Icons.north_east),
        ('stockValue', summary.stockValue, Icons.inventory_2_outlined),
      ];
      final expenseRows = summary.expenseCategories.entries
          .map((e) => [context.tr(e.key), context.money(e.value)])
          .toList();
      final stockRows = data.products
          .map(
            (p) => [
              p.name,
              '${data.ledger.stock(p.id).toStringAsFixed(2)} ${context.tr(p.baseUnit)}',
              context.money(data.ledger.stockValue(p)),
            ],
          )
          .toList();
      final udharRows = data.people
          .map(
            (p) => [
              p.name,
              context.tr(p.kind.name),
              context.money(data.ledger.personBalance(p.id)),
            ],
          )
          .toList();
      final headers = report == 'stock'
          ? ['productName', 'quantity', 'stockValue']
          : report == 'udhar'
          ? ['name', 'type', 'balance']
          : ['type', 'amount'];
      final rows = widget.expensesOnly || report == 'expenses'
          ? expenseRows
          : report == 'stock'
          ? stockRows
          : report == 'udhar'
          ? udharRows
          : metrics
                .where(
                  (m) => report == 'cropProfit' ? m.$1 == 'cropProfit' : true,
                )
                .map((m) => [context.tr(m.$1), context.money(m.$2)])
                .toList();
      final table = ExportTable(
        title: context.tr(widget.expensesOnly ? 'expenses' : 'reports'),
        subtitle:
            '${ref.watch(activeSessionProvider)!.shopName} · ${context.day(range.start)} - ${context.day(range.end)}',
        headers: headers.map(context.tr).toList(),
        rows: rows,
        footer: context.tr('reportBasisHelp'),
      );
      return PageBody(
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              '${context.day(range.start)} — ${context.day(range.end)}',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                locale: const Locale('en'),
                cancelText: context.tr('cancel'),
                confirmText: context.tr('done'),
                helpText: context.tr('date'),
                saveText: context.tr('save'),
                initialDateRange: range,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => range = picked);
            },
          ),
          if (widget.expensesOnly)
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(context.tr('addExpense')),
              onPressed: () => context.push('/entry/other'),
            ),
          if (!widget.expensesOnly)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['profit', 'stock', 'udhar', 'expenses', 'cropProfit']
                  .map(
                    (r) => ChoiceChip(
                      label: Text(context.tr(r)),
                      selected: report == r,
                      onSelected: (_) => setState(() => report = r),
                    ),
                  )
                  .toList(),
            ),
          MetricGrid(
            children:
                (widget.expensesOnly
                        ? metrics.where((m) => m.$1 == 'expenses')
                        : metrics)
                    .map(
                      (m) => MetricCard(
                        label: context.tr(m.$1),
                        value: context.money(m.$2),
                        icon: m.$3,
                      ),
                    )
                    .toList(),
          ),
          if (summary.pending > 0)
            GlassCard(
              tint: context.colors.tertiaryContainer,
              child: Text(
                '${summary.pending} ${context.tr('pendingRatesExcluded')}',
              ),
            ),
          GlassCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: table.headers
                    .map((h) => DataColumn(label: Text(h)))
                    .toList(),
                rows: table.rows
                    .map(
                      (r) => DataRow(
                        cells: r.map((s) => DataCell(Text(s))).toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (!widget.expensesOnly ||
              ref.watch(activeSessionProvider)!.role.name == 'owner')
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionButton(
                  label: context.tr('exportPdf'),
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      ExportService.sharePdf(table, 'pestikhata-report.pdf'),
                ),
                ActionButton(
                  label: context.tr('exportExcel'),
                  icon: Icons.table_chart_outlined,
                  onPressed: () =>
                      ExportService.excel(table, 'pestikhata-report.xlsx'),
                ),
              ],
            ),
          Text(context.tr('reportBasisHelp'), style: context.fonts.bodySmall),
          if (widget.expensesOnly) ...[
            SectionTitle(context.tr('expenses')),
            ...summary.entries
                .where((e) => e.kind.name == 'other' || e.kind.name == 'diesel')
                .toList()
                .reversed
                .map(
                  (e) => EntryTile(
                    entry: e,
                    data: data,
                    onTap: () => context.push('/entry-detail/${e.id}'),
                  ),
                ),
          ],
        ],
      );
    },
  );
}
