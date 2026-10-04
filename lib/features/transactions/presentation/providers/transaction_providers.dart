import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/domain/category_model.dart';
import '../../data/firestore_repositories.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction_model.dart';

// Stream Active Household ID dari UserProfile Firestore
final activeHouseholdIdProvider = StreamProvider<String?>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .snapshots()
      .map((doc) => doc.exists && doc.data() != null ? doc.data()!['householdId'] as String? : null);
});

// Repositories Providers (Dinamis: Firestore jika householdId ada, Fallback InMemory)
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final householdIdAsync = ref.watch(activeHouseholdIdProvider);
  final householdId = householdIdAsync.value;

  if (householdId != null && householdId.isNotEmpty) {
    return FirestoreCategoryRepository(householdId: householdId);
  }
  return InMemoryCategoryRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final householdIdAsync = ref.watch(activeHouseholdIdProvider);
  final householdId = householdIdAsync.value;

  if (householdId != null && householdId.isNotEmpty) {
    return FirestoreTransactionRepository(householdId: householdId);
  }
  return InMemoryTransactionRepository();
});

// Categories Notifier (Dukungan Stream Real-Time + Fallback Query)
class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;
  StreamSubscription<List<Category>>? _subscription;

  CategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initCategories();
  }

  void _initCategories() {
    final repo = _repository;
    if (repo is FirestoreCategoryRepository) {
      _subscription?.cancel();
      state = const AsyncValue.loading();
      _subscription = repo.streamCategories().listen(
        (categories) {
          if (mounted) state = AsyncValue.data(categories);
        },
        onError: (err, st) {
          if (mounted) state = AsyncValue.error(err, st);
        },
      );
    } else {
      loadCategories();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadCategories() async {
    try {
      if (mounted) state = const AsyncValue.loading();
      final categories = await _repository.getCategories();
      if (mounted) state = AsyncValue.data(categories);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(Category category) async {
    await _repository.addCategory(category);
    if (_repository is! FirestoreCategoryRepository) {
      await loadCategories();
    }
  }

  Future<void> updateCategory(Category category) async {
    await _repository.updateCategory(category);
    if (_repository is! FirestoreCategoryRepository) {
      await loadCategories();
    }
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    if (_repository is! FirestoreCategoryRepository) {
      await loadCategories();
    }
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>(
  (ref) {
    final repo = ref.watch(categoryRepositoryProvider);
    return CategoriesNotifier(repo);
  },
);

// Transactions Notifier (Dukungan Stream Real-Time + Fallback Query)
class TransactionsNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  StreamSubscription<List<Transaction>>? _subscription;

  TransactionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initTransactions();
  }

  void _initTransactions() {
    final repo = _repository;
    if (repo is FirestoreTransactionRepository) {
      _subscription?.cancel();
      state = const AsyncValue.loading();
      _subscription = repo.streamTransactions().listen(
        (transactions) {
          final sorted = List<Transaction>.from(transactions)
            ..sort((a, b) => b.date.compareTo(a.date));
          if (mounted) state = AsyncValue.data(sorted);
        },
        onError: (err, st) {
          if (mounted) state = AsyncValue.error(err, st);
        },
      );
    } else {
      loadTransactions();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadTransactions() async {
    try {
      if (mounted) state = const AsyncValue.loading();
      final transactions = await _repository.getTransactions();
      final sorted = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      if (mounted) state = AsyncValue.data(sorted);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(Transaction tx) async {
    await _repository.addTransaction(tx);
    if (_repository is! FirestoreTransactionRepository) {
      await loadTransactions();
    }
  }

  Future<void> updateTransaction(Transaction tx) async {
    await _repository.updateTransaction(tx);
    if (_repository is! FirestoreTransactionRepository) {
      await loadTransactions();
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    if (_repository is! FirestoreTransactionRepository) {
      await loadTransactions();
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, AsyncValue<List<Transaction>>>(
  (ref) {
    final repo = ref.watch(transactionRepositoryProvider);
    return TransactionsNotifier(repo);
  },
);
