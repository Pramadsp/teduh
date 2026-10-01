import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
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
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  Category? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _selectedType = tx?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: tx != null ? CurrencyUtils.formatRupiah(tx.amount).replaceAll('Rp ', '') : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori transaksi')),
      );
      return;
    }

    final amount = CurrencyInputFormatter.parseAmount(_amountController.text);
    final isEditing = widget.transaction != null;

    final newTx = Transaction(
      id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      amount: amount,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: _selectedDate,
      createdBy: widget.transaction?.createdBy ?? 'user_1',
      createdByName: widget.transaction?.createdByName ?? 'Saya',
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(transactionsProvider.notifier);
    if (isEditing) {
      notifier.updateTransaction(newTx);
    } else {
      notifier.addTransaction(newTx);
    }

    Navigator.of(context).pop();
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
              Text(
                widget.transaction == null ? 'Tambah Transaksi' : 'Ubah Transaksi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_downward, color: Colors.red),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Pemasukan'),
                    icon: Icon(Icons.arrow_upward, color: Colors.green),
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
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
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
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: filteredCategories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
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
                loading: () => const CircularProgressIndicator(),
                error: (err, st) => Text('Gagal memuat kategori: $err'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal Transaksi'),
                subtitle: Text(DateUtilsId.formatDateFull(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(widget.transaction == null ? 'Simpan' : 'Perbarui'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
