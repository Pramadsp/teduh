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
        title: const Text('Hapus Transaksi'),
        content: Text('Apakah Anda yakin ingin menghapus transaksi "${tx.categoryName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final notifier = ref.read(transactionsProvider.notifier);
              await notifier.deleteTransaction(tx.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaksi berhasil dihapus'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        notifier.addTransaction(tx);
                      },
                    ),
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada transaksi.\nTekan tombol + untuk menambah.',
                textAlign: TextAlign.center,
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
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final dateHeader = dateKeys[index];
              final txList = grouped[dateHeader]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      dateHeader,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.sageDark,
                          ),
                    ),
                  ),
                  ...txList.map((tx) {
                    final isIncome = tx.type == TransactionType.income;
                    final color = isIncome ? AppColors.income : AppColors.expense;
                    final prefix = isIncome ? '+ ' : '- ';
                    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          '${tx.createdByName}${tx.note != null ? ' • ${tx.note}' : ''}',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Gagal memuat transaksi: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        onPressed: () {
          TransactionFormModal.show(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
