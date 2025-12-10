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
    final selectedFloor = ref.watch(selectedFloorProvider);
    final hotel = ref.watch(currentHotelProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: selectedFloor != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedFloorProvider.notifier).state = null;
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        title: Row(
          children: [
            Image.asset(
              'assets/new_images/black_logo_on_yellow_bg_new_fixed_ratio.png',
              height: 28,
            ),
            const SizedBox(width: 12),
            Text(
              selectedFloor != null
                  ? 'Floor $selectedFloor'
                  : hotel?.name ?? 'Rooms',
            ),
          ],
        ),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (selectedFloor == null) {
            // Show floors view
            return _buildFloorsView(rooms);
          } else {
            // Show rooms for selected floor
            return _buildRoomsView(rooms);
          }
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

  Widget _buildFloorsView(List<Room> allRooms) {
    // Get unique floors and sort them
    final floors = allRooms.map((r) => r.floor).toSet().toList();
    floors.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Column(
      children: [
        // Stats Bar
        _buildStatsBar(allRooms),

        // Floors Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: floors.length,
            itemBuilder: (context, index) {
              final floor = floors[index];
              final floorRooms = allRooms
                  .where((r) => r.floor == floor)
                  .toList();
              return _buildFloorCard(floor, floorRooms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloorCard(String floor, List<Room> floorRooms) {
    final freeCount = floorRooms
        .where((r) => r.status == RoomStatus.free)
        .length;
    final occupiedCount = floorRooms
        .where((r) => r.status == RoomStatus.occupied)
        .length;
    final cleaningCount = floorRooms
        .where((r) => r.status == RoomStatus.cleaning)
        .length;

    return InkWell(
      onTap: () {
        ref.read(selectedFloorProvider.notifier).state = floor;
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floor Number
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
              ),
              child: Text(
                floor,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Floor Label
            Text(
              'Floor $floor',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Room Count Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFloorStatBadge(
                  icon: Icons.check_circle,
                  count: freeCount,
                  color: AppColors.roomFree,
                ),
                _buildFloorStatBadge(
                  icon: Icons.hotel,
                  count: occupiedCount,
                  color: AppColors.roomOccupied,
                ),
                _buildFloorStatBadge(
                  icon: Icons.cleaning_services,
                  count: cleaningCount,
                  color: AppColors.roomCleaning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorStatBadge({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsView(List<Room> allRooms) {
    final selectedFloor = ref.watch(selectedFloorProvider);
    final selectedStatus = ref.watch(selectedStatusFilterProvider);

    var floorRooms = allRooms.where((r) => r.floor == selectedFloor).toList();
    var filteredRooms = floorRooms;
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
        // Stats Bar for this floor
        _buildStatsBar(floorRooms),

        // Filter bar with status filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (selectedStatus != null) ...[
                Chip(
                  label: Text(selectedStatus.displayName),
                  onDeleted: () {
                    ref.read(selectedStatusFilterProvider.notifier).state =
                        null;
                  },
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showStatusFilterDialog,
              ),
            ],
          ),
        ),

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
              ref.read(selectedStatusFilterProvider.notifier).state = null;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
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

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Statuses'),
              onTap: () {
                ref.read(selectedStatusFilterProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),
            ...RoomStatus.values.map((status) {
              return ListTile(
                title: Text(status.displayName),
                onTap: () {
                  ref.read(selectedStatusFilterProvider.notifier).state =
                      status;
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
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
        // GREEN - Check In
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
        // RED - Check Out
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
        // ORANGE - Mark as Free
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
        // GREY - Mark as Free
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RoomStatus.values.where((s) => s != room.status).map((status) {
        final color = RoomStatusColors.getColor(status.name);
        return InkWell(
          onTap: () async {
            await _updateRoomStatus(ref, room.id, status);
            if (context.mounted) Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
