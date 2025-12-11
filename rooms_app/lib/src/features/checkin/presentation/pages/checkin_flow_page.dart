import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/checkin/presentation/widgets/step_confirmation.dart';
import 'package:rooms/src/features/checkin/presentation/widgets/step_customer_info.dart';
import 'package:rooms/src/features/checkin/presentation/widgets/step_payment.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.success),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    // Update room status to occupied
    final roomRepo = ref.read(roomRepositoryProvider);
    await roomRepo.updateRoomStatus(widget.room.id, RoomStatus.occupied);

    if (mounted) {
      Navigator.pop(context);
      _showSuccessDialog();
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
