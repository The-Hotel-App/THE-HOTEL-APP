import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/presentation/widgets/room_management_widgets.dart';

/// Rooms Management Page - Owner only, floorwise view
class RoomsManagementPage extends ConsumerStatefulWidget {
  const RoomsManagementPage({super.key});

  @override
  ConsumerState<RoomsManagementPage> createState() =>
      _RoomsManagementPageState();
}

class _RoomsManagementPageState extends ConsumerState<RoomsManagementPage> {
  bool _isLoading = true;
  String? _error;
  Map<int, List<ManagedRoom>> _roomsByFloor = {};
  List<RoomType> _roomTypes = [];
  Set<int> _expandedFloors = {};
  final Set<String> _selectedRooms = {};

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
        roomsRepo.getRoomsByFloor(hotel.hotelId),
        roomTypesRepo.getRoomTypes(hotel.hotelId),
      ]);

      setState(() {
        _roomsByFloor = results[0] as Map<int, List<ManagedRoom>>;
        _roomTypes = results[1] as List<RoomType>;
        _expandedFloors = _roomsByFloor.keys.toSet();
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

  @override
  Widget build(BuildContext context) {
    final floors = _roomsByFloor.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.bedroom_parent, size: 24),
            SizedBox(width: 8),
            Text('Manage Rooms'),
          ],
        ),
        actions: [
          if (_selectedRooms.isNotEmpty)
            TextButton.icon(
              onPressed: _showBulkAssignDialog,
              icon: const Icon(Icons.edit, color: AppColors.warning),
              label: Text(
                'Edit ${_selectedRooms.length}',
                style: const TextStyle(color: AppColors.warning),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRoomDialog,
            tooltip: 'Add Room',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: floors.length,
        itemBuilder: (context, index) {
          final floor = floors[index];
          final rooms = _roomsByFloor[floor]!;
          return FloorSection(
            floor: floor,
            rooms: rooms,
            isExpanded: _expandedFloors.contains(floor),
            onToggle: () => _toggleFloor(floor),
            buildRoomTile: (room) => _buildRoomTile(room),
          );
        },
      ),
    );
  }

  void _toggleFloor(int floor) {
    setState(() {
      if (_expandedFloors.contains(floor)) {
        _expandedFloors.remove(floor);
      } else {
        _expandedFloors.add(floor);
      }
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room_outlined, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          const Text(
            'No Rooms Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add rooms to your hotel',
            style: TextStyle(color: AppColors.grey500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddRoomDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ManagedRoom room) {
    final isSelected = _selectedRooms.contains(room.id);
    return RoomTile(
      room: room,
      isSelected: isSelected,
      showCheckbox: _selectedRooms.isNotEmpty,
      onTap: () => _showEditRoomDialog(room),
      onLongPress: () => _toggleRoomSelection(room.id),
      onCheckboxChanged: (v) => _toggleRoomSelection(room.id),
    );
  }

  void _toggleRoomSelection(String roomId) {
    setState(() {
      if (_selectedRooms.contains(roomId)) {
        _selectedRooms.remove(roomId);
      } else {
        _selectedRooms.add(roomId);
      }
    });
  }

  void _showAddRoomDialog() {
    AddRoomDialog.show(
      context,
      roomTypes: _roomTypes,
      onAdd: ({required roomNumber, required floor, roomTypeId}) async {
        final hotel = ref.read(currentHotelProvider);
        final repository = ref.read(roomsRepositoryProvider);

        await repository.createRoom(
          hotelId: hotel!.hotelId,
          roomNumber: roomNumber,
          floor: floor,
          roomTypeId: roomTypeId,
        );

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room added!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _showEditRoomDialog(ManagedRoom room) {
    EditRoomDialog.show(
      context,
      room: room,
      roomTypes: _roomTypes,
      onSave: (roomTypeId) async {
        final repository = ref.read(roomsRepositoryProvider);
        await repository.updateRoom(id: room.id, roomTypeId: roomTypeId);

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _showBulkAssignDialog() {
    BulkAssignDialog.show(
      context,
      roomCount: _selectedRooms.length,
      roomTypes: _roomTypes,
      onAssign: (roomTypeId) async {
        final repository = ref.read(roomsRepositoryProvider);
        await repository.bulkUpdateRoomType(
          roomIds: _selectedRooms.toList(),
          roomTypeId: roomTypeId,
        );

        setState(() => _selectedRooms.clear());
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rooms updated!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      onCancel: () => setState(() => _selectedRooms.clear()),
    );
  }
}
