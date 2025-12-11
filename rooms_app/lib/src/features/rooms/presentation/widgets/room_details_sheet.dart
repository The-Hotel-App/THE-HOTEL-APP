import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Bottom sheet for room details and actions - Clean minimal design
class RoomDetailsSheet extends ConsumerWidget {
  final Room room;

  const RoomDetailsSheet({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = RoomStatusColors.getColor(room.status.name);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Room number circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                room.roomNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // "Room Number" label
          Text(
            'Room Number',
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Primary action button
          _buildPrimaryAction(context, ref, statusColor),
          const SizedBox(height: 24),

          // Max occupancy info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 20, color: AppColors.grey600),
                const SizedBox(width: 8),
                Text(
                  'Max Occupancy: ',
                  style: TextStyle(color: AppColors.grey600, fontSize: 14),
                ),
                Text(
                  '${room.maxOccupancy}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick status buttons - 2x2 grid
          _buildStatusGrid(context, ref),
        ],
      ),
    );
  }

  /// Primary action based on room status
  Widget _buildPrimaryAction(
    BuildContext context,
    WidgetRef ref,
    Color statusColor,
  ) {
    String label;
    VoidCallback onTap;

    switch (room.status) {
      case RoomStatus.free:
        label = 'CHECK IN';
        onTap = () {
          Navigator.pop(context);
          context.push(AppRoutes.checkin, extra: room);
        };
        break;
      case RoomStatus.occupied:
        label = 'CHECK OUT';
        onTap = () {
          Navigator.pop(context);
          context.push(AppRoutes.checkout, extra: room);
        };
        break;
      case RoomStatus.cleaning:
        label = 'CLEANING DONE';
        onTap = () async {
          await _updateRoomStatus(ref, room.id, RoomStatus.free);
          if (context.mounted) Navigator.pop(context);
        };
        break;
      case RoomStatus.maintenance:
        label = 'EMERGENCY FIXED';
        onTap = () async {
          await _updateRoomStatus(ref, room.id, RoomStatus.free);
          if (context.mounted) Navigator.pop(context);
        };
        break;
      case RoomStatus.outOfService:
        label = 'RESTORE ROOM';
        onTap = () async {
          await _updateRoomStatus(ref, room.id, RoomStatus.free);
          if (context.mounted) Navigator.pop(context);
        };
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: statusColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusGrid(BuildContext context, WidgetRef ref) {
    // Define status buttons with icons and colors
    final statusButtons = [
      _StatusButtonData(
        status: RoomStatus.occupied,
        label: 'Occupied',
        icon: Icons.cancel,
        color: AppColors.roomOccupied,
      ),
      _StatusButtonData(
        status: RoomStatus.cleaning,
        label: 'Cleaning',
        icon: Icons.cleaning_services,
        color: AppColors.roomCleaning,
      ),
      _StatusButtonData(
        status: RoomStatus.maintenance,
        label: 'Emergency',
        icon: Icons.warning_amber_rounded,
        color: AppColors.roomEmergency,
      ),
      _StatusButtonData(
        status: RoomStatus.outOfService,
        label: 'Out of Service',
        icon: Icons.do_not_disturb_on_rounded,
        color: AppColors.roomOutOfService,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatusButton(context, ref, statusButtons[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatusButton(context, ref, statusButtons[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatusButton(context, ref, statusButtons[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatusButton(context, ref, statusButtons[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    _StatusButtonData data,
  ) {
    final isCurrentStatus = room.status == data.status;

    return InkWell(
      onTap: isCurrentStatus
          ? null
          : () async {
              await _updateRoomStatus(ref, room.id, data.status);
              if (context.mounted) Navigator.pop(context);
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentStatus
              ? data.color.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentStatus ? data.color : AppColors.grey300,
            width: isCurrentStatus ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              size: 18,
              color: isCurrentStatus ? data.color : AppColors.grey600,
            ),
            const SizedBox(width: 8),
            Text(
              data.label,
              style: TextStyle(
                color: isCurrentStatus ? data.color : AppColors.grey700,
                fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRoomStatus(
    WidgetRef ref,
    String roomId,
    RoomStatus status,
  ) async {
    final repo = ref.read(roomRepositoryProvider);
    await repo.updateRoomStatus(roomId, status);
    // Invalidate providers to refresh data
    ref.invalidate(roomsProvider);
  }
}

class _StatusButtonData {
  final RoomStatus status;
  final String label;
  final IconData icon;
  final Color color;

  const _StatusButtonData({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
  });
}
