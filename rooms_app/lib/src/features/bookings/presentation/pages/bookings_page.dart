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
  // Track expansion state for each section
  bool _isActiveExpanded = true;
  bool _isUpcomingExpanded = true;
  bool _isPastExpanded = false; // Past collapsed by default

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
        actions: const [],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: bookingsAsync.when(
          data: (bookings) =>
              _buildBookingsList(context, bookings, canViewMoney),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error: $e'),
                ),
              ),
            ],
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
        // Active (Checked In) - Collapsible
        if (activeBookings.isNotEmpty) ...[
          _buildCollapsibleSection(
            title: 'Active (Checked In)',
            icon: Icons.hotel,
            color: AppColors.roomOccupied,
            count: activeBookings.length,
            isExpanded: _isActiveExpanded,
            onToggle: () =>
                setState(() => _isActiveExpanded = !_isActiveExpanded),
            bookings: activeBookings,
            canViewMoney: canViewMoney,
          ),
          const SizedBox(height: 12),
        ],

        // Upcoming - Collapsible
        if (confirmedBookings.isNotEmpty) ...[
          _buildCollapsibleSection(
            title: 'Upcoming',
            icon: Icons.event,
            color: AppColors.info,
            count: confirmedBookings.length,
            isExpanded: _isUpcomingExpanded,
            onToggle: () =>
                setState(() => _isUpcomingExpanded = !_isUpcomingExpanded),
            bookings: confirmedBookings,
            canViewMoney: canViewMoney,
          ),
          const SizedBox(height: 12),
        ],

        // Past - Collapsible (collapsed by default)
        if (pastBookings.isNotEmpty) ...[
          _buildCollapsibleSection(
            title: 'Past',
            icon: Icons.history,
            color: AppColors.grey600,
            count: pastBookings.length,
            isExpanded: _isPastExpanded,
            onToggle: () => setState(() => _isPastExpanded = !_isPastExpanded),
            bookings: pastBookings,
            canViewMoney: canViewMoney,
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Booking> bookings,
    required bool canViewMoney,
  }) {
    return Column(
      children: [
        // Collapsible Header - clean and simple
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Only arrow has touch feedback
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animated content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: bookings
                  .map(
                    (b) => BookingCard(
                      booking: b,
                      canViewMoney: canViewMoney,
                      onTap: () =>
                          _showBookingDetails(context, b, canViewMoney),
                    ),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  void _showBookingDetails(
    BuildContext context,
    Booking booking,
    bool canViewMoney,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingDetailsPage(booking: booking),
      ),
    );
  }
}
