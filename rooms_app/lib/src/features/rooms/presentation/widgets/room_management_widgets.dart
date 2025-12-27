import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Color palette for room types
const List<Color> _roomTypeColors = [
  Color(0xFF4CAF50), // Green
  Color(0xFF2196F3), // Blue
  Color(0xFFFF9800), // Orange
  Color(0xFF9C27B0), // Purple
  Color(0xFFE91E63), // Pink
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFFEB3B), // Yellow
  Color(0xFF795548), // Brown
];

/// Get color for a room type based on its index
Color getRoomTypeColor(int index) {
  return _roomTypeColors[index % _roomTypeColors.length];
}

/// Floor section with colored room squares
class FloorSection extends StatelessWidget {
  final int floor;
  final Map<String?, List<ManagedRoom>> roomsByType;
  final List<RoomType> roomTypes;
  final VoidCallback onAddRoom;
  final Function(ManagedRoom) onEditRoom;
  final Function(ManagedRoom, ManagedRoom) onSwapRooms;
  final String? draggingRoomId;

  const FloorSection({
    super.key,
    required this.floor,
    required this.roomsByType,
    required this.roomTypes,
    required this.onAddRoom,
    required this.onEditRoom,
    required this.onSwapRooms,
    this.draggingRoomId,
  });

  @override
  Widget build(BuildContext context) {
    // Collect all rooms with their colors
    final allRooms = <_RoomWithColor>[];
    
    for (int i = 0; i < roomTypes.length; i++) {
      final roomType = roomTypes[i];
      final rooms = roomsByType[roomType.id];
      if (rooms != null) {
        final color = getRoomTypeColor(i);
        for (final room in rooms) {
          allRooms.add(_RoomWithColor(room: room, color: color, typeName: roomType.name));
        }
      }
    }
    
    // Add unassigned rooms (grey)
    final unassignedRooms = roomsByType[null];
    if (unassignedRooms != null) {
      for (final room in unassignedRooms) {
        allRooms.add(_RoomWithColor(room: room, color: AppColors.grey400, typeName: 'Unassigned'));
      }
    }
    
    // Sort by room number
    allRooms.sort((a, b) => compareRoomNumbers(a.room.roomNumber, b.room.roomNumber));

    return _buildFloorContainer(
      floor: floor,
      roomCount: allRooms.length,
      onAddRoom: onAddRoom,
      child: allRooms.isEmpty
          ? _buildEmptyFloor()
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allRooms.map((item) => RoomSquare(
                room: item.room,
                color: item.color,
                typeName: item.typeName,
                isDragging: draggingRoomId == item.room.id,
                isDropTarget: draggingRoomId != null && draggingRoomId != item.room.id,
                onTap: () => onEditRoom(item.room),
                onSwap: (draggedRoom) => onSwapRooms(draggedRoom, item.room),
              )).toList(),
            ),
    );
  }
}

/// Floor section with selection support
class FloorSectionSelectable extends StatelessWidget {
  final int floor;
  final Map<String?, List<ManagedRoom>> roomsByType;
  final List<RoomType> roomTypes;
  final VoidCallback onAddRoom;
  final Function(ManagedRoom)? onEditRoom;
  final Function(ManagedRoom, ManagedRoom)? onSwapRooms;
  final String? draggingRoomId;
  final bool isSelectionMode;
  final Set<String> selectedRoomIds;
  final Function(ManagedRoom) onRoomTap;
  final Function(ManagedRoom) onRoomLongPress;

  const FloorSectionSelectable({
    super.key,
    required this.floor,
    required this.roomsByType,
    required this.roomTypes,
    required this.onAddRoom,
    this.onEditRoom,
    this.onSwapRooms,
    this.draggingRoomId,
    required this.isSelectionMode,
    required this.selectedRoomIds,
    required this.onRoomTap,
    required this.onRoomLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final allRooms = _collectRooms();

    return _buildFloorContainer(
      floor: floor,
      roomCount: allRooms.length,
      onAddRoom: onAddRoom,
      child: allRooms.isEmpty
          ? _buildEmptyFloor()
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allRooms.map((item) {
                final isSelected = selectedRoomIds.contains(item.room.id);
                return RoomSquareSelectable(
                  room: item.room,
                  color: item.color,
                  typeName: item.typeName,
                  isDragging: draggingRoomId == item.room.id,
                  isDropTarget: !isSelectionMode && draggingRoomId != null && draggingRoomId != item.room.id,
                  isSelectionMode: isSelectionMode,
                  isSelected: isSelected,
                  onTap: () => onRoomTap(item.room),
                  onLongPress: () => onRoomLongPress(item.room),
                  onSwap: onSwapRooms != null 
                      ? (draggedRoom) => onSwapRooms!(draggedRoom, item.room)
                      : (_) {},
                );
              }).toList(),
            ),
    );
  }

