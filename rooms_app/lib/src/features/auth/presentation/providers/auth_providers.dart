import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/auth/data/repositories/dummy_auth_repository.dart';
import 'package:rooms/src/features/auth/domain/entities/user.dart';
import 'package:rooms/src/features/auth/domain/repositories/auth_repository.dart';

/// Provider for auth repository
/// Switch between DummyAuthRepository and real implementation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DummyAuthRepository();
});

/// Provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchAuthState();
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  return authRepo.isAuthenticated();
});
