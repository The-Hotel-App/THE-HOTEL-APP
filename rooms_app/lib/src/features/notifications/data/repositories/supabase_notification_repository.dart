import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/notifications/domain/entities/app_notification.dart';
import 'package:rooms/src/features/notifications/domain/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of NotificationRepository
///
/// Handles all notification CRUD operations with the Supabase database
class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.instance.client;

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      AppLogger.debug(
        'Fetching notifications for user: $userId',
        tag: 'Notifications',
      );

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(100);

      final notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      AppLogger.success(
        'Fetched ${notifications.length} notifications',
        tag: 'Notifications',
      );
      return notifications;
    } catch (e) {
      AppLogger.error(
        'Error fetching notifications',
        tag: 'Notifications',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<List<AppNotification>> getNotificationsForHotel(
    String userId,
    String hotelId,
  ) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('hotel_id', hotelId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching notifications for hotel',
        tag: 'Notifications',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_hidden', false);

      return (response as List).length;
    } catch (e) {
      AppLogger.error(
        'Error getting unread count',
        tag: 'Notifications',
        error: e,
      );
      return 0;
    }
  }

  @override
  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    try {
      await _client.rpc(
        'mark_notifications_read',
        params: {'p_notification_ids': notificationIds},
      );
      AppLogger.success(
        'Marked ${notificationIds.length} notifications as read',
        tag: 'Notifications',
      );
    } catch (e) {
      AppLogger.error(
        'Error marking notifications as read',
        tag: 'Notifications',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      AppLogger.success(
        'Marked all notifications as read',
        tag: 'Notifications',
      );
    } catch (e) {
      AppLogger.error(
        'Error marking all as read',
        tag: 'Notifications',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> hideAllNotifications(String userId) async {
    try {
      await _client.rpc(
        'toggle_notifications_visibility',
        params: {'p_hidden': true},
      );
      AppLogger.success('All notifications hidden', tag: 'Notifications');
    } catch (e) {
      AppLogger.error(
        'Error hiding notifications',
        tag: 'Notifications',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> restoreNotifications(String userId) async {
    try {
      await _client.rpc(
        'toggle_notifications_visibility',
        params: {'p_hidden': false},
      );
      AppLogger.success('All notifications restored', tag: 'Notifications');
    } catch (e) {
      AppLogger.error(
        'Error restoring notifications',
        tag: 'Notifications',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where((json) => json['is_hidden'] != true)
              .map((json) => AppNotification.fromJson(json))
              .toList(),
        );
  }
}
