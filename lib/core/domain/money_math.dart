/// Decimal multiplication with half-up rounding, without binary-double money
/// arithmetic. The quantity is interpreted using its canonical decimal string.
int multiplyMoney(double quantity, int unitPaise) {
  if (!quantity.isFinite || quantity < 0 || unitPaise < 0) {
    throw ArgumentError('Invalid monetary operands');
  }
  final exponentParts = quantity.toString().toLowerCase().split('e');
  final decimalParts = exponentParts[0].split('.');
  final fraction = decimalParts.length == 2 ? decimalParts[1] : '';
  final scale =
      fraction.length -
      (exponentParts.length == 2 ? int.parse(exponentParts[1]) : 0);
  final numerator =
      BigInt.parse('${decimalParts[0]}$fraction') * BigInt.from(unitPaise);
  if (scale <= 0) return (numerator * BigInt.from(10).pow(-scale)).toInt();
  final divisor = BigInt.from(10).pow(scale);
  return ((numerator + divisor ~/ BigInt.two) ~/ divisor).toInt();
}
