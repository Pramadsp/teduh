import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teduh/features/transactions/domain/transaction_model.dart';

class ExcelReportExporter {
  static Future<File> generateExcel({
    required String periodTitle,
    required List<Transaction> transactions,
    required int totalIncome,
    required int totalExpense,
    required int balance,
    required Map<String, int> categoryTotals,
  }) async {
    final excel = Excel.createExcel();

    // Sheet 1: Ringkasan
    final Sheet summarySheet = excel['Ringkasan'];
    excel.setDefaultSheet('Ringkasan');

    // Header Ringkasan
    summarySheet.appendRow([
      TextCellValue('TEDUH - LAPORAN KEUANGAN KELUARGA'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Periode: $periodTitle'),
    ]);
    summarySheet.appendRow([]); // Spacer

    summarySheet.appendRow([
      TextCellValue('Ringkasan Total'),
      TextCellValue('Nominal (IDR)'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Pemasukan'),
      IntCellValue(totalIncome),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Pengeluaran'),
      IntCellValue(totalExpense),
    ]);
    summarySheet.appendRow([
      TextCellValue('Saldo Netto'),
      IntCellValue(balance),
    ]);

    summarySheet.appendRow([]); // Spacer
    summarySheet.appendRow([
      TextCellValue('Rincian Pengeluaran per Kategori'),
      TextCellValue('Total (IDR)'),
    ]);

    categoryTotals.forEach((category, amount) {
      summarySheet.appendRow([
        TextCellValue(category),
        IntCellValue(amount),
      ]);
    });

    // Sheet 2: Transaksi
    final Sheet transactionSheet = excel['Daftar Transaksi'];

    transactionSheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Nama Transaksi'),
      TextCellValue('Jenis'),
      TextCellValue('Kategori'),
      TextCellValue('Grup / Tempat'),
      TextCellValue('Catatan'),
      TextCellValue('Pencatat'),
      TextCellValue('Nominal (IDR)'),
    ]);

    for (final tx in transactions) {
      final isIncome = tx.type == TransactionType.income;
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(tx.date);
      final typeStr = isIncome ? 'Pemasukan' : 'Pengeluaran';
      // Nominal sebagai integer agar bisa di-SUM di Excel
      final amountVal = isIncome ? tx.amount : -tx.amount;

      transactionSheet.appendRow([
        TextCellValue(dateStr),
        TextCellValue(tx.title),
        TextCellValue(typeStr),
        TextCellValue(tx.categoryName),
        TextCellValue(tx.groupName ?? '-'),
        TextCellValue(tx.note ?? '-'),
        TextCellValue(tx.createdByName),
        IntCellValue(amountVal),
      ]);
    }

    // Save File
    final fileBytes = excel.save();
    final outputDir = await getTemporaryDirectory();
    final fileName = 'laporan_teduh_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${outputDir.path}/$fileName');
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }
    return file;
  }
}
