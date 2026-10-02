import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teduh/features/auth/data/auth_service.dart';
import 'package:teduh/features/auth/domain/user_profile.dart';
import 'package:teduh/features/auth/presentation/screens/login_screen.dart';
import 'package:teduh/features/household/presentation/screens/household_setup_screen.dart';
import 'package:teduh/features/transactions/data/firestore_repositories.dart';
import 'package:teduh/features/transactions/presentation/providers/transaction_providers.dart';

class AuthGate extends ConsumerWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<UserProfile?>(
          stream: authService.streamUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              // Jika user terautentikasi tapi dokumen profile di Firestore belum ada,
              // buatkan profil secara otomatis di background agar tidak terjebak di Login.
              authService.ensureUserProfileExists(user);
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profile.householdId == null || profile.householdId!.isEmpty) {
              return HouseholdSetupScreen(uid: profile.uid);
            }

            // Integrasi Firestore Repositories Real-Time per Household
            final householdId = profile.householdId!;

            return ProviderScope(
              overrides: [
                categoryRepositoryProvider.overrideWithValue(
                  FirestoreCategoryRepository(householdId: householdId),
                ),
                transactionRepositoryProvider.overrideWithValue(
                  FirestoreTransactionRepository(householdId: householdId),
                ),
              ],
              child: child,
            );
          },
        );
      },
    );
  }
}
