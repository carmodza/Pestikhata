import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pestikhata/app.dart';
import 'package:pestikhata/core/database/app_database.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/core/providers.dart';
import 'package:pestikhata/features/auth/data/auth_repository.dart';
import 'package:pestikhata/features/demo/data/demo_data.dart';

void main() {
  testWidgets(
    'product sale, receipt and direct entry preserve prices, stock and both khatas',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      final auth = AuthRepository(const FlutterSecureStorage())
        ..session = const AppSession(
          userId: 'demo-owner',
          shopId: 'demo-local',
          shopName: 'Test Shop',
          role: AppRole.owner,
          demo: true,
        );
      addTearDown(db.close);
      addTearDown(auth.dispose);
      final repo = ShopRepository(
        db,
        'demo-local',
        'device',
        AppRole.owner,
        'demo-owner',
      );
      await DemoData.seed(repo);
      final before = await repo.snapshot();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            authProvider.overrideWithValue(auth),
            databaseProvider.overrideWithValue(db),
          ],
          child: const PestiKhataApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pesticide / Fertilizer / Seed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search / select a person'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Muhammad Ali').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search / select an item'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Sona Urea').last);
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      String value(String label) =>
          tester.widget<TextField>(field(label)).controller!.text;
      final vertical = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first;
      await tester.scrollUntilVisible(
        field('Purchase price (Rs / unit)'),
        300,
        scrollable: vertical,
      );
      expect(value('Purchase price (Rs / unit)'), '4200.00');
      expect(value('Sale price (Rs / unit)'), '4600.00');
      expect(value('Rate (Rs / unit)'), '4600.00');
      await tester.enterText(field('Quantity'), '2');
      expect(find.text('Choose available stock batch'), findsNothing);
      expect(find.text('Batch (automatic)'), findsNothing);
      expect(find.text('Add expiry date (optional)'), findsNothing);
      await tester.scrollUntilVisible(
        field('Cash amount (Rs)'),
        300,
        scrollable: vertical,
      );
      await tester.enterText(field('Cash amount (Rs)'), '2000');
      await tester.scrollUntilVisible(
        find.text('Save entry'),
        300,
        scrollable: vertical,
      );
      await tester.tap(find.text('Save entry'));
      await tester.pumpAndSettle();
      final after = await repo.snapshot();
      expect(after.entries.length, before.entries.length + 1);
      final entry = after.entries.firstWhere(
        (e) => !before.entries.any((old) => old.id == e.id),
      );
      expect(entry.totalPaise, 920000);
      expect(entry.creditPaise, 720000);
      expect(entry.purchasePaise, 420000);
      expect(entry.allocations.single.batch, 'PK-2026-A');
      expect(after.ledger.stock('urea'), before.ledger.stock('urea') - 2);
      expect(
        after.ledger.personBalance('farmer-ali'),
        before.ledger.personBalance('farmer-ali') + 720000,
      );
      expect(after.ledger.cashBalance(), before.ledger.cashBalance() + 200000);
      Future<void> openProduct() async {
        await tester.tap(find.text('Entry'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pesticide / Fertilizer / Seed'));
        await tester.pumpAndSettle();
      }

      Future<void> selectItem() async {
        await tester.tap(find.text('Search / select an item'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Sona Urea').last);
        await tester.pumpAndSettle();
      }

      Future<void> save() async {
        await tester.scrollUntilVisible(
          find.text('Save entry'),
          300,
          scrollable: vertical,
        );
        await tester.tap(find.text('Save entry'));
        await tester.pumpAndSettle();
      }

      await openProduct();
      await tester.tap(find.text('Supplier').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Agri Supply Co.').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop').last);
      await tester.pumpAndSettle();
      await selectItem();
      expect(find.text('Batch (automatic)'), findsOneWidget);
      expect(find.text('Add expiry date (optional)'), findsOneWidget);
      await tester.enterText(field('Quantity'), '3');
      await save();
      final received = await repo.snapshot();
      final receipt = received.entries.firstWhere(
        (e) => !after.entries.any((old) => old.id == e.id),
      );
      expect(receipt.isStockReceipt, isTrue);
      expect(receipt.batch, startsWith('B-'));
      expect(receipt.expiry, isNull);
      expect(received.ledger.stock('urea'), after.ledger.stock('urea') + 3);
      await openProduct();
      await tester.tap(find.text('Supplier').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Agri Supply Co.').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Farmer').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Muhammad Ali').last);
      await tester.pumpAndSettle();
      await selectItem();
      expect(find.text('Batch (automatic)'), findsNothing);
      expect(find.text('Add expiry date (optional)'), findsNothing);
      await tester.enterText(field('Quantity'), '2');
      await tester.scrollUntilVisible(
        field('Cash amount (Rs)'),
        300,
        scrollable: vertical,
      );
      await tester.enterText(field('Cash amount (Rs)'), '2000');
      await save();
      final direct = await repo.snapshot();
      final directEntry = direct.entries.firstWhere(
        (e) => !received.entries.any((old) => old.id == e.id),
      );
      expect(directEntry.isDirect, isTrue);
      expect(directEntry.totalPaise, 920000);
      expect(direct.ledger.stock('urea'), received.ledger.stock('urea'));
      expect(direct.ledger.cashBalance(), received.ledger.cashBalance());
      expect(
        direct.ledger.personBalance('farmer-ali'),
        received.ledger.personBalance('farmer-ali') + 720000,
      );
      expect(
        direct.ledger.personBalance('supplier-agri'),
        received.ledger.personBalance('supplier-agri') - 720000,
      );
      await tester.tap(find.text('Khata'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muhammad Ali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receive payment'));
      await tester.pumpAndSettle();
      expect(find.text('Pending receipts'), findsOneWidget);
      expect(find.text('Remaining'), findsWidgets);
      expect(value('Amount (Rs)'), isEmpty);
      await tester.scrollUntilVisible(
        field('Amount (Rs)'),
        300,
        scrollable: vertical,
      );
      await tester.enterText(field('Amount (Rs)'), '100');
      await save();
      final paid = await repo.snapshot();
      expect(
        paid.ledger.personBalance('farmer-ali'),
        direct.ledger.personBalance('farmer-ali') - 10000,
      );
      expect(tester.takeException(), isNull);
      await db.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'center Entry dial saves a cash receipt into local khata and journal',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance(),
          db = AppDatabase(NativeDatabase.memory());
      final auth = AuthRepository(const FlutterSecureStorage())
        ..session = const AppSession(
          userId: 'demo-owner',
          shopId: 'demo-local',
          shopName: 'Test Shop',
          role: AppRole.owner,
          demo: true,
        );
      addTearDown(db.close);
      addTearDown(auth.dispose);
      final repo = ShopRepository(
        db,
        'demo-local',
        'device',
        AppRole.owner,
        'demo-owner',
      );
      await repo.savePerson(
        const Person(id: 'farmer', name: 'Ali Test', kind: PartyKind.farmer),
      );
      debugPrint('Entry UI: person seeded');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            authProvider.overrideWithValue(auth),
            databaseProvider.overrideWithValue(db),
          ],
          child: const PestiKhataApp(),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('Entry UI: home rendered');
      await tester.tap(find.text('Entry'));
      await tester.pumpAndSettle();
      expect(find.text('Pesticide / Fertilizer / Seed'), findsOneWidget);
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();
      debugPrint('Entry UI: cash form rendered');
      await tester.tap(find.text('Search / select a person'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ali Test'));
      await tester.pumpAndSettle();
      debugPrint('Entry UI: farmer selected');
      final amount = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Amount (Rs)',
      );
      await tester.enterText(amount, '125.50');
      debugPrint('Entry UI: amount entered');
      await tester.scrollUntilVisible(
        find.text('Save entry'),
        250,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.pumpAndSettle();
      debugPrint('Entry UI: save visible');
      await tester.tap(find.text('Save entry'));
      await tester.pumpAndSettle();
      debugPrint('Entry UI: save completed');
      final data = await repo.snapshot();
      debugPrint('Entry UI: snapshot received');
      expect(data.entries.single.amountPaise, 12550);
      expect(data.ledger.personBalance('farmer'), -12550);
      expect(data.ledger.cashBalance(), 12550);
      expect((await repo.pending()).any((r) => r.entity == 'entries'), true);
      expect(tester.takeException(), isNull);
      await db.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
