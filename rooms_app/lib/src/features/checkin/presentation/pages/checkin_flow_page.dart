import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/domain/usecases/biometric_authorizer.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/widgets/biometric_verification_dialog.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
import 'package:rooms/src/features/checkin/presentation/providers/checkin_providers.dart';
import 'package:rooms/src/features/checkin/presentation/widgets/step_confirmation.dart';
import 'package:rooms/src/features/checkin/presentation/widgets/step_customer_info.dart';
import 'package:rooms/src/features/checkin/presentation/widgets/step_payment.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';
import 'package:rooms/src/features/daybook/presentation/providers/daybook_providers.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Check-in flow page - Multi-step wizard for checking in guests
class CheckinFlowPage extends ConsumerStatefulWidget {
  final Room room;

  const CheckinFlowPage({super.key, required this.room});

  @override
  ConsumerState<CheckinFlowPage> createState() => _CheckinFlowPageState();
}

class _CheckinFlowPageState extends ConsumerState<CheckinFlowPage> {
  int _currentStep = 0;

  final List<_StepInfo> _steps = [
    _StepInfo(icon: Icons.person, label: 'Guest', color: AppColors.primary),
    _StepInfo(icon: Icons.payment, label: 'Payment', color: AppColors.primary),
    _StepInfo(
      icon: Icons.check_circle,
      label: 'Confirm',
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: _buildAppBar(),
      body: _buildCurrentStep(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      leading: IconButton(
        icon: const Icon(Icons.close, size: 28),
        onPressed: () => _showExitConfirmation(),
      ),
      title: Row(
        children: [
          const Icon(Icons.login, size: 24),
          const SizedBox(width: 8),
          Text('Check In - Room ${widget.room.roomNumber}'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.white,
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < _currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppColors.success : AppColors.grey300,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          return _buildStepCircle(stepIndex);
        }),
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    final step = _steps[index];
    final isActive = index == _currentStep;
    final isCompleted = index < _currentStep;
    final color = isCompleted
        ? AppColors.success
        : (isActive ? step.color : AppColors.grey400);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? color : AppColors.grey200,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            color: isActive || isCompleted ? AppColors.white : color,
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? color : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    Widget stepContent;
    switch (_currentStep) {
      case 0:
        stepContent = StepCustomerInfo(
          room: widget.room,
          onNext: () => setState(() => _currentStep = 1),
        );
        break;
      case 1:
        stepContent = StepPayment(
          room: widget.room,
          onNext: () => setState(() => _currentStep = 2),
          onBack: () => setState(() => _currentStep = 0),
        );
        break;
      case 2:
        stepContent = StepConfirmation(
          room: widget.room,
          onConfirm: _completeCheckin,
          onBack: () => setState(() => _currentStep = 1),
        );
        break;
      default:
        stepContent = const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(child: stepContent),
      ],
    );
  }

  Future<void> _completeCheckin() async {
    // Get hotel info for biometric verification
    final hotel = ref.read(currentHotelProvider);
    final user = ref.read(currentUserProvider).valueOrNull;

    if (hotel == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Missing hotel or user data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show biometric verification dialog
    // Requirements: 4.1 - Require biometric verification at confirmation step
    final verificationResult = await BiometricVerificationDialog.show(
      context: context,
      reason:
          'Verify your identity to complete check-in for Room ${widget.room.roomNumber}',
      hotelId: hotel.hotelId,
      actionType: 'check_in',
      referenceId: widget.room.id,
    );

    // If verification failed or was cancelled, don't proceed
    // Requirements: 4.6 - Do not allow check-in without successful verification
    if (!verificationResult.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verificationResult.errorMessage ?? 'Verification failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Determine if biometric was used (vs password fallback)
    // Requirements: 4.2, 4.5 - Set checked_in_biometric_verified based on verification method
    final biometricVerified =
        verificationResult.method == VerificationMethod.biometric;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.success),
      ),
    );

    try {
      // Get check-in state
      final checkinState = ref.read(checkinStateProvider);

      if (checkinState.customer == null) {
        throw Exception('Missing customer data');
      }

      // Create booking record in database with biometric verification info
      // Requirements: 4.2 - Set checked_in_by and checked_in_biometric_verified
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final booking = Booking(
        id: '', // Will be generated by database
        hotelId: hotel.hotelId,
        roomId: widget.room.id,
        customerId: checkinState.customer!.id,
        roomNumber: widget.room.roomNumber,
        customerName: checkinState.customer!.name,
        checkIn: checkinState.checkIn,
        checkOut: checkinState.checkOut,
        guestCount: checkinState.guestCount,
        totalAmount: checkinState.totalAmount,
        paidAmount: checkinState.paidAmount,
        status: BookingStatus.checkedIn,
        paymentStatus: checkinState.paidAmount >= checkinState.totalAmount
            ? PaymentStatus.paid
            : checkinState.paidAmount > 0
            ? PaymentStatus.partial
            : PaymentStatus.pending,
        notes: checkinState.notes,
        createdAt: DateTime.now(),
        createdBy: user.id,
        // Biometric verification fields
        checkedInBy: user.id,
        checkedInBiometricVerified: biometricVerified,
      );

      final createdBooking = await bookingRepo.createBooking(booking);

      // Record payment in daybook if there's an advance payment
      if (checkinState.paidAmount > 0) {
        try {
          // Get or create today's daybook to get the daybook ID
          final daybookRepo = ref.read(dayBookRepositoryProvider);
          final todaySummary = await daybookRepo.getTodaySummary(hotel.hotelId);

          final transaction = Transaction(
            id: '',
            hotelId: hotel.hotelId,
            daybookId: todaySummary.id,
            type: TransactionType.income,
            category: TransactionCategory.roomPayment,
            amount: checkinState.paidAmount,
            description:
                'Room ${widget.room.roomNumber} - ${checkinState.customer!.name}',
            createdAt: DateTime.now(),
            createdBy: user.id,
            bookingId: createdBooking.id,
          );

          await daybookRepo.addTransaction(transaction);

          // Invalidate daybook provider to refresh
          ref.invalidate(todayDayBookProvider);
        } catch (e) {
          // Log error but don't fail the check-in
          debugPrint('Failed to record payment in daybook: $e');
        }
      }

      // Update room status to occupied
      final roomRepo = ref.read(roomRepositoryProvider);
      await roomRepo.updateRoomStatus(
        widget.room.id,
        RoomStatus.occupied,
        updatedBy: user.id,
      );

      // Invalidate providers to refresh data
      ref.invalidate(bookingsProvider);
      ref.invalidate(roomsProvider);

      // Reset check-in state
      ref.read(checkinStateProvider.notifier).reset();

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                'Check-In Complete!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Room ${widget.room.roomNumber} is now occupied',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
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

  void _showExitConfirmation() {
    AppDialog.show(
      context: context,
      title: 'Cancel Check-In?',
      content: const Text('Your progress will be lost.'),
      secondaryButtonText: 'Continue',
      onSecondaryPressed: () => Navigator.pop(context),
      primaryButtonText: 'Exit',
      onPrimaryPressed: () {
        Navigator.pop(context);
        context.pop();
      },
    );
  }
}

class _StepInfo {
  final IconData icon;
  final String label;
  final Color color;
  _StepInfo({required this.icon, required this.label, required this.color});
}
