import 'package:flutter/material.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Floor section header with expandable rooms list
class FloorSection extends StatelessWidget {
  final int floor;
  final List<ManagedRoom> rooms;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget Function(ManagedRoom room) buildRoomTile;

  const FloorSection({
    super.key,
    required this.floor,
    required this.rooms,
    required this.isExpanded,
    required this.onToggle,
    required this.buildRoomTile,
  });

  @override
  Widget build(BuildContext context) {
    // Sort rooms by room number
    final sortedRooms = List<ManagedRoom>.from(rooms)
      ..sort((a, b) {
        final aNum = int.tryParse(a.roomNumber) ?? 0;
        final bNum = int.tryParse(b.roomNumber) ?? 0;
        if (aNum != 0 && bNum != 0) return aNum.compareTo(bNum);
        return a.roomNumber.compareTo(b.roomNumber);
      });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Floor Header - Clean & Simple
          Material(
            color: AppColors.primary,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Text(
                      'Floor $floor',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${sortedRooms.length})',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Rooms List
          if (isExpanded) ...sortedRooms.map((room) => buildRoomTile(room)),
        ],
      ),
    );
  }
}

/// Room tile widget showing room details with selection
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
    final statusColor = _getStatusColor(room.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.info.withValues(alpha: 0.08)
                : AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.grey200)),
          ),
          child: Row(
            children: [
              // Checkbox for selection mode
              if (showCheckbox)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onCheckboxChanged,
                      activeColor: AppColors.primary,
                    ),
                  ),
                ),
              // Room Number Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    room.roomNumber,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Room Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomTypeName ?? 'No Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: room.roomTypeName != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      room.pricePerNight != null
                          ? '₹${room.pricePerNight!.toStringAsFixed(0)}/night • Max ${room.maxOccupancy ?? 2}'
                          : 'Max ${room.maxOccupancy ?? 2} guests',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  room.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
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
        return AppColors.roomCleaning;
      case RoomStatus.maintenance:
        return AppColors.roomEmergency;
      case RoomStatus.outOfService:
        return AppColors.grey600;
    }
  }
}

/// Add room dialog
class AddRoomDialog extends StatefulWidget {
  final List<RoomType> roomTypes;
  final Future<void> Function({
    required String roomNumber,
    required int floor,
    String? roomTypeId,
  })
  onAdd;

  const AddRoomDialog({
    super.key,
    required this.roomTypes,
    required this.onAdd,
  });

  static Future<void> show(
    BuildContext context, {
    required List<RoomType> roomTypes,
    required Future<void> Function({
      required String roomNumber,
      required int floor,
      String? roomTypeId,
    })
    onAdd,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddRoomDialog(roomTypes: roomTypes, onAdd: onAdd),
    );
  }

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();
  String? _selectedTypeId;
  bool _isSaving = false;

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Add Room',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  hintText: 'e.g. 101',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedTypeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: widget.roomTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type.id,
                        child: Text(
                          '${type.name} (₹${type.basePrice.toStringAsFixed(0)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTypeId = v),
              ),
            ],
          ),
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Edit room dialog for changing room type
class EditRoomDialog extends StatefulWidget {
  final ManagedRoom room;
  final List<RoomType> roomTypes;
  final Future<void> Function(String? roomTypeId) onSave;

  const EditRoomDialog({
    super.key,
    required this.room,
    required this.roomTypes,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required ManagedRoom room,
    required List<RoomType> roomTypes,
    required Future<void> Function(String? roomTypeId) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          EditRoomDialog(room: room, roomTypes: roomTypes, onSave: onSave),
    );
  }

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  late String? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.room.roomTypeId;
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Edit Room ${widget.room.roomNumber}',
      content: DropdownButtonFormField<String>(
        initialValue: _selectedTypeId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Room Type'),
        items: widget.roomTypes
            .map(
              (type) => DropdownMenuItem(
                value: type.id,
                child: Text(
                  '${type.name} (₹${type.basePrice.toStringAsFixed(0)})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _selectedTypeId = v),
      ),
      primaryButtonText: 'Update',
      onPrimaryPressed: () async {
        try {
          await widget.onSave(_selectedTypeId);
          if (context.mounted) Navigator.pop(context);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }
}

/// Bulk assign room type dialog
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
      title: 'Assign Type to ${widget.roomCount} Rooms',
      content: DropdownButtonFormField<String>(
        initialValue: _selectedTypeId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Room Type'),
        items: widget.roomTypes
            .map(
              (type) => DropdownMenuItem(
                value: type.id,
                child: Text(
                  '${type.name} (₹${type.basePrice.toStringAsFixed(0)})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
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
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
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
