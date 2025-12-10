import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

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
          return _buildFloorSection(floor, rooms);
        },
      ),
    );
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

  Widget _buildFloorSection(int floor, List<ManagedRoom> rooms) {
    final isExpanded = _expandedFloors.contains(floor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedFloors.remove(floor);
                } else {
                  _expandedFloors.add(floor);
                }
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey800,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.layers, color: AppColors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Floor $floor',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${rooms.length} rooms',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...rooms.map((room) => _buildRoomTile(room)),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ManagedRoom room) {
    final isSelected = _selectedRooms.contains(room.id);
    final statusColor = _getStatusColor(room.status);

    return InkWell(
      onTap: () => _showEditRoomDialog(room),
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedRooms.remove(room.id);
          } else {
            _selectedRooms.add(room.id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.info.withValues(alpha: 0.1) : null,
          border: Border(bottom: BorderSide(color: AppColors.grey200)),
        ),
        child: Row(
          children: [
            if (_selectedRooms.isNotEmpty)
              Checkbox(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedRooms.add(room.id);
                    } else {
                      _selectedRooms.remove(room.id);
                    }
                  });
                },
                activeColor: AppColors.info,
              ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Center(
                child: Text(
                  room.roomNumber,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.roomTypeName ?? 'No Type',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    room.pricePerNight != null
                        ? '₹${room.pricePerNight!.toStringAsFixed(0)}/night • Max ${room.maxOccupancy ?? 2} guests'
                        : 'No pricing set',
                    style: TextStyle(color: AppColors.grey600, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                room.status.displayName,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, color: AppColors.grey400, size: 18),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.free:
        return AppColors.roomFree;
      case RoomStatus.occupied:
        return AppColors.error;
      case RoomStatus.cleaning:
        return AppColors.warning;
      case RoomStatus.maintenance:
        return AppColors.grey600;
      case RoomStatus.outOfService:
        return AppColors.grey500;
    }
  }

  void _showAddRoomDialog() {
    final roomNumberController = TextEditingController();
    final floorController = TextEditingController(text: '1');
    String? selectedTypeId;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Room'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: roomNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Room Number',
                      hintText: 'e.g. 101',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: floorController,
                    decoration: const InputDecoration(
                      labelText: 'Floor',
                      hintText: 'e.g. 1',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTypeId,
                    decoration: const InputDecoration(labelText: 'Room Type'),
                    items: _roomTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type.id,
                            child: Text(
                              '${type.name} (₹${type.basePrice.toStringAsFixed(0)})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTypeId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isSaving = true);

                      try {
                        final hotel = ref.read(currentHotelProvider);
                        final repository = ref.read(roomsRepositoryProvider);

                        await repository.createRoom(
                          hotelId: hotel!.hotelId,
                          roomNumber: roomNumberController.text.trim(),
                          floor: int.tryParse(floorController.text) ?? 1,
                          roomTypeId: selectedTypeId,
                        );

                        if (context.mounted) Navigator.pop(context);
                        await _loadData();

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Room added!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.black),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomDialog(ManagedRoom room) {
    String? selectedTypeId = room.roomTypeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Room ${room.roomNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedTypeId,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: _roomTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type.id,
                        child: Text(
                          '${type.name} (₹${type.basePrice.toStringAsFixed(0)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTypeId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final repository = ref.read(roomsRepositoryProvider);
                  await repository.updateRoom(
                    id: room.id,
                    roomTypeId: selectedTypeId,
                  );

                  if (context.mounted) Navigator.pop(context);
                  await _loadData();

                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Room updated!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.black),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAssignDialog() {
    String? selectedTypeId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Type to ${_selectedRooms.length} Rooms'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedTypeId,
            decoration: const InputDecoration(labelText: 'Room Type'),
            items: _roomTypes
                .map(
                  (type) => DropdownMenuItem(
                    value: type.id,
                    child: Text(
                      '${type.name} (₹${type.basePrice.toStringAsFixed(0)})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setDialogState(() => selectedTypeId = v),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _selectedRooms.clear());
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedTypeId == null
                  ? null
                  : () async {
                      try {
                        final repository = ref.read(roomsRepositoryProvider);
                        await repository.bulkUpdateRoomType(
                          roomIds: _selectedRooms.toList(),
                          roomTypeId: selectedTypeId!,
                        );

                        if (context.mounted) Navigator.pop(context);
                        setState(() => _selectedRooms.clear());
                        await _loadData();

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Rooms updated!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.black),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
