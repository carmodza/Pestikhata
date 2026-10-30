import '../../../core/domain/models.dart';

/// Converts catalog form values into validated stock unit multipliers.
abstract final class UnitService {
  static Map<String, double> parse({
    required EntryKind kind,
    required String baseUnit,
    required String boriWeight,
    required String conversions,
  }) {
    if (kind == EntryKind.crop) {
      final weight = double.tryParse(boriWeight.trim());
      if (baseUnit != 'kg' || !_valid(weight)) {
        throw const DomainFailure('invalidUnit');
      }
      return {
        'kg': 1,
        'maan': 40,
        'quintal': 100,
        'ton': 1000,
        'bori': weight!,
      };
    }
    final units = <String, double>{baseUnit: 1};
    if (conversions.trim().isEmpty) return units;
    for (final pair in conversions.split(',')) {
      final values = pair.trim().split('=');
      if (values.length != 2) throw const DomainFailure('invalidUnit');
      final key = values[0].trim(), value = double.tryParse(values[1].trim());
      if (key.isEmpty ||
          key.length > 50 ||
          units.containsKey(key) ||
          !_valid(value)) {
        throw const DomainFailure('invalidUnit');
      }
      units[key] = value!;
    }
    if (units.length > 30) throw const DomainFailure('invalidUnit');
    return units;
  }

  static bool _valid(double? value) =>
      value != null && value.isFinite && value > 0 && value <= 1000000000;
}
