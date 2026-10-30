import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/models.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';
import 'editors.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String query = '';
  String? location;
  EntryKind kind = EntryKind.product;
  @override
  Widget build(BuildContext context) => ShopData(
    builder: (data) {
      final products = data.products
          .where(
            (p) =>
                p.kind == kind &&
                '${p.name} ${p.company} ${p.crop} ${p.pest}'
                    .toLowerCase()
                    .contains(query.toLowerCase()) &&
                (location == null ||
                    data.ledger.stock(p.id, location: location).abs() >
                        .000001),
          )
          .toList();
      return PageBody(
        children: [
          DropdownButtonFormField<String>(
            initialValue: location ?? 'all',
            decoration: InputDecoration(
              labelText: context.tr('stockLocation'),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(context.tr('allLocations')),
              ),
              DropdownMenuItem(
                value: 'inventory',
                child: Text(context.tr('shopStock')),
              ),
              ...data.godams.map(
                (g) => DropdownMenuItem(value: g.id, child: Text(g.name)),
              ),
            ],
            onChanged: (value) =>
                setState(() => location = value == 'all' ? null : value),
          ),
          SegmentedButton<EntryKind>(
            segments: [
              ButtonSegment(
                value: EntryKind.product,
                label: Text(context.tr('products')),
              ),
              ButtonSegment(
                value: EntryKind.crop,
                label: Text(context.tr('crops')),
              ),
            ],
            selected: {kind},
            onSelectionChanged: (v) => setState(() => kind = v.first),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: context.tr('inventorySearch'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (q) => setState(() => query = q),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.add_box_outlined),
            label: Text(
              context.tr(kind == EntryKind.crop ? 'addCrop' : 'addProduct'),
            ),
            onPressed: () => editProduct(context, ref, kind),
          ),
          if (products.isEmpty)
            EmptyState(
              message: context.tr(
                query.trim().isNotEmpty
                    ? 'noResults'
                    : location != null
                    ? 'noStockAtLocation'
                    : 'noProducts',
              ),
            )
          else
            GlassCard(
              child: Column(
                children: products.map((p) {
                  final stock = data.ledger.stock(p.id, location: location);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    leading: CircleAvatar(
                      child: Icon(
                        p.kind == EntryKind.crop
                            ? Icons.grass
                            : Icons.science_outlined,
                      ),
                    ),
                    title: Text(p.name, style: context.fonts.titleMedium),
                    subtitle: Text(
                      '${p.company} · ${p.crop}\n${context.money(p.salePaise)} / ${context.tr(p.baseUnit)}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${stock.toStringAsFixed(1)} ${context.tr(p.baseUnit)}',
                          style: context.fonts.titleMedium,
                        ),
                        if (data.ledger.stock(p.id) <= p.lowStock)
                          Text(
                            context.tr('lowStock'),
                            style: TextStyle(color: context.colors.error),
                          ),
                      ],
                    ),
                    onTap: () => context.push('/stock/${p.id}'),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    },
  );
}

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShopData(
    builder: (data) {
      final product = data.products.where((p) => p.id == id).firstOrNull;
      if (product == null) return EmptyState(message: context.tr('noResults'));
      final lots = data.ledger
          .stockLots()
          .where((l) => l.itemId == id)
          .toList();
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
                        product.name,
                        style: context.fonts.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('edit'),
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => editProduct(
                        context,
                        ref,
                        product.kind,
                        existing: product,
                      ),
                    ),
                  ],
                ),
                Text('${product.company} · ${product.crop} · ${product.pest}'),
                const SizedBox(height: 16),
                Text(
                  '${data.ledger.stock(id).toStringAsFixed(2)} ${context.tr(product.baseUnit)}',
                  style: context.fonts.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '${context.tr('purchasePrice')}: ${context.money(product.purchasePaise)}',
                ),
                Text(
                  '${context.tr('salePrice')}: ${context.money(product.salePaise)}',
                ),
                const SizedBox(height: 12),
                Text(
                  product.units.entries
                      .map(
                        (u) =>
                            '1 ${context.tr(u.key)} = ${u.value} ${context.tr(product.baseUnit)}',
                      )
                      .join('\n'),
                ),
              ],
            ),
          ),
          SectionTitle(context.tr('batchesAndLocations')),
          if (lots.isEmpty)
            EmptyState(message: context.tr('noStock'))
          else
            GlassCard(
              child: Column(
                children: lots
                    .map(
                      (l) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: const Icon(Icons.warehouse_outlined),
                        title: Text(
                          l.location == 'inventory'
                              ? context.tr('shopStock')
                              : data.godamName(l.location),
                        ),
                        subtitle: Text(
                          '${l.batch}${l.expiry == null ? '' : ' · ${context.day(l.expiry!)}'}',
                        ),
                        trailing: Text(
                          '${l.quantity.toStringAsFixed(2)} ${context.tr(product.baseUnit)}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          SectionTitle(context.tr('recentEntries')),
          GlassCard(
            child: Column(
              children: data.ledger.entries
                  .where((e) => e.itemId == id)
                  .toList()
                  .reversed
                  .take(20)
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
