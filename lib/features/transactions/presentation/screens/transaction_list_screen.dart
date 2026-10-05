import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';
import '../providers/transaction_providers.dart';
import '../widgets/group_transaction_card.dart';
import '../widgets/transaction_detail_sheet.dart';
import '../widgets/transaction_form_modal.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final transactionsAsync = ref.watch(transactionsProvider);
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      currentUid = null;
    }

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

                final Map<String, List<Transaction>> groupedByDate = {};
                for (final tx in filteredTransactions) {
                  final dateKey = DateUtilsId.formatDateFull(tx.date);
                  groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
                }

                final dateKeys = groupedByDate.keys.toList();

                return ListView.builder(
                  itemCount: dateKeys.length,
                  padding: const EdgeInsets.only(bottom: 88, left: 16, right: 16, top: 4),
                  itemBuilder: (context, index) {
                    final dateHeader = dateKeys[index];
                    final dateTransactions = groupedByDate[dateHeader]!;

                    // Pisahkan transaksi standalone vs transaksi grup (di dalam tanggal yang sama)
                    final List<Widget> listWidgets = [];

                    // Proses pengelompokan per groupId di dalam tanggal tersebut
                    final Map<String, List<Transaction>> groupedItems = {};
                    final List<Transaction> standaloneItems = [];

                    for (final tx in dateTransactions) {
                      if (tx.groupId != null && tx.groupId!.isNotEmpty) {
                        groupedItems.putIfAbsent(tx.groupId!, () => []).add(tx);
                      } else {
                        standaloneItems.add(tx);
                      }
                    }

                    // Tampilkan item standalone terlebih dahulu / sesuai urutan
                    for (final tx in standaloneItems) {
                      final isIncome = tx.type == TransactionType.income;
                      final color = isIncome ? AppColors.income : AppColors.expense;
                      final prefix = isIncome ? '+ ' : '- ';
                      final icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
                      final isCreatedByMe = currentUid == null || tx.createdBy == currentUid;

                      listWidgets.add(
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
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tx.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                if (!isCreatedByMe)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.terracotta.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.terracotta.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Oleh ${tx.createdByName}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.terracotta,
                                      ),
                                    ),
                                  ),
                              ],
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
                              if (tx.isTransfer) {
                                TransactionDetailSheet.show(context, transaction: tx);
                                return;
                              }
                              if (!isCreatedByMe) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.sageDark,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    content: Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded, color: AppColors.cream, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Transaksi ini dicatat oleh ${tx.createdByName} (Hanya Dapat Dilihat)',
                                            style: const TextStyle(color: AppColors.cream),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                return;
                              }
                              TransactionFormModal.show(context, transaction: tx);
                            },
                          ),
                        ),
                      );
                    }

                    // Tampilkan Kartu Grup Terlipat (Default Collapsed)
                    groupedItems.forEach((gId, items) {
                      if (items.isNotEmpty) {
                        final groupName = items.first.groupName ?? 'Grup Transaksi';
                        final totalGroupAmount = items.fold(0, (sum, item) => sum + item.amount);

                        listWidgets.add(
                          GroupTransactionCard(
                            groupName: groupName,
                            items: items,
                            totalAmount: totalGroupAmount,
                            currentUid: currentUid,
                          ),
                        );
                      }
                    });

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
                        ...listWidgets,
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
