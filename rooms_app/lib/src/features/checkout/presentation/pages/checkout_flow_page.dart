import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Check-out flow page - Simplified checkout process
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
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.roomOccupied,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout, size: 24),
            const SizedBox(width: 8),
            Text('Check Out - Room ${widget.room.roomNumber}'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRoomCard(),
            const SizedBox(height: 24),
            _buildAdditionalCharges(),
            const SizedBox(height: 24),
            _buildRoomStatusSelector(),
            const SizedBox(height: 32),
            _buildCheckoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.roomOccupied.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.roomOccupied, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.roomOccupied,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.room.roomNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Currently Occupied',
                  style: TextStyle(
                    color: AppColors.roomOccupied,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCharges() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text(
                'Additional Charges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '₹',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _additionalChargesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mini-bar, room service, damages, etc.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.black),
              const SizedBox(width: 8),
              const Text(
                'Set Room Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusOption(
                  true,
                  'Cleaning',
                  Icons.cleaning_services,
                  AppColors.roomCleaning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusOption(
                  false,
                  'Free',
                  Icons.check_circle,
                  AppColors.roomFree,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    bool isCleaning,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _setToCleaning == isCleaning;
    return InkWell(
      onTap: () => setState(() => _setToCleaning = isCleaning),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.grey300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.roomOccupied,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 24),
            SizedBox(width: 8),
            Text(
              'Complete Check-Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.roomOccupied),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    final newStatus = _setToCleaning ? RoomStatus.cleaning : RoomStatus.free;
    final roomRepo = ref.read(roomRepositoryProvider);
    await roomRepo.updateRoomStatus(widget.room.id, newStatus);

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
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: color, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check-Out Complete!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Room ${widget.room.roomNumber} is now ${newStatus.displayName}',
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
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
                    backgroundColor: color,
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