  List<_RoomWithColor> _collectRooms() {
    final allRooms = <_RoomWithColor>[];
    
    for (int i = 0; i < roomTypes.length; i++) {
      final roomType = roomTypes[i];
      final rooms = roomsByType[roomType.id];
      if (rooms != null) {
        final color = getRoomTypeColor(i);
        for (final room in rooms) {
          allRooms.add(_RoomWithColor(room: room, color: color, typeName: roomType.name));
        }
      }
    }
    
    final unassignedRooms = roomsByType[null];
    if (unassignedRooms != null) {
      for (final room in unassignedRooms) {
        allRooms.add(_RoomWithColor(room: room, color: AppColors.grey400, typeName: 'Unassigned'));
      }
    }
    
    allRooms.sort((a, b) => compareRoomNumbers(a.room.roomNumber, b.room.roomNumber));
    return allRooms;
  }
}

/// Floor section with select all and delete floor actions
class FloorSectionWithActions extends StatelessWidget {
  final int floor;
  final Map<String?, List<ManagedRoom>> roomsByType;
  final List<RoomType> roomTypes;
  final VoidCallback onAddRoom;
  final Function(ManagedRoom) onEditRoom;
  final Function(ManagedRoom, ManagedRoom)? onSwapRooms;
  final String? draggingRoomId;
  final bool isSelectionMode;
  final Set<String> selectedRoomIds;
  final Function(ManagedRoom) onRoomTap;
  final Function(ManagedRoom) onRoomLongPress;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onDeleteFloor;

  const FloorSectionWithActions({
    super.key,
    required this.floor,
    required this.roomsByType,
    required this.roomTypes,
    required this.onAddRoom,
    required this.onEditRoom,
    this.onSwapRooms,
    this.draggingRoomId,
    required this.isSelectionMode,
    required this.selectedRoomIds,
    required this.onRoomTap,
    required this.onRoomLongPress,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onDeleteFloor,
  });

  @override
  Widget build(BuildContext context) {
    final allRooms = _collectRooms();
    
    // Check if all rooms on this floor are selected
    final floorRoomIds = allRooms.map((r) => r.room.id).toSet();
    final allSelected = floorRoomIds.isNotEmpty && 
        floorRoomIds.every((id) => selectedRoomIds.contains(id));
    
    // Check if any room on this floor is selected
    final anySelected = floorRoomIds.any((id) => selectedRoomIds.contains(id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor Header with actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Floor $floor',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${allRooms.length}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                // Show Select All / Deselect All button when in selection mode
                if (isSelectionMode && allRooms.isNotEmpty)
                  TextButton.icon(
                    onPressed: allSelected ? onDeselectAll : onSelectAll,
                    icon: Icon(
                      allSelected ? Icons.deselect : Icons.select_all,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      allSelected ? 'Deselect All' : 'Select All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
          // Room Grid Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey100),
            ),
            child: allRooms.isEmpty
                ? _buildEmptyFloorWithAdd(onAddRoom)
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...allRooms.map((item) {
                        final isSelected = selectedRoomIds.contains(item.room.id);
                        return RoomSquareSelectable(
                          room: item.room,
                          color: item.color,
                          typeName: item.typeName,
                          isDragging: draggingRoomId == item.room.id,
                          isDropTarget: !isSelectionMode && draggingRoomId != null && draggingRoomId != item.room.id,
                          isSelectionMode: isSelectionMode,
                          isSelected: isSelected,
                          onTap: () => onRoomTap(item.room),
                          onLongPress: () => onRoomLongPress(item.room),
                          onSwap: onSwapRooms != null 
                              ? (draggedRoom) => onSwapRooms!(draggedRoom, item.room)
                              : (_) {},
                        );
                      }),
                      // Add Room button at the end
                      AddRoomButton(onTap: onAddRoom),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFloorWithAdd(VoidCallback onAdd) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AddRoomButton(onTap: onAdd),
      ),
    );
  }

  List<_RoomWithColor> _collectRooms() {
    final allRooms = <_RoomWithColor>[];
    
    for (int i = 0; i < roomTypes.length; i++) {
      final roomType = roomTypes[i];
      final rooms = roomsByType[roomType.id];
      if (rooms != null) {
        final color = getRoomTypeColor(i);
        for (final room in rooms) {
          allRooms.add(_RoomWithColor(room: room, color: color, typeName: roomType.name));
        }
      }
    }
    
    final unassignedRooms = roomsByType[null];
    if (unassignedRooms != null) {
      for (final room in unassignedRooms) {
        allRooms.add(_RoomWithColor(room: room, color: AppColors.grey400, typeName: 'Unassigned'));
      }
    }
    
    allRooms.sort((a, b) => compareRoomNumbers(a.room.roomNumber, b.room.roomNumber));
    return allRooms;
  }
}

Widget _buildFloorContainer({
  required int floor,
  required int roomCount,
  required VoidCallback onAddRoom,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floor Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                'Floor $floor',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$roomCount',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddRoom,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ),
        // Room Grid Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey100),
          ),
          child: child,
        ),
      ],
    ),
  );
}

