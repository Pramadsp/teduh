import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/shell_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/widgets/pin_verification_modal.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/household_model.dart';

class TransferModal extends ConsumerStatefulWidget {
  final Household household;
  final String currentUid;

  const TransferModal({
    super.key,
    required this.household,
    required this.currentUid,
  });

  static Future<void> show(
    BuildContext context, {
    required Household household,
    required String currentUid,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TransferModal(
        household: household,
        currentUid: currentUid,
      ),
    );
  }

  @override
  ConsumerState<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends ConsumerState<TransferModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  UserProfile? _selectedReceiver;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer(UserProfile senderProfile, UserProfile receiverProfile) async {
    if (!_formKey.currentState!.validate()) return;

    final verified = await PinVerificationModal.show(context, currentUid: widget.currentUid);
    if (verified != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = CurrencyInputFormatter.parseAmount(_amountController.text);
      final noteText = _noteController.text.trim();
      final now = DateTime.now();

      // 1. Double-Entry Log: Pengeluaran Suami / Kepala Keluarga
      final txOut = Transaction(
        id: 'tx_trf_out_${now.millisecondsSinceEpoch}',
        title: 'Transfer ke ${receiverProfile.displayName}',
        type: TransactionType.expense,
        amount: amount,
        categoryId: 'cat_transfer',
        categoryName: 'Transfer Internal',
        note: noteText.isEmpty ? null : noteText,
        date: now,
        createdBy: senderProfile.uid,
        createdByName: senderProfile.displayName,
        createdAt: now,
        updatedAt: now,
      );

      // 2. Double-Entry Log: Pemasukan Istri / Pasangan
      final txIn = Transaction(
        id: 'tx_trf_in_${now.millisecondsSinceEpoch}',
        title: 'Transfer dari ${senderProfile.displayName}',
        type: TransactionType.income,
        amount: amount,
        categoryId: 'cat_transfer',
        categoryName: 'Transfer Internal',
        note: noteText.isEmpty ? null : noteText,
        date: now,
        createdBy: receiverProfile.uid,
        createdByName: receiverProfile.displayName,
        createdAt: now,
        updatedAt: now,
      );

      final notifier = ref.read(transactionsProvider.notifier);
      await notifier.addTransaction(txOut);
      await notifier.addTransaction(txIn);

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        MainScreen.switchTab(context, 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sageDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.cream, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transfer saldo ${CurrencyUtils.formatRupiah(amount)} ke ${receiverProfile.displayName} berhasil!',
                    style: const TextStyle(color: AppColors.cream, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.expense,
            content: Text('Gagal melakukan transfer: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherMemberIds = widget.household.memberIds.where((id) => id != widget.currentUid).toList();

    if (otherMemberIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_add_rounded, size: 40, color: AppColors.terracotta),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anggota Lain Belum Bergabung',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bagikan kode undangan grup keluarga agar anggota lain dapat bergabung sebelum melakukan transfer saldo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.currentUid).snapshots(),
      builder: (context, senderSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: otherMemberIds)
              .snapshots(),
          builder: (context, receiversSnap) {
            if (!senderSnap.hasData || !receiversSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
              );
            }

            final senderProfile = UserProfile.fromMap(senderSnap.data!.data()!);
            final receiverProfiles = receiversSnap.data!.docs
                .map((doc) => UserProfile.fromMap(doc.data()))
                .toList();

            if (receiverProfiles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
              );
            }

            if (_selectedReceiver == null || !receiverProfiles.any((p) => p.uid == _selectedReceiver!.uid)) {
              _selectedReceiver = receiverProfiles.first;
            }

            final activeReceiver = _selectedReceiver!;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
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
                      const Text(
                        'Transfer Saldo Keuangan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pindahkan saldo dari ${senderProfile.displayName} ke anggota grup',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ink.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Selection Penerima Transfer Saldo (Selalu Tampil)
                      DropdownButtonFormField<String>(
                        initialValue: activeReceiver.uid,
                        dropdownColor: AppColors.sand,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.sageDark),
                        style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Penerima Transfer Saldo',
                          labelStyle: const TextStyle(color: AppColors.sageDark, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: AppColors.sand,
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
                        items: receiverProfiles.map((p) {
                          return DropdownMenuItem<String>(
                            value: p.uid,
                            child: Text(
                              '${p.displayName} (${p.email})',
                              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (selectedUid) {
                          if (selectedUid != null) {
                            final found = receiverProfiles.firstWhere((p) => p.uid == selectedUid);
                            setState(() {
                              _selectedReceiver = found;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Card Header Transfer (Dari -> Ke)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.sageDark.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DARI (PEMBAYAR)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.sageDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    senderProfile.displayName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.sageDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.cream,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'KE (PENERIMA)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.sageDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activeReceiver.displayName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Field Input Nominal Transfer
                      TextFormField(
                        controller: _amountController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Nominal Transfer',
                          labelStyle: const TextStyle(color: AppColors.sageDark, fontWeight: FontWeight.bold),
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: AppColors.sand,
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
                        validator: (value) {
                          final amount = CurrencyInputFormatter.parseAmount(value ?? '');
                          if (amount <= 0) {
                            return 'Masukkan nominal transfer yang valid (> 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field Input Catatan
                      TextFormField(
                        controller: _noteController,
                        enabled: !_isSubmitting,
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Catatan / Pesan (opsional)',
                          hintText: 'Contoh: Uang Belanja Minggu Ini',
                          labelStyle: TextStyle(color: AppColors.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: AppColors.sand,
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
                      const SizedBox(height: 24),

                      // Tombol Submit Transfer
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitTransfer(senderProfile, activeReceiver),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: AppColors.cream,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.cream,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.cream),
                                  SizedBox(width: 8),
                                  Text(
                                    'Kirim Transfer Saldo',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
