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
      yield await authRepository.getCurrentAppUser();
    }
  }
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});
