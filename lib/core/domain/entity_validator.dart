import 'models.dart';

abstract final class EntityValidator {
  static void person(Person value) {
    if (value.name.trim().isEmpty ||
        value.name.length > 300 ||
        value.phone.length > 40 ||
        value.village.length > 300 ||
        value.crops.length > 1000 ||
        value.acres < 0 ||
        !value.acres.isFinite ||
        (value.kind != PartyKind.farmer && value.kind != PartyKind.supplier)) {
      throw const DomainFailure('invalidPerson');
    }
  }

  static void product(Product value) {
    if (value.name.trim().isEmpty ||
        value.name.length > 300 ||
        value.units.isEmpty ||
        value.units.length > 30 ||
        value.units[value.baseUnit] != 1 ||
        value.units.entries.any(
          (u) =>
              u.key.trim().isEmpty ||
              u.key.length > 50 ||
              !u.value.isFinite ||
              u.value <= 0 ||
              u.value > 1000000000,
        ) ||
        value.lowStock < 0 ||
        !value.lowStock.isFinite ||
        value.purchasePaise < 0 ||
        value.salePaise < 0 ||
        value.purchasePaise > 9000000000000 ||
        value.salePaise > 9000000000000 ||
        (value.kind != EntryKind.product && value.kind != EntryKind.crop)) {
      throw const DomainFailure('invalidProduct');
    }
  }

  static void godam(Godam value) {
    if (value.name.trim().isEmpty ||
        value.name.length > 300 ||
        value.address.length > 1000) {
      throw const DomainFailure('requiredField');
    }
  }
}
