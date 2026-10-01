import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String householdId;

  FirestoreCategoryRepository({required this.householdId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('households').doc(householdId).collection('categories');

  @override
  Future<List<Category>> getCategories() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Category.fromMap(doc.data())).toList();
  }

  Stream<List<Category>> streamCategories() {
    return _collection.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Category.fromMap(doc.data())).toList(),
        );
  }

  @override
  Future<void> addCategory(Category category) async {
    await _collection.doc(category.id).set(category.toMap());
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _collection.doc(category.id).update(category.toMap());
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _collection.doc(id).delete();
  }

  // Seed Kategori Default ke Firestore saat Household baru dibuat
  Future<void> seedDefaultCategories() async {
    final defaultRepo = InMemoryCategoryRepository();
    final defaultCategories = await defaultRepo.getCategories();

    final batch = _firestore.batch();
    for (final cat in defaultCategories) {
      final docRef = _collection.doc(cat.id);
      batch.set(docRef, cat.toMap());
    }
    await batch.commit();
  }
}

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String householdId;

  FirestoreTransactionRepository({required this.householdId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('households').doc(householdId).collection('transactions');

  @override
  Future<List<Transaction>> getTransactions() async {
    final snapshot = await _collection.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
  }

  Stream<List<Transaction>> streamTransactions() {
    return _collection.orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList(),
        );
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await _collection.doc(transaction.id).set(transaction.toMap());
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await _collection.doc(transaction.id).update(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _collection.doc(id).delete();
  }
}
