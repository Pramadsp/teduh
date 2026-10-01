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
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Segmented Control Filter Period
            SegmentedButton<ReportPeriodType>(
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
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousPeriod,
                    ),
                    Expanded(
                      child: Text(
                        _getPeriodTitle(currentRange),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextPeriod,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (allTransactions) {
                final periodTxs = allTransactions
                    .where((tx) => currentRange.contains(tx.date))
                    .toList();

                final summary = FinancialSummary.calculate(periodTxs);

                if (periodTxs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Tidak ada transaksi pada periode ini.',
                        style: TextStyle(color: Colors.grey),
                      ),
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
                          child: Card(
                            color: AppColors.income.withValues(alpha: 0.15),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pemasukan', style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyUtils.formatRupiah(summary.totalIncome),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.income,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: AppColors.expense.withValues(alpha: 0.15),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pengeluaran', style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyUtils.formatRupiah(summary.totalExpense),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.expense,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: AppColors.sageDark.withValues(alpha: 0.15),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Saldo', style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyUtils.formatRupiah(summary.balance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: summary.balance >= 0
                                          ? AppColors.sageDark
                                          : AppColors.expense,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Grafik Donut Pengeluaran per Kategori
                    if (summary.totalExpense > 0) ...[
                      Text(
                        'Pengeluaran per Kategori',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: List.generate(
                              summary.categorySummaries.length,
                              (i) {
                                final cat = summary.categorySummaries[i];
                                final color = _chartColors[i % _chartColors.length];
                                return PieChartSectionData(
                                  color: color,
                                  value: cat.totalAmount.toDouble(),
                                  title: '${cat.percentage.toStringAsFixed(0)}%',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
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
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.categoryName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${cat.percentage.toStringAsFixed(1)}% (${CurrencyUtils.formatRupiah(cat.totalAmount)})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                    // Daftar Transaksi Periode Ini
                    Text(
                      'Daftar Transaksi Periode Ini',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: periodTxs.length,
                      itemBuilder: (context, index) {
                        final tx = periodTxs[index];
                        final isIncome = tx.type == TransactionType.income;
                        final color = isIncome ? AppColors.income : AppColors.expense;
                        final prefix = isIncome ? '+ ' : '- ';
                        final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              tx.categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${DateUtilsId.formatDateShort(tx.date)} • ${tx.createdByName}',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Gagal memuat laporan: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
