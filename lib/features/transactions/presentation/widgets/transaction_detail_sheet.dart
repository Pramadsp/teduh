import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/transaction_model.dart';

class TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  static Future<void> show(BuildContext context, {required Transaction transaction}) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TransactionDetailSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isIncome = tx.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final prefix = isIncome ? '+ ' : '- ';
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tx.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.sageDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: color,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tx.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$prefix${CurrencyUtils.formatRupiah(tx.amount)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          _detailRow('Kategori', tx.categoryName),
          if (tx.groupName != null && tx.groupName!.isNotEmpty)
            _detailRow('Grup', tx.groupName!),
          _detailRow('Tanggal', dateStr),
          _detailRow('Pencatat', tx.createdByName),
          if (tx.note != null && tx.note!.isNotEmpty)
            _detailRow('Catatan', tx.note!),
          const SizedBox(height: 20),
          if (tx.isTransfer)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.sageDark.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.sageDark, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transaksi transfer tidak dapat diubah.',
                      style: TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
