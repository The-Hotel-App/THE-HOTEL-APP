import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/room_management_widgets.dart';

/// Rooms Management Page - Owner only, floorwise view with room type grouping
class RoomsManagementPage extends ConsumerStatefulWidget {
  const RoomsManagementPage({super.key});

  @override
  ConsumerState<RoomsManagementPage> createState() =>
      _RoomsManagementPageState();
}

class _RoomsManagementPageState extends ConsumerState<RoomsManagementPage> {
  bool _isLoading = true;
  String? _error;
  Map<int, Map<String?, List<ManagedRoom>>> _roomsByFloorAndType = {};
  List<RoomType> _roomTypes = [];
  String? _draggingRoomId;
  
  // Multi-select state
  bool _isSelectionMode = false;
  final Set<String> _selectedRoomIds = {};

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

      setState(() {
        _roomsByFloorAndType =
            results[0] as Map<int, Map<String?, List<ManagedRoom>>>;
        _roomTypes = results[1] as List<RoomType>;
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

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRoomIds.clear();
    });
  }

  void _toggleRoomSelection(String roomId) {
    setState(() {
      if (_selectedRoomIds.contains(roomId)) {
        _selectedRoomIds.remove(roomId);
      } else {
        _selectedRoomIds.add(roomId);
      }
      if (_selectedRoomIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _onRoomLongPress(ManagedRoom room) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedRoomIds.add(room.id);
      });
    }
  }

  void _selectAllRoomsOnFloor(int floor) {
    final roomsByType = _roomsByFloorAndType[floor];
    if (roomsByType == null) return;
    
    setState(() {
      _isSelectionMode = true;
      for (final rooms in roomsByType.values) {
        for (final room in rooms) {
          _selectedRoomIds.add(room.id);
        }
      }
    });
  }

  void _deselectAllRoomsOnFloor(int floor) {
    final roomsByType = _roomsByFloorAndType[floor];
    if (roomsByType == null) return;
    
    setState(() {
      for (final rooms in roomsByType.values) {
        for (final room in rooms) {
          _selectedRoomIds.remove(room.id);
        }
      }
      // Exit selection mode if no rooms selected
      if (_selectedRoomIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  List<String> _getRoomIdsOnFloor(int floor) {
    final roomsByType = _roomsByFloorAndType[floor];
    if (roomsByType == null) return [];
    
    final ids = <String>[];
    for (final rooms in roomsByType.values) {
      for (final room in rooms) {
        ids.add(room.id);
      }
    }
    return ids;
  }

  Future<void> _deleteSelectedRooms() async {
    if (_selectedRoomIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rooms?'),
        content: Text('Delete ${_selectedRoomIds.length} selected room(s)? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(roomsRepositoryProvider);
      final deletedCount = _selectedRoomIds.length;
      
      for (final roomId in _selectedRoomIds) {
        await repository.deleteRoom(roomId);
      }

      ref.invalidate(roomsProvider);
      ref.invalidate(roomsByFloorProvider);
      ref.invalidate(roomsByFloorAndTypeProvider);
      
      setState(() {
        _selectedRoomIds.clear();
        _isSelectionMode = false;
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount room(s) deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting rooms: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFloor(int floor) async {
    final roomIds = _getRoomIdsOnFloor(floor);
    if (roomIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Floor $floor?'),
        content: Text('This will delete all ${roomIds.length} room(s) on this floor. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete Floor'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(roomsRepositoryProvider);
      
      for (final roomId in roomIds) {
        await repository.deleteRoom(roomId);
      }

      ref.invalidate(roomsProvider);
      ref.invalidate(roomsByFloorProvider);
      ref.invalidate(roomsByFloorAndTypeProvider);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor $floor deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting floor: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final floors = _roomsByFloorAndType.keys.toList()..sort();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBody(floors),
            // Selection capsule at top center
            if (_isSelectionMode && _selectedRoomIds.isNotEmpty)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(child: _buildSelectionCapsule()),
              ),
            // Bottom action bar when in selection mode
            if (_isSelectionMode && _selectedRoomIds.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: _buildSelectionActionBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCapsule() {
    return GestureDetector(
      onTap: _exitSelectionMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedRoomIds.length} selected',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.close,
              color: AppColors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _deleteSelectedRooms,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showBulkEditRoomTypeDialog,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit Type'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (_isSelectionMode) {
            _exitSelectionMode();
          } else {
            context.pop();
          }
        },
      ),
      title: const Text('Manage Rooms'),
    );
  }

  Widget _buildBody(List<int> floors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (floors.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Legend at top
          if (_roomTypes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: RoomTypeLegendWithStatus(roomTypes: _roomTypes),
              ),
            ),
          // Floor sections
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final floor = floors[index];
                  final roomsByType = _roomsByFloorAndType[floor]!;
                  return FloorSectionWithActions(
                    floor: floor,
                    roomsByType: roomsByType,
                    roomTypes: _roomTypes,
                    onAddRoom: () => _showAddRoomDialog(initialFloor: floor),
                    onEditRoom: _showEditRoomDialog,
                    onSwapRooms: _isSelectionMode ? null : _handleSwapRooms,
                    draggingRoomId: _draggingRoomId,
                    isSelectionMode: _isSelectionMode,
                    selectedRoomIds: _selectedRoomIds,
                    onRoomTap: _isSelectionMode 
                        ? (room) => _toggleRoomSelection(room.id)
                        : _showEditRoomDialog,
                    onRoomLongPress: _onRoomLongPress,
                    onSelectAll: () => _selectAllRoomsOnFloor(floor),
                    onDeselectAll: () => _deselectAllRoomsOnFloor(floor),
                    onDeleteFloor: () => _deleteFloor(floor),
                  );
                },
                childCount: floors.length,
              ),
            ),
          ),
          // Add Floor button at bottom
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: OutlinedButton.icon(
                onPressed: _showAddFloorDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Floor'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 64, color: AppColors.grey400),
            const SizedBox(height: 24),
            const Text(
              'No Rooms Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a floor with rooms to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddFloorDialog,
              icon: const Icon(Icons.domain_add_outlined, size: 18),
              label: const Text('Add Floor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoomDialog({int? initialFloor, String? initialRoomTypeId}) {
    AddRoomDialog.show(
      context,
      roomTypes: _roomTypes,
      initialFloor: initialFloor,
      initialRoomTypeId: initialRoomTypeId,
      onAdd: ({required roomNumber, required floor, roomTypeId}) async {
        final hotel = ref.read(currentHotelProvider);
        final repository = ref.read(roomsRepositoryProvider);

        await repository.createRoom(
          hotelId: hotel!.hotelId,
          roomNumber: roomNumber,
          floor: floor,
          roomTypeId: roomTypeId,
        );

        ref.invalidate(roomsProvider);
        ref.invalidate(roomsByFloorProvider);
        ref.invalidate(roomsByFloorAndTypeProvider);

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room added!'), backgroundColor: AppColors.success),
          );
        }
      },
    );
  }

  void _showEditRoomDialog(ManagedRoom room) {
    final availableFloors = _roomsByFloorAndType.keys.toList()..sort();

    EditRoomDialog.show(
      context,
      room: room,
      roomTypes: _roomTypes,
      availableFloors: availableFloors,
      onSave: ({roomNumber, roomTypeId, floor, clearRoomType = false}) async {
        final repository = ref.read(roomsRepositoryProvider);

        await repository.updateRoomDetails(
          id: room.id,
          roomNumber: roomNumber,
          floor: floor,
          roomTypeId: roomTypeId,
          clearRoomType: clearRoomType,
        );

        ref.invalidate(roomsProvider);
        ref.invalidate(roomsByFloorProvider);
        ref.invalidate(roomsByFloorAndTypeProvider);

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room updated!'), backgroundColor: AppColors.success),
          );
        }
      },
      onDelete: () async {
        final repository = ref.read(roomsRepositoryProvider);
        await repository.deleteRoom(room.id);

        ref.invalidate(roomsProvider);
        ref.invalidate(roomsByFloorProvider);
        ref.invalidate(roomsByFloorAndTypeProvider);

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room deleted!'), backgroundColor: AppColors.success),
          );
        }
      },
    );
  }

  void _showAddFloorDialog() {
    final existingFloors = _roomsByFloorAndType.keys.toSet();

    AddFloorDialogRequired.show(
      context,
      existingFloors: existingFloors,
      onAdd: ({required floorNumber, required startRoom, required endRoom}) async {
        final hotel = ref.read(currentHotelProvider);
        final repository = ref.read(roomsRepositoryProvider);

        await repository.createRoomsForFloor(
          hotelId: hotel!.hotelId,
          floor: floorNumber,
          startRoom: startRoom,
          endRoom: endRoom,
        );

        ref.invalidate(roomsProvider);
        ref.invalidate(roomsByFloorProvider);
        ref.invalidate(roomsByFloorAndTypeProvider);

        await _loadData();

        if (mounted) {
          final roomCount = endRoom - startRoom + 1;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Floor $floorNumber added with $roomCount rooms!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _showBulkEditRoomTypeDialog() {
    if (_selectedRoomIds.isEmpty) return;

    BulkEditRoomTypeDialog.show(
      context,
      roomCount: _selectedRoomIds.length,
      roomTypes: _roomTypes,
      onSave: (String? roomTypeId) async {
        final repository = ref.read(roomsRepositoryProvider);
        
        for (final roomId in _selectedRoomIds) {
          await repository.updateRoomDetails(
            id: roomId,
            roomTypeId: roomTypeId,
            clearRoomType: roomTypeId == null,
          );
        }

        ref.invalidate(roomsProvider);
        ref.invalidate(roomsByFloorProvider);
        ref.invalidate(roomsByFloorAndTypeProvider);

        setState(() {
          _selectedRoomIds.clear();
          _isSelectionMode = false;
        });

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room types updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleSwapRooms(ManagedRoom draggedRoom, ManagedRoom targetRoom) async {
    if (draggedRoom.id == targetRoom.id) return;
    if (draggedRoom.floor != targetRoom.floor) return;

    try {
      final repository = ref.read(roomsRepositoryProvider);
      await repository.swapRoomNumbers(roomId1: draggedRoom.id, roomId2: targetRoom.id);

      ref.invalidate(roomsProvider);
      ref.invalidate(roomsByFloorProvider);
      ref.invalidate(roomsByFloorAndTypeProvider);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Swapped rooms ${draggedRoom.roomNumber} and ${targetRoom.roomNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error swapping rooms: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
