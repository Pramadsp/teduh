class Household {
  final String id;
  final String name;
  final List<String> memberIds;
  final String inviteCode;
  final String? creatorUid;
  final List<String> transferPrivileges;
  final DateTime createdAt;

  const Household({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.inviteCode,
    this.creatorUid,
    this.transferPrivileges = const [],
    required this.createdAt,
  });

  bool isOwner(String uid) {
    if (creatorUid == null || creatorUid!.isEmpty) {
      // Fallback untuk grup lama: member pertama dianggap creator/owner (Admin/Leader)
      return memberIds.isNotEmpty && memberIds.first == uid;
    }
    return creatorUid == uid;
  }

  bool canTransfer(String uid) {
    return isOwner(uid) || transferPrivileges.contains(uid);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'creatorUid': creatorUid,
      'transferPrivileges': transferPrivileges,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Household.fromMap(Map<String, dynamic> map) {
    final memberList = List<String>.from(map['memberIds'] as List);
    final privilegesList = map['transferPrivileges'] != null
        ? List<String>.from(map['transferPrivileges'] as List)
        : <String>[];

    return Household(
      id: map['id'] as String,
      name: map['name'] as String,
      memberIds: memberList,
      inviteCode: map['inviteCode'] as String,
      creatorUid: (map['creatorUid'] as String?) ?? (memberList.isNotEmpty ? memberList.first : null),
      transferPrivileges: privilegesList,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
