import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/app_shell.dart';
import '../../../core/presentation/widgets.dart';
import '../../../core/providers.dart';
import '../../../l10n/strings.dart';
import '../../ledger/domain/ledger_engine.dart';
import '../../reports/application/report_service.dart';
import '../../demo/data/demo_data.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShopData(
    builder: (data) {
      final ledger = data.ledger, now = DateTime.now();
      final summary = DashboardSummary(data, now);
      final cashIn = summary.cashIn,
          cashOut = summary.cashOut,
          sales = summary.sales,
          given = summary.given,
          received = summary.received,
          low = summary.low,
          expiring = summary.expiring,
          negative = summary.negative;
      return PageBody(
        children: [
          GlassCard(
            tint: context.colors.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(activeSessionProvider)!.shopName,
                  style: context.fonts.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(context.day(now)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('homeWelcome'),
                        style: context.fonts.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => showEntryDial(context),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('newEntry')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (Uri.base.queryParameters['desktopSession'] != null)
            GlassCard(child: Text(context.tr('desktopComplete'))),
          if (ref.watch(activeSessionProvider)!.demo && data.records.isEmpty)
            ActionButton(
              label: context.tr('seedDemoData'),
              icon: Icons.science_outlined,
              onPressed: () => DemoData.seed(ref.read(repositoryProvider)),
            ),
          SectionTitle(context.tr('todayOverview')),
          MetricGrid(
            children: [
              MetricCard(
                label: context.tr('cashIn'),
                value: context.money(cashIn),
                icon: Icons.south_west,
              ),
              MetricCard(
                label: context.tr('cashOut'),
                value: context.money(cashOut),
                icon: Icons.north_east,
              ),
              MetricCard(
                label: context.tr('sales'),
                value: context.money(sales),
                icon: Icons.shopping_bag_outlined,
              ),
              MetricCard(
                label: context.tr('cashBalance'),
                value: context.money(ledger.cashBalance()),
                icon: Icons.account_balance_wallet_outlined,
              ),
              MetricCard(
                label: context.tr('udharGiven'),
                value: context.money(given),
                icon: Icons.person_add_alt,
              ),
              MetricCard(
                label: context.tr('udharReceived'),
                value: context.money(received),
                icon: Icons.handshake_outlined,
              ),
            ],
          ),
          SectionTitle(
            '${context.tr('pendingRates')} (${ledger.pendingRates.length})',
          ),
          if (ledger.pendingRates.isEmpty)
            EmptyState(
              message: context.tr('noPendingRates'),
              icon: Icons.check_circle_outline,
            )
          else
            GlassCard(
              child: Column(
                children: ledger.pendingRates
                    .map(
                      (e) => EntryTile(
                        entry: e,
                        data: data,
                        onTap: () async {
                          final rate = await askText(
                            context,
                            title: context.tr('setRate'),
                            numeric: true,
                          );
                          if (rate == null || !context.mounted) return;
                          try {
                            await ref
                                .read(repositoryProvider)
                                .resolveRate(e.id, parseMoney(rate));
                            if (context.mounted) {
                              context.toast(context.tr('rateUpdated'));
                            }
                          } catch (error) {
                            if (context.mounted) {
                              context.toast(context.failure(error));
                            }
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          if (negative.isNotEmpty)
            GlassCard(
              tint: context.colors.errorContainer,
              child: Text(context.tr('negativeStockWarning')),
            ),
          SectionTitle(
            context.tr('stockAlerts'),
            action: TextButton(
              onPressed: () => context.push('/stock'),
              child: Text(context.tr('viewAll')),
            ),
          ),
          if (low.isEmpty && expiring.isEmpty)
            EmptyState(message: context.tr('noStockAlerts'))
          else
            GlassCard(
              child: Column(
                children: [
                  for (final p in low)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(p.name),
                      subtitle: Text(context.tr('lowStock')),
                      trailing: Text(
                        '${ledger.stock(p.id).toStringAsFixed(1)} ${context.tr(p.baseUnit)}',
                      ),
                    ),
                  for (final lot in expiring)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.event_busy,
                        color: context.colors.error,
                      ),
                      title: Text(data.productName(lot.itemId)),
                      subtitle: Text(
                        '${lot.batch} · ${context.day(lot.expiry!)}',
                      ),
                      trailing: Text(
                        context.tr(
                          lot.expiry!.isBefore(now)
                              ? 'expired'
                              : 'expiringSoon',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SectionTitle(
            context.tr('recentEntries'),
            action: TextButton(
              onPressed: () => context.go('/roznamcha'),
              child: Text(context.tr('viewAll')),
            ),
          ),
          if (ledger.entries.isEmpty)
            EmptyState(message: context.tr('noEntries'))
          else
            GlassCard(
              child: Column(
                children: ledger.entries.reversed
                    .take(5)
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
