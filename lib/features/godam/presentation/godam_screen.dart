import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../../core/providers.dart';
import '../../../core/presentation/widgets.dart';
import '../../../l10n/strings.dart';

class GodamScreen extends ConsumerWidget {
  const GodamScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ShopData(
    builder: (data) => PageBody(
      children: [
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: Text(context.tr('addGodam')),
          onPressed: () async {
            final name = await askText(context, title: context.tr('godamName'));
            if (name == null || !context.mounted) return;
            final address = await askText(
              context,
              title: context.tr('address'),
            );
            if (address == null) return;
            try {
              await ref
                  .read(repositoryProvider)
                  .saveGodam(
                    Godam(
                      id: ShopRepository.uuid.v4(),
                      name: name.trim(),
                      address: address.trim(),
                    ),
                  );
            } catch (e) {
              if (context.mounted) context.toast(context.failure(e));
            }
          },
        ),
        for (final location in [
          (id: 'inventory', name: context.tr('shopStock'), address: ''),
          ...data.godams.map(
            (g) => (id: g.id, name: g.name, address: g.address),
          ),
        ])
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: context.fonts.titleLarge),
                if (location.address.isNotEmpty) Text(location.address),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(context.tr('transferProducts')),
                      onPressed: () =>
                          context.push('/entry/product?from=${location.id}'),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.grass),
                      label: Text(context.tr('transferCrops')),
                      onPressed: () =>
                          context.push('/entry/crop?from=${location.id}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...data.products
                    .where(
                      (p) =>
                          data.ledger.stock(p.id, location: location.id).abs() >
                          .000001,
                    )
                    .map(
                      (p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        trailing: Text(
                          '${data.ledger.stock(p.id, location: location.id).toStringAsFixed(2)} ${context.tr(p.baseUnit)}',
                        ),
                        onTap: () => context.push('/stock/${p.id}'),
                      ),
                    ),
              ],
            ),
          ),
        Text(context.tr('transferHelp'), style: context.fonts.bodySmall),
      ],
    ),
  );
}
