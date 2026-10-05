import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/shell_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_range_helper.dart';
import '../../../../core/utils/financial_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../household/domain/household_model.dart';
import '../../../household/presentation/widgets/transfer_modal.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/widgets/group_transaction_card.dart';
import '../../../transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_form_modal.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          final allTimeSummary = FinancialSummary.calculate(allTransactions);

          final currentMonthRange = DateRangeHelper.getMonthlyRange(now);
          final currentMonthTxs = allTransactions
              .where((tx) => currentMonthRange.contains(tx.date))
              .toList();

          final monthlySummary = FinancialSummary.calculate(currentMonthTxs);
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
                        // Header Total Saldo Grup
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: AppColors.cream,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'TOTAL SALDO GRUP',
                              style: TextStyle(
                                color: AppColors.cream.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CurrencyUtils.formatRupiah(allTimeSummary.balance),
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sub-seksi Kartu Saldo Per-Anggota
                        if (allTimeSummary.userBalances.isNotEmpty) ...[
                          const Text(
                            'SALDO PER-ANGGOTA',
                            style: TextStyle(
                              color: AppColors.cream,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: allTimeSummary.userBalances.values.map((u) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.sand,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.sageDark.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 10,
                                            backgroundColor: AppColors.sageDark,
                                            child: Text(
                                              u.userName.isNotEmpty ? u.userName[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.cream,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Saldo ${u.userName}',
                                              style: const TextStyle(
                                                color: AppColors.ink,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        CurrencyUtils.formatRupiah(u.balance),
                                        style: TextStyle(
                                          color: u.balance >= 0 ? AppColors.income : AppColors.expense,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const DashboardTransferButton(),
                          const SizedBox(height: 18),
                        ],

                        // Indikator Pemasukan & Pengeluaran Bulan Ini
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
                                            'Pemasukan (${DateUtilsId.formatMonthYear(now)})',
                                            style: TextStyle(
                                              color: AppColors.cream.withValues(alpha: 0.85),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyUtils.formatRupiah(monthlySummary.totalIncome),
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
                                            'Pengeluaran (${DateUtilsId.formatMonthYear(now)})',
                                            style: TextStyle(
                                              color: AppColors.cream.withValues(alpha: 0.85),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyUtils.formatRupiah(monthlySummary.totalExpense),
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
                      onPressed: () => MainScreen.switchTab(context, 1),
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
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.sageDark.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.sageDark),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Transaksi Tercatat',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catatan transaksi harian Anda akan tampil di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Builder(
                    builder: (context) {
                      final List<Widget> recentWidgets = [];
                      final Set<String> processedGroupIds = {};
                      final authService = AuthService();
                      final currentUid = authService.currentUser?.uid;

                      for (final tx in recentTxs) {
                        if (tx.groupId != null && tx.groupId!.isNotEmpty) {
                          if (!processedGroupIds.contains(tx.groupId)) {
                            processedGroupIds.add(tx.groupId!);
                            final groupItems = allTransactions.where((t) => t.groupId == tx.groupId).toList();
                            final totalGroupAmount = groupItems.fold(0, (acc, item) => acc + item.amount);

                            recentWidgets.add(
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

                          recentWidgets.add(
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
                        children: recentWidgets,
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

class DashboardTransferButton extends StatelessWidget {
  const DashboardTransferButton({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<UserProfile?>(
      stream: authService.streamUserProfile(currentUser.uid),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        if (profile?.householdId == null || profile!.householdId!.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('households')
              .doc(profile.householdId)
              .snapshots(),
          builder: (context, householdSnap) {
            if (!householdSnap.hasData || !householdSnap.data!.exists) {
              return const SizedBox.shrink();
            }

            final household = Household.fromMap(householdSnap.data!.data()!);
            if (!household.canTransfer(currentUser.uid)) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: AppColors.cream,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.cream),
                  label: const Text(
                    'Transfer Saldo ke Anggota',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.cream),
                  ),
                  onPressed: () {
                    TransferModal.show(
                      context,
                      household: household,
                      currentUid: currentUser.uid,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
