import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart' hide roomsProvider;
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Color palette for room types - cycles through these colors
const List<Color> _roomTypeColors = [
  Color(0xFF4CAF50), // Green
  Color(0xFF2196F3), // Blue
  Color(0xFFE91E63), // Pink
  Color(0xFF9C27B0), // Purple
  Color(0xFFFF9800), // Orange
  Color(0xFF00BCD4), // Cyan
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF3F51B5), // Indigo
  Color(0xFF009688), // Teal
  Color(0xFFCDDC39), // Lime
];

/// Dialog for assigning rooms to a room type
class AssignRoomsDialog extends ConsumerStatefulWidget {
  final RoomType roomType;

  const AssignRoomsDialog({super.key, required this.roomType});

  @override
  ConsumerState<AssignRoomsDialog> createState() => _AssignRoomsDialogState();
}

class _AssignRoomsDialogState extends ConsumerState<AssignRoomsDialog> {
  List<ManagedRoom> _allRooms = [];
  List<RoomType> _allRoomTypes = [];
  Set<String> _selectedRoomIds = {};
  Map<String, Color> _roomTypeColorMap = {};
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
      
      // Load rooms and room types in parallel
      final roomsRepo = ref.read(roomsRepositoryProvider);
      final roomTypesRepo = ref.read(roomTypesRepositoryProvider);
      
      final results = await Future.wait([
        roomsRepo.getRooms(hotel.hotelId),
        roomTypesRepo.getRoomTypes(hotel.hotelId),
      ]);
      
      final rooms = results[0] as List<ManagedRoom>;
      final roomTypes = results[1] as List<RoomType>;

      // Pre-select rooms that are already assigned to this room type
      final preSelectedIds = rooms
          .where((r) => r.roomTypeId == widget.roomType.id)
          .map((r) => r.id)
          .toSet();

      // Build color map for room types
      final colorMap = <String, Color>{};
      for (var i = 0; i < roomTypes.length; i++) {
        colorMap[roomTypes[i].id] = _roomTypeColors[i % _roomTypeColors.length];
      }

