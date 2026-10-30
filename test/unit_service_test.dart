import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/core/domain/models.dart';
import 'package:pestikhata/features/catalog/application/unit_service.dart';

void main() {
  test('crop bori weight is per crop while maan stays forty kg', () {
    for (final weight in [40, 50, 100]) {
      final units = UnitService.parse(
        kind: EntryKind.crop,
        baseUnit: 'kg',
        boriWeight: '$weight',
        conversions: '',
      );
      expect(units['maan'], 40);
      expect(units['bori'], weight);
      expect(units['ton'], 1000);
    }
  });
  test(
    'product conversions reject ambiguous duplicates and nonfinite weights',
    () {
      for (final input in [
        'carton=12, carton=24',
        'piece=10',
        'carton=NaN',
        'carton=Infinity',
        'carton=-1',
        'carton=0',
        'carton=12=24',
      ]) {
        expect(
          () => UnitService.parse(
            kind: EntryKind.product,
            baseUnit: 'piece',
            boriWeight: '',
            conversions: input,
          ),
          throwsA(isA<DomainFailure>()),
        );
      }
      expect(
        UnitService.parse(
          kind: EntryKind.product,
          baseUnit: 'piece',
          boriWeight: '',
          conversions: 'carton=12, dozen=12',
        ),
        {'piece': 1, 'carton': 12, 'dozen': 12},
      );
    },
  );
}
