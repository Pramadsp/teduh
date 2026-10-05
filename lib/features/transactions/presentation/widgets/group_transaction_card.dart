import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';
import 'transaction_form_modal.dart';

class GroupTransactionCard extends StatefulWidget {
  final String groupName;
  final List<Transaction> items;
  final int totalAmount;
  final String? currentUid;

  const GroupTransactionCard({
    super.key,
    required this.groupName,
    required this.items,
    required this.totalAmount,
    required this.currentUid,
  });

  @override
  State<GroupTransactionCard> createState() => _GroupTransactionCardState();
}

class _GroupTransactionCardState extends State<GroupTransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final totalFormatted = CurrencyUtils.formatRupiah(widget.totalAmount);

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
      child: Column(
        children: [
          // Header Group Card (Collapsed View - Default)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.expense.withValues(alpha: 0.12),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.expense, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.groupName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.sageDark.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.items.length} Item',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sageDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Grup Pengeluaran Struk',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '- $totalFormatted',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.sageDark,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Child Items (Hanya tampil saat kartu dilebarkan)
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: AppColors.sageDark.withValues(alpha: 0.15),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: widget.items.map((tx) {
                  final isIncome = tx.type == TransactionType.income;
                  final color = isIncome ? AppColors.income : AppColors.expense;
                  final prefix = isIncome ? '+ ' : '- ';
                  final isCreatedByMe = widget.currentUid == null || tx.createdBy == widget.currentUid;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.sageDark.withValues(alpha: 0.1),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (!isCreatedByMe) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.sageDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: Text(
                                'Transaksi ini dicatat oleh ${tx.createdByName} (Hanya Dapat Dilihat)',
                                style: const TextStyle(color: AppColors.cream),
                              ),
                            ),
                          );
                          return;
                        }
                        TransactionFormModal.show(context, transaction: tx);
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  '${tx.categoryName} • ${tx.createdByName}${tx.note != null && tx.note!.isNotEmpty ? ' (${tx.note})' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.ink.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$prefix${CurrencyUtils.formatRupiah(tx.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
