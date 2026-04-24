import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyPdfExporter {
  static Future<void> previewMonthlyReport({
    required BuildContext context,
    required DateTime month,
    required String userName,
    required int incomeCents,
    required int expenseCents,
    required List<Map<String, Object?>> byCategory,
  }) async {
    final bytes = await buildMonthlyReportBytes(
      month: month,
      userName: userName,
      incomeCents: incomeCents,
      expenseCents: expenseCents,
      byCategory: byCategory,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename:
      'sandokti_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List> buildMonthlyReportBytes({
    required DateTime month,
    required String userName,
    required int incomeCents,
    required int expenseCents,
    required List<Map<String, Object?>> byCategory,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('sandokti PDF ✅', style: pw.TextStyle(fontSize: 22)),
              pw.SizedBox(height: 10),
              pw.Text('User: $userName'),
              pw.Text('Income: $incomeCents'),
              pw.Text('Expense: $expenseCents'),
              pw.Text('Rows: ${byCategory.length}'),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }
}