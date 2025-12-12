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

  /// Register a new user (for employee join flow)
  Future<User> register({
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

  /// Change current user's password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Create a staff account (owner only)
  Future<void> createStaffAccount({
    required String email,
    required String password,
    required String name,
    String? phone,
    required UserRole role,
    required String hotelId,
  });

  /// Get hotel by hotel code
  Future<Map<String, dynamic>?> getHotelByCode(String hotelCode);

  /// Validate join code
  Future<Map<String, dynamic>> validateJoinCode(
    String hotelCode,
    String joinCode,
  );

  /// Submit join request
  Future<void> submitJoinRequest({required String hotelId, String? joinCodeId});

  /// Check if hotel code is available
  Future<bool> isHotelCodeAvailable(String hotelCode);

  /// Get hotels owned by the current user (where user is the owner)
  Future<List<Map<String, dynamic>>> getOwnerHotels(String userId);
}
