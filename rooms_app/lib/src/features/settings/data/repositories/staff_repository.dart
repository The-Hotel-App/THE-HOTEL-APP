import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
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
      AppLogger.debug('Fetching staff for hotel: $hotelId', tag: 'Staff');
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

      AppLogger.success('Fetched ${staff.length} staff members', tag: 'Staff');
      return staff;
    } catch (e) {
      AppLogger.error('Error fetching staff', tag: 'Staff', error: e);
      rethrow;
    }
  }

  /// Remove staff from hotel completely
  /// This deletes from hotel_staff and user_profiles if staff only works at this hotel
  Future<void> removeStaff(String staffId, String hotelId) async {
    try {
      AppLogger.info(
        'Removing staff: $staffId from hotel: $hotelId',
        tag: 'Staff',
      );

      // Call the RPC function for complete deletion
      final response = await _client.rpc(
        'delete_staff_completely',
        params: {'p_staff_id': staffId, 'p_hotel_id': hotelId},
      );

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        AppLogger.success('${result['message']}', tag: 'Staff');
      } else {
        throw Exception(result['error'] ?? 'Failed to remove staff');
      }
    } catch (e) {
      AppLogger.error('Error removing staff', tag: 'Staff', error: e);
      rethrow;
    }
  }

  /// Toggle staff active status
  Future<void> toggleStaffActive(String staffId, bool isActive) async {
    try {
      AppLogger.debug(
        'Toggling staff active: $staffId -> $isActive',
        tag: 'Staff',
      );
      await _client
          .from('hotel_staff')
          .update({'is_active': isActive})
          .eq('id', staffId);
      AppLogger.success('Staff status updated', tag: 'Staff');
    } catch (e) {
      AppLogger.error('Error updating staff status', tag: 'Staff', error: e);
      rethrow;
    }
  }

  /// Update staff member details (name and role)
  Future<void> updateStaff({
    required String staffId,
    required String userId,
    required String name,
    required UserRole role,
  }) async {
    try {
      AppLogger.info('Updating staff: $staffId', tag: 'Staff');

      // Update user_profiles (name)
      await _client
          .from('user_profiles')
          .update({'name': name})
          .eq('id', userId);

      // Update hotel_staff (role)
      final roleString = _roleToString(role);
      await _client
          .from('hotel_staff')
          .update({'role': roleString})
          .eq('id', staffId);

      AppLogger.success('Staff updated successfully', tag: 'Staff');
    } catch (e) {
      AppLogger.error('Error updating staff', tag: 'Staff', error: e);
      rethrow;
    }
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager:
        return 'manager';
      case UserRole.staff:
        return 'staff';
      case UserRole.kitchenManager:
        return 'kitchen_manager';
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
