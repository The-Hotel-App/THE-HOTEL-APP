import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/bookings/presentation/pages/booking_guests_page.dart';
import 'package:rooms/src/features/bookings/presentation/pages/booking_payment_page.dart';
import 'package:rooms/src/features/bookings/presentation/pages/booking_rooms_page.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';

/// New Booking Page - Hub for the booking flow
class NewBookingPage extends ConsumerStatefulWidget {
  const NewBookingPage({super.key});

  @override
  ConsumerState<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends ConsumerState<NewBookingPage> {
  @override
  void initState() {
    super.initState();
    // Reset booking state when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newBookingProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(newBookingProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
        title: const Text('New Booking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stay Dates Section
            _buildDatesSection(bookingState),
            const SizedBox(height: 16),
            // Number of Guests Section
            _buildGuestsSection(bookingState),
            const SizedBox(height: 16),
            // Personal Info Section
            _buildNavigationCard(
              title: 'Personal Info',
              subtitle: _getPersonalInfoSubtitle(bookingState),
              icon: Icons.person,
              isCompleted: bookingState.allGuestsFilled,
              onTap: () => _navigateToPersonalInfo(),
            ),
            const SizedBox(height: 12),
            // Room Info Section
            _buildNavigationCard(
              title: 'Room Info',
              subtitle: _getRoomInfoSubtitle(bookingState),
              icon: Icons.bed,
              isCompleted: bookingState.hasRoomsSelected,
              onTap: () => _navigateToRoomInfo(),
            ),
            const SizedBox(height: 12),
            // Payment Info Section
            _buildNavigationCard(
              title: 'Payment Info',
              subtitle: _getPaymentSubtitle(bookingState),
              icon: Icons.payment,
              isCompleted: false,
              isEnabled:
                  bookingState.allGuestsFilled && bookingState.hasRoomsSelected,
              onTap: () => _navigateToPayment(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection(NewBookingState state) {
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
            'Stay Dates',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateCard('Check In', state.checkIn, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: AppColors.grey400),
              ),
              Expanded(
                child: _buildDateCard('Check Out', state.checkOut, false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.numberOfNights} ${state.numberOfNights == 1 ? 'Night' : 'Nights'}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime date, bool isCheckIn) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: isCheckIn
              ? DateTime.now()
              : ref.read(newBookingProvider).checkIn,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          final notifier = ref.read(newBookingProvider.notifier);
          if (isCheckIn) {
            var checkOut = ref.read(newBookingProvider).checkOut;
            if (checkOut.isBefore(picked) ||
                checkOut.isAtSameMomentAs(picked)) {
              checkOut = picked.add(const Duration(days: 1));
            }
            notifier.setDates(picked, checkOut);
          } else {
            notifier.setDates(ref.read(newBookingProvider).checkIn, picked);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsSection(NewBookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Number of Guests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${state.guestCount}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Minus Button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.guestCount > 1
                        ? () => ref
                              .read(newBookingProvider.notifier)
                              .setGuestCount(state.guestCount - 1)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey200,
                      foregroundColor: AppColors.black,
                      disabledBackgroundColor: AppColors.grey100,
                      disabledForegroundColor: AppColors.grey400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.remove, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Plus Button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => ref
                        .read(newBookingProvider.notifier)
                        .setGuestCount(state.guestCount + 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.white : AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: AppColors.success, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : (isEnabled ? AppColors.black : AppColors.grey300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? AppColors.black : AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled
                          ? AppColors.textSecondary
                          : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isEnabled ? AppColors.grey400 : AppColors.grey300,
            ),
          ],
        ),
      ),
    );
  }

  String _getPersonalInfoSubtitle(NewBookingState state) {
    if (state.guests.isEmpty) {
      return 'Add guest details';
    }
    final filledCount = state.guests.where((g) => g != null).length;
    if (filledCount == 0) {
      return 'Add guest details';
    }
    if (filledCount == state.guestCount) {
      return '$filledCount ${filledCount == 1 ? 'guest' : 'guests'} added';
    }
    return '$filledCount of ${state.guestCount} guests added';
  }

  String _getRoomInfoSubtitle(NewBookingState state) {
    if (state.selectedRooms.isEmpty) {
      return 'Select rooms';
    }
    return '${state.selectedRooms.length} ${state.selectedRooms.length == 1 ? 'room' : 'rooms'} selected';
  }

  String _getPaymentSubtitle(NewBookingState state) {
    if (!state.allGuestsFilled || !state.hasRoomsSelected) {
      return 'Complete guest & room info first';
    }
    return 'Total: ₹${state.totalAmount.toStringAsFixed(0)}';
  }

  void _navigateToPersonalInfo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BookingGuestsPage()));
  }

  void _navigateToRoomInfo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BookingRoomsPage()));
  }

  void _navigateToPayment() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BookingPaymentPage()));
  }

  void _showExitConfirmation() {
    CustomDialog.show(
      context: context,
      title: 'Cancel Booking?',
      icon: Icons.warning_amber_rounded,
      type: CustomDialogType.warning,
      content: const Text('Your progress will be lost.'),
      primaryButtonText: 'Exit',
      primaryButtonColor: AppColors.error,
      onPrimaryPressed: () {
        Navigator.pop(context);
        context.pop();
      },
      secondaryButtonText: 'Continue',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }
}
