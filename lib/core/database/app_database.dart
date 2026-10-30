import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Documents extends Table {
  TextColumn get shopId => text()();
  TextColumn get entity => text()();
  TextColumn get id => text()();
  TextColumn get payload => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {shopId, entity, id};
}

class Outbox extends Table {
  TextColumn get shopId => text()();
  TextColumn get entity => text()();
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  TextColumn get deviceId => text()();
  @override
  Set<Column> get primaryKey => {shopId, entity, id};
}

class SyncCursors extends Table {
  TextColumn get shopId => text()();
  TextColumn get serverTime => text()();
  @override
  Set<Column> get primaryKey => {shopId};
}

@DriftDatabase(tables: [Documents, Outbox, SyncCursors])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'pestikhata',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.dart.js'),
              ),
            ),
      );
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX documents_shop_entity ON documents(shop_id, entity)',
      );
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
