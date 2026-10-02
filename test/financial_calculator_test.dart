import 'package:flutter_test/flutter_test.dart';
import 'package:teduh/core/utils/date_range_helper.dart';
import 'package:teduh/core/utils/financial_calculator.dart';
import 'package:teduh/features/transactions/domain/transaction_model.dart';

void main() {
  group('DateRangeHelper Tests', () {
    test('getDailyRange sets start at 00:00:00 and end at 23:59:59', () {
      final date = DateTime(2026, 10, 15, 14, 30);
      final range = DateRangeHelper.getDailyRange(date);

      expect(range.start, DateTime(2026, 10, 15, 0, 0, 0, 0));
      expect(range.end, DateTime(2026, 10, 15, 23, 59, 59, 999));
      expect(range.contains(DateTime(2026, 10, 15, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 16, 0, 0, 0)), isFalse);
    });

    test('getWeeklyRange starts Monday and ends Sunday across month boundary', () {
      // 29 Oct 2026 is Thursday. Monday is 26 Oct, Sunday is 1 Nov.
      final date = DateTime(2026, 10, 29);
      final range = DateRangeHelper.getWeeklyRange(date);

      expect(range.start.weekday, DateTime.monday);
      expect(range.start, DateTime(2026, 10, 26, 0, 0, 0, 0));
      expect(range.end.weekday, DateTime.sunday);
      expect(range.end, DateTime(2026, 11, 1, 23, 59, 59, 999));
    });

    test('getMonthlyRange leap year and month end handling', () {
      // Feb 2024 leap year -> 29 days
      final date = DateTime(2024, 2, 10);
      final range = DateRangeHelper.getMonthlyRange(date);

      expect(range.start, DateTime(2024, 2, 1, 0, 0, 0, 0));
      expect(range.end, DateTime(2024, 2, 29, 23, 59, 59, 999));
    });
  });

  group('FinancialSummary Calculator Tests', () {
    test('calculate totals, balance, and category percentages correctly', () {
      final txs = [
        Transaction(
          id: '1',
          title: 'Gaji Bulanan',
          type: TransactionType.income,
          amount: 5000000,
          categoryId: 'inc_1',
          categoryName: 'Gaji',
          date: DateTime.now(),
          createdBy: 'u1',
          createdByName: 'Suami',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          title: 'Belanja Bulanan',
          type: TransactionType.expense,
          amount: 1500000,
          categoryId: 'exp_1',
          categoryName: 'Belanja',
          date: DateTime.now(),
          createdBy: 'u2',
          createdByName: 'Istri',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '3',
          title: 'Makan',
          type: TransactionType.expense,
          amount: 500000,
          categoryId: 'exp_2',
          categoryName: 'Makan',
          date: DateTime.now(),
          createdBy: 'u1',
          createdByName: 'Suami',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final summary = FinancialSummary.calculate(txs);

      expect(summary.totalIncome, 5000000);
      expect(summary.totalExpense, 2000000);
      expect(summary.balance, 3000000);

      expect(summary.categorySummaries.length, 2);
      expect(summary.categorySummaries.first.categoryName, 'Belanja');
      expect(summary.categorySummaries.first.totalAmount, 1500000);
      expect(summary.categorySummaries.first.percentage, 75.0);

      expect(summary.categorySummaries.last.categoryName, 'Makan');
      expect(summary.categorySummaries.last.totalAmount, 500000);
      expect(summary.categorySummaries.last.percentage, 25.0);
    });
  });
}
