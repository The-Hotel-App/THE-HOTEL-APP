import 'package:rooms/src/features/notifications/domain/entities/app_notification.dart';

/// Repository interface for notification operations
///
/// Defines the contract for fetching, updating, and managing notifications.
/// Implementations can be Supabase, dummy, or any other data source.
abstract class NotificationRepository {
  /// Get all notifications for a user across all their hotels
  Future<List<AppNotification>> getNotifications(String userId);

  /// Get notifications for a specific hotel
  Future<List<AppNotification>> getNotificationsForHotel(
    String userId,
    String hotelId,
  );

  /// Get unread notification count
  Future<int> getUnreadCount(String userId);

  /// Mark notifications as read
  Future<void> markAsRead(List<String> notificationIds);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Hide all notifications (soft delete for "clear history")
  Future<void> hideAllNotifications(String userId);

  /// Restore hidden notifications
  Future<void> restoreNotifications(String userId);

  /// Watch notifications stream for real-time updates
  Stream<List<AppNotification>> watchNotifications(String userId);
}
