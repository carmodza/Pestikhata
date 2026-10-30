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
    'crop purchase and sale fields update the billed rate and support rate later',
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
      expect(find.text('Crop purchase & sale rates'), findsOneWidget);
      await tester.enterText(field('Purchase price (Rs / unit)'), '125.50');
      expect(
        tester.widget<TextField>(field('Rate (Rs / unit)')).controller!.text,
        '125.50',
      );
      await tester.enterText(field('Sale price (Rs / unit)'), '200.25');
      expect(
        tester.widget<TextField>(field('Rate (Rs / unit)')).controller!.text,
        '125.50',
      );
      await tester.tap(find.text('Rate later'));
      await tester.pumpAndSettle();
      expect(field('Rate (Rs / unit)'), findsNothing);
      await save(tester);
      var data = await app.repo.snapshot();
      final entry = data.entries.firstWhere(
        (e) => !before.entries.any((old) => old.id == e.id),
      );
      expect(entry.kind, EntryKind.crop);
      expect(entry.ratePending, isTrue);
      expect(entry.purchasePaise, 12550);
      expect(entry.salePaise, 20025);
      expect(data.ledger.stock('wheat'), before.ledger.stock('wheat') + 1);
      await completeRate(tester, 'Wheat', '130');
      data = await app.repo.snapshot();
      expect(
        data.entries.firstWhere((e) => e.id == entry.id).totalPaise,
        13000,
      );
      expect(
        data.entries.firstWhere((e) => e.id == entry.id).ratePending,
        isFalse,
      );
      expect(data.ledger.stock('wheat'), before.ledger.stock('wheat') + 1);
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
