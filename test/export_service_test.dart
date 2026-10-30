import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pestikhata/features/export/data/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline PDF export paginates a ledger beyond twenty pages', () async {
    final bytes = await ExportService.pdf(
      ExportTable(
        title: 'Farmer khata',
        subtitle: 'PestiKhata · Muhammad Ali',
        headers: ['Date', 'Description', 'Amount', 'Balance'],
        rows: List.generate(
          1400,
          (i) => [
            '2026-10-30',
            'Wheat receipt $i',
            'Rs 1,250.50',
            'Rs 25,000.00',
          ],
        ),
        footer: 'Balance: Rs 25,000.00',
      ),
    );
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    final content = latin1.decode(bytes);
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(content).length,
      greaterThan(20),
    );
    expect(content, contains('%%EOF'));
  });
}
