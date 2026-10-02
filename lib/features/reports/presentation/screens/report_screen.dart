import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_range_helper.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/transaction_form_modal.dart';

enum ReportPeriodType { daily, weekly, monthly }

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  ReportPeriodType _selectedPeriod = ReportPeriodType.monthly;
  DateTime _selectedDate = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currentRange = _getCurrentRange();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        centerTitle: true,
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
                final periodTxs = allTransactions
                    .where((tx) => currentRange.contains(tx.date))
                    .toList();

                final summary = FinancialSummary.calculate(periodTxs);

                if (periodTxs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.sageDark.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Text(
                      'Tidak ada transaksi pada periode ini.',
                      style: TextStyle(color: AppColors.ink),
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
                                  CurrencyUtils.formatRupiah(summary.totalIncome),
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
                                  CurrencyUtils.formatRupiah(summary.totalExpense),
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
                                  'Saldo',
                                  style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyUtils.formatRupiah(summary.balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: summary.balance >= 0
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
                    // Grafik Donut Pengeluaran per Kategori
                    if (summary.totalExpense > 0) ...[
                      const Text(
                        'Pengeluaran per Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                    summary.categorySummaries.length,
                                    (i) {
                                      final cat = summary.categorySummaries[i];
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
                            ...List.generate(summary.categorySummaries.length, (i) {
                              final cat = summary.categorySummaries[i];
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: periodTxs.length,
                      itemBuilder: (context, index) {
                        final tx = periodTxs[index];
                        final isIncome = tx.type == TransactionType.income;
                        final color = isIncome ? AppColors.income : AppColors.expense;
                        final prefix = isIncome ? '+ ' : '- ';
                        final icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

                        return Container(
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
                              tx.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Text(
                              '${DateUtilsId.formatDateShort(tx.date)} • ${tx.createdByName}',
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
                              TransactionFormModal.show(context, transaction: tx);
                            },
                          ),
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
