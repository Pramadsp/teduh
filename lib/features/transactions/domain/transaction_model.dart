enum TransactionType { income, expense }

class Transaction {
  final String id;
  final TransactionType type;
  final int amount; // dalam integer Rupiah, selalu positif
  final String categoryId;
  final String categoryName;
  final String? note;
  final DateTime date;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.note,
    required this.date,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'note': note,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: map['amount'] as int,
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdBy: map['createdBy'] as String,
      createdByName: map['createdByName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
