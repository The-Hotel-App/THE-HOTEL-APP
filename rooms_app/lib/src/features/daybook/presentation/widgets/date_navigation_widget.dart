import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

/// Widget for navigating between dates in the daybook
class DateNavigationWidget extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPreviousDay;
  final VoidCallback? onNextDay;
  final VoidCallback onDateTap;

  const DateNavigationWidget({
    super.key,
    required this.selectedDate,
    required this.isToday,
    required this.onPreviousDay,
    this.onNextDay,
    required this.onDateTap,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous day button
          IconButton(
            onPressed: onPreviousDay,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.black,
            tooltip: 'Previous day',
          ),
          // Date display (tappable)
          Expanded(
            child: GestureDetector(
              onTap: onDateTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.black.withValues(alpha: 0.05)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isToday ? AppColors.black : AppColors.grey600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isToday ? 'Today' : _formatDate(selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isToday ? AppColors.black : AppColors.grey700,
                      ),
                    ),
                    if (!isToday) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.history,
                        size: 14,
                        color: AppColors.grey500,
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: AppColors.grey600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Next day button (disabled when at today)
          IconButton(
            onPressed: onNextDay,
            icon: const Icon(Icons.chevron_right),
            color: onNextDay != null ? AppColors.black : AppColors.grey400,
            tooltip: isToday ? 'Already at today' : 'Next day',
          ),
        ],
      ),
    );
  }
}
