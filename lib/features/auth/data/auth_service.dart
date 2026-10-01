import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../household/domain/household_model.dart';
import '../domain/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register User Baru
  Future<UserProfile> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user!;
    await user.updateDisplayName(displayName);

    final profile = UserProfile(
      uid: user.uid,
      displayName: displayName,
      email: email.trim(),
    );

    await _firestore.collection('users').doc(user.uid).set(profile.toMap());
    return profile;
  }

  // Login User
  Future<UserProfile?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user!;
    return getUserProfile(user.uid);
  }

  // Get User Profile
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  // Stream User Profile
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? UserProfile.fromMap(doc.data()!) : null);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Generate 6 Character Invite Code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Buat Household Baru
  Future<Household> createHousehold({
    required String uid,
    required String householdName,
  }) async {
    final householdId = _firestore.collection('households').doc().id;
    final inviteCode = _generateInviteCode();

    final household = Household(
      id: householdId,
      name: householdName,
      memberIds: [uid],
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );

    // Write batch
    final batch = _firestore.batch();
    batch.set(_firestore.collection('households').doc(householdId), household.toMap());
    batch.set(_firestore.collection('invites').doc(inviteCode), {'householdId': householdId});
    batch.update(_firestore.collection('users').doc(uid), {'householdId': householdId});

    await batch.commit();
    return household;
  }

  // Gabung ke Household dengan Kode Undangan
  Future<void> joinHouseholdWithCode({
    required String uid,
    required String inviteCode,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    final inviteDoc = await _firestore.collection('invites').doc(cleanCode).get();

    if (!inviteDoc.exists || inviteDoc.data() == null) {
      throw Exception('Kode undangan tidak valid');
    }

    final householdId = inviteDoc.data()!['householdId'] as String;
    final householdRef = _firestore.collection('households').doc(householdId);
    final householdDoc = await householdRef.get();

    if (!householdDoc.exists || householdDoc.data() == null) {
      throw Exception('Grup keluarga tidak ditemukan');
    }

    final household = Household.fromMap(householdDoc.data()!);
    if (household.memberIds.length >= 2) {
      throw Exception('Grup keluarga ini sudah penuh (maksimal 2 anggota)');
    }

    final batch = _firestore.batch();
    batch.update(householdRef, {
      'memberIds': FieldValue.arrayUnion([uid])
    });
    batch.update(_firestore.collection('users').doc(uid), {'householdId': householdId});

    await batch.commit();
  }
}
