import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_range_helper.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/transaction_form_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teduh',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
            ),
            Text(
              'Urusan uang jadi lebih tenang',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.sageDark,
                  ),
            ),
          ],
        ),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final currentMonthRange = DateRangeHelper.getMonthlyRange(now);
          final currentMonthTxs = allTransactions
              .where((tx) => currentMonthRange.contains(tx.date))
              .toList();

          final summary = FinancialSummary.calculate(currentMonthTxs);
          final recentTxs = allTransactions.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container Saldo Utama
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.sageDark,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sageDark.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.cream,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo Bulan Ini (${DateUtilsId.formatMonthYear(now)})',
                              style: TextStyle(
                                color: AppColors.cream.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CurrencyUtils.formatRupiah(summary.balance),
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.income.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: AppColors.cream,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pemasukan',
                                            style: TextStyle(
                                              color: AppColors.cream.withValues(alpha: 0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyUtils.formatRupiah(summary.totalIncome),
                                            style: const TextStyle(
                                              color: AppColors.cream,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 28,
                                width: 1,
                                color: AppColors.cream.withValues(alpha: 0.2),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward_rounded,
                                        color: AppColors.cream,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pengeluaran',
                                            style: TextStyle(
                                              color: AppColors.cream.withValues(alpha: 0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyUtils.formatRupiah(summary.totalExpense),
                                            style: const TextStyle(
                                              color: AppColors.cream,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      recentTxs.isEmpty
                          ? 'Transaksi Terakhir'
                          : '${recentTxs.length} Transaksi Terakhir',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: AppColors.sageDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recentTxs.isEmpty)
                  Container(
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
                      'Belum ada transaksi tercatat.',
                      style: TextStyle(color: AppColors.ink),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentTxs.length,
                    itemBuilder: (context, index) {
                      final tx = recentTxs[index];
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
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          subtitle: Text(
                            '${tx.categoryName} • ${DateUtilsId.formatDateShort(tx.date)}',
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
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.sageDark),
        ),
        error: (err, st) => Center(
          child: Text(
            'Gagal memuat dashboard: $err',
            style: const TextStyle(color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
