import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/pages/booking_details_page.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
import 'package:rooms/src/features/bookings/presentation/widgets/booking_widgets.dart';

class BookingsPage extends ConsumerStatefulWidget {
  /// When true, hides back button for use as embedded tab content
  final bool embedded;

  const BookingsPage({super.key, this.embedded = false});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  Future<void> _refresh() async {
    ref.invalidate(bookingsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canViewMoney = currentUser?.role.canViewMoneyDetails ?? false;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Row(
          children: [
            Image.asset(
              'assets/new_images/black_logo_on_yellow_bg_new_fixed_ratio.png',
              height: 28,
            ),
            const SizedBox(width: 12),
            const Text('Bookings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: bookingsAsync.when(
          data: (bookings) => _buildBookingsList(context, bookings, canViewMoney),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e')))],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    List<Booking> bookings,
    bool canViewMoney,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            const Text(
              'No bookings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Group by status
    final activeBookings = bookings
        .where((b) => b.status == BookingStatus.checkedIn)
        .toList();
    final confirmedBookings = bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();
    final pastBookings = bookings
        .where(
          (b) =>
              b.status == BookingStatus.checkedOut ||
              b.status == BookingStatus.cancelled,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeBookings.isNotEmpty) ...[
          BookingSectionHeader(
            title: 'Active (Checked In)',
            icon: Icons.hotel,
            color: AppColors.roomOccupied,
            count: activeBookings.length,
          ),
          ...activeBookings.map(
            (b) => BookingCard(
              booking: b,
              canViewMoney: canViewMoney,
              onTap: () => _showBookingDetails(context, b, canViewMoney),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (confirmedBookings.isNotEmpty) ...[
          BookingSectionHeader(
            title: 'Upcoming',
            icon: Icons.event,
            color: AppColors.info,
            count: confirmedBookings.length,
          ),
          ...confirmedBookings.map(
            (b) => BookingCard(
              booking: b,
              canViewMoney: canViewMoney,
              onTap: () => _showBookingDetails(context, b, canViewMoney),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (pastBookings.isNotEmpty) ...[
          BookingSectionHeader(
            title: 'Past',
            icon: Icons.history,
            color: AppColors.grey600,
            count: pastBookings.length,
          ),
          ...pastBookings.map(
            (b) => BookingCard(
              booking: b,
              canViewMoney: canViewMoney,
              onTap: () => _showBookingDetails(context, b, canViewMoney),
            ),
          ),
        ],
      ],
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking, bool canViewMoney) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingDetailsPage(booking: booking),
      ),
    );
  }
}