Widget _buildEmptyFloor() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'No rooms on this floor',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _RoomWithColor {
  final ManagedRoom room;
  final Color color;
  final String typeName;
  
  _RoomWithColor({required this.room, required this.color, required this.typeName});
}

/// Add room button widget (+ icon square)
class AddRoomButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddRoomButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.grey300,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Compact room square widget
class RoomSquare extends StatelessWidget {
  final ManagedRoom room;
  final Color color;
  final String typeName;
  final bool isDragging;
  final bool isDropTarget;
  final VoidCallback onTap;
  final Function(ManagedRoom) onSwap;

  const RoomSquare({
    super.key,
    required this.room,
    required this.color,
    required this.typeName,
    required this.isDragging,
    required this.isDropTarget,
    required this.onTap,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<ManagedRoom>(
      onWillAcceptWithDetails: (details) {
        return details.data.floor == room.floor && details.data.id != room.id;
      },
      onAcceptWithDetails: (details) => onSwap(details.data),
      builder: (context, candidateData, rejectedData) {
        final isValidDropTarget = candidateData.isNotEmpty;

        return LongPressDraggable<ManagedRoom>(
          data: room,
          feedback: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            shadowColor: color.withValues(alpha: 0.4),
            child: _buildSquare(color, isHighlighted: true, scale: 1.1),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: _buildSquare(color),
          ),
          child: _buildSquare(
            color,
            isHighlighted: isValidDropTarget,
            showTooltip: true,
          ),
        );
      },
    );
  }

  Widget _buildSquare(Color bgColor, {bool isHighlighted = false, bool showTooltip = false, double scale = 1.0}) {
    // Determine if room is occupied/unavailable
    final isOccupied = room.status == RoomStatus.occupied;
    final isCleaning = room.status == RoomStatus.cleaning;
    final isMaintenance = room.status == RoomStatus.maintenance;
    final isOutOfService = room.status == RoomStatus.outOfService;
    final isUnavailable = isOccupied || isCleaning || isMaintenance || isOutOfService;

    Widget square = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 52 * scale,
        height: 52 * scale,
        decoration: BoxDecoration(
          gradient: isUnavailable
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bgColor,
                    Color.lerp(bgColor, AppColors.black, 0.15)!,
                  ],
                ),
          color: isUnavailable ? bgColor.withValues(alpha: 0.35) : null,
          borderRadius: BorderRadius.circular(10),
          border: isHighlighted
              ? Border.all(color: AppColors.primary, width: 2.5)
              : Border.all(color: bgColor.withValues(alpha: 0.3), width: 1),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Room number
            Center(
              child: Text(
                room.roomNumber,
                style: TextStyle(
                  color: _getTextColor(bgColor),
                  fontWeight: FontWeight.w700,
                  fontSize: 14 * scale,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Status indicator
            if (isUnavailable)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _getStatusIndicatorColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusIndicatorColor().withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: '$typeName • ${room.status.displayName}',
        preferBelow: false,
        verticalOffset: 28,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        child: square,
      );
    }
    return square;
  }

  Color _getTextColor(Color bgColor) {
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? AppColors.textPrimary : AppColors.white;
  }

