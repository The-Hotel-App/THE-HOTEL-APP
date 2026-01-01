import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/customers/presentation/providers/customer_providers.dart';

/// Comprehensive Guest Details Page showing personal info, booking history,
/// payments, and co-guests
class GuestDetailsPage extends ConsumerWidget {
  final Customer customer;

  const GuestDetailsPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(customerBookingsProvider(customer.id));
    final coGuestsAsync = ref.watch(customerCoGuestsProvider(customer.id));

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: CustomScrollView(
        slivers: [
          // Collapsible App Bar with guest header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(),
              collapseMode: CollapseMode.parallax,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Info Section
                  _buildSectionTitle('Personal Information', Icons.person),
                  const SizedBox(height: 12),
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 24),

                  // Booking History Section
                  _buildSectionTitle('Booking History', Icons.history),
                  const SizedBox(height: 12),
                  bookingsAsync.when(
                    data: (bookings) {
                      final typedBookings = bookings
                          .map((b) => b as Map<String, dynamic>)
                          .toList();
                      return _buildBookingHistorySection(
                        context,
                        typedBookings,
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _buildErrorCard('Failed to load bookings'),
                  ),
                  const SizedBox(height: 24),

                  // Payment Summary Section
                  _buildSectionTitle('Payment Summary', Icons.payment),
                  const SizedBox(height: 12),
                  bookingsAsync.when(
                    data: (bookings) {
                      final typedBookings = bookings
                          .map((b) => b as Map<String, dynamic>)
                          .toList();
                      return _buildPaymentSummaryCard(typedBookings);
                    },
                    loading: () => _buildLoadingCard(),
                    error: (e, _) => _buildErrorCard('Failed to load payments'),
                  ),
                  const SizedBox(height: 24),

                  // Co-Guests Section
                  _buildSectionTitle('Travelled With', Icons.group),
                  const SizedBox(height: 12),
                  coGuestsAsync.when(
                    data: (coGuests) =>
                        _buildCoGuestsSection(context, coGuests),
                    loading: () => _buildLoadingCard(),
                    error: (e, _) =>
                        _buildErrorCard('Failed to load co-guests'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.black,
            customer.gender == Gender.male
                ? AppColors.info.withValues(alpha: 0.8)
                : AppColors.error.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Text(
              customer.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Gender and Age
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customer.gender.displayName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                if (customer.age != null) ...[
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${customer.age} years',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Total visits badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${customer.totalVisits} visit${customer.totalVisits != 1 ? 's' : ''}',
                style: TextStyle(
                  color: customer.gender == Gender.male
                      ? AppColors.info
                      : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
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

  Widget _buildPersonalInfoCard() {
    return Container(
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
      child: Column(
        children: [
          _buildInfoRow(Icons.phone, 'Phone', customer.phone),
          if (customer.email != null && customer.email!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.email, 'Email', customer.email!),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            Icons.badge,
            customer.idType.displayName,
            customer.idNumber,
          ),
          if (customer.address != null && customer.address!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, 'Address', customer.address!),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            Icons.calendar_today,
            'First Visit',
            _formatDate(customer.createdAt),
          ),
          if (customer.lastVisit != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              Icons.update,
              'Last Visit',
              _formatDate(customer.lastVisit!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.grey600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    );
  }

  Widget _buildBookingHistorySection(
    BuildContext context,
    List<Map<String, dynamic>> bookings,
  ) {
    if (bookings.isEmpty) {
      return _buildEmptyCard('No booking history');
    }

    return Column(
      children: bookings.map((booking) {
        return _buildBookingCard(context, booking);
      }).toList(),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final checkIn = DateTime.parse(booking['check_in'] as String);
    final checkOut = DateTime.parse(booking['check_out'] as String);
    final status = booking['status'] as String? ?? 'confirmed';
    final totalAmount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final paidAmount = (booking['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final statusColor = _getBookingStatusColor(status);
    final paymentStatus = _getPaymentStatus(totalAmount, paidAmount);
    final paymentColor = _getPaymentStatusColor(paymentStatus);

    // Get room info
    String roomNumber = 'N/A';
    String? roomTypeName;
    final roomData = booking['rooms'];
    if (roomData != null && roomData is Map) {
      roomNumber = roomData['room_number'] as String? ?? 'N/A';
      final roomTypes = roomData['room_types'];
      if (roomTypes != null && roomTypes is Map) {
        roomTypeName = roomTypes['name'] as String?;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to booking details if needed
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        roomNumber,
                        style: TextStyle(
                          color: statusColor,
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
                          'Room $roomNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (roomTypeName != null)
                          Text(
                            roomTypeName,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paymentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          paymentStatus,
                          style: TextStyle(
                            color: paymentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Date and amount row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check In',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatDate(checkIn),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: AppColors.grey400),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Check Out',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatDate(checkOut),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.success,
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

  Widget _buildPaymentSummaryCard(List<Map<String, dynamic>> bookings) {
    double totalSpent = 0;
    double totalPaid = 0;

    for (final booking in bookings) {
      totalSpent += (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
      totalPaid += (booking['amount_paid'] as num?)?.toDouble() ?? 0.0;
    }

    final pending = totalSpent - totalPaid;

    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPaymentItem(
                  'Total Spent',
                  '₹${totalSpent.toStringAsFixed(0)}',
                  AppColors.info,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.grey200),
              Expanded(
                child: _buildPaymentItem(
                  'Total Paid',
                  '₹${totalPaid.toStringAsFixed(0)}',
                  AppColors.success,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.grey200),
              Expanded(
                child: _buildPaymentItem(
                  'Pending',
                  '₹${pending.toStringAsFixed(0)}',
                  pending > 0 ? AppColors.error : AppColors.grey500,
                ),
              ),
            ],
          ),
          if (bookings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 16, color: AppColors.grey600),
                const SizedBox(width: 8),
                Text(
                  '${bookings.length} booking${bookings.length != 1 ? 's' : ''} total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCoGuestsSection(BuildContext context, List<Customer> coGuests) {
    if (coGuests.isEmpty) {
      return _buildEmptyCard('No travel companions found');
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: coGuests.length,
        itemBuilder: (context, index) {
          return _buildCoGuestCard(context, coGuests[index]);
        },
      ),
    );
  }

  Widget _buildCoGuestCard(BuildContext context, Customer coGuest) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push('/guest-details', extra: coGuest);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: coGuest.gender == Gender.male
                      ? AppColors.info.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    coGuest.name.isNotEmpty
                        ? coGuest.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: coGuest.gender == Gender.male
                          ? AppColors.info
                          : AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                coGuest.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                coGuest.phone,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  Color _getBookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.info;
      case 'checked_in':
      case 'checkedin':
        return AppColors.roomOccupied;
      case 'checked_out':
      case 'checkedout':
        return AppColors.success;
      case 'cancelled':
        return AppColors.grey600;
      default:
        return AppColors.grey500;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
      case 'checkedin':
        return 'Checked In';
      case 'checked_out':
      case 'checkedout':
        return 'Checked Out';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getPaymentStatus(double total, double paid) {
    if (paid >= total) return 'Paid';
    if (paid > 0) return 'Partial';
    return 'Pending';
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return AppColors.success;
      case 'Partial':
        return AppColors.warning;
      case 'Pending':
        return AppColors.error;
      default:
        return AppColors.grey500;
    }
  }
}
