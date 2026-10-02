import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/core/theme/app_colors.dart';
import 'package:teduh/features/categories/domain/category_model.dart';
import 'package:teduh/features/transactions/presentation/providers/transaction_providers.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCategoryDialog({Category? category, required CategoryType defaultType}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    CategoryType selectedType = category?.type ?? defaultType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: AppColors.cream,
            title: Text(
              category == null ? 'Tambah Kategori' : 'Ubah Kategori',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<CategoryType>(
                    segments: const [
                      ButtonSegment(
                        value: CategoryType.expense,
                        label: Text('Pengeluaran'),
                      ),
                      ButtonSegment(
                        value: CategoryType.income,
                        label: Text('Pemasukan'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (newVal) {
                      setModalState(() {
                        selectedType = newVal.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(labelText: 'Nama Kategori'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama kategori wajib diisi';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal', style: TextStyle(color: AppColors.sageDark)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final repo = ref.read(categoryRepositoryProvider);
                  final name = nameController.text.trim();

                  if (category == null) {
                    final newCat = Category(
                      id: 'cat_custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      type: selectedType,
                      isDefault: false,
                    );
                    await repo.addCategory(newCat);
                  } else {
                    final updatedCat = Category(
                      id: category.id,
                      name: name,
                      type: selectedType,
                      iconKey: category.iconKey,
                      isDefault: category.isDefault,
                    );
                    await repo.updateCategory(updatedCat);
                  }

                  ref.read(categoriesProvider.notifier).loadCategories();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteCategory(Category category) async {
    final transactionsAsync = ref.read(transactionsProvider);
    final transactions = transactionsAsync.asData?.value ?? [];

    final isUsed = transactions.any((tx) => tx.categoryId == category.id);

    if (isUsed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.cream,
          title: const Text(
            'Kategori Tidak Dapat Dihapus',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          content: Text(
            'Kategori "${category.name}" sudah digunakan dalam riwayat transaksi. Anda tidak dapat menghapusnya demi menjaga keutuhan laporan keuangan.',
            style: const TextStyle(color: AppColors.ink),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: AppColors.cream,
        title: const Text(
          'Hapus Kategori',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
          style: const TextStyle(color: AppColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.sageDark)),
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
              final repo = ref.read(categoryRepositoryProvider);
              await repo.deleteCategory(category.id);
              ref.read(categoriesProvider.notifier).loadCategories();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.sageDark,
                    content: Text('Kategori "${category.name}" berhasil dihapus', style: const TextStyle(color: AppColors.cream)),
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.sageDark,
          labelColor: AppColors.sageDark,
          unselectedLabelColor: AppColors.ink.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final expenseCategories =
              categories.where((c) => c.type == CategoryType.expense).toList();
          final incomeCategories =
              categories.where((c) => c.type == CategoryType.income).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryListView(expenseCategories, CategoryType.expense),
              _buildCategoryListView(incomeCategories, CategoryType.income),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageDark)),
        error: (err, st) => Center(child: Text('Gagal memuat kategori: $err', style: const TextStyle(color: AppColors.ink))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        onPressed: () {
          final currentType = _tabController.index == 0
              ? CategoryType.expense
              : CategoryType.income;
          _showCategoryDialog(defaultType: currentType);
        },
        child: const Icon(Icons.add, color: AppColors.cream),
      ),
    );
  }

  Widget _buildCategoryListView(List<Category> list, CategoryType type) {
    if (list.isEmpty) {
      return const Center(child: Text('Belum ada kategori.', style: TextStyle(color: AppColors.ink)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88, top: 12, left: 16, right: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cat = list[index];

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
              backgroundColor: type == CategoryType.income
                  ? AppColors.income.withValues(alpha: 0.12)
                  : AppColors.expense.withValues(alpha: 0.12),
              child: Icon(
                type == CategoryType.income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: type == CategoryType.income ? AppColors.income : AppColors.expense,
                size: 20,
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            subtitle: cat.isDefault
                ? Text('Bawaan sistem', style: TextStyle(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.5)))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.sageDark, size: 20),
                  onPressed: () {
                    _showCategoryDialog(category: cat, defaultType: type);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                  onPressed: () {
                    _confirmDeleteCategory(cat);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
