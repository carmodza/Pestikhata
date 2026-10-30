import 'dart:convert';

import 'money_math.dart';

enum EntryKind { cash, product, crop, diesel, other }

enum PartyKind { farmer, supplier, godam, inventory, walkIn }

enum AppRole { owner, staff }

enum EntryDirection { incoming, outgoing, direct, transfer }

class DomainFailure implements Exception {
  const DomainFailure(this.code);
  final String code;
  @override
  String toString() => code;
}

typedef Json = Map<String, dynamic>;

String calendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class Endpoint {
  const Endpoint(this.kind, [this.id]);
  final PartyKind kind;
  final String? id;
  bool get internal => kind == PartyKind.inventory || kind == PartyKind.godam;
  bool get person => kind == PartyKind.farmer || kind == PartyKind.supplier;
  String get stockKey => kind == PartyKind.inventory ? 'inventory' : id!;
  Json toJson() => {'kind': kind.name, 'id': id};
  factory Endpoint.fromJson(Json j) => Endpoint(
    PartyKind.values.byName(j['kind'] as String),
    j['id'] as String?,
  );
  bool sameAs(Endpoint other) => kind == other.kind && id == other.id;
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.kind,
    this.phone = '',
    this.village = '',
    this.acres = 0,
    this.crops = '',
  });
  final String id, name, phone, village, crops;
  final PartyKind kind;
  final double acres;
  Json toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'phone': phone,
    'village': village,
    'acres': acres,
    'crops': crops,
  };
  factory Person.fromJson(Json j) => Person(
    id: j['id'],
    name: j['name'],
    kind: PartyKind.values.byName(j['kind']),
    phone: j['phone'] ?? '',
    village: j['village'] ?? '',
    acres: (j['acres'] as num?)?.toDouble() ?? 0,
    crops: j['crops'] ?? '',
  );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    this.company = '',
    this.crop = '',
    this.pest = '',
    this.kind = EntryKind.product,
    this.baseUnit = 'piece',
    this.units = const {'piece': 1},
    this.lowStock = 5,
    this.purchasePaise = 0,
    this.salePaise = 0,
  });
  final String id, name, company, crop, pest, baseUnit;
  final EntryKind kind;

  /// Multipliers convert an entry unit to the item's base unit.
  final Map<String, double> units;
  final double lowStock;
  final int purchasePaise, salePaise;
  Json toJson() => {
    'id': id,
    'name': name,
    'company': company,
    'crop': crop,
    'pest': pest,
    'kind': kind.name,
    'baseUnit': baseUnit,
    'units': units,
    'lowStock': lowStock,
    'purchasePaise': purchasePaise,
    'salePaise': salePaise,
  };
  factory Product.fromJson(Json j) => Product(
    id: j['id'],
    name: j['name'],
    company: j['company'] ?? '',
    crop: j['crop'] ?? '',
    pest: j['pest'] ?? '',
    kind: EntryKind.values.byName(j['kind']),
    baseUnit: j['baseUnit'],
    units: (j['units'] as Map).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    ),
    lowStock: (j['lowStock'] as num).toDouble(),
    purchasePaise: j['purchasePaise'] ?? 0,
    salePaise: j['salePaise'] ?? 0,
  );
}

class Godam {
  const Godam({required this.id, required this.name, this.address = ''});
  final String id, name, address;
  Json toJson() => {'id': id, 'name': name, 'address': address};
  factory Godam.fromJson(Json j) =>
      Godam(id: j['id'], name: j['name'], address: j['address'] ?? '');
}

