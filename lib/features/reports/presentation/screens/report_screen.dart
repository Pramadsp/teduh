import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_range_helper.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../../export/data/excel_exporter.dart';
import '../../../export/data/pdf_exporter.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/group_transaction_card.dart';
import '../../../transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_form_modal.dart';

enum ReportPeriodType { daily, weekly, monthly }
enum ExpenseReportView { category, group }

class GroupExpenseSummary {
  final String groupName;
  final int totalAmount;
  final double percentage;

  GroupExpenseSummary({
    required this.groupName,
    required this.totalAmount,
    required this.percentage,
  });
}

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> with AutomaticKeepAliveClientMixin {
  ReportPeriodType _selectedPeriod = ReportPeriodType.monthly;
  ExpenseReportView _expenseReportView = ExpenseReportView.category;
  DateTime _selectedDate = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  final List<Color> _chartColors = [
    AppColors.expense,
    AppColors.terracotta,
    AppColors.sageDark,
    AppColors.sage,
    Colors.amber[700]!,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  List<GroupExpenseSummary> _calculateGroupSummaries(List<Transaction> periodTxs) {
    final Map<String, int> groupTotals = {};
    int totalGroupExpense = 0;

    for (final tx in periodTxs) {
      final isTransferInternal = tx.categoryId == 'cat_transfer' ||
          tx.categoryName == 'Transfer Internal' ||
          tx.title.startsWith('Transfer ');
      if (isTransferInternal) continue;

      if (tx.type == TransactionType.expense) {
        final name = (tx.groupName != null && tx.groupName!.isNotEmpty)
            ? tx.groupName!
            : 'Tanpa Grup';
        groupTotals[name] = (groupTotals[name] ?? 0) + tx.amount;
        totalGroupExpense += tx.amount;
      }
    }

    final List<GroupExpenseSummary> result = [];
    if (totalGroupExpense > 0) {
      groupTotals.forEach((name, amount) {
        final percentage = (amount / totalGroupExpense) * 100;
        result.add(GroupExpenseSummary(
          groupName: name,
          totalAmount: amount,
          percentage: percentage,
        ));
      });
      result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }
    return result;
  }

  DateRange _getCurrentRange() {
    switch (_selectedPeriod) {
      case ReportPeriodType.daily:
        return DateRangeHelper.getDailyRange(_selectedDate);
      case ReportPeriodType.weekly:
        return DateRangeHelper.getWeeklyRange(_selectedDate);
      case ReportPeriodType.monthly:
        return DateRangeHelper.getMonthlyRange(_selectedDate);
    }
  }

  void _previousPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriodType.daily:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
        case ReportPeriodType.weekly:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case ReportPeriodType.monthly:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedPeriod) {
        case ReportPeriodType.daily:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
        case ReportPeriodType.weekly:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case ReportPeriodType.monthly:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
      }
    });
  }

  String _getPeriodTitle(DateRange range) {
    switch (_selectedPeriod) {
      case ReportPeriodType.daily:
        return DateUtilsId.formatDateFull(_selectedDate);
      case ReportPeriodType.weekly:
        return '${DateUtilsId.formatDateShort(range.start)} - ${DateUtilsId.formatDateShort(range.end)}';
      case ReportPeriodType.monthly:
        return DateUtilsId.formatMonthYear(_selectedDate);
    }
  }

  void _showExportOptions({
    required BuildContext context,
    required String periodTitle,
    required List<Transaction> transactions,
    required int totalIncome,
    required int totalExpense,
    required int balance,
    required Map<String, int> categoryTotals,
  }) {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada transaksi pada periode ini untuk diekspor'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sageDark.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ekspor Laporan Keuangan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  periodTitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.expense),
                  ),
                  title: const Text(
                    'Ekspor PDF (.pdf)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  subtitle: const Text('Format cetak rapi dengan ringkasan & tabel'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final file = await PdfReportExporter.generatePdf(
                      periodTitle: periodTitle,
                      transactions: transactions,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      balance: balance,
                      categoryTotals: categoryTotals,
                    );
                    _showExportSuccessModal(messenger, file.path, 'PDF');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppColors.income),
                  ),
                  title: const Text(
                    'Ekspor Excel (.xlsx)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                  subtitle: const Text('Sheet ringkasan & nominal angka untuk kalkulasi'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final file = await ExcelReportExporter.generateExcel(
                      periodTitle: periodTitle,
                      transactions: transactions,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      balance: balance,
                      categoryTotals: categoryTotals,
                    );
                    _showExportSuccessModal(messenger, file.path, 'Excel');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExportSuccessModal(ScaffoldMessengerState messenger, String path, String formatName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 52),
                const SizedBox(height: 12),
                Text(
                  'Laporan $formatName Berhasil Dibuat!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.sageDark),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, color: AppColors.sageDark),
                        label: const Text('Buka File', style: TextStyle(color: AppColors.sageDark)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          OpenFilex.open(path);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sageDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.share_rounded, color: AppColors.cream),
                        label: const Text('Bagikan', style: TextStyle(color: AppColors.cream)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Share.shareXFiles([XFile(path)], text: 'Laporan Keuangan Teduh');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final transactionsAsync = ref.watch(transactionsProvider);
    final currentRange = _getCurrentRange();

    final periodTitle = _getPeriodTitle(currentRange);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        centerTitle: true,
        actions: [
          transactionsAsync.maybeWhen(
            data: (allTransactions) {
              final allTimeSummary = FinancialSummary.calculate(allTransactions);
              final periodTxs = allTransactions
                  .where((tx) => currentRange.contains(tx.date))
                  .toList();
              final periodRealSummary = FinancialSummary.calculate(
                periodTxs,
                excludeInternalTransfers: true,
              );

              final categoryTotalsMap = {
                for (var cs in periodRealSummary.categorySummaries) cs.categoryName: cs.totalAmount
              };

              return IconButton(
                icon: const Icon(Icons.file_download_outlined, color: AppColors.sageDark),
                tooltip: 'Ekspor Laporan',
                onPressed: () {
                  _showExportOptions(
                    context: context,
                    periodTitle: periodTitle,
                    transactions: periodTxs,
                    totalIncome: periodRealSummary.totalIncome,
                    totalExpense: periodRealSummary.totalExpense,
                    balance: allTimeSummary.balance,
                    categoryTotals: categoryTotalsMap,
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Segmented Control Filter Period
            SegmentedButton<ReportPeriodType>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.sageDark;
                  }
                  return AppColors.sand;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.cream;
                  }
                  return AppColors.ink;
                }),
                textStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
                  return TextStyle(
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: states.contains(WidgetState.selected)
                        ? AppColors.cream
                        : AppColors.ink,
                  );
                }),
                side: WidgetStateProperty.all(
                  BorderSide(
                    color: AppColors.sageDark.withValues(alpha: 0.2),
                  ),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: ReportPeriodType.daily,
                  label: Text('Harian'),
                ),
                ButtonSegment(
                  value: ReportPeriodType.weekly,
                  label: Text('Mingguan'),
                ),
                ButtonSegment(
                  value: ReportPeriodType.monthly,
                  label: Text('Bulanan'),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedPeriod = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            // Navigasi Periode (Panah Kiri / Judul / Panah Kanan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sageDark.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.sageDark),
                    onPressed: _previousPeriod,
                  ),
                  Expanded(
                    child: Text(
                      _getPeriodTitle(currentRange),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.sageDark),
                    onPressed: _nextPeriod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            transactionsAsync.when(
              data: (allTransactions) {
                final allTimeSummary = FinancialSummary.calculate(allTransactions);

                final periodTxs = allTransactions
                    .where((tx) => currentRange.contains(tx.date))
                    .toList();

                final periodRealSummary = FinancialSummary.calculate(
                  periodTxs,
                  excludeInternalTransfers: true,
                );

                if (periodTxs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.sageDark.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.sageDark.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.sageDark),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tidak Ada Transaksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Belum ada transaksi tercatat pada periode ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Ringkasan Angka
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.income.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pemasukan',
                                  style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyUtils.formatRupiah(periodRealSummary.totalIncome),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.income,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.expense.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengeluaran',
                                  style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyUtils.formatRupiah(periodRealSummary.totalExpense),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.expense,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.sageDark.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo Tersedia',
                                  style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyUtils.formatRupiah(allTimeSummary.balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: allTimeSummary.balance >= 0
                                        ? AppColors.sageDark
                                        : AppColors.expense,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Grafik Donut Pengeluaran per Kategori / Grup (Mengecualikan Transfer Internal)
                    if (periodRealSummary.totalExpense > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pengeluaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          SegmentedButton<ExpenseReportView>(
                            style: SegmentedButton.styleFrom(
                              selectedBackgroundColor: AppColors.sageDark,
                              selectedForegroundColor: AppColors.cream,
                              backgroundColor: AppColors.sand,
                              foregroundColor: AppColors.ink,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: ExpenseReportView.category,
                                label: Text('Per Kategori'),
                              ),
                              ButtonSegment(
                                value: ExpenseReportView.group,
                                label: Text('Per Grup'),
                              ),
                            ],
                            selected: {_expenseReportView},
                            onSelectionChanged: (val) {
                              setState(() {
                                _expenseReportView = val.first;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_expenseReportView == ExpenseReportView.category) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.sageDark.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 36,
                                    sections: List.generate(
                                      periodRealSummary.categorySummaries.length,
                                      (i) {
                                        final cat = periodRealSummary.categorySummaries[i];
                                        final color = _chartColors[i % _chartColors.length];
                                        return PieChartSectionData(
                                          color: color,
                                          value: cat.totalAmount.toDouble(),
                                          title: '${cat.percentage.toStringAsFixed(0)}%',
                                          radius: 46,
                                          titleStyle: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Rincian Daftar Kategori
                              ...List.generate(periodRealSummary.categorySummaries.length, (i) {
                                final cat = periodRealSummary.categorySummaries[i];
                                final color = _chartColors[i % _chartColors.length];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cat.categoryName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${cat.percentage.toStringAsFixed(1)}% (${CurrencyUtils.formatRupiah(cat.totalAmount)})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.ink,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Tampilan Per Grup
                        Builder(
                          builder: (context) {
                            final groupSummaries = _calculateGroupSummaries(periodTxs);
                            if (groupSummaries.isEmpty) {
                              return const Center(child: Text('Belum ada data grup.'));
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.sand,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.sageDark.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 36,
                                        sections: List.generate(
                                          groupSummaries.length,
                                          (i) {
                                            final grp = groupSummaries[i];
                                            final color = _chartColors[i % _chartColors.length];
                                            return PieChartSectionData(
                                              color: color,
                                              value: grp.totalAmount.toDouble(),
                                              title: '${grp.percentage.toStringAsFixed(0)}%',
                                              radius: 46,
                                              titleStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Rincian Daftar Grup
                                  ...List.generate(groupSummaries.length, (i) {
                                    final grp = groupSummaries[i];
                                    final color = _chartColors[i % _chartColors.length];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              grp.groupName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.ink,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${grp.percentage.toStringAsFixed(1)}% (${CurrencyUtils.formatRupiah(grp.totalAmount)})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.ink,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                    // Daftar Transaksi Periode Ini
                    const Text(
                      'Daftar Transaksi Periode Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final List<Widget> periodWidgets = [];
                        final Set<String> processedGroupIds = {};
                        final authService = AuthService();
                        final currentUid = authService.currentUser?.uid;

                        for (final tx in periodTxs) {
                          if (tx.groupId != null && tx.groupId!.isNotEmpty) {
                            if (!processedGroupIds.contains(tx.groupId)) {
                              processedGroupIds.add(tx.groupId!);
                              final groupItems = periodTxs.where((t) => t.groupId == tx.groupId).toList();
                              final totalGroupAmount = groupItems.fold(0, (acc, item) => acc + item.amount);

                              periodWidgets.add(
                                GroupTransactionCard(
                                  groupName: tx.groupName ?? 'Grup Transaksi',
                                  items: groupItems,
                                  totalAmount: totalGroupAmount,
                                  currentUid: currentUid,
                                ),
                              );
                            }
                          } else {
                            final isIncome = tx.type == TransactionType.income;
                            final color = isIncome ? AppColors.income : AppColors.expense;
                            final prefix = isIncome ? '+ ' : '- ';
                            final icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

                            periodWidgets.add(
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.sand,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.sageDark.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.12),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  title: Text(
                                    tx.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tx.categoryName} • ${DateUtilsId.formatDateShort(tx.date)} • ${tx.createdByName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ink.withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    '$prefix${CurrencyUtils.formatRupiah(tx.amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onTap: () {
                                    if (tx.isTransfer) {
                                      TransactionDetailSheet.show(context, transaction: tx);
                                      return;
                                    }
                                    TransactionFormModal.show(context, transaction: tx);
                                  },
                                ),
                              ),
                            );
                          }
                        }

                        return Column(
                          children: periodWidgets,
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
              error: (err, st) => Center(child: Text('Gagal memuat laporan: $err', style: const TextStyle(color: AppColors.ink))),
            ),
          ],
        ),
      ),
    );
  }
}
