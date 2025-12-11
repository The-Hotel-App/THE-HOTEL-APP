import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Open notification settings
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.grey700.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: AppColors.grey700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Alerts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '3 unread notifications',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notifications List
          _buildNotificationCard(
            icon: Icons.check_circle_outline,
            title: 'Check-out Completed',
            message: 'Room 101 has been checked out successfully',
            time: '2 hours ago',
            color: AppColors.success,
            isUnread: true,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.warning_amber,
            title: 'Emergency Required',
            message: 'Room 205 needs attention - AC not working',
            time: '4 hours ago',
            color: AppColors.warning,
            isUnread: true,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.event_available,
            title: 'New Booking',
            message: 'Room 304 booked for 3 nights',
            time: '5 hours ago',
            color: AppColors.info,
            isUnread: true,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.person_add,
            title: 'Guest Check-in',
            message: 'Room 202 checked in at 2:30 PM',
            time: 'Yesterday',
            color: AppColors.success,
            isUnread: false,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.payment,
            title: 'Payment Received',
            message: 'Room 101 - ₹5,000 payment completed',
            time: '2 days ago',
            color: AppColors.success,
            isUnread: false,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.cleaning_services,
            title: 'Housekeeping Done',
            message: 'Rooms 101, 102, 103 cleaned',
            time: '2 days ago',
            color: AppColors.info,
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required Color color,
    required bool isUnread,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isUnread ? AppColors.white : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? color.withValues(alpha: 0.3) : AppColors.grey300,
          width: isUnread ? 2 : 1,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: AppColors.grey600),
            ),
          ],
        ),
        onTap: () {
          // TODO: Mark as read and show details
        },
      ),
    );
  }
}