      setState(() {
        _allRooms = rooms;
        _allRoomTypes = roomTypes;
        _selectedRoomIds = preSelectedIds;
        _roomTypeColorMap = colorMap;
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

  Future<void> _saveAssignments() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(roomsRepositoryProvider);

      // Get rooms that were previously assigned to this type but are now unselected
      final previouslyAssigned = _allRooms
          .where((r) => r.roomTypeId == widget.roomType.id)
          .map((r) => r.id)
          .toSet();

      // Rooms to add (newly selected)
      final toAdd = _selectedRoomIds.difference(previouslyAssigned);

      // Rooms to remove (previously assigned but now unselected)
      final toRemove = previouslyAssigned.difference(_selectedRoomIds);

      // Update newly assigned rooms
      if (toAdd.isNotEmpty) {
        await repository.bulkUpdateRoomType(
          roomIds: toAdd.toList(),
          roomTypeId: widget.roomType.id,
        );
      }

      // For removed rooms, we need to clear their room_type_id
      for (final roomId in toRemove) {
        await repository.clearRoomType(roomId);
      }

      // Invalidate room providers to refresh data
      ref.invalidate(roomsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room assignments updated for "${widget.roomType.name}"'),
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

  void _onRoomTap(ManagedRoom room) {
    final isSelected = _selectedRoomIds.contains(room.id);
    final isAssignedToOtherType = room.roomTypeId != null &&
        room.roomTypeId != widget.roomType.id;

    if (isSelected) {
      // Deselecting - no warning needed
      setState(() {
        _selectedRoomIds.remove(room.id);
      });
    } else if (isAssignedToOtherType) {
      // Room is assigned to another type - show warning
      _showReassignWarning(room);
    } else {
      // Unassigned room - just select it
      setState(() {
        _selectedRoomIds.add(room.id);
      });
    }
  }

  void _showReassignWarning(ManagedRoom room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Room Type?'),
        content: Text(
          'Room ${room.roomNumber} is currently assigned to "${room.roomTypeName}".\n\n'
          'Do you want to reassign it to "${widget.roomType.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedRoomIds.add(room.id);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
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
              onPressed: _isSaving ? null : _saveAssignments,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allRooms.isEmpty) {
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

    return _buildRoomGrid();
  }

  Widget _buildRoomGrid() {
    // Group rooms by floor
    final roomsByFloor = <int, List<ManagedRoom>>{};
    for (final room in _allRooms) {
      roomsByFloor.putIfAbsent(room.floor, () => []).add(room);
    }

    final floors = roomsByFloor.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: floors.length + 2, // +1 for info card, +1 for legend
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildInfoCard();
        }
        if (index == 1) {
          return _buildLegend();
        }

        final floor = floors[index - 2];
        final floorRooms = roomsByFloor[floor]!;

        return _buildFloorSection(floor, floorRooms);
      },
    );
  }

  Widget _buildInfoCard() {
    final selectedCount = _selectedRoomIds.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedCount room${selectedCount == 1 ? '' : 's'} selected for ${widget.roomType.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap on rooms to select/deselect.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    // Get room types that have at least one room assigned
    final usedTypeIds = _allRooms
        .where((r) => r.roomTypeId != null)
        .map((r) => r.roomTypeId!)
        .toSet();

    // Filter to room types actually in use, plus the current one
    final typesToShow = _allRoomTypes.where((t) =>
        usedTypeIds.contains(t.id) || t.id == widget.roomType.id).toList();

    if (typesToShow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Type Colors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // Add unassigned indicator
              _buildLegendItem('Unassigned', AppColors.grey300),
              // Add all room types
              ...typesToShow.map((type) {
                final color = _roomTypeColorMap[type.id] ?? AppColors.grey400;
                final isCurrentType = type.id == widget.roomType.id;
                return _buildLegendItem(
                  type.name + (isCurrentType ? ' (current)' : ''),
                  color,
                  isCurrentType: isCurrentType,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isCurrentType = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isCurrentType ? color : AppColors.grey600,
            fontWeight: isCurrentType ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildFloorSection(int floor, List<ManagedRoom> rooms) {
    // Sort rooms by room number
    rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Floor $floor',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${rooms.length} rooms',
                style: TextStyle(color: AppColors.grey500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Room grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: rooms.map((room) => _buildRoomTile(room)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ManagedRoom room) {
    final isSelected = _selectedRoomIds.contains(room.id);
    final isAssignedToCurrentType = room.roomTypeId == widget.roomType.id;
    final isAssignedToOtherType = room.roomTypeId != null &&
        room.roomTypeId != widget.roomType.id;

    Color tileColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      // Selected for this room type - use current room type's color
      final currentTypeColor = _roomTypeColorMap[widget.roomType.id] ?? AppColors.warning;
      tileColor = currentTypeColor.withValues(alpha: 0.3);
      borderColor = currentTypeColor;
      textColor = currentTypeColor;
    } else if (isAssignedToOtherType && room.roomTypeId != null) {
      // Assigned to another room type - use that type's color
      final otherTypeColor = _roomTypeColorMap[room.roomTypeId!] ?? AppColors.grey400;
      tileColor = otherTypeColor.withValues(alpha: 0.15);
      borderColor = otherTypeColor.withValues(alpha: 0.5);
      textColor = otherTypeColor;
    } else if (isAssignedToCurrentType && !isSelected) {
      // Originally assigned to current type but now deselected
      tileColor = AppColors.grey100;
      borderColor = AppColors.grey300;
      textColor = AppColors.grey500;
    } else {
      // Unassigned
      tileColor = AppColors.white;
      borderColor = AppColors.grey300;
      textColor = AppColors.black;
    }

    return GestureDetector(
      onTap: () => _onRoomTap(room),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              room.roomNumber,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _roomTypeColorMap[widget.roomType.id] ?? AppColors.warning,
                size: 16,
              )
            else if (isAssignedToOtherType && room.roomTypeName != null)
              Text(
                room.roomTypeName!,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
