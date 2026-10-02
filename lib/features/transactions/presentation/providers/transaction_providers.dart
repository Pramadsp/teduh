import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/domain/category_model.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_model.dart';

// Repositories Providers
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return InMemoryCategoryRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return InMemoryTransactionRepository();
});

// Categories Notifier
class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;

  CategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final categories = await _repository.getCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>(
  (ref) {
    final repo = ref.watch(categoryRepositoryProvider);
    return CategoriesNotifier(repo);
  },
  dependencies: [categoryRepositoryProvider],
);

// Transactions Notifier
class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final transactions = await _repository.getTransactions();
      final sorted = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      state = AsyncValue.data(sorted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(Transaction tx) async {
    await _repository.addTransaction(tx);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _repository.updateTransaction(tx);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>(
  (ref) {
    final repo = ref.watch(transactionRepositoryProvider);
    return TransactionsNotifier(repo);
  },
  dependencies: [transactionRepositoryProvider],
);
