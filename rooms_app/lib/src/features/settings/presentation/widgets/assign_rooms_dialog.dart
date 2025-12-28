import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart'
    hide roomsProvider;
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/room_management_widgets.dart';

/// Dialog for assigning rooms to a room type
/// Uses the same UI layout as RoomsManagementPage for consistency
class AssignRoomsDialog extends ConsumerStatefulWidget {
  final RoomType roomType;

  const AssignRoomsDialog({super.key, required this.roomType});

  @override
  ConsumerState<AssignRoomsDialog> createState() => _AssignRoomsDialogState();
}

class _AssignRoomsDialogState extends ConsumerState<AssignRoomsDialog> {
  Map<int, Map<String?, List<ManagedRoom>>> _roomsByFloorAndType = {};
  List<RoomType> _allRoomTypes = [];
  Set<String> _selectedRoomIds = {};
  Set<String> _originallyAssignedIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hotel = ref.read(currentHotelProvider);
    if (hotel == null) {
      setState(() {
        _error = 'No hotel selected';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      final roomsRepo = ref.read(roomsRepositoryProvider);
      final roomTypesRepo = ref.read(roomTypesRepositoryProvider);

      final results = await Future.wait([
        roomsRepo.getRoomsByFloorAndType(hotel.hotelId),
        roomTypesRepo.getRoomTypes(hotel.hotelId),
      ]);

      final roomsByFloorAndType =
          results[0] as Map<int, Map<String?, List<ManagedRoom>>>;
      final roomTypes = results[1] as List<RoomType>;

      // Collect rooms that are already assigned to this room type
      final preSelectedIds = <String>{};
      for (final floorData in roomsByFloorAndType.values) {
        for (final rooms in floorData.values) {
          for (final room in rooms) {
            if (room.roomTypeId == widget.roomType.id) {
              preSelectedIds.add(room.id);
            }
          }
        }
      }

      setState(() {
        _roomsByFloorAndType = roomsByFloorAndType;
        _allRoomTypes = roomTypes;
        _selectedRoomIds = preSelectedIds;
        _originallyAssignedIds = Set.from(preSelectedIds);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onRoomTap(ManagedRoom room) {
    final isSelected = _selectedRoomIds.contains(room.id);
    final isAssignedToOtherType =
        room.roomTypeId != null && room.roomTypeId != widget.roomType.id;

    if (isSelected) {
      // Deselecting
      setState(() {
        _selectedRoomIds.remove(room.id);
      });
    } else if (isAssignedToOtherType) {
      // Room is assigned to another type - show warning
      _showReassignWarning(room);
    } else {
      // Select the room
      setState(() {
        _selectedRoomIds.add(room.id);
      });
    }
  }

  void _showReassignWarning(ManagedRoom room) {
    CustomDialog.show(
      context: context,
      title: 'Change Room Type?',
      icon: Icons.swap_horiz,
      type: CustomDialogType.warning,
      content: Text(
        'Room ${room.roomNumber} is currently assigned to "${room.roomTypeName}".\n\n'
        'Do you want to reassign it to "${widget.roomType.name}"?',
      ),
      primaryButtonText: 'Reassign',
      onPrimaryPressed: () {
        Navigator.pop(context);
        setState(() {
          _selectedRoomIds.add(room.id);
        });
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _saveAssignments() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(roomsRepositoryProvider);

      // Rooms to add (newly selected)
      final toAdd = _selectedRoomIds.difference(_originallyAssignedIds);

      // Rooms to remove (previously assigned but now unselected)
      final toRemove = _originallyAssignedIds.difference(_selectedRoomIds);

      // Update newly assigned rooms
      if (toAdd.isNotEmpty) {
        await repository.bulkUpdateRoomType(
          roomIds: toAdd.toList(),
          roomTypeId: widget.roomType.id,
        );
      }

      // For removed rooms, clear their room_type_id
      for (final roomId in toRemove) {
        await repository.clearRoomType(roomId);
      }

      // Invalidate room providers to refresh data
      ref.invalidate(roomsProvider);
      ref.invalidate(roomsByFloorAndTypeProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Room assignments updated for "${widget.roomType.name}"',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool get _hasChanges {
    return !_selectedRoomIds.containsAll(_originallyAssignedIds) ||
        !_originallyAssignedIds.containsAll(_selectedRoomIds);
  }

  @override
  Widget build(BuildContext context) {
    final floors = _roomsByFloorAndType.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Rooms', style: TextStyle(fontSize: 18)),
            Text(
              widget.roomType.name,
              style: TextStyle(fontSize: 14, color: AppColors.grey300),
            ),
          ],
        ),
        actions: [
          if (!_isLoading && _error == null)
            TextButton(
              onPressed: _isSaving || !_hasChanges ? null : _saveAssignments,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: _hasChanges
                            ? AppColors.warning
                            : AppColors.grey400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _buildBody(floors),
    );
  }

  Widget _buildBody(List<int> floors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (floors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bed, size: 64, color: AppColors.grey400),
            SizedBox(height: 16),
            Text(
              'No rooms available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add rooms to your hotel first',
              style: TextStyle(color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Info card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildInfoCard(),
            ),
          ),
          // Legend at top
          if (_allRoomTypes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: RoomTypeLegendWithStatus(roomTypes: _allRoomTypes),
              ),
            ),
          // Floor sections
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final floor = floors[index];
                final roomsByType = _roomsByFloorAndType[floor]!;
                return FloorSectionSelectable(
                  floor: floor,
                  roomsByType: roomsByType,
                  roomTypes: _allRoomTypes,
                  isSelectionMode: true, // Always in selection mode
                  selectedRoomIds: _selectedRoomIds,
                  onRoomTap: _onRoomTap,
                  onRoomLongPress: (_) {}, // No long press in assign mode
                );
              }, childCount: floors.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final addedCount = _selectedRoomIds
        .difference(_originallyAssignedIds)
        .length;
    final removedCount = _originallyAssignedIds
        .difference(_selectedRoomIds)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_selectedRoomIds.length} room${_selectedRoomIds.length == 1 ? '' : 's'} assigned to ${widget.roomType.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_hasChanges) ...[
            const SizedBox(height: 8),
            Text(
              '${addedCount > 0 ? '+$addedCount added' : ''}${addedCount > 0 && removedCount > 0 ? ', ' : ''}${removedCount > 0 ? '-$removedCount removed' : ''}',
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Tap rooms to select/deselect. Selected rooms will be highlighted.',
            style: TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}
