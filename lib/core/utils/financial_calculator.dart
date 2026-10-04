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

class UserBalanceSummary {
  final String uid;
  final String userName;
  final int income;
  final int expense;
  final int balance;

  const UserBalanceSummary({
    required this.uid,
    required this.userName,
    required this.income,
    required this.expense,
    required this.balance,
  });
}

class FinancialSummary {
  final int totalIncome;
  final int totalExpense;
  final int balance;
  final List<CategorySummary> categorySummaries;
  final Map<String, UserBalanceSummary> userBalances;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categorySummaries,
    required this.userBalances,
  });

  static FinancialSummary calculate(
    List<Transaction> transactions, {
    bool excludeInternalTransfers = false,
  }) {
    int income = 0;
    int expense = 0;
    final Map<String, int> expensePerCategory = {};
    final Map<String, String> categoryNames = {};

    // Tracking Saldo Per User
    final Map<String, int> userIncomes = {};
    final Map<String, int> userExpenses = {};
    final Map<String, String> userNames = {};

    for (final tx in transactions) {
      // Jika excludeInternalTransfers aktif, kecualikan transaksi bertipe Transfer Internal dari Cashflow & Grafik
      final isTransferInternal = tx.categoryId == 'cat_transfer' ||
          tx.categoryName == 'Transfer Internal' ||
          tx.title.startsWith('Transfer ');

      if (excludeInternalTransfers && isTransferInternal) {
        continue;
      }

      final uid = tx.createdBy;
      userNames[uid] = tx.createdByName;

      if (tx.type == TransactionType.income) {
        income += tx.amount;
        userIncomes[uid] = (userIncomes[uid] ?? 0) + tx.amount;
      } else {
        expense += tx.amount;
        userExpenses[uid] = (userExpenses[uid] ?? 0) + tx.amount;
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

    final Map<String, UserBalanceSummary> uBalances = {};
    userNames.forEach((uid, name) {
      final uInc = userIncomes[uid] ?? 0;
      final uExp = userExpenses[uid] ?? 0;
      uBalances[uid] = UserBalanceSummary(
        uid: uid,
        userName: name,
        income: uInc,
        expense: uExp,
        balance: uInc - uExp,
      );
    });

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      categorySummaries: summaries,
      userBalances: uBalances,
    );
  }
}
