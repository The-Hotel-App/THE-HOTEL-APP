import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Check-out flow page - Sleek, compact checkout process
class CheckoutFlowPage extends ConsumerStatefulWidget {
  final Room room;

  const CheckoutFlowPage({super.key, required this.room});

  @override
  ConsumerState<CheckoutFlowPage> createState() => _CheckoutFlowPageState();
}

class _CheckoutFlowPageState extends ConsumerState<CheckoutFlowPage> {
  bool _setToCleaning = true;
  final _additionalChargesController = TextEditingController(text: '0');

  @override
  void dispose() {
    _additionalChargesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canViewMoney = currentUser?.role.canViewMoneyDetails ?? false;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Check Out',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room header - compact
                  _buildRoomHeader(),
                  const SizedBox(height: 24),

                  // Additional charges (if permitted)
                  if (canViewMoney) ...[
                    _buildAdditionalCharges(),
                    const SizedBox(height: 24),
                  ],

                  // Room status selector
                  _buildRoomStatusSelector(),
                ],
              ),
            ),
          ),

          // Bottom checkout button
          _buildCheckoutButton(),
        ],
      ),
    );
  }

  Widget _buildRoomHeader() {
    return Row(
      children: [
        // Room number badge
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              widget.room.roomNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                widget.room.roomType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.roomOccupied,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Occupied',
                    style: TextStyle(
                      color: AppColors.roomOccupied,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalCharges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Charges',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _additionalChargesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mini-bar, room service, damages, etc.',
          style: TextStyle(color: AppColors.grey500, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRoomStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Room Status After Checkout',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption(
                isCleaning: true,
                label: 'Cleaning',
                icon: Icons.cleaning_services_rounded,
                color: AppColors.roomCleaning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusOption(
                isCleaning: false,
                label: 'Free',
                icon: Icons.check_circle_rounded,
                color: AppColors.roomFree,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption({
    required bool isCleaning,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _setToCleaning == isCleaning;

    return GestureDetector(
      onTap: () => setState(() => _setToCleaning = isCleaning),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.white : color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Complete Check-Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;

    // Require fingerprint verification for managers
    if (currentUser?.role.name == 'manager') {
      final biometricService = ref.read(biometricServiceProvider);
      final hasBiometric = ref.read(userBiometricStatusProvider);

      if (hasBiometric) {
        final authenticated = await biometricService.authenticate(
          reason: 'Verify your identity to complete checkout',
          biometricOnly: false,
        );

        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.black),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    final newStatus = _setToCleaning ? RoomStatus.cleaning : RoomStatus.free;
    final roomRepo = ref.read(roomRepositoryProvider);
    await roomRepo.updateRoomStatus(
      widget.room.id,
      newStatus,
      updatedBy: currentUser?.id,
    );

    if (mounted) {
      Navigator.pop(context);
      _showSuccessDialog(newStatus);
    }
  }

  void _showSuccessDialog(RoomStatus newStatus) {
    final color = newStatus == RoomStatus.cleaning
        ? AppColors.roomCleaning
        : AppColors.roomFree;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Check-Out Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Room ${widget.room.roomNumber} → ${newStatus.displayName}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