  Color _getStatusIndicatorColor() {
    switch (room.status) {
      case RoomStatus.occupied:
        return AppColors.error;
      case RoomStatus.cleaning:
        return AppColors.roomCleaning;
      case RoomStatus.maintenance:
        return AppColors.roomEmergency;
      case RoomStatus.outOfService:
        return AppColors.grey600;
      default:
        return Colors.transparent;
    }
  }
}

/// Room square with selection support
class RoomSquareSelectable extends StatelessWidget {
  final ManagedRoom room;
  final Color color;
  final String typeName;
  final bool isDragging;
  final bool isDropTarget;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(ManagedRoom) onSwap;

  const RoomSquareSelectable({
    super.key,
    required this.room,
    required this.color,
    required this.typeName,
    required this.isDragging,
    required this.isDropTarget,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelectionMode) {
      return _buildSelectableSquare();
    }

    // Normal mode: tap to edit, long-press to enter selection mode
    // Drag is handled separately
    return DragTarget<ManagedRoom>(
      onWillAcceptWithDetails: (details) {
        return details.data.floor == room.floor && details.data.id != room.id;
      },
      onAcceptWithDetails: (details) => onSwap(details.data),
      builder: (context, candidateData, rejectedData) {
        final isValidDropTarget = candidateData.isNotEmpty;

        return LongPressDraggable<ManagedRoom>(
          data: room,
          delay: const Duration(milliseconds: 300),
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            child: _buildSquare(isHighlighted: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildSquare(),
          ),
          onDragStarted: onLongPress, // Enter selection mode when drag starts
          child: GestureDetector(
            onTap: onTap,
            child: _buildSquare(isHighlighted: isValidDropTarget),
          ),
        );
      },
    );
  }

