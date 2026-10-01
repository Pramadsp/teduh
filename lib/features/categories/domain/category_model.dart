enum CategoryType { income, expense }

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String? iconKey;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.iconKey,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconKey': iconKey,
      'isDefault': isDefault,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      iconKey: map['iconKey'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}
