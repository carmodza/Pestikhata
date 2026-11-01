import '../../../core/data/shop_repository.dart';
import '../../../core/domain/models.dart';
import '../../../core/domain/money_math.dart';
import '../../ledger/domain/ledger_engine.dart';

class EntryInput {
  EntryKind kind = EntryKind.product;
  Endpoint source = const Endpoint(PartyKind.inventory);
  Endpoint destination = const Endpoint(PartyKind.farmer);
  DateTime date = DateTime.now();
  Product? product;
  DateTime? expiry;
  String title = '',
      note = '',
      batch = ShopRepository.newBatch(DateTime.now()),
      unit = 'piece',
      quantity = '1',
      rate = '0',
      purchase = '0',
      sale = '0',
      cash = '0',
      amount = '0',
      expenseCategory = 'other';
  bool ratePending = false;
  bool purchaseRatePending = false;
  bool get isDirect => source.person && destination.person;
  bool get isTransfer => source.internal && destination.internal;
  bool get cropPurchase =>
      kind == EntryKind.crop && !source.internal && !isTransfer;
  bool get cropSale =>
      kind == EntryKind.crop && !destination.internal && !isTransfer;
  bool get cropPurchasePending =>
      cropPurchase && (isDirect ? purchaseRatePending : ratePending);
  bool get receivingProduct =>
      kind == EntryKind.product && !source.internal && destination.internal;
  bool get salePricing => source.internal || isDirect;
  bool get isRateBearing =>
      kind == EntryKind.product ||
      kind == EntryKind.crop ||
      kind == EntryKind.diesel;
}

class EntryService {
  const EntryService(this.repository);
  final ShopRepository repository;
  static void changeEndpoint(EntryInput input, bool source, Endpoint endpoint) {
    final wasPurchasePending = input.cropPurchase && input.cropPurchasePending;
    final wasSalePending = input.cropSale && input.ratePending;
    final wasSale = input.salePricing;
    if (source) {
      input.source = endpoint;
    } else {
      input.destination = endpoint;
    }
    // Changing a person or storage location must not discard an edited price.
    if (input.kind == EntryKind.crop || wasSale != input.salePricing) {
      input.rate = input.salePricing ? input.sale : input.purchase;
    }
    if (input.kind == EntryKind.crop) {
      input.purchaseRatePending = input.isDirect && wasPurchasePending;
      input.ratePending = input.salePricing
          ? wasSalePending
          : wasPurchasePending;
    }
    if (input.source.internal && input.destination.internal) {
      input.ratePending = false;
      input.purchaseRatePending = false;
      input.cash = '0';
    }
  }

  static JournalEntry preview(EntryInput input, {String id = 'preview'}) {
    final quantity = double.tryParse(input.quantity) ?? 0;
    final isAmount =
        input.kind == EntryKind.cash || input.kind == EntryKind.other;
    final amount = isAmount ? parseMoney(input.amount) : 0;
    final crop = input.kind == EntryKind.crop;
    final rate = crop
        ? (input.cropSale ? input.sale : input.purchase)
        : input.rate;
    return JournalEntry(
      id: id,
      kind: input.kind,
      source: input.source,
      destination: input.destination,
      date: input.date,
      itemId: input.product?.id,
      title: input.product?.name ?? input.title.trim(),
      note: input.note.trim(),
      batch: input.receivingProduct ? input.batch.trim() : '',
      expiry: input.receivingProduct ? input.expiry : null,
      quantity: quantity,
      unit: input.kind == EntryKind.diesel ? 'liter' : input.unit,
      unitFactor: input.product?.units[input.unit] ?? 1,
      ratePaise: isAmount || input.ratePending || input.isTransfer
          ? 0
          : parseMoney(rate),
      purchasePaise: crop && (input.isTransfer || input.cropPurchasePending)
          ? 0
          : parseMoney(input.purchase),
      salePaise: crop && (!input.cropSale || input.ratePending)
          ? 0
          : parseMoney(input.sale),
      cashPaise: input.kind == EntryKind.other
          ? amount
          : input.kind == EntryKind.cash
          ? 0
          : parseMoney(input.cash),
      amountPaise: amount,
      ratePending: input.ratePending,
      cropPricing: crop,
      purchaseRatePending: crop && input.isDirect && input.purchaseRatePending,
      expenseCategory: input.expenseCategory,
    );
  }

  Future<void> save(EntryInput input) =>
      repository.saveEntry(preview(input, id: ShopRepository.uuid.v4()));
  static void selectProduct(EntryInput input, Product product) {
    if (input.product?.id != product.id) input.expiry = null;
    input.product = product;
    input.unit =
        product.kind == EntryKind.crop && product.units.containsKey('maan')
        ? 'maan'
        : product.baseUnit;
    applyUnit(input);
  }

  static void applyUnit(EntryInput input) {
    final product = input.product;
    if (product == null) return;
    final factor = product.units[input.unit] ?? 1;
    input.purchase = moneyInput(multiplyMoney(factor, product.purchasePaise));
    input.sale = moneyInput(multiplyMoney(factor, product.salePaise));
    input.rate = input.salePricing ? input.sale : input.purchase;
  }

  static void changeUnit(EntryInput input, String unit) {
    final units = input.product?.units;
    final factor = (units?[unit] ?? 1) / (units?[input.unit] ?? 1);
    String converted(String text) {
      try {
        return moneyInput(multiplyMoney(factor, parseMoney(text)));
      } on DomainFailure {
        // A blank/incomplete price remains editable when the unit changes.
        return '';
      }
    }

    input.purchase = converted(input.purchase);
    input.sale = converted(input.sale);
    input.rate = converted(input.rate);
    input.unit = unit;
  }

  static void editPrice(EntryInput input, String field, String value) {
    if (field == 'purchase') input.purchase = value;
    if (field == 'sale') input.sale = value;
    if ((field == 'sale' && input.salePricing) ||
        (field == 'purchase' && !input.salePricing)) {
      input.rate = value;
    }
  }

  static void selectPaymentPerson(
    EntryInput input,
    Person person,
    bool receiving,
  ) {
    input.source = receiving
        ? Endpoint(person.kind, person.id)
        : const Endpoint(PartyKind.inventory);
    input.destination = receiving
        ? const Endpoint(PartyKind.inventory)
        : Endpoint(person.kind, person.id);
  }
}
