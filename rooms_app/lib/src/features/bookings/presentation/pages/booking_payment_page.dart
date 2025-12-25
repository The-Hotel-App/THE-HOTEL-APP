import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';
import 'package:rooms/src/features/daybook/presentation/providers/daybook_providers.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Payment page - Final step of booking flow
class BookingPaymentPage extends ConsumerStatefulWidget {
  const BookingPaymentPage({super.key});

  @override
  ConsumerState<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends ConsumerState<BookingPaymentPage> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with total amount
    final state = ref.read(newBookingProvider);
    _amountController.text = state.totalAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(newBookingProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Booking Summary
            _buildSummaryCard(bookingState),
            const SizedBox(height: 16),
            // Room Details
            _buildRoomDetailsCard(bookingState),
            const SizedBox(height: 16),
            // Guest Summary
            _buildGuestSummaryCard(bookingState),
            const SizedBox(height: 16),
            // Payment Section
            _buildPaymentCard(bookingState),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bookingState),
    );
  }

  Widget _buildSummaryCard(NewBookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Check In',
            '${state.checkIn.day}/${state.checkIn.month}/${state.checkIn.year}',
          ),
          _buildSummaryRow(
            'Check Out',
            '${state.checkOut.day}/${state.checkOut.month}/${state.checkOut.year}',
          ),
          _buildSummaryRow('Nights', '${state.numberOfNights}'),
          _buildSummaryRow('Guests', '${state.guestCount}'),
          _buildSummaryRow('Rooms', '${state.selectedRooms.length}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRoomDetailsCard(NewBookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...state.selectedRooms.map(
            (room) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bed, color: AppColors.grey600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room.roomNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          room.roomTypeName ?? 'Standard',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(room.pricePerNight * state.numberOfNights).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${state.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSummaryCard(NewBookingState state) {
    final guests = state.guests.where((g) => g != null).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...guests.asMap().entries.map((entry) {
            final index = entry.key;
            final guest = entry.value!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.grey200,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guest.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Primary',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(NewBookingState state) {
    final paidAmount = double.tryParse(_amountController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount to Pay Now',
              prefixText: '₹ ',
              helperText: 'Enter 0 for pay later',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              ref.read(newBookingProvider.notifier).setPaidAmount(amount);
              setState(() {}); // Refresh to show/hide payment mode
            },
          ),
          const SizedBox(height: 12),
          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickAmountButton('Full', state.totalAmount),
              _buildQuickAmountButton('Half', state.totalAmount / 2),
              _buildQuickAmountButton('₹1000', 1000),
              _buildQuickAmountButton('₹0', 0),
            ],
          ),
          // Payment mode selector (only show if paying something)
          if (paidAmount > 0) ...[
            const SizedBox(height: 20),
            const Text(
              'Payment Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _buildPaymentModeSelector(state),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentModeSelector(NewBookingState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMode.values.map((mode) {
        final isSelected = state.paymentMode == mode;
        return InkWell(
          onTap: () {
            ref.read(newBookingProvider.notifier).setPaymentMode(mode);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.black : AppColors.grey300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPaymentModeIcon(mode),
                  size: 18,
                  color: isSelected ? AppColors.white : AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  mode.displayName,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPaymentModeIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.money;
      case PaymentMode.upi:
        return Icons.qr_code;
      case PaymentMode.card:
        return Icons.credit_card;
      case PaymentMode.bankTransfer:
        return Icons.account_balance;
      case PaymentMode.other:
        return Icons.more_horiz;
    }
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return InkWell(
      onTap: () {
        _amountController.text = amount.toStringAsFixed(0);
        ref.read(newBookingProvider.notifier).setPaidAmount(amount);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildBottomBar(NewBookingState state) {
    final paidAmount = double.tryParse(_amountController.text) ?? 0;
    final pendingAmount = state.totalAmount - paidAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text(
                  '₹${state.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Paying Now'),
                Text(
                  '₹${paidAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            if (pendingAmount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pending'),
                  Text(
                    '₹${pendingAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _completeBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Complete Check-In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeBooking() async {
    // Require fingerprint verification for users with biometric enabled
    final biometricService = ref.read(biometricServiceProvider);
    final hasBiometric = ref.read(userBiometricStatusProvider);

    if (hasBiometric) {
      final authenticated = await biometricService.authenticate(
        reason: 'Verify your identity to complete check-in',
        biometricOnly: false,
      );

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification failed or cancelled'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final bookingState = ref.read(newBookingProvider);
      final hotel = ref.read(currentHotelProvider);
      final user = ref.read(currentUserProvider).valueOrNull;
      final paidAmount = double.tryParse(_amountController.text) ?? 0;

      if (hotel == null) throw Exception('No hotel selected');
      if (bookingState.guests.isEmpty || bookingState.guests[0] == null) {
        throw Exception('Primary guest not set');
      }

      final primaryGuest = bookingState.guests[0]!;
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final roomRepo = ref.read(roomRepositoryProvider);
      final supabase = SupabaseService.instance.client;

      // Use the first room for the main booking record
      final firstRoom = bookingState.selectedRooms.first;

      // Create a single booking with total amount
      final booking = Booking(
        id: '',
        hotelId: hotel.hotelId,
        roomId: firstRoom.roomId,
        customerId: primaryGuest.id,
        roomNumber: firstRoom.roomNumber,
        customerName: primaryGuest.name,
        checkIn: bookingState.checkIn,
        checkOut: bookingState.checkOut,
        guestCount: bookingState.guestCount,
        totalAmount: bookingState.totalAmount,
        paidAmount: paidAmount,
        status: BookingStatus.checkedIn,
        paymentStatus: paidAmount >= bookingState.totalAmount
            ? PaymentStatus.paid
            : paidAmount > 0
            ? PaymentStatus.partial
            : PaymentStatus.pending,
        createdAt: DateTime.now(),
        createdBy: user?.id ?? '',
      );

      final createdBooking = await bookingRepo.createBooking(booking);

      // Link all guests to the booking via booking_guests junction table
      final guests = bookingState.guests.where((g) => g != null).toList();
      for (int i = 0; i < guests.length; i++) {
        final guest = guests[i]!;
        await supabase.from('booking_guests').insert({
          'booking_id': createdBooking.id,
          'guest_id': guest.id,
          'is_primary': i == 0, // First guest is primary
        });
      }

      // Link all rooms to the booking via booking_rooms junction table
      // and update room status to occupied
      for (final selectedRoom in bookingState.selectedRooms) {
        await supabase.from('booking_rooms').insert({
          'booking_id': createdBooking.id,
          'room_id': selectedRoom.roomId,
          'room_price':
              selectedRoom.pricePerNight * bookingState.numberOfNights,
        });

        // Update room status to occupied
        await roomRepo.updateRoomStatus(
          selectedRoom.roomId,
          RoomStatus.occupied,
          updatedBy: user?.id,
        );
      }

      // Record payment in daybook if paid
      if (paidAmount > 0) {
        try {
          final daybookRepo = ref.read(dayBookRepositoryProvider);
          final todaySummary = await daybookRepo.getTodaySummary(hotel.hotelId);

          // Build room numbers string for description
          final roomNumbers = bookingState.selectedRooms
              .map((r) => r.roomNumber)
              .join(', ');

          final transaction = Transaction(
            id: '',
            hotelId: hotel.hotelId,
            daybookId: todaySummary.id,
            type: TransactionType.income,
            category: TransactionCategory.roomPayment,
            amount: paidAmount,
            description:
                'Room $roomNumbers - ${primaryGuest.name} (${bookingState.paymentMode.displayName})',
            createdAt: DateTime.now(),
            createdBy: user?.id ?? '',
            bookingId: createdBooking.id,
          );

          await daybookRepo.addTransaction(transaction);
        } catch (e) {
          debugPrint('Failed to record payment in daybook: $e');
        }
      }

      // Invalidate providers
      ref.invalidate(bookingsProvider);
      ref.invalidate(roomsProvider);
      ref.invalidate(todayDayBookProvider);

      // Reset booking state
      ref.read(newBookingProvider.notifier).reset();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Complete!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guests have been checked in successfully',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Pop back to dashboard
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
