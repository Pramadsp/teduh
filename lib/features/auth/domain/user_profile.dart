class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? householdId;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.householdId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'householdId': householdId,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      householdId: map['householdId'] as String?,
    );
  }
}
