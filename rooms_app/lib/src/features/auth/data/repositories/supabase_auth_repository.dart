import 'package:flutter/material.dart';
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
      debugPrint('🔐 SupabaseAuth: Sign up attempt for $email');

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

      debugPrint('✅ User signed up: ${response.user!.id}');

      // Fetch the created user profile with retry (database trigger might take a moment)
      app.User? userProfile;
      int retries = 0;
      const maxRetries = 5;

      while (userProfile == null && retries < maxRetries) {
        if (retries > 0) {
          debugPrint(
            '⏳ Waiting for profile creation... (attempt ${retries + 1}/$maxRetries)',
          );
          await Future.delayed(
            Duration(milliseconds: 500 * retries),
          ); // Progressive delay
        }

        userProfile = await _getUserProfile(response.user!.id);
        retries++;
      }

      if (userProfile == null) {
        throw Exception('User profile not created after $maxRetries attempts');
      }

      debugPrint('✅ User profile created successfully');

      return userProfile;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Supabase Auth error: ${e.message}');
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  @override
  Future<app.User> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 SupabaseAuth: Login attempt for $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed - no user returned');
      }

      debugPrint('✅ User logged in: ${response.user!.id}');

      // Fetch user profile
      final userProfile = await _getUserProfile(response.user!.id);

      if (userProfile == null) {
        // Profile doesn't exist yet - create a minimal user from auth data
        // This allows the router to redirect them to the setup page
        debugPrint('⚠️ No profile found, creating minimal user for setup flow');
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

      debugPrint('✅ Login successful: ${userProfile.name}');

      return userProfile;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Supabase Auth error: ${e.message}');
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      debugPrint('🔐 SupabaseAuth: Logout');
      await _client.auth.signOut();
      debugPrint('✅ Logged out successfully');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      rethrow;
    }
  }

  @override
  Future<app.User?> getCurrentUser() async {
    try {
      final authUser = _client.auth.currentUser;

      if (authUser == null) {
        debugPrint('ℹ️ No authenticated user');
        return null;
      }

      debugPrint('ℹ️ Getting profile for user: ${authUser.id}');
      final userProfile = await _getUserProfile(authUser.id);

      if (userProfile == null) {
        // Profile doesn't exist yet - create minimal user for setup flow
        debugPrint('⚠️ No profile found, creating minimal user for setup flow');
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
      debugPrint('❌ Error getting current user: $e');
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
        debugPrint('⚠️ No profile found in auth state, creating minimal user');
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
      debugPrint('🏨 Getting hotels for user: $userId');

      final response = await _client.rpc(
        'get_user_hotels',
        params: {'user_uuid': userId},
      );

      if (response == null) {
        return [];
      }

      final hotels = (response as List)
          .map((json) => app.UserHotel.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Found ${hotels.length} hotels for user');

      return hotels;
    } catch (e) {
      debugPrint('❌ Error getting user hotels: $e');
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
      debugPrint('👤 Updating profile for user: $userId');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;

      await _client.from('user_profiles').update(updates).eq('id', userId);

      debugPrint('✅ Profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBiometricStatus({
    required String userId,
    required bool hasBiometric,
  }) async {
    try {
      debugPrint('👆 Updating biometric status for user: $userId');

      await _client
          .from('user_profiles')
          .update({
            'has_biometric': hasBiometric,
            'biometric_enrolled_at': hasBiometric
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('id', userId);

      debugPrint('✅ Biometric status updated');
    } catch (e) {
      debugPrint('❌ Error updating biometric status: $e');
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
      debugPrint('ℹ️ Email check error: $e');
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
        debugPrint('⚠️ User profile not found for: $userId');
        return null;
      }

      // Get email from auth user
      final authUser = _client.auth.currentUser;
      final email = authUser?.email ?? '';

      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] = email;

      return app.User.fromJson(profileData);
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
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
      debugPrint('🔐 SupabaseAuth: Changing password');

      // Supabase requires the user to be signed in with the current session
      // The updateUser method will update the password
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));

      debugPrint('✅ Password changed successfully');
    } catch (e) {
      debugPrint('❌ Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  /// Create a staff account (owner only)
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
      debugPrint('🔐 SupabaseAuth: Creating staff account for $email');

      // Create user via Supabase Auth admin functions (requires service role)
      // For now, we'll use the regular signUp and then add to hotel_staff
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );

      if (response.user == null) {
        throw Exception('Failed to create staff account');
      }

      final userId = response.user!.id;
      debugPrint('✅ Staff user created: $userId');

      // Wait for the user_profiles trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Add staff to hotel_staff table with role
      await _client.from('hotel_staff').insert({
        'hotel_id': hotelId,
        'user_id': userId,
        'role': role.dbValue,
        'is_active': true,
        'created_by': _client.auth.currentUser?.id,
      });

      debugPrint('✅ Staff added to hotel with role: ${role.displayName}');
    } catch (e) {
      debugPrint('❌ Error creating staff account: $e');
      throw Exception('Failed to create staff account: $e');
    }
  }
}
