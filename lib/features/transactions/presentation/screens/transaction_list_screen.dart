import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_form_modal.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.cream,
        title: const Text(
          'Hapus Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi "${tx.categoryName}"?',
          style: const TextStyle(color: AppColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.sageDark),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final notifier = ref.read(transactionsProvider.notifier);
              await notifier.deleteTransaction(tx.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.sageDark,
                    content: const Text(
                      'Transaksi berhasil dihapus',
                      style: TextStyle(color: AppColors.cream),
                    ),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.terracotta,
                      onPressed: () {
                        notifier.addTransaction(tx);
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada transaksi.\nTekan tombol + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.ink),
              ),
            );
          }

          final Map<String, List<Transaction>> grouped = {};
          for (final tx in transactions) {
            final dateKey = DateUtilsId.formatDateFull(tx.date);
            grouped.putIfAbsent(dateKey, () => []).add(tx);
          }

          final dateKeys = grouped.keys.toList();

          return ListView.builder(
            itemCount: dateKeys.length,
            padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16, top: 12),
            itemBuilder: (context, index) {
              final dateHeader = dateKeys[index];
              final txList = grouped[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      dateHeader,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.sageDark,
                      ),
                    ),
                  ),
                  ...txList.map((tx) {
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
                          '${tx.createdByName}${tx.note != null ? ' • ${tx.note}' : ''}',
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
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          TransactionFormModal.show(context, transaction: tx);
                        },
                        onLongPress: () {
                          _confirmDelete(context, ref, tx);
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
        error: (err, st) => Center(child: Text('Gagal memuat transaksi: $err', style: const TextStyle(color: AppColors.ink))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        onPressed: () {
          TransactionFormModal.show(context);
        },
        child: const Icon(Icons.add, color: AppColors.cream),
      ),
    );
  }
}
