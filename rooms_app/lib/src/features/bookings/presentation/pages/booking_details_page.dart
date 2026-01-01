import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/utils/tariff_calculator.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/bookings/data/repositories/supabase_booking_repository.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
import 'package:rooms/src/features/bookings/presentation/widgets/collect_payment_dialog.dart';
import 'package:rooms/src/features/bookings/presentation/widgets/tariff_timeline_popup.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';

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

  // Tariff fields for visualization
  int _tariffDurationHours = 24;
  double _tariffAmount = 0;
  double _gracePeriodHours = 2;
  bool _tariffLoaded = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadTariffInfo();
  }

  /// Load tariff info from room type
  Future<void> _loadTariffInfo() async {
    // Get room info from first room (use same tariff for all rooms in multi-room booking)
    final roomId = _booking.rooms.isNotEmpty
        ? _booking.rooms.first.roomId
        : _booking.roomId;

    try {
      final hotel = ref.read(currentHotelProvider);
      if (hotel != null) {
        final rooms = await ref.read(roomsProvider(hotel.hotelId).future);
        final room = rooms.where((r) => r.id == roomId).firstOrNull;
        if (room != null && mounted) {
          setState(() {
            _tariffDurationHours = room.tariffDurationHours;
            _tariffAmount = room.tariffAmount;
            _gracePeriodHours = room.gracePeriodHours;
            _tariffLoaded = true;
          });
        }
      }
    } catch (e) {
      // Use defaults if loading fails
      if (mounted) {
        setState(() => _tariffLoaded = true);
      }
    }
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
    final hasPendingPayment =
        !_booking.isFullyPaid && _booking.pendingAmount > 0;

    final isCheckedIn = _booking.status == BookingStatus.checkedIn;
    final showFloatingButtons = isCheckedIn && _tariffLoaded;

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
        actions: const [],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                // Add bottom padding to prevent content from being hidden behind floating buttons
                bottom: showFloatingButtons ? 100 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(statusColor),
                  const SizedBox(height: 20),

                  // Merged Rooms & Tariff Section (horizontally scrollable)
                  _buildSectionTitle('Rooms & Tariff', Icons.bed),
                  const SizedBox(height: 12),
                  _buildRoomsAndTariffSection(),
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

                  // Payment action button (non-floating)
                  if (hasPendingPayment) ...[
                    const SizedBox(height: 24),
                    _buildPaymentActionButton(),
                  ],
                ],
              ),
            ),
          ),
          // Floating action buttons at the bottom
          if (showFloatingButtons)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildFloatingActionButtons(),
            ),
        ],
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
                            const Icon(
                              Icons.bed,
                              color: Colors.white,
                              size: 28,
                            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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

  /// Merged Rooms & Tariff section - horizontally scrollable
  Widget _buildRoomsAndTariffSection() {
    final rooms = _booking.rooms.isNotEmpty
        ? _booking.rooms
        : [
            BookingRoom(
              roomId: _booking.roomId,
              roomNumber: _booking.roomNumber,
              roomPrice: _booking.totalAmount,
              // Use loaded tariff values instead of defaults
              tariffDurationHours: _tariffDurationHours,
              tariffAmount: _tariffAmount,
              gracePeriodHours: _gracePeriodHours,
            ),
          ];

    // Single room - show as full-width card
    if (rooms.length == 1) {
      return _buildTappableRoomCard(rooms.first);
    }

    // Multiple rooms - horizontally scrollable with intrinsic height
    return SizedBox(
      height: null, // Let content determine height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rooms.asMap().entries.map((entry) {
              final index = entry.key;
              final room = entry.value;
              return Container(
                width: 300,
                margin: EdgeInsets.only(
                  right: index < rooms.length - 1 ? 12 : 0,
                ),
                child: _buildTappableRoomCard(room),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Wraps room card with tap gesture to show timeline popup
  Widget _buildTappableRoomCard(BookingRoom room) {
    // Only make tappable for checked-in bookings
    if (_booking.status != BookingStatus.checkedIn) {
      return _buildRoomTariffCard(room);
    }

    // Use room-specific tariff values
    final roomTariffDuration = room.tariffDurationHours;
    final roomTariffAmount = room.tariffAmount > 0
        ? room.tariffAmount
        : room.roomPrice;
    final roomGracePeriod = room.gracePeriodHours;

    // Booking times are already in local time from repository
    final checkIn = _booking.checkIn;
    final now = DateTime.now();
    final checkOut = _booking.checkOut;

    // Debug logging
    final elapsed = now.difference(checkIn);
    AppLogger.info('=== TARIFF CALC DEBUG (Card) ===', tag: 'TariffCalc');
    AppLogger.info('CheckIn: $checkIn, isUtc: ${checkIn.isUtc}', tag: 'TariffCalc');
    AppLogger.info('Now: $now', tag: 'TariffCalc');
    AppLogger.info('Elapsed: ${elapsed.inMinutes} minutes (${elapsed.inHours}h ${elapsed.inMinutes % 60}m)', tag: 'TariffCalc');
    AppLogger.info('Tariff Duration: ${roomTariffDuration}h', tag: 'TariffCalc');
    AppLogger.info('================================', tag: 'TariffCalc');

    final currentResult = TariffCalculator.calculate(
      checkIn: checkIn,
      checkOut: now,
      tariffDurationHours: roomTariffDuration,
      tariffAmount: roomTariffAmount,
      gracePeriodHours: roomGracePeriod,
    );

    final expectedResult = TariffCalculator.calculate(
      checkIn: checkIn,
      checkOut: checkOut,
      tariffDurationHours: roomTariffDuration,
      tariffAmount: roomTariffAmount,
      gracePeriodHours: roomGracePeriod,
    );

    AppLogger.info('Current cycles: ${currentResult.cycles}, Status: ${currentResult.status}', tag: 'TariffCalc');

    // Create a booking copy for the popup (times are already local)
    final localBooking = _booking;

    return GestureDetector(
      onTap: () => TariffTimelinePopup.show(
        context,
        booking: localBooking,
        room: room,
        currentResult: currentResult,
        expectedResult: expectedResult,
      ),
      child: Stack(
        children: [
          _buildRoomTariffCard(room),
          // Tap indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timeline,
                    size: 12,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Combined room info + tariff card
  Widget _buildRoomTariffCard(BookingRoom room) {
    final roomStatusColor = _getRoomStatusColor(room.roomStatus);
    final roomStatusText = _getRoomStatusText(room.roomStatus);
    final statusColor = _getStatusColor(_booking.status);

    // Use room-specific tariff values
    final roomTariffDuration = room.tariffDurationHours;
    final roomTariffAmount = room.tariffAmount > 0
        ? room.tariffAmount
        : room.roomPrice;
    final roomGracePeriod = room.gracePeriodHours;

    // Calculate tariff if booking is checked in
    TariffResult? currentResult;
    TariffResult? expectedResult;
    Color tariffStatusColor = AppColors.grey400;
    IconData tariffStatusIcon = Icons.schedule;

    if (_booking.status == BookingStatus.checkedIn) {
      // Times are already in local timezone from repository
      final checkIn = _booking.checkIn;
      final now = DateTime.now();
      final checkOut = _booking.checkOut;

      currentResult = TariffCalculator.calculate(
        checkIn: checkIn,
        checkOut: now,
        tariffDurationHours: roomTariffDuration,
        tariffAmount: roomTariffAmount,
        gracePeriodHours: roomGracePeriod,
      );

      expectedResult = TariffCalculator.calculate(
        checkIn: checkIn,
        checkOut: checkOut,
        tariffDurationHours: roomTariffDuration,
        tariffAmount: roomTariffAmount,
        gracePeriodHours: roomGracePeriod,
      );

      switch (currentResult.status) {
        case TariffStatus.withinTariff:
          tariffStatusColor = AppColors.success;
          tariffStatusIcon = Icons.check_circle;
          break;
        case TariffStatus.inGracePeriod:
          tariffStatusColor = AppColors.warning;
          tariffStatusIcon = Icons.schedule;
          break;
        case TariffStatus.nextTariffApplied:
          tariffStatusColor = AppColors.error;
          tariffStatusIcon = Icons.warning_amber;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: currentResult != null
              ? tariffStatusColor.withValues(alpha: 0.3)
              : AppColors.grey200,
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Room header
          Row(
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
                    if (room.roomTypeName != null)
                      Text(
                        room.roomTypeName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tariff rate info (using room-specific values)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: AppColors.grey600),
                const SizedBox(width: 6),
                Text(
                  '₹${roomTariffAmount.toStringAsFixed(0)} / ${roomTariffDuration}h',
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.timer_outlined, size: 14, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(
                  '+${roomGracePeriod.toStringAsFixed(0)}h grace',
                  style: TextStyle(color: AppColors.grey500, fontSize: 11),
                ),
              ],
            ),
          ),

          // Tariff visualization (only for checked-in bookings)
          if (currentResult != null && expectedResult != null) ...[
            const SizedBox(height: 12),

            // Status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tariffStatusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(tariffStatusIcon, color: tariffStatusColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      currentResult.statusMessage,
                      style: TextStyle(
                        color: tariffStatusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Cycle segments visualization
            _buildCompactTimelineSegments(currentResult, expectedResult),
            const SizedBox(height: 10),

            // Cycle summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentResult.cycles} cycle${currentResult.cycles > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Stay: ${currentResult.formattedDuration}',
                      style: TextStyle(color: AppColors.grey600, fontSize: 11),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${currentResult.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: tariffStatusColor,
                      ),
                    ),
                    if (expectedResult.cycles != currentResult.cycles)
                      Text(
                        'Expected: ₹${expectedResult.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // For non-checked-in bookings, just show price
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room Total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '₹${room.roomPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Compact timeline segments for card view - horizontally scrollable
  Widget _buildCompactTimelineSegments(
    TariffResult current,
    TariffResult expected,
  ) {
    final maxCycles = expected.cycles > current.cycles
        ? expected.cycles
        : current.cycles;

    // Fixed width per segment ensures text doesn't overlap
    const double segmentWidth = 28.0;
    const double segmentSpacing = 2.0;

    // Calculate if we need scrolling (more than 8 cycles for typical card width)
    final needsScroll = maxCycles > 8;

    Widget buildSegments() {
      return Row(
        mainAxisSize: needsScroll ? MainAxisSize.min : MainAxisSize.max,
        children: List.generate(maxCycles, (index) {
          final cycleNum = index + 1;
          final isCompleted = cycleNum < current.cycles;
          final isCurrent = cycleNum == current.cycles;

          Color segmentColor;
          if (isCompleted) {
            segmentColor = AppColors.success;
          } else if (isCurrent) {
            switch (current.status) {
              case TariffStatus.withinTariff:
                segmentColor = AppColors.info;
                break;
              case TariffStatus.inGracePeriod:
                segmentColor = AppColors.warning;
                break;
              case TariffStatus.nextTariffApplied:
                segmentColor = AppColors.error;
                break;
            }
          } else {
            segmentColor = AppColors.grey200;
          }

          return Container(
            width: needsScroll ? segmentWidth : null,
            margin: EdgeInsets.only(
              right: index < maxCycles - 1 ? segmentSpacing : 0,
            ),
            decoration: BoxDecoration(
              color: segmentColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Text(
                '$cycleNum',
                style: TextStyle(
                  color: segmentColor == AppColors.grey200
                      ? AppColors.grey500
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }),
      );
    }

    // Wrap with Expanded for non-scrolling, or build scrollable container
    if (needsScroll) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 24,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: buildSegments(),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 24,
          child: Row(
            children: List.generate(maxCycles, (index) {
              final cycleNum = index + 1;
              final isCompleted = cycleNum < current.cycles;
              final isCurrent = cycleNum == current.cycles;

              Color segmentColor;
              if (isCompleted) {
                segmentColor = AppColors.success;
              } else if (isCurrent) {
                switch (current.status) {
                  case TariffStatus.withinTariff:
                    segmentColor = AppColors.info;
                    break;
                  case TariffStatus.inGracePeriod:
                    segmentColor = AppColors.warning;
                    break;
                  case TariffStatus.nextTariffApplied:
                    segmentColor = AppColors.error;
                    break;
                }
              } else {
                segmentColor = AppColors.grey200;
              }

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < maxCycles - 1 ? segmentSpacing : 0,
                  ),
                  decoration: BoxDecoration(
                    color: segmentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Text(
                      '$cycleNum',
                      style: TextStyle(
                        color: segmentColor == AppColors.grey200
                            ? AppColors.grey500
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }
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
            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                          if (guest.gender != null)
                            _formatGender(guest.gender!),
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
            _buildCompactInfoRow(
              Icons.badge,
              '${_formatIdType(guest.idType!)}: ${guest.idNumber}',
            ),
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
                backgroundColor: guest.isPrimary
                    ? AppColors.info
                    : AppColors.grey400,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
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
                          if (guest.gender != null)
                            _formatGender(guest.gender!),
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
              Container(width: 1, height: 60, color: AppColors.grey200),
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
                  Icons.schedule,
                  'Duration',
                  TariffCalculator.formatDuration(
                    _booking.checkOut.difference(_booking.checkIn),
                  ),
                  AppColors.info,
                ),
              ),
              Container(width: 1, height: 60, color: AppColors.grey200),
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

  Widget _buildStayDetailItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          _buildPaymentRow(
            'Amount Paid',
            _booking.paidAmount,
            color: AppColors.success,
          ),
          if (!_booking.isFullyPaid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: AppColors.error,
                        size: 20,
                      ),
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

  Widget _buildPaymentRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
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
            color:
                color ??
                (isBold ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  /// Floating action buttons for Extend Stay and Checkout
  Widget _buildFloatingActionButtons() {
    return Row(
      children: [
        // Extend Stay button
        Expanded(
          child: _buildFloatingButton(
            icon: Icons.more_time,
            label: 'Extend',
            color: AppColors.info,
            onPressed: _navigateToExtendStay,
          ),
        ),
        const SizedBox(width: 12),
        // Checkout button
        Expanded(
          child: _buildFloatingButton(
            icon: Icons.logout,
            label: 'Checkout',
            color: AppColors.warning,
            onPressed: _performCheckout,
          ),
        ),
      ],
    );
  }

  /// Build a floating action button with shadow
  Widget _buildFloatingButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
    );
  }

  /// Payment action button (non-floating)
  Widget _buildPaymentActionButton() {
    return _buildActionButton(
      icon: Icons.payment,
      label: 'Collect ₹${_booking.pendingAmount.toStringAsFixed(0)}',
      color: AppColors.success,
      onPressed: () async {
        final collectedAmount = await CollectPaymentDialog.show(
          context,
          _booking,
        );
        if (collectedAmount != null && collectedAmount > 0) {
          _updatePayment(collectedAmount);
        }
      },
      isFullWidth: true,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
      ),
    );
  }

  /// Navigate to extend stay page
  void _navigateToExtendStay() {
    context.push(
      '/extend-stay',
      extra: {
        'booking': _booking,
        'tariffDurationHours': _tariffDurationHours,
        'tariffAmount': _tariffAmount,
        'gracePeriodHours': _gracePeriodHours,
      },
    );
  }

  /// Perform checkout
  Future<void> _performCheckout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Checkout'),
        content: Text(
          'Checkout ${_booking.customerName} from Room ${_booking.allRoomNumbers}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository =
            ref.read(bookingRepositoryProvider) as SupabaseBookingRepository;
        await repository.updateBookingStatus(
          _booking.id,
          BookingStatus.checkedOut,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checkout successful'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(); // Return to previous screen
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
