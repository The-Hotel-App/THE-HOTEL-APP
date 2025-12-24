import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/biometric_audit_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for biometric audit logging
/// Handles logging and retrieval of biometric verification attempts
class BiometricAuditLogRepository {
  final SupabaseService _supabaseService;

  BiometricAuditLogRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// Log a biometric verification attempt
  /// Creates an entry in the biometric_audit_logs table
  Future<void> logVerification({
    required String hotelId,
    required String userId,
    required String actionType,
    String? referenceId,
    required bool success,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      AppLogger.debug(
        'Logging biometric verification: $actionType, success: $success',
        tag: 'BiometricAudit',
      );

      await _client.from('biometric_audit_logs').insert({
        'hotel_id': hotelId,
        'user_id': userId,
        'action_type': actionType,
        'reference_id': referenceId,
        'verified_at': DateTime.now().toIso8601String(),
        'device_info': deviceInfo,
        'success': success,
      });

      AppLogger.success(
        'Biometric verification logged successfully',
        tag: 'BiometricAudit',
      );
    } catch (e) {
      AppLogger.error(
        'Error logging biometric verification',
        tag: 'BiometricAudit',
        error: e,
      );
      rethrow;
    }
  }

  /// Get verification logs for a specific user
  /// Returns logs ordered by verified_at descending (most recent first)
  Future<List<BiometricAuditLog>> getLogsForUser(String userId) async {
    try {
      AppLogger.debug(
        'Getting biometric logs for user: $userId',
        tag: 'BiometricAudit',
      );

      final response = await _client
          .from('biometric_audit_logs')
          .select()
          .eq('user_id', userId)
          .order('verified_at', ascending: false);

      final logs = (response as List)
          .map(
            (json) => BiometricAuditLog.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      AppLogger.success(
        'Found ${logs.length} biometric logs for user',
        tag: 'BiometricAudit',
      );

      return logs;
    } catch (e) {
      AppLogger.error(
        'Error getting biometric logs for user',
        tag: 'BiometricAudit',
        error: e,
      );
      return [];
    }
  }

  /// Get verification logs for a specific hotel
  /// Returns logs ordered by verified_at descending (most recent first)
  Future<List<BiometricAuditLog>> getLogsForHotel(String hotelId) async {
    try {
      AppLogger.debug(
        'Getting biometric logs for hotel: $hotelId',
        tag: 'BiometricAudit',
      );

      final response = await _client
          .from('biometric_audit_logs')
          .select()
          .eq('hotel_id', hotelId)
          .order('verified_at', ascending: false);

      final logs = (response as List)
          .map(
            (json) => BiometricAuditLog.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      AppLogger.success(
        'Found ${logs.length} biometric logs for hotel',
        tag: 'BiometricAudit',
      );

      return logs;
    } catch (e) {
      AppLogger.error(
        'Error getting biometric logs for hotel',
        tag: 'BiometricAudit',
        error: e,
      );
      return [];
    }
  }

  /// Get verification logs for a specific action type
  /// Useful for auditing specific types of actions
  Future<List<BiometricAuditLog>> getLogsByActionType({
    required String hotelId,
    required String actionType,
    int? limit,
  }) async {
    try {
      AppLogger.debug(
        'Getting biometric logs for action type: $actionType',
        tag: 'BiometricAudit',
      );

      var query = _client
          .from('biometric_audit_logs')
          .select()
          .eq('hotel_id', hotelId)
          .eq('action_type', actionType)
          .order('verified_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      final logs = (response as List)
          .map(
            (json) => BiometricAuditLog.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      AppLogger.success(
        'Found ${logs.length} biometric logs for action type',
        tag: 'BiometricAudit',
      );

      return logs;
    } catch (e) {
      AppLogger.error(
        'Error getting biometric logs by action type',
        tag: 'BiometricAudit',
        error: e,
      );
      return [];
    }
  }

  /// Get a specific log entry by reference ID
  /// Useful for looking up the verification for a specific action
  Future<BiometricAuditLog?> getLogByReferenceId(String referenceId) async {
    try {
      AppLogger.debug(
        'Getting biometric log for reference: $referenceId',
        tag: 'BiometricAudit',
      );

      final response = await _client
          .from('biometric_audit_logs')
          .select()
          .eq('reference_id', referenceId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning(
          'No biometric log found for reference: $referenceId',
          tag: 'BiometricAudit',
        );
        return null;
      }

      return BiometricAuditLog.fromJson(response);
    } catch (e) {
      AppLogger.error(
        'Error getting biometric log by reference',
        tag: 'BiometricAudit',
        error: e,
      );
      return null;
    }
  }
}
