import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../domain/models.dart';
import '../domain/entity_validator.dart';
import '../../features/ledger/domain/ledger_engine.dart';

class ShopSnapshot {
  ShopSnapshot(this.records);
  final List<RecordEnvelope> records;
  Iterable<Json> _entity(String name) => records
      .where((r) => r.entity == name && !r.deleted)
      .map((r) => r.payload);
  late final List<Person> people = _entity(
    'people',
  ).map(Person.fromJson).toList()..sort((a, b) => a.name.compareTo(b.name));
  late final List<Product> products = _entity(
    'products',
  ).map(Product.fromJson).toList()..sort((a, b) => a.name.compareTo(b.name));
  late final List<Godam> godams = _entity(
    'godams',
  ).map(Godam.fromJson).toList();
  late final List<JournalEntry> entries = _entity(
    'entries',
  ).map(JournalEntry.fromJson).toList();
  late final List<RateRecord> rates = _entity(
    'rates',
  ).map(RateRecord.fromJson).toList()..sort((a, b) => b.date.compareTo(a.date));
  late final LedgerEngine ledger = LedgerEngine(entries);
  String personName(String? id) =>
      people.where((p) => p.id == id).firstOrNull?.name ?? '';
  String productName(String? id) =>
      products.where((p) => p.id == id).firstOrNull?.name ?? '';
  String godamName(String? id) =>
      godams.where((p) => p.id == id).firstOrNull?.name ?? '';
}

class ShopRepository {
  ShopRepository(this.db, this.shopId, this.deviceId, this.role, this.userId);
  final AppDatabase db;
  final String shopId, deviceId, userId;
  final AppRole role;
  static const entities = {'people', 'products', 'godams', 'entries', 'rates'};
  static const uuid = Uuid();
  static String newBatch(DateTime date) =>
      'B-${calendarDate(date).replaceAll('-', '')}-${uuid.v4().replaceAll('-', '').substring(0, 12).toUpperCase()}';
  static RecordEnvelope envelope(Document d) => RecordEnvelope(
    id: d.id,
    entity: d.entity,
    shopId: d.shopId,
    payload: jsonDecode(d.payload) as Json,
    updatedAt: d.updatedAt,
    deviceId: d.deviceId,
    deleted: d.deleted,
  );

  Future<ShopSnapshot> snapshot() async => ShopSnapshot(
    (await (db.select(
      db.documents,
    )..where((d) => d.shopId.equals(shopId))).get()).map(envelope).toList(),
  );
  Stream<ShopSnapshot> watch() =>
      (db.select(db.documents)..where((d) => d.shopId.equals(shopId)))
          .watch()
          .map((rows) => ShopSnapshot(rows.map(envelope).toList()));
  Stream<int> watchPending() => (db.select(
    db.outbox,
  )..where((o) => o.shopId.equals(shopId))).watch().map((r) => r.length);

  Future<String?> syncCursor() async => (await (db.select(
    db.syncCursors,
  )..where((c) => c.shopId.equals(shopId))).getSingleOrNull())?.serverTime;
  Future<void> saveSyncCursor(String value) async {
    await db
        .into(db.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(shopId: shopId, serverTime: value),
        );
  }

  Future<void> _put(
    String entity,
    String id,
    Json payload, {
    bool deleted = false,
  }) async {
    if (!entities.contains(entity)) throw const DomainFailure('invalidBackup');
    final previous =
        await (db.select(db.documents)..where(
              (d) =>
                  d.shopId.equals(shopId) &
                  d.entity.equals(entity) &
                  d.id.equals(id),
            ))
            .getSingleOrNull();
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final version = previous == null || now > previous.updatedAt
        ? now
        : previous.updatedAt + 1;
    await db
        .into(db.documents)
        .insertOnConflictUpdate(
          DocumentsCompanion.insert(
            shopId: shopId,
            entity: entity,
            id: id,
            payload: jsonEncode(payload),
            updatedAt: version,
            deviceId: deviceId,
            deleted: Value(deleted),
          ),
        );
    await db
        .into(db.outbox)
        .insertOnConflictUpdate(
          OutboxCompanion.insert(
            shopId: shopId,
            entity: entity,
            id: id,
            updatedAt: version,
            deviceId: deviceId,
          ),
        );
  }