class StockAllocation {
  const StockAllocation({
    required this.batch,
    required this.quantity,
    this.expiry,
  });
  final String batch;
  final double quantity;
  final DateTime? expiry;
  Json toJson() => {
    'batch': batch,
    'quantity': quantity,
    'expiry': expiry == null ? null : calendarDate(expiry!),
  };
  factory StockAllocation.fromJson(Json j) => StockAllocation(
    batch: j['batch'] as String,
    quantity: (j['quantity'] as num).toDouble(),
    expiry: j['expiry'] == null ? null : DateTime.parse(j['expiry'] as String),
  );
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.kind,
    required this.source,
    required this.destination,
    required this.date,
    this.itemId,
    this.title = '',
    this.note = '',
    this.batch = '',
    this.expiry,
    this.quantity = 1,
    this.unit = 'piece',
    this.unitFactor = 1,
    this.ratePaise = 0,
    this.purchasePaise = 0,
    this.salePaise = 0,
    this.cashPaise = 0,
    this.amountPaise = 0,
    this.ratePending = false,
    this.expenseCategory = 'other',
    this.createdBy = '',
    this.createdAt = 0,
    this.voided = false,
    this.allocations = const [],
  });
  final String id, title, note, batch, unit, expenseCategory, createdBy;
  final int createdAt;
  final String? itemId;
  final EntryKind kind;
  final Endpoint source, destination;
  final DateTime date;
  final DateTime? expiry;
  final double quantity, unitFactor;
  final int ratePaise, purchasePaise, salePaise, cashPaise, amountPaise;
  final bool ratePending, voided;
  final List<StockAllocation> allocations;
  bool get hasStock => kind == EntryKind.product || kind == EntryKind.crop;
  bool get isRateBearing => hasStock || kind == EntryKind.diesel;
  bool get isTransfer => source.internal && destination.internal;
  bool get isDirect => source.person && destination.person;
  bool get isStockReceipt =>
      hasStock && !source.internal && destination.internal;
  EntryDirection get direction => isDirect
      ? EntryDirection.direct
      : isTransfer
      ? EntryDirection.transfer
      : destination.internal
      ? EntryDirection.incoming
      : EntryDirection.outgoing;
  List<StockAllocation> get stockMovements => allocations.isNotEmpty
      ? allocations
      : [StockAllocation(batch: batch, quantity: baseQuantity, expiry: expiry)];
  int get totalPaise => ratePending || isTransfer
      ? 0
      : (kind == EntryKind.cash || kind == EntryKind.other
            ? amountPaise
            : multiplyMoney(quantity, ratePaise));
  int get creditPaise => kind == EntryKind.cash ? 0 : totalPaise - cashPaise;
  double get baseQuantity => quantity * unitFactor;
  int get cashDelta {
    if (isTransfer || isDirect) return 0;
    if (kind == EntryKind.cash) {
      return amountPaise * (destination.internal ? 1 : -1);
    }
    if (kind == EntryKind.other || kind == EntryKind.diesel) return -cashPaise;
    return cashPaise * (source.internal ? 1 : -1);
  }

  int get cashInPaise => isDirect
      ? (kind == EntryKind.cash ? amountPaise : cashPaise)
      : (cashDelta > 0 ? cashDelta : 0);
  int get cashOutPaise => isDirect
      ? (kind == EntryKind.cash ? amountPaise : cashPaise)
      : (cashDelta < 0 ? -cashDelta : 0);

  bool get isSale =>
      hasStock &&
      (source.internal || isDirect) &&
      !destination.internal &&
      destination.kind != PartyKind.supplier;
  Json toJson() => {
    'id': id,
    'kind': kind.name,
    'source': source.toJson(),
    'destination': destination.toJson(),
    'date': calendarDate(date),
    'itemId': itemId,
    'title': title,
    'note': note,
    'batch': batch,
    'expiry': expiry == null ? null : calendarDate(expiry!),
    'quantity': quantity,
    'unit': unit,
    'unitFactor': unitFactor,
    'ratePaise': ratePaise,
    'purchasePaise': purchasePaise,
    'salePaise': salePaise,
    'cashPaise': cashPaise,
    'amountPaise': amountPaise,
    'ratePending': ratePending,
    'expenseCategory': expenseCategory,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'voided': voided,
    if (allocations.isNotEmpty)
      'allocations': allocations.map((a) => a.toJson()).toList(),
  };
  factory JournalEntry.fromJson(Json j) => JournalEntry(
    id: j['id'],
    kind: EntryKind.values.byName(j['kind']),
    source: Endpoint.fromJson(j['source']),
    destination: Endpoint.fromJson(j['destination']),
    date: DateTime.parse(j['date']).toLocal(),
    itemId: j['itemId'],
    title: j['title'] ?? '',
    note: j['note'] ?? '',
    batch: j['batch'] ?? '',
    expiry: j['expiry'] == null ? null : DateTime.parse(j['expiry']).toLocal(),
    quantity: (j['quantity'] as num).toDouble(),
    unit: j['unit'],
    unitFactor: (j['unitFactor'] as num).toDouble(),
    ratePaise: j['ratePaise'],
    purchasePaise: j['purchasePaise'],
    salePaise: j['salePaise'],
    cashPaise: j['cashPaise'],
    amountPaise: j['amountPaise'],
    ratePending: j['ratePending'],
    expenseCategory: j['expenseCategory'],
    createdBy: j['createdBy'] ?? '',
    createdAt: j['createdAt'] ?? 0,
    voided: j['voided'] ?? false,
    allocations: ((j['allocations'] ?? []) as List)
        .map((a) => StockAllocation.fromJson(Map<String, dynamic>.from(a)))
        .toList(),
  );
  JournalEntry withRate(int rate) {
    final json = toJson()
      ..['ratePaise'] = rate
      ..['ratePending'] = false;
    return JournalEntry.fromJson(json);
  }

  JournalEntry voidEntry() =>
      JournalEntry.fromJson(toJson()..['voided'] = true);
}

class RateRecord {
  const RateRecord({
    required this.id,
    required this.itemId,
    required this.date,
    required this.purchasePaise,
    required this.salePaise,
  });
  final String id, itemId;
  final DateTime date;
  final int purchasePaise, salePaise;
  Json toJson() => {
    'id': id,
    'itemId': itemId,
    'date': date.toUtc().toIso8601String(),
    'purchasePaise': purchasePaise,
    'salePaise': salePaise,
  };
  factory RateRecord.fromJson(Json j) => RateRecord(
    id: j['id'],
    itemId: j['itemId'],
    date: DateTime.parse(j['date']).toLocal(),
    purchasePaise: j['purchasePaise'],
    salePaise: j['salePaise'],
  );
}

class RecordEnvelope {
  const RecordEnvelope({
    required this.id,
    required this.entity,
    required this.shopId,
    required this.payload,
    required this.updatedAt,
    required this.deviceId,
    this.deleted = false,
  });
  final String id, entity, shopId, deviceId;
  final Json payload;

  /// UTC microseconds plus device ID form a deterministic LWW ordering.
  final int updatedAt;
  final bool deleted;
  Json toJson() => {
    'id': id,
    'entity': entity,
    'shopId': shopId,
    'payload': payload,
    'updatedAt': updatedAt,
    'deviceId': deviceId,
    'deleted': deleted,
  };
  factory RecordEnvelope.fromJson(Json j) => RecordEnvelope(
    id: j['id'],
    entity: j['entity'],
    shopId: j['shopId'],
    payload: Map<String, dynamic>.from(j['payload']),
    updatedAt: j['updatedAt'],
    deviceId: j['deviceId'],
    deleted: j['deleted'] ?? false,
  );
  bool newerThan(RecordEnvelope other) =>
      updatedAt > other.updatedAt ||
      (updatedAt == other.updatedAt && deviceId.compareTo(other.deviceId) > 0);
  String encode() => jsonEncode(toJson());
}
