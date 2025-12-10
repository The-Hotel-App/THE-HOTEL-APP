import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/domain/entities/user.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
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

    return PopScope(
      canPop: selectedFloor == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedFloor != null) {
          // If we're on a floor page, go back to floors view
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
      ),
    );
  }

  Widget _buildFloorsView(List<Room> allRooms) {
    // Get unique floors and sort them
    final floors = allRooms.map((r) => r.floor).toSet().toList();
    floors.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: floors.length + 1, // +1 for stats bar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Stats Bar as first item
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildStatsBar(allRooms),
          );
        }

        final floorIndex = index - 1;
        final floor = floors[floorIndex];
        final floorRooms = allRooms.where((r) => r.floor == floor).toList();
        return _buildFloorListItem(floor, floorRooms);
      },
    );
  }

  Widget _buildFloorListItem(String floor, List<Room> floorRooms) {
    return InkWell(
      onTap: () {
        ref.read(selectedFloorProvider.notifier).state = floor;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Floor Number Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  floor,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Floor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Floor $floor',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${floorRooms.length} rooms',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 24),
          ],
        ),
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

    if (filteredRooms.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filteredRooms.length + 2, // +2 for stats bar and filter bar
      itemBuilder: (context, index) {
        if (index == 0) {
          // Stats Bar as first item
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildStatsBar(floorRooms),
          );
        }

        if (index == 1) {
          // Filter bar as second item
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...selectedStatuses.map((status) {
                          final statusColor = RoomStatusColors.getColor(
                            status.name,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                                        selectedStatuses,
                                      );
                                      updated.remove(status);
                                      ref
                                              .read(
                                                selectedStatusFilterProvider
                                                    .notifier,
                                              )
                                              .state =
                                          updated;
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showStatusFilterDialog,
                ),
              ],
            ),
          );
        }

        // Room items
        final roomIndex = index - 2;
        return _buildRoomListItem(filteredRooms[roomIndex]);
      },
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

  Widget _buildRoomListItem(Room room) {
    final statusColor = RoomStatusColors.getColor(room.status.name);

    return InkWell(
      onTap: () => _showRoomDetails(room),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Room Number Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                border: Border.all(color: statusColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  room.roomNumber,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Room Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room.roomNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
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

            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 24),
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
    showDialog(context: context, builder: (context) => _StatusFilterDialog());
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

class _StatusFilterDialog extends ConsumerStatefulWidget {
  const _StatusFilterDialog();

  @override
  ConsumerState<_StatusFilterDialog> createState() =>
      _StatusFilterDialogState();
}

class _StatusFilterDialogState extends ConsumerState<_StatusFilterDialog> {
  late Set<RoomStatus> localSelected;

  @override
  void initState() {
    super.initState();
    localSelected = Set.from(ref.read(selectedStatusFilterProvider));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter by Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter options
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...RoomStatus.values.map((status) {
                  final isSelected = localSelected.contains(status);
                  final statusColor = RoomStatusColors.getColor(status.name);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          localSelected.add(status);
                        } else {
                          localSelected.remove(status);
                        }
                      });
                    },
                    title: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(status.displayName),
                      ],
                    ),
                    activeColor: statusColor,
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => localSelected.clear());
                    },
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      ref.read(selectedStatusFilterProvider.notifier).state =
                          localSelected;
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
