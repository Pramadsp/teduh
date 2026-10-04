import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teduh/features/categories/presentation/screens/category_list_screen.dart';
import 'package:teduh/features/transactions/data/transaction_repository.dart';
import 'package:teduh/features/transactions/domain/transaction_model.dart';
import 'package:teduh/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  group('Category Management & Protection Tests', () {
    testWidgets('CategoryListScreen renders tabs and lists categories',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeHouseholdIdProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: CategoryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Kelola Kategori'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
    });

    testWidgets('Shows Dialog when trying to delete a used category',
        (WidgetTester tester) async {
      final txRepo = InMemoryTransactionRepository();
      await txRepo.addTransaction(
        Transaction(
          id: 'tx_test_1',
          title: 'Makan & Minum',
          type: TransactionType.expense,
          amount: 25000,
          categoryId: 'cat_exp_1',
          categoryName: 'Makan & Minum',
          date: DateTime.now(),
          createdBy: 'u1',
          createdByName: 'Suami',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          activeHouseholdIdProvider.overrideWith((ref) => Stream.value(null)),
          transactionRepositoryProvider.overrideWithValue(txRepo),
        ],
      );

      // Pastikan transaksi dimuat terlebih dahulu
      await container.read(transactionsProvider.notifier).loadTransactions();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CategoryListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deleteIconButton = find.byIcon(Icons.delete_outline_rounded).first;
      await tester.tap(deleteIconButton);
      await tester.pumpAndSettle();

      expect(find.text('Kategori Tidak Dapat Dihapus'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);
    });
  });
}
