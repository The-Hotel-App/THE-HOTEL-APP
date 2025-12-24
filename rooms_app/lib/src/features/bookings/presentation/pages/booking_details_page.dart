import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
import 'package:rooms/src/features/bookings/presentation/widgets/collect_payment_dialog.dart';

/// Full-page booking details view
class BookingDetailsPage extends ConsumerStatefulWidget {
  final Booking booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends ConsumerState<BookingDetailsPage> {
  late Booking _booking;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  /// Update the local booking state with new payment amount
  void _updatePayment(double collectedAmount) {
    final newPaidAmount = _booking.paidAmount + collectedAmount;
    final newPaymentStatus = newPaidAmount >= _booking.totalAmount
        ? PaymentStatus.paid
        : newPaidAmount > 0
            ? PaymentStatus.partial
            : PaymentStatus.pending;

    setState(() {
      _booking = _booking.copyWith(
        paidAmount: newPaidAmount,
        paymentStatus: newPaymentStatus,
      );
    });
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    ref.invalidate(bookingsProvider);

    // Wait for the provider to fetch new data
    try {
      final bookings = await ref.read(bookingsProvider.future);
      final updated = bookings.where((b) => b.id == _booking.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() => _booking = updated);
      }
    } catch (e) {
      // Ignore errors, just stop refreshing
    }

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_booking.status);
    final hasPendingPayment = !_booking.isFullyPaid && _booking.pendingAmount > 0;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(statusColor),
              const SizedBox(height: 20),

              // Rooms Section
              _buildSectionTitle('Rooms', Icons.bed),
              const SizedBox(height: 12),
              _buildRoomsSection(statusColor),
              const SizedBox(height: 20),

              // Guests Section
              _buildSectionTitle('Guests', Icons.people),
              const SizedBox(height: 12),
              _buildGuestsSection(),
              const SizedBox(height: 20),

              // Stay Details Section
              _buildSectionTitle('Stay Details', Icons.calendar_today),
              const SizedBox(height: 12),
              _buildStayDetailsCard(),
              const SizedBox(height: 20),

              // Payment Section
              _buildSectionTitle('Payment', Icons.payment),
              const SizedBox(height: 12),
              _buildPaymentCard(),

              // Collect Payment Button
              if (hasPendingPayment) ...[
                const SizedBox(height: 20),
                _buildCollectPaymentButton(),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.grey700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(Color statusColor) {
    final roomCount = _booking.rooms.isNotEmpty ? _booking.rooms.length : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: roomCount > 1
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bed, color: Colors.white, size: 28),
                            Text(
                              '×$roomCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _booking.allRoomNumbers,
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
                      _booking.customerName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomCount > 1
                          ? 'Rooms: ${_booking.allRoomNumbers}'
                          : 'Room ${_booking.allRoomNumbers}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _booking.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _booking.paymentStatus.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsSection(Color statusColor) {
    final rooms = _booking.rooms.isNotEmpty
        ? _booking.rooms
        : [
            BookingRoom(
              roomId: _booking.roomId,
              roomNumber: _booking.roomNumber,
              roomPrice: _booking.totalAmount,
            )
          ];

    return Column(
      children: rooms.map((room) => _buildRoomCard(room, statusColor)).toList(),
    );
  }

  Widget _buildRoomCard(BookingRoom room, Color statusColor) {
    final roomStatusColor = _getRoomStatusColor(room.roomStatus);
    final roomStatusText = _getRoomStatusText(room.roomStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                room.roomNumber,
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
                  'Room ${room.roomNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (room.roomTypeName != null)
                  Text(
                    room.roomTypeName!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roomStatusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roomStatusText,
                        style: TextStyle(
                          color: roomStatusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${room.roomPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.success,
                ),
              ),
              Text(
                'total',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildGuestsSection() {
    final guests = _booking.guests.isNotEmpty
        ? _booking.guests
        : [
            BookingGuest(
              guestId: _booking.customerId,
              name: _booking.customerName,
              phone: _booking.customerPhone,
              email: _booking.customerEmail,
              isPrimary: true,
            )
          ];

    // If only one guest, show as a card
    if (guests.length == 1) {
      return _buildGuestCard(guests.first);
    }

    // Multiple guests - show horizontally scrollable cards
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: guests.length,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: index < guests.length - 1 ? 12 : 0),
            child: _buildCompactGuestCard(guests[index]),
          );
        },
      ),
    );
  }

