import '../domain/category_model.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}

class InMemoryCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [
    // Pengeluaran Default
    const Category(id: 'cat_exp_1', name: 'Makan & Minum', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_2', name: 'Belanja Rumah Tangga', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_3', name: 'Transportasi', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_4', name: 'Tagihan & Utilitas', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_5', name: 'Kesehatan', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_6', name: 'Pendidikan', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_7', name: 'Hiburan', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_8', name: 'Sedekah & Donasi', type: CategoryType.expense, isDefault: true),
    const Category(id: 'cat_exp_9', name: 'Lainnya', type: CategoryType.expense, isDefault: true),
    // Pemasukan Default
    const Category(id: 'cat_inc_1', name: 'Gaji', type: CategoryType.income, isDefault: true),
    const Category(id: 'cat_inc_2', name: 'Bonus', type: CategoryType.income, isDefault: true),
    const Category(id: 'cat_inc_3', name: 'Usaha', type: CategoryType.income, isDefault: true),
    const Category(id: 'cat_inc_4', name: 'Lainnya', type: CategoryType.income, isDefault: true),
  ];

  @override
  Future<List<Category>> getCategories() async {
    return List.unmodifiable(_categories);
  }

  @override
  Future<void> addCategory(Category category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }
}
