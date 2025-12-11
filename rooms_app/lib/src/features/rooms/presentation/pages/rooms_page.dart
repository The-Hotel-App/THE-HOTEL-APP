import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/room_details_sheet.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/room_list_item.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/room_stats_bar.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/status_filter_dialog.dart';

/// Main rooms page displaying floors and rooms grid
class RoomsPage extends ConsumerStatefulWidget {
  const RoomsPage({super.key});

  @override
  ConsumerState<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends ConsumerState<RoomsPage> {
  Future<void> _refreshRooms() async {
    // Invalidate providers to force refresh from database
    ref.invalidate(roomsProvider);
    // Wait a bit for stream to reconnect
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final hotel = ref.watch(currentHotelProvider);

    return PopScope(
      canPop: selectedFloor == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedFloor != null) {
          ref.read(selectedFloorProvider.notifier).state = null;
        }
      },
      child: Scaffold(
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
                    : hotel?.hotelName ?? 'Rooms',
              ),
            ],
          ),
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshRooms,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: roomsAsync.when(
          data: (rooms) {
            if (selectedFloor == null) {
              return _buildFloorsView(rooms);
            } else {
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshRooms,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorsView(List<Room> allRooms) {
    final floors = allRooms.map((r) => r.floor).toSet().toList();
    floors.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return RefreshIndicator(
      onRefresh: _refreshRooms,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: floors.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RoomStatsBar(rooms: allRooms),
            );
          }

          final floorIndex = index - 1;
          final floor = floors[floorIndex];
          final floorRooms = allRooms.where((r) => r.floor == floor).toList();
          return FloorListItem(
            floor: floor,
            rooms: floorRooms,
            onTap: () {
              ref.read(selectedFloorProvider.notifier).state = floor;
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomsView(List<Room> allRooms) {
    final selectedFloor = ref.watch(selectedFloorProvider);
    final selectedStatuses = ref.watch(selectedStatusFilterProvider);

    var floorRooms = allRooms.where((r) => r.floor == selectedFloor).toList();
    var filteredRooms = floorRooms;
    if (selectedStatuses.isNotEmpty) {
      filteredRooms = filteredRooms
          .where((r) => selectedStatuses.contains(r.status))
          .toList();
    }

    // Always sort by room number
    filteredRooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    if (filteredRooms.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRooms,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filteredRooms.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RoomStatsBar(rooms: floorRooms),
            );
          }

          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFilterBar(selectedStatuses),
            );
          }

          final roomIndex = index - 2;
          return RoomListItem(
            room: filteredRooms[roomIndex],
            onTap: () => _showRoomDetails(filteredRooms[roomIndex]),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(Set<RoomStatus> selectedStatuses) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: selectedStatuses.map((status) {
                final statusColor = RoomStatusColors.getColor(status.name);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(status, statusColor),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showStatusFilterDialog,
        ),
      ],
    );
  }

  Widget _buildFilterChip(RoomStatus status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              final updated = Set<RoomStatus>.from(
                ref.read(selectedStatusFilterProvider),
              );
              updated.remove(status);
              ref.read(selectedStatusFilterProvider.notifier).state = updated;
            },
            child: Icon(Icons.close, size: 14, color: statusColor),
          ),
        ],
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
              ref.read(selectedStatusFilterProvider.notifier).state = {};
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

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const StatusFilterDialog(),
    );
  }

  void _showRoomDetails(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomDetailsSheet(room: room),
    );
  }
}