  Future<void> savePerson(Person person) => db.transaction(() async {
    EntityValidator.person(person);
    await _put('people', person.id, person.toJson());
  });
  Future<void> saveProduct(Product product) => db.transaction(() async {
    EntityValidator.product(product);
    final existing = (await snapshot()).products
        .where((p) => p.id == product.id)
        .firstOrNull;
    if (existing != null &&
        (existing.kind != product.kind ||
            existing.baseUnit != product.baseUnit ||
            jsonEncode(existing.units) != jsonEncode(product.units)) &&
        (await snapshot()).entries.any((e) => e.itemId == product.id)) {
      throw const DomainFailure('unitLocked');
    }
    await _put('products', product.id, product.toJson());
  });
  Future<void> saveGodam(Godam godam) => db.transaction(() async {
    EntityValidator.godam(godam);
    await _put('godams', godam.id, godam.toJson());
  });
  Future<void> saveEntry(JournalEntry entry) => db.transaction(() async {
    final data = await snapshot();
    final existing = data.entries.where((e) => e.id == entry.id).firstOrNull;
    if (existing != null) throw const DomainFailure('entryImmutable');
    if (entry.kind == EntryKind.product &&
        entry.isStockReceipt &&
        entry.batch.isEmpty) {
      entry = JournalEntry.fromJson(
        entry.toJson()..['batch'] = newBatch(entry.date),
      );
    }
    entry = data.ledger.allocateStock(entry);
    data.ledger.validate(
      entry,
      products: data.products,
      people: data.people,
      godams: data.godams,
    );
    await _put(
      'entries',
      entry.id,
      JournalEntry.fromJson(
        entry.toJson()
          ..['createdBy'] = userId
          ..['createdAt'] = DateTime.now().toUtc().microsecondsSinceEpoch,
      ).toJson(),
    );
  });
  Future<void> resolveRate(String id, int rate, {bool purchase = false}) =>
      resolveEntryRates(
        id,
        rate: purchase ? null : rate,
        purchase: purchase ? rate : null,
      );

  Future<void> resolveEntryRates(String id, {int? rate, int? purchase}) =>
      db.transaction(() async {
        final data = await snapshot();
        final entry = data.entries.where((e) => e.id == id).firstOrNull;
        if (entry == null ||
            !entry.isRateBearing ||
            entry.isTransfer ||
            entry.voided ||
            (rate == null && purchase == null) ||
            (purchase != null && !(entry.cropPricing && entry.isDirect))) {
          throw const DomainFailure('entryImmutable');
        }
        if ((rate != null && !entry.ratePending) ||
            (purchase != null && !entry.purchaseRatePending)) {
          requireOwner();
        }
        var updated = entry;
        if (rate != null) updated = updated.withRate(rate);
        if (purchase != null) updated = updated.withPurchaseRate(purchase);
        final other = LedgerEngine(data.entries.where((e) => e.id != id));
        other.validate(
          updated,
          products: data.products,
          people: data.people,
          godams: data.godams,
          checkStock: false,
        );
        await _put('entries', id, updated.toJson());
      });
  Future<void> voidEntry(String id) => db.transaction(() async {
    requireOwner();
    final data = await snapshot();
    final entry = data.entries.where((e) => e.id == id).firstOrNull;
    if (entry == null) throw const DomainFailure('entryImmutable');
    final after = LedgerEngine(data.entries.where((e) => e.id != id));
    for (final lot in after.stockLots().where((l) => l.quantity < -.000001)) {
      final previous =
          data.ledger
              .stockLots()
              .where(
                (l) =>
                    l.itemId == lot.itemId &&
                    l.location == lot.location &&
                    l.batch == lot.batch &&
                    l.expiry == lot.expiry,
              )
              .firstOrNull
              ?.quantity ??
          0;
      if (lot.quantity < previous - .000001) {
        throw const DomainFailure('insufficientStock');
      }
    }
    await _put('entries', id, entry.voidEntry().toJson());
  });
  Future<void> saveRate(Product item, int purchase, int sale) =>
      db.transaction(() async {
        final current = (await snapshot()).products
            .where((p) => p.id == item.id)
            .firstOrNull;
        if (current == null || purchase < 0 || sale < 0) {
          throw const DomainFailure('invalidAmount');
        }
        EntityValidator.product(
          Product.fromJson(
            current.toJson()
              ..['purchasePaise'] = purchase
              ..['salePaise'] = sale,
          ),
        );
        final rateId = uuid.v4();
        await _put(
          'rates',
          rateId,
          RateRecord(
            id: rateId,
            itemId: item.id,
            date: DateTime.now(),
            purchasePaise: purchase,
            salePaise: sale,
          ).toJson(),
        );
        await _put(
          'products',
          item.id,
          current.toJson()
            ..['purchasePaise'] = purchase
            ..['salePaise'] = sale,
        );
      });
  void requireOwner() {
    if (role != AppRole.owner) throw const DomainFailure('ownerOnly');
  }

