import '../../features/transactions/domain/transaction_model.dart';

class CategorySummary {
  final String categoryId;
  final String categoryName;
  final int totalAmount;
  final double percentage; // 0.0 - 100.0

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
  });
}

class FinancialSummary {
  final int totalIncome;
  final int totalExpense;
  final int balance;
  final List<CategorySummary> categorySummaries;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categorySummaries,
  });

  static FinancialSummary calculate(List<Transaction> transactions) {
    int income = 0;
    int expense = 0;
    final Map<String, int> expensePerCategory = {};
    final Map<String, String> categoryNames = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        expensePerCategory[tx.categoryId] =
            (expensePerCategory[tx.categoryId] ?? 0) + tx.amount;
        categoryNames[tx.categoryId] = tx.categoryName;
      }
    }

    final List<CategorySummary> summaries = [];
    if (expense > 0) {
      expensePerCategory.forEach((catId, catAmount) {
        final percentage = (catAmount / expense) * 100;
        summaries.add(CategorySummary(
          categoryId: catId,
          categoryName: categoryNames[catId] ?? 'Lainnya',
          totalAmount: catAmount,
          percentage: percentage,
        ));
      });
      // Urutkan pengeluaran terbesar di atas
      summaries.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      categorySummaries: summaries,
    );
  }
}
