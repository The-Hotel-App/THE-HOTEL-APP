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

/// Main rooms page displaying floors and rooms grid
class RoomsPage extends ConsumerStatefulWidget {
  /// When true, hides back button for use as embedded tab content
  final bool embedded;

  const RoomsPage({super.key, this.embedded = false});

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
              : widget.embedded
              ? null // No back button when embedded as tab
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

    var floorRooms = allRooms.where((r) => r.floor == selectedFloor).toList();

    // Sort by room number numerically
    floorRooms.sort((a, b) {
      final aNum = int.tryParse(a.roomNumber) ?? 0;
      final bNum = int.tryParse(b.roomNumber) ?? 0;
      return aNum.compareTo(bNum);
    });

    if (floorRooms.isEmpty) {
      return _buildEmptyState();
    }

    // Create pairs for row-by-row display (1,2), (3,4), etc.
    final List<List<Room>> roomRows = [];
    for (var i = 0; i < floorRooms.length; i += 2) {
      if (i + 1 < floorRooms.length) {
        roomRows.add([floorRooms[i], floorRooms[i + 1]]);
      } else {
        roomRows.add([floorRooms[i]]);
      }
    }

    return RefreshIndicator(
      onRefresh: _refreshRooms,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Stats Bar
            RoomStatsBar(rooms: floorRooms),
            const SizedBox(height: 16),
            // Row-by-row layout
            ...roomRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Left room
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: RoomGridTile(
                          room: row[0],
                          onTap: () => _showRoomDetails(row[0]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right room (or empty space)
                    Expanded(
                      child: row.length > 1
                          ? SizedBox(
                              height: 64,
                              child: RoomGridTile(
                                room: row[1],
                                onTap: () => _showRoomDetails(row[1]),
                              ),
                            )
                          : const SizedBox(height: 64),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            'No Rooms on this Floor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      builder: (context) => RoomDetailsSheet(room: room),
    );
  }
}
