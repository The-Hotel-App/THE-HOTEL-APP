import 'package:rooms/src/features/auth/domain/entities/user.dart';

/// Abstract authentication repository
abstract class AuthRepository {
  /// Login with email and password
  Future<User> login({required String email, required String password});

  /// Logout current user
  Future<void> logout();

  /// Get current authenticated user
  Future<User?> getCurrentUser();

  /// Watch authentication state stream
  Stream<User?> watchAuthState();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
