import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/utils/tariff_calculator.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/widgets/collect_payment_dialog.dart';

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

/// Booking card widget - shows multiple rooms
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
    final roomCount = booking.rooms.isNotEmpty ? booking.rooms.length : 1;

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
                  // Room indicator - shows count if multiple rooms
                  _buildRoomIndicator(statusColor, roomCount),
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
                        // Show room numbers
                        Text(
                          roomCount > 1
                              ? 'Rooms: ${booking.allRoomNumbers}'
                              : 'Room ${booking.allRoomNumbers}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
                              Icons.schedule,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TariffCalculator.formatDuration(
                                booking.checkOut.difference(booking.checkIn),
                              ),
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

  Widget _buildRoomIndicator(Color statusColor, int roomCount) {
    if (roomCount == 1) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            booking.allRoomNumbers,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Multiple rooms - show count with icon
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bed, color: Colors.white, size: 20),
          Text(
            '×$roomCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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

/// Booking details bottom sheet - shows all rooms, guests, and payment info
class BookingDetailsSheet extends StatelessWidget {
  final Booking booking;
  final bool canViewMoney;
  final VoidCallback? onCollectPayment;
  final VoidCallback? onWriteOff;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    required this.canViewMoney,
    this.onCollectPayment,
    this.onWriteOff,
  });

  static void show(
    BuildContext context, {
    required Booking booking,
    required bool canViewMoney,
    VoidCallback? onCollectPayment,
    VoidCallback? onWriteOff,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailsSheet(
        booking: booking,
        canViewMoney: canViewMoney,
        onCollectPayment: onCollectPayment,
        onWriteOff: onWriteOff,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final hasPendingPayment = !booking.isFullyPaid && booking.pendingAmount > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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

                // Rooms Section
                _buildSectionTitle('Rooms', Icons.bed),
                const SizedBox(height: 12),
                _buildRoomsSection(statusColor),
                const SizedBox(height: 24),

                // Guests Section
                _buildSectionTitle('Guests', Icons.people),
                const SizedBox(height: 12),
                _buildGuestsSection(),
                const SizedBox(height: 24),

                // Stay Details Section
                _buildSectionTitle('Stay Details', Icons.calendar_today),
                const SizedBox(height: 12),
                _buildStayDetailsSection(),

                // Payment Section
                if (canViewMoney) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle('Payment', Icons.payment),
                  const SizedBox(height: 12),
                  _buildPaymentSection(),
                ],

                // Payment action buttons for pending payments
                if (hasPendingPayment && canViewMoney) ...[
                  const SizedBox(height: 24),
                  _buildPaymentActions(context),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsSection(Color statusColor) {
    final rooms = booking.rooms.isNotEmpty
        ? booking.rooms
        : [
            BookingRoom(
              roomId: booking.roomId,
              roomNumber: booking.roomNumber,
              roomPrice: booking.totalAmount,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rooms.asMap().entries.map((entry) {
          final index = entry.key;
          final room = entry.value;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: index < rooms.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.grey200))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      room.roomNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${room.roomNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (room.roomPrice > 0)
                        Text(
                          '₹${room.roomPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGuestsSection() {
    final guests = booking.guests.isNotEmpty
        ? booking.guests
        : [
            BookingGuest(
              guestId: booking.customerId,
              name: booking.customerName,
              phone: booking.customerPhone,
              email: booking.customerEmail,
              isPrimary: true,
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: guests.asMap().entries.map((entry) {
          final index = entry.key;
          final guest = entry.value;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: index < guests.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.grey200))
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: guest.isPrimary
                      ? AppColors.info
                      : AppColors.grey400,
                  child: Text(
                    guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            guest.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (guest.isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (guest.phone != null && guest.phone!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              guest.phone!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      if (guest.idType != null && guest.idNumber != null)
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${guest.idType}: ${guest.idNumber}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStayDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.login,
            'Check In',
            _formatDateFull(booking.checkIn),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.logout,
            'Check Out',
            _formatDateFull(booking.checkOut),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.schedule,
            'Duration',
            TariffCalculator.formatDuration(
              booking.checkOut.difference(booking.checkIn),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.people,
            'Total Guests',
            '${booking.guestCount}',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final paymentColor = _getPaymentColor(booking.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 14)),
              Text(
                '₹${booking.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paid', style: TextStyle(fontSize: 14)),
              Text(
                '₹${booking.paidAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          if (!booking.isFullyPaid) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending', style: TextStyle(fontSize: 14)),
                Text(
                  '₹${booking.pendingAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: paymentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booking.paymentStatus.displayName,
              style: TextStyle(
                color: paymentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pending: ₹${booking.pendingAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onCollectPayment != null) {
                      onCollectPayment!();
                    } else {
                      _showCollectPaymentDialog(context);
                    }
                  },
                  icon: const Icon(Icons.add_card, size: 18),
                  label: const Text('Collect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (onWriteOff != null) {
                      onWriteOff!();
                    } else {
                      _showWriteOffDialog(context);
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Write Off'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCollectPaymentDialog(BuildContext context) {
    CollectPaymentDialog.show(context, booking);
  }

  void _showWriteOffDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Write off feature - coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    final roomCount = booking.rooms.isNotEmpty ? booking.rooms.length : 1;

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
              child: roomCount > 1
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bed, color: Colors.white, size: 24),
                        Text(
                          '×$roomCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      booking.allRoomNumbers,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        booking.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (!booking.isFullyPaid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Partial',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
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

  String _formatDateFull(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
