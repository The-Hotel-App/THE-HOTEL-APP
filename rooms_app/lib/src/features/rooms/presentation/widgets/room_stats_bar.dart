import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Stats bar showing room status counts
class RoomStatsBar extends StatelessWidget {
  final List<Room> rooms;

  const RoomStatsBar({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final freeCount = rooms.where((r) => r.status == RoomStatus.free).length;
    final occupiedCount = rooms
        .where((r) => r.status == RoomStatus.occupied)
        .length;
    final cleaningCount = rooms
        .where((r) => r.status == RoomStatus.cleaning)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            color: AppColors.roomFree,
            label: 'Free',
            count: freeCount,
          ),
          Container(width: 1, height: 40, color: AppColors.grey300),
          _buildStatItem(
            color: AppColors.roomOccupied,
            label: 'Occupied',
            count: occupiedCount,
          ),
          Container(width: 1, height: 40, color: AppColors.grey300),
          _buildStatItem(
            color: AppColors.roomCleaning,
            label: 'Cleaning',
            count: cleaningCount,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
