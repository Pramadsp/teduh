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
            title: Text(category == null ? 'Tambah Kategori' : 'Ubah Kategori'),
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
                child: const Text('Batal'),
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
                child: const Text('Simpan'),
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
          title: const Text('Kategori Tidak Dapat Dihapus'),
          content: Text(
            'Kategori "${category.name}" sudah digunakan dalam riwayat transaksi. Anda tidak dapat menghapusnya demi menjaga keutuhan laporan keuangan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(categoryRepositoryProvider);
              await repo.deleteCategory(category.id);
              ref.read(categoriesProvider.notifier).loadCategories();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kategori "${category.name}" berhasil dihapus')),
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
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        bottom: TabBar(
          controller: _tabController,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Gagal memuat kategori: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.terracotta,
        onPressed: () {
          final currentType = _tabController.index == 0
              ? CategoryType.expense
              : CategoryType.income;
          _showCategoryDialog(defaultType: currentType);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryListView(List<Category> list, CategoryType type) {
    if (list.isEmpty) {
      return const Center(child: Text('Belum ada kategori.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cat = list[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.sage.withValues(alpha: 0.2),
              child: Icon(
                type == CategoryType.income ? Icons.arrow_upward : Icons.arrow_downward,
                color: type == CategoryType.income ? AppColors.income : AppColors.expense,
              ),
            ),
            title: Text(
              cat.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: cat.isDefault
                ? const Text('Bawaan sistem', style: TextStyle(fontSize: 12, color: Colors.grey))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    _showCategoryDialog(category: cat, defaultType: type);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.expense),
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
