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
        // Keep floors collapsed by default
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(theme),
      body: _buildBody(floors),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: const Text('Manage Rooms'),
      actions: [
        if (_selectedRooms.isNotEmpty)
          TextButton(
            onPressed: _showBulkAssignDialog,
            child: Text(
              'Edit (${_selectedRooms.length})',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showAddRoomDialog,
          tooltip: 'Add Room',
        ),
      ],
    );
  }

  Widget _buildBody(List<int> floors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading rooms...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (floors.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: floors.length,
        itemBuilder: (context, index) {
          final floor = floors[index];
          final rooms = _roomsByFloor[floor]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FloorSection(
              floor: floor,
              rooms: rooms,
              isExpanded: _expandedFloors.contains(floor),
              onToggle: () => _toggleFloor(floor),
              buildRoomTile: (room) => _buildRoomTile(room),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.grey200, AppColors.grey100],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                size: 56,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Rooms Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding rooms to your hotel.\nYou can assign room types and manage floors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddRoomDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
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
