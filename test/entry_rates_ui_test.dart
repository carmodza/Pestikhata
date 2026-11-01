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

Future<({AppDatabase db, ShopRepository repo})> launch(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(1100, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        databaseProvider.overrideWithValue(db),
        authProvider.overrideWithValue(auth),
      ],
      child: const PestiKhataApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (db: db, repo: repo);
}

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
Future<void> open(WidgetTester tester, String category) async {
  await tester.tap(find.text('Entry'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(category));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save entry'));
  await tester.tap(find.text('Save entry'));
  await tester.pumpAndSettle();
}

Future<void> finish(WidgetTester tester, AppDatabase db) async {
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  final closing = db.close();
  await tester.pumpAndSettle();
  await closing;
}

Future<void> completeRate(
  WidgetTester tester,
  String title,
  String rate,
) async {
  await tester.ensureVisible(find.text(title).first);
  await tester.tap(find.text(title).first);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, rate);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'crop storage receipt shows only purchase rate, defaults to maan and updates farmer khata',
    (tester) async {
      final app = await launch(tester);
      final before = await app.repo.snapshot();
      await open(tester, 'Crop');
      await tester.tap(find.text('Farmer').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Muhammad Ali'), findsWidgets);
      await tester.tap(find.textContaining('Muhammad Ali').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search / select an item'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Wheat').last);
      await tester.pumpAndSettle();
      expect(field('Sale price (Rs / unit)'), findsNothing);
      expect(field('Rate (Rs / unit)'), findsNothing);
      await tester.enterText(field('Quantity'), '10');
      await tester.enterText(field('Purchase price (Rs / unit)'), '2800');
      expect(find.text('Purchase total'), findsOneWidget);
      expect(find.text('Sale total'), findsNothing);
      await save(tester);
      var data = await app.repo.snapshot();
      final entry = data.entries.firstWhere(
        (e) => !before.entries.any((old) => old.id == e.id),
      );
      expect(entry.kind, EntryKind.crop);
      expect(entry.ratePending, isFalse);
      expect(entry.purchasePaise, 280000);
      expect(entry.salePaise, 0);
      expect(entry.unit, 'maan');
      expect(entry.totalPaise, 2800000);
      expect(
        data.ledger.personBalance('farmer-ali'),
        before.ledger.personBalance('farmer-ali') - 2800000,
      );
      expect(data.ledger.stock('wheat'), before.ledger.stock('wheat') + 400);
      await open(tester, 'Crop');
      await tester.tap(find.text('Godam').first);
      await tester.pumpAndSettle();
      expect(find.text('Select a godam'), findsOneWidget);
      await tester.tap(find.text('Main Godam'));
      await tester.pumpAndSettle();
      expect(find.text('Main Godam'), findsOneWidget);
      expect(find.text('Rate later'), findsNothing);
      await finish(tester, app.db);
    },
  );

  testWidgets('stored crop sale shows sale price only and bills its buyer', (
    tester,
  ) async {
    final app = await launch(tester);
    final before = await app.repo.snapshot();
    await open(tester, 'Crop');
    await tester.tap(find.text('Godam').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Godam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Farmer').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Muhammad Ali').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search / select an item'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Wheat').last);
    await tester.pumpAndSettle();
    expect(field('Purchase price (Rs / unit)'), findsNothing);
    expect(field('Rate (Rs / unit)'), findsNothing);
    await tester.enterText(field('Quantity'), '2');
    await tester.enterText(field('Sale price (Rs / unit)'), '3200');
    await tester.enterText(field('Received now (Rs)'), '1000');
    await save(tester);
    final data = await app.repo.snapshot();
    final entry = data.entries.firstWhere(
      (e) => !before.entries.any((old) => e.id == old.id),
    );
    expect(entry.totalPaise, 640000);
    expect(
      data.ledger.personBalance('farmer-ali'),
      before.ledger.personBalance('farmer-ali') + 540000,
    );
    expect(
      data.ledger.stock('wheat', location: 'godam-main'),
      before.ledger.stock('wheat', location: 'godam-main') - 80,
    );
    expect(
      data.ledger.personBalance('farmer-ahmed'),
      before.ledger.personBalance('farmer-ahmed'),
    );
    await finish(tester, app.db);
  });

  testWidgets(
    'direct crop purchase posts now; pending sale resolves independently from Home',
    (tester) async {
      final app = await launch(tester);
      final before = await app.repo.snapshot();
      await open(tester, 'Crop');
      await tester.tap(find.text('Farmer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ahmed Raza').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Farmer').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Muhammad Ali').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search / select an item'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Wheat').last);
      await tester.pumpAndSettle();
      expect(field('Rate (Rs / unit)'), findsNothing);
      expect(field('Purchase price (Rs / unit)'), findsOneWidget);
      expect(field('Sale price (Rs / unit)'), findsOneWidget);
      await tester.enterText(field('Quantity'), '10');
      await tester.enterText(field('Purchase price (Rs / unit)'), '2800');
      await tester.tap(find.text('Sale rate later'));
      await tester.pumpAndSettle();
      expect(field('Sale price (Rs / unit)'), findsNothing);
      await tester.enterText(field('Cash through Shop (Rs)'), '1000');
      await save(tester);
      var data = await app.repo.snapshot();
      final entry = data.entries.firstWhere(
        (e) => !before.entries.any((old) => e.id == old.id),
      );
      expect(entry.ratePending, true);
      expect(entry.purchaseRatePending, false);
      expect(entry.purchasePaise, 280000);
      expect(
        data.ledger.personBalance('farmer-ahmed'),
        before.ledger.personBalance('farmer-ahmed') - 2700000,
      );
      expect(
        data.ledger.personBalance('farmer-ali'),
        before.ledger.personBalance('farmer-ali') - 100000,
      );
      await tester.ensureVisible(find.text('Wheat').first);
      await tester.tap(find.text('Wheat').first);
      await tester.pumpAndSettle();
      expect(find.text('Crop purchase & sale rates'), findsOneWidget);
      await tester.enterText(field('Sale price (Rs / unit)'), '3200');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      data = await app.repo.snapshot();
      expect(
        data.entries.firstWhere((e) => e.id == entry.id).hasPendingRate,
        false,
      );
      expect(
        data.ledger.personBalance('farmer-ahmed'),
        before.ledger.personBalance('farmer-ahmed') - 2700000,
      );
      expect(
        data.ledger.personBalance('farmer-ali'),
        before.ledger.personBalance('farmer-ali') + 3100000,
      );
      expect(data.ledger.cashBalance(), before.ledger.cashBalance());
      expect(data.ledger.stock('wheat'), before.ledger.stock('wheat'));
      await finish(tester, app.db);
    },
  );

  testWidgets(
    'crop purchase rate later resolves without creating a sale rate',
    (tester) async {
      final app = await launch(tester);
      final before = await app.repo.snapshot();
      await open(tester, 'Crop');
      await tester.tap(find.text('Farmer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ahmed Raza').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search / select an item'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Wheat').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rate later'));
      await tester.pumpAndSettle();
      expect(field('Purchase price (Rs / unit)'), findsNothing);
      expect(field('Sale price (Rs / unit)'), findsNothing);
      await save(tester);
      final entry = (await app.repo.snapshot()).entries.firstWhere(
        (e) => !before.entries.any((old) => e.id == old.id),
      );
      await completeRate(tester, 'Wheat', '2800');
      final data = await app.repo.snapshot();
      final priced = data.entries.firstWhere((e) => e.id == entry.id);
      expect(priced.purchasePaise, 280000);
      expect(priced.salePaise, 0);
      expect(priced.hasPendingRate, false);
      expect(data.ledger.stock('wheat'), before.ledger.stock('wheat') + 40);
      expect(
        data.ledger.personBalance('farmer-ahmed'),
        before.ledger.personBalance('farmer-ahmed') - 280000,
      );
      await finish(tester, app.db);
    },
  );

  testWidgets('diesel pending rate can be saved and completed from Home', (
    tester,
  ) async {
    final app = await launch(tester);
    final before = await app.repo.snapshot();
    await open(tester, 'Diesel');
    await tester.tap(find.text('Supplier').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Agri Supply Co.').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Liters'), '10');
    await tester.tap(find.text('Rate later'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Cash amount (Rs)'), '500');
    await save(tester);
    var data = await app.repo.snapshot();
    final entry = data.entries.firstWhere(
      (e) => !before.entries.any((old) => old.id == e.id),
    );
    expect(entry.ratePending, isTrue);
    expect(entry.quantity, 10);
    expect(data.ledger.cashBalance(), before.ledger.cashBalance() - 50000);
    await completeRate(tester, 'Diesel', '250');
    data = await app.repo.snapshot();
    expect(data.entries.firstWhere((e) => e.id == entry.id).totalPaise, 250000);
    expect(
      data.entries.firstWhere((e) => e.id == entry.id).ratePending,
      isFalse,
    );
    expect(data.ledger.cashBalance(), before.ledger.cashBalance() - 50000);
    expect(
      data.ledger.personBalance('supplier-agri'),
      before.ledger.personBalance('supplier-agri') - 200000,
    );
    await finish(tester, app.db);
  });
}
