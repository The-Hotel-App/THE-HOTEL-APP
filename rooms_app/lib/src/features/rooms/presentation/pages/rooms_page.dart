import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/hotel_setup/presentation/providers/setup_providers.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final selectedFloor = ref.watch(selectedFloorFilterProvider);
    final selectedStatus = ref.watch(selectedStatusFilterProvider);
    final hotel = ref.watch(currentHotelProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/new_images/black_logo_on_yellow_bg_new_fixed_ratio.png',
              height: 28,
            ),
            const SizedBox(width: 12),
            Text(hotel?.name ?? 'Rooms'),
          ],
        ),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) {
          // Apply filters
          var filteredRooms = rooms;
          if (selectedFloor != null) {
            filteredRooms = filteredRooms
                .where((r) => r.floor == selectedFloor)
                .toList();
          }
          if (selectedStatus != null) {
            filteredRooms = filteredRooms
                .where((r) => r.status == selectedStatus)
                .toList();
          }

          if (filteredRooms.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Stats Bar
              _buildStatsBar(rooms),

              // Active Filters
              if (selectedFloor != null || selectedStatus != null)
                _buildActiveFilters(),

              // Room Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    return _buildRoomCard(filteredRooms[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(List<Room> allRooms) {
    final freeCount = allRooms.where((r) => r.status == RoomStatus.free).length;
    final occupiedCount = allRooms
        .where((r) => r.status == RoomStatus.occupied)
        .length;
    final cleaningCount = allRooms
        .where((r) => r.status == RoomStatus.cleaning)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            icon: Icons.check_circle,
            color: AppColors.roomFree,
            label: 'Free',
            count: freeCount,
          ),
          Container(width: 1, height: 40, color: AppColors.grey300),
          _buildStatItem(
            icon: Icons.hotel,
            color: AppColors.roomOccupied,
            label: 'Occupied',
            count: occupiedCount,
          ),
          Container(width: 1, height: 40, color: AppColors.grey300),
          _buildStatItem(
            icon: Icons.cleaning_services,
            color: AppColors.roomCleaning,
            label: 'Cleaning',
            count: cleaningCount,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    final selectedFloor = ref.watch(selectedFloorFilterProvider);
    final selectedStatus = ref.watch(selectedStatusFilterProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20),
          const SizedBox(width: 8),
          const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (selectedFloor != null) ...[
            Chip(
              label: Text('Floor $selectedFloor'),
              onDeleted: () {
                ref.read(selectedFloorFilterProvider.notifier).state = null;
              },
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 8),
          ],
          if (selectedStatus != null) ...[
            Chip(
              label: Text(selectedStatus.displayName),
              onDeleted: () {
                ref.read(selectedStatusFilterProvider.notifier).state = null;
              },
              backgroundColor: Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final statusColor = RoomStatusColors.getColor(room.status.name);

    return InkWell(
      onTap: () => _showRoomDetails(room),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Room Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                room.roomNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status Icon
            Icon(_getStatusIcon(room.status), size: 32, color: statusColor),
            const SizedBox(height: 4),

            // Status Text
            Text(
              room.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),

            // Room Type
            Text(
              room.roomType,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bed, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          const Text(
            'No Rooms Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(selectedFloorFilterProvider.notifier).state = null;
              ref.read(selectedStatusFilterProvider.notifier).state = null;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Rooms'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Floor'),
              initialValue: ref.read(selectedFloorFilterProvider),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Floors')),
                ...['1', '2', '3'].map(
                  (floor) => DropdownMenuItem(
                    value: floor,
                    child: Text('Floor $floor'),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(selectedFloorFilterProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RoomStatus>(
              decoration: const InputDecoration(labelText: 'Status'),
              initialValue: ref.read(selectedStatusFilterProvider),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...RoomStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(selectedStatusFilterProvider.notifier).state = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showRoomDetails(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoomDetailsSheet(room: room),
    );
  }
}

class _RoomDetailsSheet extends ConsumerWidget {
  final Room room;

  const _RoomDetailsSheet({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = RoomStatusColors.getColor(room.status.name);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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

          // Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildDetailRow(Icons.layers, 'Floor', room.floor),
                _buildDetailRow(
                  Icons.attach_money,
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
                  'Change Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...RoomStatus.values.map((status) {
                  final isSelected = room.status == status;
                  final color = RoomStatusColors.getColor(status.name);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: isSelected
                          ? null
                          : () async {
                              await _updateRoomStatus(ref, room.id, status);
                              if (context.mounted) Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? color
                            : color.withValues(alpha: 0.1),
                        foregroundColor: isSelected ? Colors.white : color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            const Icon(Icons.check, size: 20)
                          else
                            Icon(_getStatusIcon(status), size: 20),
                          const SizedBox(width: 8),
                          Text(status.displayName),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
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
