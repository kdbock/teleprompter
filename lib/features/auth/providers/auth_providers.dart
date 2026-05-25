import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../../../shared/models/app_user.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for Firebase Auth user stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider for current AppUser
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final authRepository = ref.watch(authRepositoryProvider);
  
  await for (final user in authRepository.authStateChanges) {
    if (user == null) {
      yield null;
    } else {
      // Emit immediately from Firebase Auth so navigation is never blocked
      // by Firestore profile hydration on first run.
      final now = DateTime.now();
      yield AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
        photoUrl: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
      );

      // Attempt to upgrade to canonical Firestore-backed profile.
      final firestoreUser = await authRepository.getCurrentAppUser();
      if (firestoreUser != null) {
        yield firestoreUser;
      }
    }
  }
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});
