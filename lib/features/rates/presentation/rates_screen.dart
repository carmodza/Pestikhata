import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import '../../ledger/domain/ledger_engine.dart';

class RatesScreen extends ConsumerStatefulWidget {
  const RatesScreen({super.key});
  @override
  ConsumerState<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends ConsumerState<RatesScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) => ShopData(
    builder: (data) => PageBody(
      children: [
        Text(context.tr('ratesHelp'), style: context.fonts.bodyLarge),
        TextField(
          decoration: InputDecoration(
            labelText: context.tr('search'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (q) => setState(() => query = q),
        ),
        for (final p in data.products.where(
          (p) => p.name.toLowerCase().contains(query.toLowerCase()),
        ))
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: context.fonts.titleLarge),
                Text('${context.tr('baseUnit')}: ${context.tr(p.baseUnit)}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${context.tr('purchasePrice')}\n${context.money(p.purchasePaise)}',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${context.tr('salePrice')}\n${context.money(p.salePaise)}',
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('updateRate'),
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final purchase = await askText(
                          context,
                          title: context.tr('purchasePrice'),
                          initial: moneyInput(p.purchasePaise),
                          numeric: true,
                        );
                        if (purchase == null || !context.mounted) return;
                        final sale = await askText(
                          context,
                          title: context.tr('salePrice'),
                          initial: moneyInput(p.salePaise),
                          numeric: true,
                        );
                        if (sale == null) return;
                        try {
                          await ref
                              .read(repositoryProvider)
                              .saveRate(
                                p,
                                parseMoney(purchase),
                                parseMoney(sale),
                              );
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
                  ],
                ),
                if (data.rates.where((r) => r.itemId == p.id).isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    context.tr('priceHistory'),
                    style: context.fonts.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TrendPainter(
                        data.rates
                            .where((r) => r.itemId == p.id)
                            .take(30)
                            .toList()
                            .reversed
                            .map((r) => r.salePaise.toDouble())
                            .toList(),
                        context.colors.primary,
                      ),
                    ),
                  ),
                  ...data.rates
                      .where((r) => r.itemId == p.id)
                      .take(5)
                      .map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(context.day(r.date)),
                          trailing: Text(
                            '${context.money(r.purchasePaise)} / ${context.money(r.salePaise)}',
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        if (data.products.isEmpty)
          EmptyState(message: context.tr('noProducts')),
      ],
    ),
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final min = values.reduce(math.min),
        max = values.reduce(math.max),
        range = math.max(1.0, max - min);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
              ? size.width / 2
              : size.width * i / (values.length - 1),
          y = size.height - 8 - (values[i] - min) / range * (size.height - 16);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
