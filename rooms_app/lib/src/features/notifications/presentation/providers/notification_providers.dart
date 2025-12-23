import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/notifications/data/repositories/supabase_notification_repository.dart';
import 'package:rooms/src/features/notifications/domain/entities/app_notification.dart';
import 'package:rooms/src/features/notifications/domain/repositories/notification_repository.dart';

/// Provider for notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

/// Provider for all notifications for the current user
final notificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications(user.id);
});

/// Stream provider for real-time notification updates
final notificationsStreamProvider = StreamProvider<List<AppNotification>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(user.id);
});

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 0;

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount(user.id);
});

/// Provider for notifications filtered by current hotel
final hotelNotificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final hotel = ref.watch(currentHotelProvider);

  if (user == null || hotel == null) return [];

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotificationsForHotel(user.id, hotel.hotelId);
});

/// State provider to track if notifications are hidden (cleared)
final notificationsHiddenProvider = StateProvider<bool>((ref) => false);

/// Notifier for managing notification actions
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;
  final String _userId;

  NotificationNotifier(this._repository, this._userId)
    : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _repository.getNotifications(_userId);
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _loadNotifications();

  Future<void> markAsRead(List<String> ids) async {
    try {
      await _repository.markAsRead(ids);
      await _loadNotifications();
    } catch (e) {
      // Ignore errors for mark as read
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead(_userId);
      await _loadNotifications();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> hideAll() async {
    await _repository.hideAllNotifications(_userId);
    await _loadNotifications();
  }

  Future<void> restoreAll() async {
    await _repository.restoreNotifications(_userId);
    await _loadNotifications();
  }
}

/// Provider for notification notifier
final notificationNotifierProvider =
    StateNotifierProvider.family<
      NotificationNotifier,
      AsyncValue<List<AppNotification>>,
      String
    >((ref, userId) {
      final repo = ref.watch(notificationRepositoryProvider);
      return NotificationNotifier(repo, userId);
    });
