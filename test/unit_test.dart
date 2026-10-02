import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teduh/core/utils/currency_input_formatter.dart';
import 'package:teduh/core/utils/formatters.dart';
import 'package:teduh/features/categories/data/category_repository.dart';
import 'package:teduh/features/categories/domain/category_model.dart';
import 'package:teduh/features/transactions/data/transaction_repository.dart';
import 'package:teduh/features/transactions/domain/transaction_model.dart';
import 'package:teduh/features/transactions/presentation/screens/transaction_list_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('CurrencyInputFormatter Tests', () {
    test('parseAmount parses formatted string to integer', () {
      expect(CurrencyInputFormatter.parseAmount('50.000'), 50000);
      expect(CurrencyInputFormatter.parseAmount('Rp 1.250.000'), 1250000);
      expect(CurrencyInputFormatter.parseAmount(''), 0);
    });
  });

  group('CurrencyUtils & DateUtilsId Tests', () {
    test('formatRupiah formatting correctly', () {
      expect(CurrencyUtils.formatRupiah(1250000), 'Rp 1.250.000');
      expect(CurrencyUtils.formatRupiah(0), 'Rp 0');
    });

    test('DateUtilsId formatters work properly', () {
      final date = DateTime(2026, 10, 1);
      expect(DateUtilsId.formatDateShort(date), contains('1 Okt 2026'));
      expect(DateUtilsId.formatMonthYear(date), contains('Oktober 2026'));
    });
  });

  group('InMemory Repositories Tests', () {
    test('InMemoryCategoryRepository seed & CRUD', () async {
      final repo = InMemoryCategoryRepository();
      var categories = await repo.getCategories();
      expect(categories.length, 13); // 9 expense + 4 income

      const newCat = Category(
        id: 'cat_custom_1',
        name: 'Hobi',
        type: CategoryType.expense,
      );
      await repo.addCategory(newCat);
      categories = await repo.getCategories();
      expect(categories.length, 14);

      await repo.deleteCategory('cat_custom_1');
      categories = await repo.getCategories();
      expect(categories.length, 13);
    });

    test('InMemoryTransactionRepository CRUD', () async {
      final repo = InMemoryTransactionRepository();
      var txs = await repo.getTransactions();
      expect(txs.isEmpty, isTrue);

      final tx = Transaction(
        id: 'tx_1',
        title: 'Makan Nasi Goreng',
        type: TransactionType.expense,
        amount: 50000,
        categoryId: 'cat_exp_1',
        categoryName: 'Makan & Minum',
        date: DateTime.now(),
        createdBy: 'user_1',
        createdByName: 'Suami',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.addTransaction(tx);
      txs = await repo.getTransactions();
      expect(txs.length, 1);
      expect(txs.first.amount, 50000);

      await repo.deleteTransaction('tx_1');
      txs = await repo.getTransactions();
      expect(txs.isEmpty, isTrue);
    });
  });

  group('Transaction CRUD Widget Tests', () {
    testWidgets('TransactionListScreen displays FAB and renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TransactionListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Daftar Transaksi'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
