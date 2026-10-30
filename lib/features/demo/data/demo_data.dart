import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';

abstract final class DemoData {
  static Future<void> clear(ShopRepository repo) async {
    repo.requireOwner();
    if (repo.shopId != 'demo-local') throw const DomainFailure('demoOnly');
    await repo.db.transaction(() async {
      await (repo.db.delete(
        repo.db.outbox,
      )..where((o) => o.shopId.equals(repo.shopId))).go();
      await (repo.db.delete(
        repo.db.documents,
      )..where((d) => d.shopId.equals(repo.shopId))).go();
    });
  }

  static Future<void> seed(ShopRepository repo) async {
    repo.requireOwner();
    if (repo.shopId != 'demo-local') throw const DomainFailure('demoOnly');
    await repo.db.transaction(() async {
      if ((await repo.snapshot()).records.isNotEmpty) return;
      final today = DateTime.now();
      final yesterday = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(const Duration(days: 1));
      final expiry = DateTime(today.year, today.month + 2, 1);
      const farmer = Person(
        id: 'farmer-ali',
        name: 'Muhammad Ali',
        kind: PartyKind.farmer,
        phone: '+923001234567',
        village: 'Chak 42, Multan',
        acres: 18,
        crops: 'Wheat, Cotton',
      );
      const farmer2 = Person(
        id: 'farmer-ahmed',
        name: 'Ahmed Raza',
        kind: PartyKind.farmer,
        phone: '+923211234567',
        village: 'Shujabad',
        acres: 12,
        crops: 'Rice, Wheat',
      );
      const supplier = Person(
        id: 'supplier-agri',
        name: 'Agri Supply Co.',
        kind: PartyKind.supplier,
        phone: '+923331234567',
        village: 'Multan',
      );
      const urea = Product(
        id: 'urea',
        name: 'Sona Urea 50 kg',
        company: 'FFC',
        crop: 'Wheat',
        baseUnit: 'bag',
        units: {'bag': 1},
        purchasePaise: 420000,
        salePaise: 460000,
        lowStock: 15,
      );
      const pesticide = Product(
        id: 'imidacloprid',
        name: 'Imidacloprid 250 ml',
        company: 'Agri Care',
        crop: 'Cotton',
        pest: 'Whitefly',
        purchasePaise: 85000,
        salePaise: 110000,
        lowStock: 10,
      );
      const wheat = Product(
        id: 'wheat',
        name: 'Wheat',
        kind: EntryKind.crop,
        baseUnit: 'kg',
        units: {'kg': 1, 'maan': 40, 'quintal': 100, 'bori': 50, 'ton': 1000},
        purchasePaise: 7200,
        salePaise: 8000,
        lowStock: 100,
      );
      for (final p in [farmer, farmer2, supplier]) {
        await repo.savePerson(p);
      }
      for (final p in [urea, pesticide, wheat]) {
        await repo.saveProduct(p);
      }
      await repo.saveGodam(
        const Godam(
          id: 'godam-main',
          name: 'Main Godam',
          address: 'Bosan Road, Multan',
        ),
      );
      await repo.saveEntry(
        JournalEntry(
          id: 'opening-cash',
          kind: EntryKind.cash,
          source: const Endpoint(PartyKind.walkIn),
          destination: const Endpoint(PartyKind.inventory),
          date: yesterday,
          amountPaise: 25000000,
          title: 'Opening cash',
        ),
      );
      for (final item in [urea, pesticide]) {
        final qty = item.id == 'urea' ? 100.0 : 40.0;
        await repo.saveEntry(
          JournalEntry(
            id: 'purchase-${item.id}',
            kind: EntryKind.product,
            source: const Endpoint(PartyKind.supplier, 'supplier-agri'),
            destination: const Endpoint(PartyKind.inventory),
            date: yesterday,
            itemId: item.id,
            title: item.name,
            batch: 'PK-2026-A',
            expiry: expiry,
            quantity: qty,
            unit: item.baseUnit,
            ratePaise: item.purchasePaise,
            purchasePaise: item.purchasePaise,
            salePaise: item.salePaise,
            cashPaise: 0,
          ),
        );
      }
      await repo.saveEntry(
        JournalEntry(
          id: 'purchase-wheat',
          kind: EntryKind.crop,
          source: const Endpoint(PartyKind.farmer, 'farmer-ahmed'),
          destination: const Endpoint(PartyKind.godam, 'godam-main'),
          date: yesterday,
          itemId: 'wheat',
          title: 'Wheat',
          quantity: 30,
          unit: 'maan',
          unitFactor: 40,
          ratePaise: 288000,
          purchasePaise: 288000,
          cashPaise: 4000000,
        ),
      );
      await repo.saveEntry(
        JournalEntry(
          id: 'sale-urea',
          kind: EntryKind.product,
          source: const Endpoint(PartyKind.inventory),
          destination: const Endpoint(PartyKind.farmer, 'farmer-ali'),
          date: today,
          itemId: 'urea',
          title: urea.name,
          batch: 'PK-2026-A',
          expiry: expiry,
          quantity: 12,
          unit: 'bag',
          ratePaise: 460000,
          purchasePaise: 420000,
          salePaise: 460000,
          cashPaise: 3000000,
        ),
      );
      await repo.saveEntry(
        JournalEntry(
          id: 'sale-pending',
          kind: EntryKind.product,
          source: const Endpoint(PartyKind.inventory),
          destination: const Endpoint(PartyKind.farmer, 'farmer-ahmed'),
          date: today,
          itemId: 'imidacloprid',
          title: pesticide.name,
          batch: 'PK-2026-A',
          expiry: expiry,
          quantity: 5,
          unit: 'piece',
          purchasePaise: 85000,
          salePaise: 110000,
          ratePending: true,
        ),
      );
      await repo.saveEntry(
        JournalEntry(
          id: 'receive-cash',
          kind: EntryKind.cash,
          source: const Endpoint(PartyKind.farmer, 'farmer-ali'),
          destination: const Endpoint(PartyKind.inventory),
          date: today,
          title: 'Payment received',
          amountPaise: 500000,
        ),
      );
      await repo.saveEntry(
        JournalEntry(
          id: 'rent',
          kind: EntryKind.other,
          source: const Endpoint(PartyKind.inventory),
          destination: const Endpoint(PartyKind.walkIn),
          date: today,
          title: 'Shop rent',
          amountPaise: 1800000,
          cashPaise: 1800000,
          expenseCategory: 'rent',
        ),
      );
    });
  }
}
