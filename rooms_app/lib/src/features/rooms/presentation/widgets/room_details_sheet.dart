import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/domain/entities/user.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Bottom sheet for room details and actions
class RoomDetailsSheet extends ConsumerWidget {
  final Room room;

  const RoomDetailsSheet({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = RoomStatusColors.getColor(room.status.name);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canViewMoney = currentUser?.role.canViewMoneyDetails ?? false;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    room.roomNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomType,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        room.status.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Primary Action Button (Color-coded for illiterate users)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildPrimaryAction(context, ref),
          ),

          // Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildDetailRow(Icons.layers, 'Floor', room.floor),
                if (canViewMoney)
                  _buildDetailRow(
                    Icons.currency_rupee,
                    'Price/Night',
                    '₹${room.pricePerNight.toStringAsFixed(0)}',
                  ),
                _buildDetailRow(
                  Icons.people,
                  'Max Occupancy',
                  '${room.maxOccupancy}',
                ),
                if (room.lastCleaned != null)
                  _buildDetailRow(
                    Icons.cleaning_services,
                    'Last Cleaned',
                    _formatDateTime(room.lastCleaned!),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Quick Status Change',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildQuickStatusButtons(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Primary action based on room status - BIG, COLOR-CODED button
  Widget _buildPrimaryAction(BuildContext context, WidgetRef ref) {
    switch (room.status) {
      case RoomStatus.free:
        return _buildBigActionButton(
          context: context,
          icon: Icons.login,
          label: 'CHECK IN',
          color: AppColors.roomFree,
          onTap: () {
            Navigator.pop(context);
            context.push(AppRoutes.checkin, extra: room);
          },
        );
      case RoomStatus.occupied:
        return _buildBigActionButton(
          context: context,
          icon: Icons.logout,
          label: 'CHECK OUT',
          color: AppColors.roomOccupied,
          onTap: () {
            Navigator.pop(context);
            context.push(AppRoutes.checkout, extra: room);
          },
        );
      case RoomStatus.cleaning:
        return _buildBigActionButton(
          context: context,
          icon: Icons.check_circle,
          label: 'CLEANING DONE',
          color: AppColors.roomCleaning,
          onTap: () async {
            await _updateRoomStatus(ref, room.id, RoomStatus.free);
            if (context.mounted) Navigator.pop(context);
          },
        );
      case RoomStatus.maintenance:
        return _buildBigActionButton(
          context: context,
          icon: Icons.check_circle,
          label: 'REPAIR DONE',
          color: AppColors.grey600,
          onTap: () async {
            await _updateRoomStatus(ref, room.id, RoomStatus.free);
            if (context.mounted) Navigator.pop(context);
          },
        );
      case RoomStatus.outOfService:
        return _buildBigActionButton(
          context: context,
          icon: Icons.refresh,
          label: 'RESTORE ROOM',
          color: AppColors.grey600,
          onTap: () async {
            await _updateRoomStatus(ref, room.id, RoomStatus.free);
            if (context.mounted) Navigator.pop(context);
          },
        );
    }
  }

  Widget _buildBigActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusButtons(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isStaff = currentUser?.role == UserRole.staff;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RoomStatus.values
          .where((s) => s != room.status)
          .where((s) {
            // Staff can only change to Cleaning or Free
            if (isStaff) {
              return s == RoomStatus.cleaning || s == RoomStatus.free;
            }
            return true;
          })
          .map((status) {
            final color = RoomStatusColors.getColor(status.name);
            return InkWell(
              onTap: () async {
                await _updateRoomStatus(ref, room.id, status);
                if (context.mounted) Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      status.displayName,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _updateRoomStatus(
    WidgetRef ref,
    String roomId,
    RoomStatus status,
  ) async {
    final repo = ref.read(roomRepositoryProvider);
    await repo.updateRoomStatus(roomId, status);
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.free:
        return Icons.check_circle;
      case RoomStatus.occupied:
        return Icons.hotel;
      case RoomStatus.cleaning:
        return Icons.cleaning_services;
      case RoomStatus.maintenance:
        return Icons.build;
      case RoomStatus.outOfService:
        return Icons.block;
    }
  }
}
