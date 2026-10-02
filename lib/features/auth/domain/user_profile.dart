class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? householdId;
  final String? pin;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.householdId,
    this.pin,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'householdId': householdId,
      'pin': pin,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      email: map['email'] as String,
      householdId: map['householdId'] as String?,
      pin: map['pin'] as String?,
    );
  }
}
