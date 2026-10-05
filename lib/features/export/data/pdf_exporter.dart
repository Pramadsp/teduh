import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:teduh/core/utils/formatters.dart';
import 'package:teduh/features/transactions/domain/transaction_model.dart';

class PdfReportExporter {
  static Future<File> generatePdf({
    required String periodTitle,
    required List<Transaction> transactions,
    required int totalIncome,
    required int totalExpense,
    required int balance,
    required Map<String, int> categoryTotals,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('4A6B50'); // Sage Dark
    final textColor = PdfColor.fromHex('2F3A32'); // Ink
    final creamColor = PdfColor.fromHex('FAF6EE');
    final incomeColor = PdfColor.fromHex('4F8A5B');
    final expenseColor = PdfColor.fromHex('C0583F');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TEDUH - Laporan Keuangan',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    periodTitle,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: primaryColor, thickness: 1.5),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: textColor),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Ringkasan Keuangan Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: creamColor,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: primaryColor, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Total Pemasukan', style: pw.TextStyle(fontSize: 10, color: textColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        CurrencyUtils.formatRupiah(totalIncome),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: incomeColor),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Total Pengeluaran', style: pw.TextStyle(fontSize: 10, color: textColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        CurrencyUtils.formatRupiah(totalExpense),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: expenseColor),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Saldo Netto', style: pw.TextStyle(fontSize: 10, color: textColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        CurrencyUtils.formatRupiah(balance),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: balance >= 0 ? incomeColor : expenseColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Rincian per Kategori
            if (categoryTotals.isNotEmpty) ...[
              pw.Text(
                'Rincian Pengeluaran per Kategori',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellHeight: 24,
                cellStyle: pw.TextStyle(fontSize: 9, color: textColor),
                headers: ['Kategori', 'Total Pengeluaran'],
                data: categoryTotals.entries.map((e) {
                  return [e.key, CurrencyUtils.formatRupiah(e.value)];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Tabel Daftar Transaksi
            pw.Text(
              'Daftar Transaksi',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellHeight: 22,
              cellStyle: pw.TextStyle(fontSize: 8, color: textColor),
              headers: ['Tanggal', 'Nama Transaksi', 'Jenis', 'Kategori', 'Grup / Tempat', 'Catatan', 'Pencatat', 'Nominal'],
              data: transactions.map((tx) {
                final isIncome = tx.type == TransactionType.income;
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(tx.date);
                final typeStr = isIncome ? 'Pemasukan' : 'Pengeluaran';
                final amountStr = '${isIncome ? '+' : '-'} ${CurrencyUtils.formatRupiah(tx.amount)}';

                return [
                  dateStr,
                  tx.title,
                  typeStr,
                  tx.categoryName,
                  tx.groupName ?? '-',
                  tx.note ?? '-',
                  tx.createdByName,
                  amountStr,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final fileName = 'laporan_teduh_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
