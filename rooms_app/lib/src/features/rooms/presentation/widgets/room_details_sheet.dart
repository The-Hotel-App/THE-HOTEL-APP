import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/widgets/biometric_verification_dialog.dart';
import 'package:rooms/src/features/bookings/data/repositories/supabase_booking_repository.dart';
import 'package:rooms/src/features/bookings/presentation/providers/booking_providers.dart';
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
          context.push(AppRoutes.bookingSearch);
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
          await _updateRoomStatusWithVerification(
            context,
            ref,
            room.id,
            RoomStatus.free,
            'Verify to mark room as cleaned',
          );
        };
        break;
      case RoomStatus.maintenance:
        label = 'EMERGENCY FIXED';
        onTap = () async {
          await _updateRoomStatusWithVerification(
            context,
            ref,
            room.id,
            RoomStatus.free,
            'Verify to mark emergency as fixed',
          );
        };
        break;
      case RoomStatus.outOfService:
        label = 'RESTORE ROOM';
        onTap = () async {
          await _updateRoomStatusWithVerification(
            context,
            ref,
            room.id,
            RoomStatus.free,
            'Verify to restore room to service',
          );
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
    // Define status buttons with icons and colors - no "Occupied" option
    // Rooms can only become occupied via check-in
    final statusButtons = [
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

    // Use vertical layout with full-width buttons to prevent overflow
    return Column(
      children: statusButtons
          .map(
            (data) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildStatusButton(context, ref, data),
            ),
          )
          .toList(),
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
              // If room is occupied, ask for checkout confirmation first
              if (room.status == RoomStatus.occupied) {
                _showCheckoutConfirmation(context, ref, data.status);
              } else {
                await _updateRoomStatusWithVerification(
                  context,
                  ref,
                  room.id,
                  data.status,
                  'Verify to change room status to ${data.label}',
                );
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isCurrentStatus
              ? data.color.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black,
            width: isCurrentStatus ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              size: 20,
              color: isCurrentStatus ? data.color : AppColors.grey600,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                data.label,
                style: TextStyle(
                  color: isCurrentStatus ? data.color : AppColors.grey700,
                  fontWeight: isCurrentStatus
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutConfirmation(
    BuildContext context,
    WidgetRef ref,
    RoomStatus newStatus,
  ) {
    AppDialog.show(
      context: context,
      title: 'Guest is Checked In',
      content: const Text(
        'This room has a guest checked in. You need to check out the guest before changing the room status.',
      ),
      primaryButtonText: 'Check Out & Change Status',
      onPrimaryPressed: () async {
        Navigator.pop(context); // Close dialog

        // Require biometric verification for checkout + status change
        final hotel = ref.read(currentHotelProvider);
        if (hotel == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No hotel selected'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final result = await BiometricVerificationDialog.show(
          context: context,
          reason: 'Verify to check out guest and change room status',
          hotelId: hotel.hotelId,
          actionType: 'room_status_change',
          referenceId: room.id,
        );

        if (!result.success) {
          AppLogger.warning(
            'Verification failed for checkout + status change: ${result.errorMessage}',
            tag: 'RoomDetailsSheet',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Verification failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        try {
          // Get verified user ID
          final currentUserId =
              SupabaseService.instance.client.auth.currentUser?.id;

          // Checkout any active booking for this room
          final bookingRepo =
              ref.read(bookingRepositoryProvider) as SupabaseBookingRepository;
          await bookingRepo.checkoutActiveBookingForRoom(room.id);

          // Update room status with verified user
          final repo = ref.read(roomRepositoryProvider);
          await repo.updateRoomStatus(
            room.id,
            newStatus,
            updatedBy: currentUserId,
          );
          ref.invalidate(bookingsProvider);

          AppLogger.success(
            'Room ${room.roomNumber} checked out and status changed to ${newStatus.name}',
            tag: 'RoomDetailsSheet',
          );

          if (context.mounted) Navigator.pop(context); // Close sheet
        } catch (e) {
          AppLogger.error(
            'Error during checkout + status change',
            tag: 'RoomDetailsSheet',
            error: e,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
    );
  }

  /// Update room status with biometric verification
  /// Requirements: 3.1, 3.6
  Future<void> _updateRoomStatusWithVerification(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    RoomStatus status,
    String reason,
  ) async {
    final hotel = ref.read(currentHotelProvider);
    if (hotel == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No hotel selected'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show biometric verification dialog
    final result = await BiometricVerificationDialog.show(
      context: context,
      reason: reason,
      hotelId: hotel.hotelId,
      actionType: 'room_status_change',
      referenceId: roomId,
    );

    if (!result.success) {
      AppLogger.warning(
        'Verification failed for room status change: ${result.errorMessage}',
        tag: 'RoomDetailsSheet',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Verification successful - update room status
    try {
      final repo = ref.read(roomRepositoryProvider);
      final currentUserId =
          SupabaseService.instance.client.auth.currentUser?.id;
      await repo.updateRoomStatus(roomId, status, updatedBy: currentUserId);

      // Invalidate providers to refresh data
      ref.invalidate(roomsProvider);

      AppLogger.success(
        'Room status updated to ${status.name} by verified user',
        tag: 'RoomDetailsSheet',
      );

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      AppLogger.error(
        'Error updating room status',
        tag: 'RoomDetailsSheet',
        error: e,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating room status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
