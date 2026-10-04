import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/auth_service.dart';
import '../../../categories/domain/category_model.dart';
import '../../domain/transaction_model.dart';
import '../providers/transaction_providers.dart';

class TransactionFormModal extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const TransactionFormModal({super.key, this.transaction});

  static Future<void> show(BuildContext context, {Transaction? transaction}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TransactionFormModal(transaction: transaction),
    );
  }

  @override
  ConsumerState<TransactionFormModal> createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends ConsumerState<TransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  Category? _selectedCategory;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _selectedType = tx?.type ?? TransactionType.expense;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null ? CurrencyUtils.formatRupiah(tx.amount).replaceAll('Rp ', '') : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori transaksi')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = CurrencyInputFormatter.parseAmount(_amountController.text);
      final isEditing = widget.transaction != null;

      final authService = AuthService();
      final currentUser = authService.currentUser;
      final userProfile = currentUser != null ? await authService.getUserProfile(currentUser.uid) : null;
      final currentUid = currentUser?.uid ?? 'user_anonymous';
      final currentName = userProfile?.displayName ?? currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'Pengguna';

      final newTx = Transaction(
        id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        type: _selectedType,
        amount: amount,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        date: _selectedDate,
        createdBy: widget.transaction?.createdBy ?? currentUid,
        createdByName: widget.transaction?.createdByName ?? currentName,
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final notifier = ref.read(transactionsProvider.notifier);
      if (isEditing) {
        await notifier.updateTransaction(newTx);
      } else {
        await notifier.addTransaction(newTx);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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
              Text(
                widget.transaction == null ? 'Tambah Transaksi' : 'Ubah Transaksi',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SegmentedButton<TransactionType>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                  selectedForegroundColor: AppColors.cream,
                  backgroundColor: AppColors.sand,
                  foregroundColor: AppColors.ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  side: BorderSide(
                    color: AppColors.sageDark.withValues(alpha: 0.2),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategory = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Nama Transaksi',
                  hintText: 'Contoh: Beli Kue, Gaji Bulanan',
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
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nama transaksi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Nominal',
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
                    return 'Masukkan nominal yang valid (> 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  final filteredCategories = categories.where((c) {
                    final targetType = _selectedType == TransactionType.income
                        ? CategoryType.income
                        : CategoryType.expense;
                    return c.type == targetType;
                  }).toList();

                  if (_selectedCategory == null && widget.transaction != null) {
                    try {
                      _selectedCategory = filteredCategories.firstWhere(
                        (c) => c.id == widget.transaction!.categoryId,
                      );
                    } catch (_) {}
                  }

                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    dropdownColor: AppColors.sand,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.sageDark),
                    style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Kategori',
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
                    items: filteredCategories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                    validator: (val) => val == null ? 'Pilih kategori' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
                error: (err, st) => Text('Gagal memuat kategori: $err', style: const TextStyle(color: AppColors.ink)),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.sageDark.withValues(alpha: 0.15),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: const Text(
                    'Tanggal Transaksi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.sageDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    DateUtilsId.formatDateFull(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.sageDark, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: AppColors.sageDark,
                                  onPrimary: AppColors.cream,
                                  surface: AppColors.cream,
                                  onSurface: AppColors.ink,
                                ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
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
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageDark,
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
                    : Text(
                        widget.transaction == null ? 'Simpan' : 'Perbarui',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
