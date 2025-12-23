import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart' as app;
import 'package:rooms/src/features/auth/domain/repositories/auth_repository_new.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Supabase implementation of AuthRepository
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseService _supabaseService;

  SupabaseAuthRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService.instance;

  sb.SupabaseClient get _client => _supabaseService.client;

  @override
  Future<app.User> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      AppLogger.auth('Sign up attempt for $email');

      // Check if email already exists
      final exists = await emailExists(email);
      if (exists) {
        throw Exception('Email already registered');
      }

      // Sign up with Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );

      if (response.user == null) {
        throw Exception('Sign up failed - no user returned');
      }

      AppLogger.success('User signed up: ${response.user!.id}', tag: 'Auth');

      // Fetch the created user profile with retry (database trigger might take a moment)
      app.User? userProfile;
      int retries = 0;
      const maxRetries = 5;

      while (userProfile == null && retries < maxRetries) {
        if (retries > 0) {
          AppLogger.debug(
            'Waiting for profile creation... (attempt ${retries + 1}/$maxRetries)',
            tag: 'Auth',
          );
          await Future.delayed(Duration(milliseconds: 500 * retries));
        }

        userProfile = await _getUserProfile(response.user!.id);
        retries++;
      }

      if (userProfile == null) {
        throw Exception('User profile not created after $maxRetries attempts');
      }

      AppLogger.success('User profile created successfully', tag: 'Auth');

      return userProfile;
    } on sb.AuthException catch (e) {
      AppLogger.error('Supabase Auth error', tag: 'Auth', error: e.message);
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      AppLogger.error('Sign up error', tag: 'Auth', error: e);
      rethrow;
    }
  }

  @override
  Future<app.User> login({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.auth('Login attempt for $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed - no user returned');
      }

      AppLogger.success('User logged in: ${response.user!.id}', tag: 'Auth');

      // Fetch user profile
      final userProfile = await _getUserProfile(response.user!.id);

      if (userProfile == null) {
        // Profile doesn't exist yet - create a minimal user from auth data
        // This allows the router to redirect them to the setup page
        AppLogger.warning(
          'No profile found, creating minimal user for setup flow',
          tag: 'Auth',
        );
        final authUser = response.user!;
        return app.User(
          id: authUser.id,
          name:
              authUser.userMetadata?['name'] as String? ??
              authUser.email?.split('@').first ??
              'User',
          email: authUser.email ?? '',
          phone: authUser.userMetadata?['phone'] as String?,
          createdAt: DateTime.now(),
          isActive: true,
          hasBiometric: false,
        );
      }

      if (!userProfile.isActive) {
        await logout();
        throw Exception('Account is deactivated. Contact administrator.');
      }

      AppLogger.success('Login successful: ${userProfile.name}', tag: 'Auth');

      return userProfile;
    } on sb.AuthException catch (e) {
      AppLogger.error('Supabase Auth error', tag: 'Auth', error: e.message);
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      AppLogger.error('Login error', tag: 'Auth', error: e);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      AppLogger.auth('Logout');
      await _client.auth.signOut();
      AppLogger.success('Logged out successfully', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Logout error', tag: 'Auth', error: e);
      rethrow;
    }
  }

  @override
  Future<app.User?> getCurrentUser() async {
    try {
      final authUser = _client.auth.currentUser;

      if (authUser == null) {
        AppLogger.info('No authenticated user', tag: 'Auth');
        return null;
      }

      AppLogger.debug('Getting profile for user: ${authUser.id}', tag: 'Auth');
      final userProfile = await _getUserProfile(authUser.id);

      if (userProfile == null) {
        // Profile doesn't exist yet - create minimal user for setup flow
        AppLogger.warning(
          'No profile found, creating minimal user for setup flow',
          tag: 'Auth',
        );
        return app.User(
          id: authUser.id,
          name:
              authUser.userMetadata?['name'] as String? ??
              authUser.email?.split('@').first ??
              'User',
          email: authUser.email ?? '',
          phone: authUser.userMetadata?['phone'] as String?,
          createdAt: DateTime.now(),
          isActive: true,
          hasBiometric: false,
        );
      }

      return userProfile;
    } catch (e) {
      AppLogger.error('Error getting current user', tag: 'Auth', error: e);
      return null;
    }
  }

  @override
  Stream<app.User?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final authUser = state.session?.user;
      if (authUser == null) return null;

      final userProfile = await _getUserProfile(authUser.id);

      if (userProfile == null) {
        // Profile doesn't exist yet - create minimal user for setup flow
        AppLogger.warning(
          'No profile found in auth state, creating minimal user',
          tag: 'Auth',
        );
        return app.User(
          id: authUser.id,
          name:
              authUser.userMetadata?['name'] as String? ??
              authUser.email?.split('@').first ??
              'User',
          email: authUser.email ?? '',
          phone: authUser.userMetadata?['phone'] as String?,
          createdAt: DateTime.now(),
          isActive: true,
          hasBiometric: false,
        );
      }

      return userProfile;
    });
  }

  @override
  Future<List<app.UserHotel>> getUserHotels(String userId) async {
    try {
      AppLogger.debug('Getting hotels for user: $userId', tag: 'Auth');

      final response = await _client.rpc(
        'get_user_hotels',
        params: {'user_uuid': userId},
      );

      final hotels = (response as List)
          .map((json) => app.UserHotel.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.success('Found ${hotels.length} hotels for user', tag: 'Auth');

      return hotels;
    } catch (e) {
      AppLogger.error('Error getting user hotels', tag: 'Auth', error: e);
      return [];
    }
  }

  @override
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
  }) async {
    try {
      AppLogger.debug(
        'Updating/creating profile for user: $userId',
        tag: 'Auth',
      );

      // Use upsert to ensure profile exists - if it doesn't exist, create it
      final profileData = <String, dynamic>{'id': userId, 'is_active': true};
      if (name != null) profileData['name'] = name;
      if (phone != null) profileData['phone'] = phone;

      await _client.from('user_profiles').upsert(profileData, onConflict: 'id');

      AppLogger.success('Profile updated/created successfully', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Error updating profile', tag: 'Auth', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateBiometricStatus({
    required String userId,
    required bool hasBiometric,
  }) async {
    try {
      AppLogger.debug(
        'Updating biometric status for user: $userId',
        tag: 'Auth',
      );

      await _client
          .from('user_profiles')
          .update({
            'has_biometric': hasBiometric,
            'biometric_enrolled_at': hasBiometric
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', userId);

      AppLogger.success('Biometric status updated', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Error updating biometric status', tag: 'Auth', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> emailExists(String email) async {
    try {
      // Note: Supabase Auth handles duplicate email checking
      // This will be caught during sign up
      return false;
    } catch (e) {
      AppLogger.info('Email check error: $e', tag: 'Auth');
      return false;
    }
  }

  /// Private helper to fetch user profile
  Future<app.User?> _getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('User profile not found for: $userId', tag: 'Auth');
        return null;
      }

      // Get email from auth user
      final authUser = _client.auth.currentUser;
      final email = authUser?.email ?? '';

      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] = email;

      return app.User.fromJson(profileData);
    } catch (e) {
      AppLogger.error('Error fetching user profile', tag: 'Auth', error: e);
      return null;
    }
  }

  /// Change user password
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.auth('Changing password');

      // Supabase requires the user to be signed in with the current session
      // The updateUser method will update the password
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));

      AppLogger.success('Password changed successfully', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Error changing password', tag: 'Auth', error: e);
      throw Exception('Failed to change password: $e');
    }
  }

  /// Create a staff account (owner only)
  /// IMPORTANT: This method preserves the owner's session after creating the staff account
  @override
  Future<void> createStaffAccount({
    required String email,
    required String password,
    required String name,
    String? phone,
    required app.UserRole role,
    required String hotelId,
  }) async {
    try {
      AppLogger.auth('Creating staff account for $email');

      // IMPORTANT: Save the owner's session BEFORE signing up the new user
      // because signUp() auto-logs in as the new user
      final ownerSession = _client.auth.currentSession;
      final ownerId = _client.auth.currentUser?.id;

      if (ownerId == null || ownerSession == null) {
        throw Exception(
          'You must be logged in as the hotel owner to create staff accounts',
        );
      }
      AppLogger.debug('Owner creating staff: $ownerId', tag: 'Auth');

      // Create user via Supabase Auth
      // Note: This will log us in as the new user!
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );

      if (response.user == null) {
        // Restore owner session before throwing
        await _client.auth.setSession(ownerSession.refreshToken!);
        throw Exception('Failed to create staff account');
      }

      final newUserId = response.user!.id;
      AppLogger.success('Staff user created: $newUserId', tag: 'Auth');

      // Wait for the user_profiles trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Use RPC function to add staff (bypasses RLS since it uses SECURITY DEFINER)
      // The function verifies that p_created_by is the hotel owner
      await _client.rpc(
        'add_staff_to_hotel',
        params: {
          'p_hotel_id': hotelId,
          'p_user_id': newUserId,
          'p_role': role.dbValue,
          'p_created_by': ownerId,
        },
      );

      AppLogger.success(
        'Staff added to hotel with role: ${role.displayName}',
        tag: 'Auth',
      );

      // CRITICAL: Restore owner's session after creating staff
      AppLogger.debug('Restoring owner session...', tag: 'Auth');
      await _client.auth.setSession(ownerSession.refreshToken!);
      AppLogger.success('Owner session restored', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Error creating staff account', tag: 'Auth', error: e);
      throw Exception('Failed to create staff account: $e');
    }
  }

  /// Get hotel by hotel code
  @override
  Future<Map<String, dynamic>?> getHotelByCode(String hotelCode) async {
    try {
      AppLogger.debug('Looking up hotel by code: $hotelCode', tag: 'Auth');

      // Use the get_hotel_by_code RPC function (SECURITY DEFINER)
      // This ensures consistent access regardless of auth state
      final response = await _client.rpc(
        'get_hotel_by_code',
        params: {'p_hotel_code': hotelCode.toLowerCase()},
      );

      if (response == null || (response as List).isEmpty) {
        AppLogger.warning('Hotel not found for code: $hotelCode', tag: 'Auth');
        return null;
      }

      final hotel = response.first as Map<String, dynamic>;
      AppLogger.success('Found hotel: ${hotel['name']}', tag: 'Auth');
      return hotel;
    } catch (e) {
      AppLogger.error('Error looking up hotel', tag: 'Auth', error: e);
      return null;
    }
  }

  /// Check if hotel code is available
  @override
  Future<bool> isHotelCodeAvailable(String hotelCode) async {
    try {
      AppLogger.debug(
        'Checking hotel code availability: $hotelCode',
        tag: 'Auth',
      );

      final response = await _client
          .from('hotels')
          .select('id')
          .eq('hotel_code', hotelCode.toLowerCase())
          .maybeSingle();

      final isAvailable = response == null;
      AppLogger.success('Hotel code available: $isAvailable', tag: 'Auth');
      return isAvailable;
    } catch (e) {
      AppLogger.error('Error checking hotel code', tag: 'Auth', error: e);
      return false;
    }
  }

  /// Get hotels owned by the current user
  @override
  Future<List<Map<String, dynamic>>> getOwnerHotels(String userId) async {
    try {
      AppLogger.debug('Getting hotels owned by user: $userId', tag: 'Auth');

      final response = await _client
          .from('hotels')
          .select(
            'id, name, address, phone, email, hotel_code, is_setup_completed, created_at',
          )
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final hotels = (response as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();

      AppLogger.success(
        'Found ${hotels.length} hotels owned by user',
        tag: 'Auth',
      );

      return hotels;
    } catch (e) {
      AppLogger.error('Error getting owner hotels', tag: 'Auth', error: e);
      return [];
    }
  }
}
