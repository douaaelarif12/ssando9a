import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/budget/data/datasources/firestore/budget_firestore_datasource.dart';
import '../../features/budget/data/models/transaction_model.dart';

class PdfService {
  static Future<void> generateMonthlyReport({
required BudgetFirestoreDatasource ds,
  }) async {
    final now = DateTime.now();

    final incomeCents = await ds.getMonthlyIncomeTotalCents(now.year, now.month);
    final expenseCents = await ds.getMonthlyExpenseCents(now.year, now.month);
    final balanceCents = incomeCents - expenseCents;
    final transactions = await ds.getTransactionsForMonth(now.year, now.month);

    final pdf = pw.Document();
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(now);

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Rapport Budget Sandokti',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Période : $monthLabel'),
          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Résumé du mois',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Revenus : ${_formatMoney(incomeCents)}'),
                pw.Text('Dépenses : ${_formatMoney(expenseCents)}'),
                pw.Text('Solde : ${_formatMoney(balanceCents)}'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text(
            'Transactions du mois',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          if (transactions.isEmpty)
            pw.Text('Aucune transaction pour ce mois.')
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(),
              cellAlignment: pw.Alignment.centerLeft,
              headers: const ['Date', 'Type', 'Titre', 'Montant'],
              data: transactions.map((t) {
                return [
                  _formatDate(t.occurredAt),
                  _typeLabel(t.type),
                  t.title,
                  _signedAmount(t),
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static String _formatMoney(int cents) {
    final value = cents / 100;
    return '${value.toStringAsFixed(2)} DH';
  }

  static String _formatDate(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Prime';
      case 'saving':
        return 'Épargne';
      case 'expense':
      default:
        return 'Dépense';
    }
  }

  static String _signedAmount(TransactionModel t) {
    final sign = t.type == 'expense' ? '-' : '+';
    return '$sign${_formatMoney(t.amountCents)}';
  }
}