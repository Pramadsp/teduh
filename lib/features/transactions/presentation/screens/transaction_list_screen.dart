import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_form_modal.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Cari transaksi (nama, catatan, kategori)...',
                hintStyle: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.sageDark),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.sageDark, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.sand,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.sageDark.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.sageDark.withValues(alpha: 0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.sageDark, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (allTransactions) {
                if (allTransactions.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.sageDark.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.sageDark),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tekan tombol + di bawah untuk mencatat transaksi pertama Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter transaksi sesuai searchQuery
                final filteredTransactions = allTransactions.where((tx) {
                  if (_searchQuery.isEmpty) return true;
                  final titleMatch = tx.title.toLowerCase().contains(_searchQuery);
                  final noteMatch = tx.note != null && tx.note!.toLowerCase().contains(_searchQuery);
                  final categoryMatch = tx.categoryName.toLowerCase().contains(_searchQuery);
                  return titleMatch || noteMatch || categoryMatch;
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 40, color: AppColors.terracotta),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Transaksi Tidak Ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tidak ada transaksi yang cocok dengan kata kunci "$_searchQuery".',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final Map<String, List<Transaction>> grouped = {};
                for (final tx in filteredTransactions) {
                  final dateKey = DateUtilsId.formatDateFull(tx.date);
                  grouped.putIfAbsent(dateKey, () => []).add(tx);
                }

                final dateKeys = grouped.keys.toList();

                return ListView.builder(
                  itemCount: dateKeys.length,
                  padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16, top: 4),
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
                                tx.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                '${tx.categoryName} • ${tx.createdByName}${tx.note != null && tx.note!.isNotEmpty ? ' (${tx.note})' : ''}',
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
          ),
        ],
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
