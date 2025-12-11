import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';

/// Section header widget for booking groups
class BookingSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const BookingSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Booking card widget
class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool canViewMoney;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.canViewMoney,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final paymentColor = _getPaymentColor(booking.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        booking.roomNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.guestCount} guests',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.nights_stay,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.stayDuration} nights',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (canViewMoney)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: paymentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 12,
                            color: paymentColor,
                          ),
                          Text(
                            booking.isFullyPaid
                                ? 'Paid'
                                : '₹${booking.pendingAmount.toStringAsFixed(0)} due',
                            style: TextStyle(
                              color: paymentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.info;
      case BookingStatus.checkedIn:
        return AppColors.roomOccupied;
      case BookingStatus.checkedOut:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.grey600;
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.partial:
        return AppColors.warning;
      case PaymentStatus.pending:
        return AppColors.error;
      case PaymentStatus.refunded:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Booking details bottom sheet
class BookingDetailsSheet extends StatelessWidget {
  final Booking booking;
  final bool canViewMoney;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    required this.canViewMoney,
  });

  static void show(
    BuildContext context, {
    required Booking booking,
    required bool canViewMoney,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BookingDetailsSheet(booking: booking, canViewMoney: canViewMoney),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildHeader(statusColor),
                const SizedBox(height: 24),
                _buildDetailRow(
                  Icons.login,
                  'Check In',
                  _formatDate(booking.checkIn),
                ),
                _buildDetailRow(
                  Icons.logout,
                  'Check Out',
                  _formatDate(booking.checkOut),
                ),
                _buildDetailRow(
                  Icons.nights_stay,
                  'Duration',
                  '${booking.stayDuration} night(s)',
                ),
                _buildDetailRow(
                  Icons.people,
                  'Guests',
                  '${booking.guestCount}',
                ),
                if (canViewMoney) ...[
                  const Divider(height: 32),
                  _buildDetailRow(
                    Icons.currency_rupee,
                    'Total',
                    '₹${booking.totalAmount.toStringAsFixed(0)}',
                  ),
                  _buildDetailRow(
                    Icons.check_circle,
                    'Paid',
                    '₹${booking.paidAmount.toStringAsFixed(0)}',
                  ),
                  if (!booking.isFullyPaid)
                    _buildDetailRow(
                      Icons.warning,
                      'Pending',
                      '₹${booking.pendingAmount.toStringAsFixed(0)}',
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                booking.roomNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.info;
      case BookingStatus.checkedIn:
        return AppColors.roomOccupied;
      case BookingStatus.checkedOut:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.grey600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
