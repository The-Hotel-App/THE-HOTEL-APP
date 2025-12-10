import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart' as app;
import 'package:rooms/src/features/auth/domain/repositories/auth_repository_new.dart';

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
        throw Exception('User profile not found');
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
      return await _getUserProfile(authUser.id);
    } catch (e) {
      debugPrint('❌ Error getting current user: $e');
      return null;
    }
  }

  @override
  Stream<app.User?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;

      return await _getUserProfile(user.id);
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
}