  Widget _buildCompactGuestCard(BookingGuest guest) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and primary badge
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: guest.isPrimary ? AppColors.info : AppColors.grey400,
                child: Text(
                  guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guest.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (guest.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (guest.gender != null || guest.age != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (guest.gender != null) _formatGender(guest.gender!),
                          if (guest.age != null) '${guest.age} yrs',
                        ].join(' • '),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Contact Info - compact
          if (guest.phone != null && guest.phone!.isNotEmpty)
            _buildCompactInfoRow(Icons.phone, guest.phone!),
          if (guest.email != null && guest.email!.isNotEmpty)
            _buildCompactInfoRow(Icons.email, guest.email!),
          if (guest.idType != null && guest.idNumber != null)
            _buildCompactInfoRow(Icons.badge, '${_formatIdType(guest.idType!)}: ${guest.idNumber}'),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BookingGuest guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and primary badge
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: guest.isPrimary ? AppColors.info : AppColors.grey400,
                child: Text(
                  guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guest.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        if (guest.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (guest.gender != null || guest.age != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (guest.gender != null) _formatGender(guest.gender!),
                          if (guest.age != null) '${guest.age} years',
                        ].join(' • '),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Contact Info
          if (guest.phone != null && guest.phone!.isNotEmpty)
            _buildInfoRow(Icons.phone, 'Phone', guest.phone!),
          if (guest.email != null && guest.email!.isNotEmpty)
            _buildInfoRow(Icons.email, 'Email', guest.email!),

          // ID Info
          if (guest.idType != null && guest.idNumber != null) ...[
            _buildInfoRow(Icons.badge, 'ID Type', _formatIdType(guest.idType!)),
            _buildInfoRow(Icons.numbers, 'ID Number', guest.idNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.grey500),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _buildStayDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStayDetailItem(
                  Icons.login,
                  'Check In',
                  _formatDateFull(_booking.checkIn),
                  AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.grey200,
              ),
              Expanded(
                child: _buildStayDetailItem(
                  Icons.logout,
                  'Check Out',
                  _formatDateFull(_booking.checkOut),
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStayDetailItem(
                  Icons.nights_stay,
                  'Duration',
                  '${_booking.stayDuration} night(s)',
                  AppColors.info,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppColors.grey200,
              ),
              Expanded(
                child: _buildStayDetailItem(
                  Icons.people,
                  'Guests',
                  '${_booking.guestCount}',
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStayDetailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    final paymentColor = _getPaymentColor(_booking.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Payment Status Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: paymentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _booking.isFullyPaid ? Icons.check_circle : Icons.pending,
                  color: paymentColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _booking.paymentStatus.displayName,
                  style: TextStyle(
                    color: paymentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Breakdown
          _buildPaymentRow('Total Amount', _booking.totalAmount, isBold: true),
          const SizedBox(height: 12),
          _buildPaymentRow('Amount Paid', _booking.paidAmount, color: AppColors.success),
          if (!_booking.isFullyPaid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending Due',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${_booking.pendingAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          final collectedAmount = await CollectPaymentDialog.show(context, _booking);
          if (collectedAmount != null && collectedAmount > 0) {
            // Update UI immediately with the collected amount
            _updatePayment(collectedAmount);
          }
        },
        icon: const Icon(Icons.add_card, size: 22),
        label: Text(
          'Collect ₹${_booking.pendingAmount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Helper methods
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

  Color _getRoomStatusColor(String? status) {
    switch (status) {
      case 'free':
        return AppColors.roomFree;
      case 'occupied':
        return AppColors.roomOccupied;
      case 'cleaning':
        return AppColors.roomCleaning;
      case 'maintenance':
        return AppColors.warning;
      default:
        return AppColors.grey500;
    }
  }

  String _getRoomStatusText(String? status) {
    switch (status) {
      case 'free':
        return 'Available';
      case 'occupied':
        return 'Occupied';
      case 'cleaning':
        return 'Cleaning';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Unknown';
    }
  }

  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Other';
    }
  }

  String _formatIdType(String idType) {
    switch (idType.toLowerCase()) {
      case 'aadhar':
        return 'Aadhar Card';
      case 'passport':
        return 'Passport';
      case 'driving_license':
      case 'drivinglicense':
        return 'Driving License';
      case 'voter_id':
      case 'voterid':
        return 'Voter ID';
      default:
        return idType;
    }
  }

  String _formatDateFull(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
