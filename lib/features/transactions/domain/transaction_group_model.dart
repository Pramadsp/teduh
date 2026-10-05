class TransactionGroup {
  final String id;
  final String name;
  final DateTime date;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionGroup({
    required this.id,
    required this.name,
    required this.date,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionGroup.fromMap(Map<String, dynamic> map) {
    return TransactionGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      createdBy: map['createdBy'] as String,
      createdByName: map['createdByName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
