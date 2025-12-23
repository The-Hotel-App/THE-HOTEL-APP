import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/notifications/domain/entities/app_notification.dart';
import 'package:rooms/src/features/notifications/presentation/providers/notification_providers.dart';

/// Notifications page showing notification history with clear/restore functionality
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _showHidden = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notificationsAsync = ref.watch(notificationNotifierProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value, user.id),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Clear history'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'restore',
                enabled: _showHidden,
                child: Row(
                  children: [
                    Icon(
                      Icons.restore,
                      size: 20,
                      color: _showHidden ? null : AppColors.grey400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Restore notifications',
                      style: TextStyle(
                        color: _showHidden ? null : AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(notificationNotifierProvider(user.id).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return _buildNotificationsList(notifications, user.id);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 40,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (_showHidden) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _restoreNotifications(),
              icon: const Icon(Icons.restore),
              label: const Text('Restore cleared notifications'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    List<AppNotification> notifications,
    String userId,
  ) {
    // Group notifications by date
    final grouped = <String, List<AppNotification>>{};
    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationNotifierProvider(userId).notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final items = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey600,
                  ),
                ),
              ),
              // Notifications for this date
              ...items.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationCard(n, userId),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, String userId) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification, userId),
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.grey100 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? AppColors.grey300
                : color.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: notification.isRead
                        ? FontWeight.w600
                        : FontWeight.bold,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(fontSize: 11, color: AppColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, String userId) {
    switch (action) {
      case 'mark_all_read':
        ref.read(notificationNotifierProvider(userId).notifier).markAllAsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'clear_history':
        _showClearConfirmation(userId);
        break;
      case 'restore':
        _restoreNotifications();
        break;
    }
  }

  void _showClearConfirmation(String userId) {
    AppDialog.show(
      context: context,
      title: 'Clear Notification History?',
      content: const Text(
        'This will hide all notifications from view. You can restore them later if needed.',
      ),
      primaryButtonText: 'Clear',
      onPrimaryPressed: () {
        Navigator.pop(context);
        _clearHistory(userId);
      },
      secondaryButtonText: 'Cancel',
    );
  }

  void _clearHistory(String userId) async {
    try {
      await ref.read(notificationNotifierProvider(userId).notifier).hideAll();
      setState(() => _showHidden = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications cleared'),
            backgroundColor: AppColors.grey700,
            action: SnackBarAction(
              label: 'Restore',
              textColor: AppColors.warning,
              onPressed: _restoreNotifications,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _restoreNotifications() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref
          .read(notificationNotifierProvider(user.id).notifier)
          .restoreAll();
      setState(() => _showHidden = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications restored'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(AppNotification notification, String userId) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider(userId).notifier).markAsRead([
        notification.id,
      ]);
    }

    // TODO: Navigate to relevant screen based on notification type
    // For now, just show the data in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'Hotel: ${notification.hotelName ?? 'Unknown'}',
              style: TextStyle(color: AppColors.grey600, fontSize: 12),
            ),
            if (notification.roomNumber != null)
              Text(
                'Room: ${notification.roomNumber}',
                style: TextStyle(color: AppColors.grey600, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newBooking:
        return AppColors.info;
      case NotificationType.roomStatusChange:
        return AppColors.warning;
      case NotificationType.checkout:
        return AppColors.success;
      case NotificationType.payment:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.grey600;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newBooking:
        return Icons.event_available;
      case NotificationType.roomStatusChange:
        return Icons.meeting_room;
      case NotificationType.checkout:
        return Icons.check_circle_outline;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('h:mm a').format(date);
    }
  }
}
