import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Staff member entity (represents hotel_staff + user_profiles join)
class StaffMember {
  final String id;
  final String hotelId;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;
    return StaffMember(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      userId: json['user_id'] as String,
      name: userProfile?['name'] as String? ?? 'Unknown',
      phone: userProfile?['phone'] as String?,
      role: _parseRole(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'staff':
        return UserRole.staff;
      case 'kitchen_manager':
        return UserRole.kitchenManager;
      default:
        return UserRole.staff;
    }
  }
}

/// Repository for staff CRUD operations
class StaffRepository {
  final SupabaseClient _client;

  StaffRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.instance.client;

  /// Get all staff for a hotel
  Future<List<StaffMember>> getStaff(String hotelId) async {
    try {
      debugPrint('📦 Fetching staff for hotel: $hotelId');
      // Use the explicit relationship name to avoid ambiguity
      // hotel_staff has TWO foreign keys to user_profiles (user_id and created_by)
      // We want the user_id relationship, so we specify: user_profiles!hotel_staff_user_id_fkey
      final response = await _client
          .from('hotel_staff')
          .select('*, user_profiles!hotel_staff_user_id_fkey(name, phone)')
          .eq('hotel_id', hotelId)
          .order('created_at', ascending: false);

      final staff = (response as List)
          .map((json) => StaffMember.fromJson(json))
          .toList();

      debugPrint('✅ Fetched ${staff.length} staff members');
      return staff;
    } catch (e) {
      debugPrint('❌ Error fetching staff: $e');
      rethrow;
    }
  }

  /// Remove staff from hotel completely
  /// This deletes from hotel_staff and user_profiles if staff only works at this hotel
  Future<void> removeStaff(String staffId, String hotelId) async {
    try {
      debugPrint('📦 Removing staff completely: $staffId from hotel: $hotelId');
      
      // Call the RPC function for complete deletion
      final response = await _client.rpc('delete_staff_completely', params: {
        'p_staff_id': staffId,
        'p_hotel_id': hotelId,
      });
      
      final result = response as Map<String, dynamic>;
      
      if (result['success'] == true) {
        debugPrint('✅ ${result['message']}');
      } else {
        throw Exception(result['error'] ?? 'Failed to remove staff');
      }
    } catch (e) {
      debugPrint('❌ Error removing staff: $e');
      rethrow;
    }
  }

  /// Toggle staff active status
  Future<void> toggleStaffActive(String staffId, bool isActive) async {
    try {
      debugPrint('📦 Toggling staff active: $staffId -> $isActive');
      await _client
          .from('hotel_staff')
          .update({'is_active': isActive})
          .eq('id', staffId);
      debugPrint('✅ Staff status updated');
    } catch (e) {
      debugPrint('❌ Error updating staff status: $e');
      rethrow;
    }
  }
}

/// Provider for staff repository
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository();
});

/// Provider for staff list
final staffListProvider = FutureProvider.family<List<StaffMember>, String>((
  ref,
  hotelId,
) async {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.getStaff(hotelId);
});