  Widget _buildSelectableSquare() {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          _buildSquare(isHighlighted: isSelected),
          if (isSelected)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSquare({bool isHighlighted = false}) {
    final isUnavailable = room.status != RoomStatus.free;
    final bgColor = color;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isUnavailable ? bgColor.withValues(alpha: 0.4) : bgColor,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted
            ? Border.all(color: AppColors.primary, width: 2.5)
            : Border.all(color: bgColor.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: isHighlighted 
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.black.withValues(alpha: 0.1),
            blurRadius: isHighlighted ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              room.roomNumber,
              style: TextStyle(
                color: _getTextColor(bgColor),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (isUnavailable && !isSelectionMode)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusIndicatorColor(),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTextColor(Color bgColor) {
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? AppColors.textPrimary : AppColors.white;
  }

  Color _getStatusIndicatorColor() {
    switch (room.status) {
      case RoomStatus.occupied:
        return AppColors.error;
      case RoomStatus.cleaning:
        return AppColors.roomCleaning;
      case RoomStatus.maintenance:
        return AppColors.roomEmergency;
      case RoomStatus.outOfService:
        return AppColors.grey600;
      default:
        return Colors.transparent;
    }
  }
}

/// Room type legend widget with status indicators explanation
class RoomTypeLegendWithStatus extends StatelessWidget {
  final List<RoomType> roomTypes;

  const RoomTypeLegendWithStatus({super.key, required this.roomTypes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Types
          Text(
            'ROOM TYPES',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              ...roomTypes.asMap().entries.map((entry) => _LegendItem(
                    color: getRoomTypeColor(entry.key),
                    label: entry.value.name,
                  )),
              _LegendItem(color: AppColors.grey400, label: 'Unassigned'),
            ],
          ),
          const SizedBox(height: 16),
          // Status Indicators
          Text(
            'STATUS INDICATORS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _StatusLegendItem(color: AppColors.error, label: 'Occupied'),
              _StatusLegendItem(color: AppColors.roomCleaning, label: 'Cleaning'),
              _StatusLegendItem(color: AppColors.roomEmergency, label: 'Maintenance'),
              _StatusLegendItem(color: AppColors.grey600, label: 'Out of Service'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 1),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Room type legend widget
class RoomTypeLegend extends StatelessWidget {
  final List<RoomType> roomTypes;

  const RoomTypeLegend({super.key, required this.roomTypes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Types',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              ...roomTypes.asMap().entries.map((entry) => _LegendItem(
                    color: getRoomTypeColor(entry.key),
                    label: entry.value.name,
                  )),
              _LegendItem(color: AppColors.grey400, label: 'Unassigned'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                Color.lerp(color, AppColors.black, 0.15)!,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


/// Add room dialog
class AddRoomDialog extends StatefulWidget {
  final List<RoomType> roomTypes;
  final int? initialFloor;
  final String? initialRoomTypeId;
  final Future<void> Function({
    required String roomNumber,
    required int floor,
    String? roomTypeId,
  }) onAdd;

  const AddRoomDialog({
    super.key,
    required this.roomTypes,
    required this.onAdd,
    this.initialFloor,
    this.initialRoomTypeId,
  });

  static Future<void> show(
    BuildContext context, {
    required List<RoomType> roomTypes,
    required Future<void> Function({
      required String roomNumber,
      required int floor,
      String? roomTypeId,
    }) onAdd,
    int? initialFloor,
    String? initialRoomTypeId,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddRoomDialog(
        roomTypes: roomTypes,
        onAdd: onAdd,
        initialFloor: initialFloor,
        initialRoomTypeId: initialRoomTypeId,
      ),
    );
  }

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _roomNumberController = TextEditingController();
  late final TextEditingController _floorController;
  final _formKey = GlobalKey<FormState>();
  late String? _selectedTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _floorController = TextEditingController(
      text: widget.initialFloor?.toString() ?? '1',
    );
    _selectedTypeId = widget.initialRoomTypeId;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate hint text based on current floor value
    final floorValue = int.tryParse(_floorController.text) ?? 1;
    final roomHint = 'e.g. ${floorValue}01';
    
    return CustomDialog(
      title: 'Add Room',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roomNumberController,
              decoration: InputDecoration(
                labelText: 'Room Number',
                hintText: roomHint,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Floor',
                hintText: 'e.g. 1',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onChanged: (_) => setState(() {}), // Rebuild to update room hint
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Room Type'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('No Type')),
                ...widget.roomTypes.map((type) => DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedTypeId = v),
            ),
          ],
        ),
      ),
      primaryButtonText: 'Add',
      isPrimaryLoading: _isSaving,
      onPrimaryPressed: _handleAdd,
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onAdd(
        roomNumber: _roomNumberController.text.trim(),
        floor: int.tryParse(_floorController.text) ?? 1,
        roomTypeId: _selectedTypeId,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

/// Edit room dialog
class EditRoomDialog extends StatefulWidget {
  final ManagedRoom room;
  final List<RoomType> roomTypes;
  final List<int> availableFloors;
  final Future<void> Function({
    String? roomNumber,
    String? roomTypeId,
    int? floor,
    bool clearRoomType,
  }) onSave;
  final Future<void> Function() onDelete;

  const EditRoomDialog({
    super.key,
    required this.room,
    required this.roomTypes,
    required this.availableFloors,
    required this.onSave,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required ManagedRoom room,
    required List<RoomType> roomTypes,
    required List<int> availableFloors,
    required Future<void> Function({
      String? roomNumber,
      String? roomTypeId,
      int? floor,
      bool clearRoomType,
    }) onSave,
    required Future<void> Function() onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditRoomDialog(
        room: room,
        roomTypes: roomTypes,
        availableFloors: availableFloors,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  late final TextEditingController _roomNumberController;
  final _formKey = GlobalKey<FormState>();
  late String? _selectedTypeId;
  late int _selectedFloor;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _roomNumberController = TextEditingController(text: widget.room.roomNumber);
    _selectedTypeId = widget.room.roomTypeId;
    _selectedFloor = widget.room.floor;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Room ${widget.room.roomNumber}',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _roomNumberController,
              decoration: const InputDecoration(labelText: 'Room Number'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedFloor,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Floor'),
              items: widget.availableFloors
                  .map((f) => DropdownMenuItem(value: f, child: Text('Floor $f')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFloor = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Room Type'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('No Type')),
                ...widget.roomTypes.map((type) => DropdownMenuItem(
                      value: type.id,
                      child: Text(type.name),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedTypeId = v),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _handleDelete,
              icon: _isDeleting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: AppColors.error),
              label: Text(_isDeleting ? 'Deleting...' : 'Delete', style: const TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ],
        ),
      ),
      primaryButtonText: 'Save',
      isPrimaryLoading: _isSaving,
      onPrimaryPressed: _handleSave,
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final newRoomNumber = _roomNumberController.text.trim();
      await widget.onSave(
        roomNumber: newRoomNumber != widget.room.roomNumber ? newRoomNumber : null,
        floor: _selectedFloor != widget.room.floor ? _selectedFloor : null,
        roomTypeId: _selectedTypeId != widget.room.roomTypeId ? _selectedTypeId : null,
        clearRoomType: _selectedTypeId != widget.room.roomTypeId && _selectedTypeId == null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room?'),
        content: Text('Delete room ${widget.room.roomNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await widget.onDelete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

/// Add floor dialog
class AddFloorDialog extends StatefulWidget {
  final Set<int> existingFloors;
  final Future<void> Function({required int floorNumber, int? startRoom, int? endRoom}) onAdd;

  const AddFloorDialog({super.key, required this.existingFloors, required this.onAdd});

  static Future<void> show(
    BuildContext context, {
    required Set<int> existingFloors,
    required Future<void> Function({required int floorNumber, int? startRoom, int? endRoom}) onAdd,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddFloorDialog(existingFloors: existingFloors, onAdd: onAdd),
    );
  }

  @override
  State<AddFloorDialog> createState() => _AddFloorDialogState();
}

class _AddFloorDialogState extends State<AddFloorDialog> {
  final _floorController = TextEditingController();
  final _startRoomController = TextEditingController();
  final _endRoomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _createRooms = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingFloors.isNotEmpty) {
      final maxFloor = widget.existingFloors.reduce((a, b) => a > b ? a : b);
      _floorController.text = (maxFloor + 1).toString();
    } else {
      _floorController.text = '1';
    }
  }

  @override
  void dispose() {
    _floorController.dispose();
    _startRoomController.dispose();
    _endRoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Add Floor',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(labelText: 'Floor Number'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                final floor = int.tryParse(v!);
                if (floor == null || floor <= 0) return 'Invalid';
                if (widget.existingFloors.contains(floor)) return 'Exists';
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Create rooms'),
              value: _createRooms,
              onChanged: (v) => setState(() => _createRooms = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_createRooms) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startRoomController,
                      decoration: const InputDecoration(labelText: 'Start'),
                      keyboardType: TextInputType.number,
                      validator: _createRooms ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endRoomController,
                      decoration: const InputDecoration(labelText: 'End'),
                      keyboardType: TextInputType.number,
                      validator: _createRooms
                          ? (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              final end = int.tryParse(v!);
                              final start = int.tryParse(_startRoomController.text);
                              if (end != null && start != null && end < start) return 'Invalid';
                              return null;
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      primaryButtonText: 'Add',
      isPrimaryLoading: _isSaving,
      onPrimaryPressed: _handleAdd,
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onAdd(
        floorNumber: int.parse(_floorController.text),
        startRoom: _createRooms ? int.tryParse(_startRoomController.text) : null,
        endRoom: _createRooms ? int.tryParse(_endRoomController.text) : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

/// Add floor dialog with required room creation
class AddFloorDialogRequired extends StatefulWidget {
  final Set<int> existingFloors;
  final Future<void> Function({required int floorNumber, required int startRoom, required int endRoom}) onAdd;

  const AddFloorDialogRequired({super.key, required this.existingFloors, required this.onAdd});

  static Future<void> show(
    BuildContext context, {
    required Set<int> existingFloors,
    required Future<void> Function({required int floorNumber, required int startRoom, required int endRoom}) onAdd,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddFloorDialogRequired(existingFloors: existingFloors, onAdd: onAdd),
    );
  }

  @override
  State<AddFloorDialogRequired> createState() => _AddFloorDialogRequiredState();
}

class _AddFloorDialogRequiredState extends State<AddFloorDialogRequired> {
  final _floorController = TextEditingController();
  final _startRoomController = TextEditingController();
  final _endRoomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    int nextFloor = 1;
    if (widget.existingFloors.isNotEmpty) {
      nextFloor = widget.existingFloors.reduce((a, b) => a > b ? a : b) + 1;
    }
    _floorController.text = nextFloor.toString();
    // Pre-fill room numbers based on floor (e.g., floor 2 -> rooms 201-210)
    _startRoomController.text = '${nextFloor}01';
    _endRoomController.text = '${nextFloor}10';
  }

  @override
  void dispose() {
    _floorController.dispose();
    _startRoomController.dispose();
    _endRoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Add Floor',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _floorController,
              decoration: const InputDecoration(labelText: 'Floor Number'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                final floor = int.tryParse(v!);
                if (floor == null || floor <= 0) return 'Invalid floor number';
                if (widget.existingFloors.contains(floor)) return 'Floor already exists';
                return null;
              },
              onChanged: (v) {
                // Auto-update room numbers when floor changes
                final floor = int.tryParse(v);
                if (floor != null && floor > 0) {
                  _startRoomController.text = '${floor}01';
                  _endRoomController.text = '${floor}10';
                }
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Room Numbers',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startRoomController,
                    decoration: const InputDecoration(labelText: 'From'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(v!) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endRoomController,
                    decoration: const InputDecoration(labelText: 'To'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      final end = int.tryParse(v!);
                      final start = int.tryParse(_startRoomController.text);
                      if (end == null) return 'Invalid';
                      if (start != null && end < start) return 'Must be >= start';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'At least one room is required to create a floor',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      primaryButtonText: 'Create Floor',
      isPrimaryLoading: _isSaving,
      onPrimaryPressed: _handleAdd,
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onAdd(
        floorNumber: int.parse(_floorController.text),
        startRoom: int.parse(_startRoomController.text),
        endRoom: int.parse(_endRoomController.text),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

/// Bulk assign dialog (kept for compatibility)
class BulkAssignDialog extends StatefulWidget {
  final int roomCount;
  final List<RoomType> roomTypes;
  final Future<void> Function(String roomTypeId) onAssign;
  final VoidCallback onCancel;

  const BulkAssignDialog({
    super.key,
    required this.roomCount,
    required this.roomTypes,
    required this.onAssign,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required int roomCount,
    required List<RoomType> roomTypes,
    required Future<void> Function(String roomTypeId) onAssign,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BulkAssignDialog(
        roomCount: roomCount,
        roomTypes: roomTypes,
        onAssign: onAssign,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<BulkAssignDialog> createState() => _BulkAssignDialogState();
}

class _BulkAssignDialogState extends State<BulkAssignDialog> {
  String? _selectedTypeId;

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Assign Type (${widget.roomCount})',
      content: DropdownButtonFormField<String>(
        value: _selectedTypeId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Room Type'),
        items: widget.roomTypes.map((type) => DropdownMenuItem(value: type.id, child: Text(type.name))).toList(),
        onChanged: (v) => setState(() => _selectedTypeId = v),
      ),
      primaryButtonText: 'Assign',
      isPrimaryDisabled: _selectedTypeId == null,
      onPrimaryPressed: () async {
        if (_selectedTypeId == null) return;
        try {
          await widget.onAssign(_selectedTypeId!);
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        Navigator.pop(context);
        widget.onCancel();
      },
    );
  }
}

/// Legacy RoomTile for backwards compatibility
class RoomTile extends StatelessWidget {
  final ManagedRoom room;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckboxChanged;

  const RoomTile({
    super.key,
    required this.room,
    required this.isSelected,
    required this.showCheckbox,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(room.roomNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
      ),
      title: Text(room.roomTypeName ?? 'No Type'),
      subtitle: Text(room.status.displayName),
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isSelected,
    );
  }
}

/// Bulk edit room type dialog
class BulkEditRoomTypeDialog extends StatefulWidget {
  final int roomCount;
  final List<RoomType> roomTypes;
  final Future<void> Function(String? roomTypeId) onSave;

  const BulkEditRoomTypeDialog({
    super.key,
    required this.roomCount,
    required this.roomTypes,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required int roomCount,
    required List<RoomType> roomTypes,
    required Future<void> Function(String? roomTypeId) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BulkEditRoomTypeDialog(
        roomCount: roomCount,
        roomTypes: roomTypes,
        onSave: onSave,
      ),
    );
  }

  @override
  State<BulkEditRoomTypeDialog> createState() => _BulkEditRoomTypeDialogState();
}

class _BulkEditRoomTypeDialogState extends State<BulkEditRoomTypeDialog> {
  String? _selectedTypeId;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Edit Room Type',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change room type for ${widget.roomCount} selected room(s)',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTypeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Room Type'),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('No Type')),
              ...widget.roomTypes.map((type) => DropdownMenuItem(
                    value: type.id,
                    child: Text(type.name),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedTypeId = v),
          ),
        ],
      ),
      primaryButtonText: 'Save',
      isPrimaryLoading: _isSaving,
      onPrimaryPressed: _handleSave,
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_selectedTypeId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
