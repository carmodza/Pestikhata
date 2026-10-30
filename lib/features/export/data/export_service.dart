import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportTable {
  const ExportTable({
    required this.title,
    required this.subtitle,
    required this.headers,
    required this.rows,
    this.footer = '',
  });
  final String title, subtitle, footer;
  final List<String> headers;
  final List<List<String>> rows;
}

abstract final class ExportService {
  static Future<Uint8List> pdf(ExportTable table) async {
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final doc = pw.Document(
      title: table.title,
      author: 'PestiKhata',
      creator: 'PestiKhata',
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
      ),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: table.headers.length > 6
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4,
        // Long shop ledgers must not fail at MultiPage's default 20 pages.
        maxPages: table.rows.length + 2,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PestiKhata',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.green800),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              table.title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(table.subtitle),
            pw.SizedBox(height: 18),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Text(table.footer)),
            pw.SizedBox(width: 12),
            pw.Text('${context.pageNumber} / ${context.pagesCount}'),
          ],
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: table.headers,
            data: table.rows.isEmpty
                ? [List.filled(table.headers.length, '-')]
                : table.rows,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(7),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> sharePdf(ExportTable table, String filename) async =>
      Printing.sharePdf(bytes: await pdf(table), filename: filename);
  static Future<void> excel(ExportTable table, String filename) async {
    final book = Excel.createExcel();
    final sheet = book['PestiKhata'];
    book.delete('Sheet1');
    sheet.appendRow([TextCellValue(table.title)]);
    sheet.appendRow([TextCellValue(table.subtitle)]);
    sheet.appendRow(table.headers.map((s) => TextCellValue(s)).toList());
    for (final row in table.rows) {
      sheet.appendRow(row.map((s) => TextCellValue(s)).toList());
    }
    sheet.appendRow([TextCellValue(table.footer)]);
    final bytes = Uint8List.fromList(book.encode()!);
    await FilePicker.platform.saveFile(
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      bytes: bytes,
    );
  }
}
