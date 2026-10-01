class Household {
  final String id;
  final String name;
  final List<String> memberIds;
  final String inviteCode;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Household.fromMap(Map<String, dynamic> map) {
    return Household(
      id: map['id'] as String,
      name: map['name'] as String,
      memberIds: List<String>.from(map['memberIds'] as List),
      inviteCode: map['inviteCode'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
