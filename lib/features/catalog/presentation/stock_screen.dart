import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';
import '../../godam/presentation/godam_screen.dart';
import 'inventory_screen.dart';

/// A single stock workspace for the item catalog and its storage locations.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key, this.showGodams = false});
  final bool showGodams;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: showGodams ? 1 : 0,
    child: Column(
      children: [
        TabBar(
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_outlined),
              text: context.tr('items'),
            ),
            Tab(
              icon: const Icon(Icons.warehouse_outlined),
              text: context.tr('godamsTransfers'),
            ),
          ],
        ),
        const Expanded(
          child: TabBarView(children: [InventoryScreen(), GodamScreen()]),
        ),
      ],
    ),
  );
}
