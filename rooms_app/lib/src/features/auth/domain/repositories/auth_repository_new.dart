import 'package:rooms/src/features/auth/domain/entities/user_new.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Sign up a new user (for hotel owner registration)
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  });

  /// Log in with email and password
  Future<User> login({required String email, required String password});

  /// Log out current user
  Future<void> logout();

  /// Get current authenticated user
  Future<User?> getCurrentUser();

  /// Stream of auth state changes
  Stream<User?> authStateChanges();

  /// Get user's hotels
  Future<List<UserHotel>> getUserHotels(String userId);

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
  });

  /// Update biometric enrollment status
  Future<void> updateBiometricStatus({
    required String userId,
    required bool hasBiometric,
  });

  /// Check if email already exists
  Future<bool> emailExists(String email);
}
