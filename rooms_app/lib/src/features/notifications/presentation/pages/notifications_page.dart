import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/notifications/domain/entities/app_notification.dart';
import 'package:rooms/src/features/notifications/presentation/providers/notification_providers.dart';

/// Filter type for notifications
enum NotificationFilter {
  all('All'),
  bookings('Bookings'),
  roomStatus('Room Status'),
  payments('Payments'),
  system('System');

  final String label;
  const NotificationFilter(this.label);
}

/// Notifications page showing notification history with clear/restore functionality
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _showHidden = false;
  NotificationFilter _selectedFilter = NotificationFilter.all;
  final Set<String> _collapsedSections = {};

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
        title: const Text('Notifications'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all, size: 22),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref
                  .read(notificationNotifierProvider(user.id).notifier)
                  .markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All marked as read'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings',
            onPressed: () => _showSettingsBottomSheet(user.id),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Notifications list
          Expanded(
            child: notificationsAsync.when(
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
                final filtered = _filterNotifications(notifications);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildNotificationsList(filtered, user.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build horizontal filter chips
  Widget _buildFilterChips() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: NotificationFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                selectedColor: AppColors.black,
                backgroundColor: AppColors.grey100,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.black : AppColors.grey300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Filter notifications based on selected filter
  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
  ) {
    if (_selectedFilter == NotificationFilter.all) {
      return notifications;
    }
    return notifications.where((n) {
      switch (_selectedFilter) {
        case NotificationFilter.bookings:
          return n.type == NotificationType.newBooking;
        case NotificationFilter.roomStatus:
          return n.type == NotificationType.roomStatusChange;
        case NotificationFilter.payments:
          return n.type == NotificationType.payment ||
              n.type == NotificationType.checkout;
        case NotificationFilter.system:
          return n.type == NotificationType.system;
        default:
          return true;
      }
    }).toList();
  }

  /// Show settings bottom sheet
  void _showSettingsBottomSheet(String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Notification Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              // Clear history option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text('Clear History'),
                subtitle: const Text('Hide all notifications'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showClearConfirmation(userId);
                },
              ),
              // Restore option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restore,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                title: const Text('Restore Notifications'),
                subtitle: const Text('Unhide cleared notifications'),
                enabled: _showHidden,
                onTap: _showHidden
                    ? () {
                        Navigator.pop(ctx);
                        _restoreNotifications();
                      }
                    : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 36,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == NotificationFilter.all
                ? 'No Notifications'
                : 'No ${_selectedFilter.label} Notifications',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
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
        padding: const EdgeInsets.all(12),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final items = grouped[dateKey]!;
          final isCollapsed = _collapsedSections.contains(dateKey);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsible date header
              InkWell(
                onTap: () {
                  setState(() {
                    if (isCollapsed) {
                      _collapsedSections.remove(dateKey);
                    } else {
                      _collapsedSections.add(dateKey);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        dateKey,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${items.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isCollapsed ? Icons.expand_more : Icons.expand_less,
                        size: 20,
                        color: AppColors.grey500,
                      ),
                    ],
                  ),
                ),
              ),
              // Notifications for this date (if not collapsed)
              if (!isCollapsed)
                ...items.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildNotificationCard(n, userId),
                  ),
                ),
              if (isCollapsed) const SizedBox(height: 4),
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
          color: notification.isRead ? AppColors.white : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? AppColors.grey200
                : color.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
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
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(fontSize: 11, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(String userId) {
    CustomDialog.show(
      context: context,
      title: 'Clear Notification History?',
      icon: Icons.delete_sweep,
      type: CustomDialogType.warning,
      content: const Text(
        'This will hide all notifications from view. You can restore them later if needed.',
      ),
      primaryButtonText: 'Clear',
      onPrimaryPressed: () {
        Navigator.pop(context);
        _clearHistory(userId);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
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
    CustomDialog.show(
      context: context,
      title: notification.title,
      icon: _getNotificationIcon(notification.type),
      iconColor: _getNotificationColor(notification.type),
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
      primaryButtonText: 'Close',
      onPrimaryPressed: () => Navigator.pop(context),
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
      return DateFormat('MMM d').format(date);
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
