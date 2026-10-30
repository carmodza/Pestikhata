import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/data/shop_repository.dart';
import 'package:pestikhata/core/database/app_database.dart';
import 'package:pestikhata/core/domain/models.dart';

void main() {
  test(
    'unsynced entries, cash, khata and cursor survive database restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'pestikhata-test-',
      );
      final file = File('${directory.path}/shop.sqlite');
      var db = AppDatabase(NativeDatabase(file));
      try {
        var repository = ShopRepository(
          db,
          'shop',
          'device',
          AppRole.owner,
          'owner',
        );
        await repository.savePerson(
          const Person(id: 'farmer', name: 'Ali', kind: PartyKind.farmer),
        );
        await repository.saveEntry(
          JournalEntry(
            id: 'receipt',
            kind: EntryKind.cash,
            source: const Endpoint(PartyKind.farmer, 'farmer'),
            destination: const Endpoint(PartyKind.inventory),
            date: DateTime(2026, 10, 30),
            amountPaise: 12550,
          ),
        );
        await repository.saveSyncCursor('2026-10-30T10:00:00Z');
        await db.close();
        db = AppDatabase(NativeDatabase(file));
        repository = ShopRepository(
          db,
          'shop',
          'device',
          AppRole.owner,
          'owner',
        );
        final data = await repository.snapshot();
        expect(data.entries.single.id, 'receipt');
        expect(data.ledger.cashBalance(), 12550);
        expect(data.ledger.personBalance('farmer'), -12550);
        expect((await repository.pending()).length, 2);
        expect(await repository.syncCursor(), '2026-10-30T10:00:00Z');
        final otherShop = ShopRepository(
          db,
          'another-shop',
          'device',
          AppRole.owner,
          'other',
        );
        expect((await otherShop.snapshot()).entries, isEmpty);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