  Future<void> mergeRemote(RecordEnvelope remote) => db.transaction(() async {
    if (remote.shopId != shopId || !entities.contains(remote.entity)) {
      throw const DomainFailure('invalidBackup');
    }
    final current =
        await (db.select(db.documents)..where(
              (d) =>
                  d.shopId.equals(shopId) &
                  d.entity.equals(remote.entity) &
                  d.id.equals(remote.id),
            ))
            .getSingleOrNull();
    if (current == null || remote.newerThan(envelope(current))) {
      await db
          .into(db.documents)
          .insertOnConflictUpdate(
            DocumentsCompanion.insert(
              shopId: shopId,
              entity: remote.entity,
              id: remote.id,
              payload: jsonEncode(remote.payload),
              updatedAt: remote.updatedAt,
              deviceId: remote.deviceId,
              deleted: Value(remote.deleted),
            ),
          );
      await (db.delete(db.outbox)..where(
            (o) =>
                o.shopId.equals(shopId) &
                o.entity.equals(remote.entity) &
                o.id.equals(remote.id) &
                o.updatedAt.isSmallerOrEqualValue(remote.updatedAt),
          ))
          .go();
    }
  });
  Future<List<RecordEnvelope>> pending() async {
    final rows = await (db.select(
      db.outbox,
    )..where((o) => o.shopId.equals(shopId))).get();
    final result = <RecordEnvelope>[];
    for (final row in rows) {
      final document =
          await (db.select(db.documents)..where(
                (d) =>
                    d.shopId.equals(shopId) &
                    d.entity.equals(row.entity) &
                    d.id.equals(row.id),
              ))
              .getSingleOrNull();
      if (document != null) result.add(envelope(document));
    }
    // Restores and concurrent local edits can insert an entry before its
    // catalog dependencies in the outbox. Firestore validates references.
    const order = {
      'people': 0,
      'products': 1,
      'godams': 2,
      'rates': 3,
      'entries': 4,
    };
    result.sort((a, b) => order[a.entity]!.compareTo(order[b.entity]!));
    return result;
  }

  Future<void> acknowledge(RecordEnvelope sent) async {
    await (db.delete(db.outbox)..where(
          (o) =>
              o.shopId.equals(shopId) &
              o.entity.equals(sent.entity) &
              o.id.equals(sent.id) &
              o.updatedAt.equals(sent.updatedAt) &
              o.deviceId.equals(sent.deviceId),
        ))
        .go();
  }

  Future<String> backup() async {
    requireOwner();
    return jsonEncode({
      'format': 'pestikhata',
      'version': 1,
      'shopId': shopId,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'records': (await snapshot()).records.map((r) => r.toJson()).toList(),
    });
  }

  Future<void> restore(String content) async {
    requireOwner();
    Json json;
    List<RecordEnvelope> records;
    try {
      json = jsonDecode(content) as Json;
      if (json['format'] != 'pestikhata' ||
          json['version'] != 1 ||
          json['shopId'] != shopId) {
        throw const DomainFailure('invalidBackup');
      }
      records = (json['records'] as List)
          .map((r) => RecordEnvelope.fromJson(r as Json))
          .toList();
      if (records.length > 100000 ||
          records.any(
            (r) =>
                r.shopId != shopId ||
                !entities.contains(r.entity) ||
                r.payload['id'] != r.id,
          )) {
        throw const DomainFailure('invalidBackup');
      }
      final active = ShopSnapshot(records);
      final keys = records.map((r) => '${r.entity}/${r.id}').toSet();
      if (keys.length != records.length ||
          records.any((r) => r.entity == 'entries' && r.deleted)) {
        throw const DomainFailure('invalidBackup');
      }
      for (final person in active.people) {
        EntityValidator.person(person);
      }
      for (final product in active.products) {
        EntityValidator.product(product);
      }
      for (final godam in active.godams) {
        EntityValidator.godam(godam);
      }
      for (final entry in active.entries) {
        active.ledger.validate(
          entry,
          products: active.products,
          people: active.people,
          godams: active.godams,
          checkStock: false,
        );
      }
      for (final rate in active.rates) {
        if (!active.products.any((p) => p.id == rate.itemId) ||
            rate.purchasePaise < 0 ||
            rate.salePaise < 0) {
          throw const DomainFailure('invalidBackup');
        }
      }
    } catch (_) {
      throw const DomainFailure('invalidBackup');
    }
    await db.transaction(() async {
      // Merge the backup rather than deleting newer local work. Restored records
      // get a new version so every restored write is also placed in the outbox.
      final existing = (await snapshot()).records;
      for (final record in records) {
        final local = existing
            .where((r) => r.id == record.id && r.entity == record.entity)
            .firstOrNull;
        if (local == null || record.newerThan(local)) {
          await _put(
            record.entity,
            record.id,
            record.payload,
            deleted: record.deleted,
          );
        }
      }
    });
  }
}
