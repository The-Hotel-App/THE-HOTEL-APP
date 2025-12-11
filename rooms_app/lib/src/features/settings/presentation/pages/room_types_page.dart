import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';

/// Room Types Management Page - Owner only
class RoomTypesPage extends ConsumerStatefulWidget {
  const RoomTypesPage({super.key});

  @override
  ConsumerState<RoomTypesPage> createState() => _RoomTypesPageState();
}

class _RoomTypesPageState extends ConsumerState<RoomTypesPage> {
  List<RoomType> _roomTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
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
      final repository = ref.read(roomTypesRepositoryProvider);
      final roomTypes = await repository.getRoomTypes(hotel.hotelId);
      setState(() {
        _roomTypes = roomTypes;
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
            Icon(Icons.category, size: 24),
            SizedBox(width: 8),
            Text('Room Types'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(null),
            tooltip: 'Add Room Type',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoomTypes,
            tooltip: 'Refresh',
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
              onPressed: _loadRoomTypes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildRoomTypesList();
  }

  Widget _buildRoomTypesList() {
    return RefreshIndicator(
      onRefresh: _loadRoomTypes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roomTypes.length,
        itemBuilder: (context, index) {
          final roomType = _roomTypes[index];
          return _buildRoomTypeCard(roomType);
        },
      ),
    );
  }

  Widget _buildRoomTypeCard(RoomType roomType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bedroom_parent, color: AppColors.warning),
        ),
        title: Text(
          roomType.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '₹${roomType.basePrice.toStringAsFixed(0)}/night • Max ${roomType.maxOccupancy} guests',
            ),
            if (roomType.description != null &&
                roomType.description!.isNotEmpty)
              Text(
                roomType.description!,
                style: TextStyle(color: AppColors.grey500, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(roomType);
            } else if (value == 'delete') {
              _showDeleteConfirmation(roomType);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(RoomType? roomType) {
    final isEditing = roomType != null;
    final nameController = TextEditingController(text: roomType?.name ?? '');
    final priceController = TextEditingController(
      text: roomType?.basePrice.toStringAsFixed(0) ?? '',
    );
    final occupancyController = TextEditingController(
      text: roomType?.maxOccupancy.toString() ?? '2',
    );
    final descriptionController = TextEditingController(
      text: roomType?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Room Type' : 'Add Room Type'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Deluxe, Suite...',
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price/Night (₹)',
                      hintText: '1500',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: occupancyController,
                    decoration: const InputDecoration(
                      labelText: 'Max Guests',
                      hintText: '2',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional',
                    ),
                    maxLines: 2,
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
                        final repository = ref.read(
                          roomTypesRepositoryProvider,
                        );

                        if (isEditing) {
                          await repository.updateRoomType(
                            id: roomType.id,
                            name: nameController.text.trim(),
                            basePrice:
                                double.tryParse(priceController.text) ?? 0,
                            maxOccupancy:
                                int.tryParse(occupancyController.text) ?? 2,
                            description: descriptionController.text.trim(),
                          );
                        } else {
                          await repository.createRoomType(
                            hotelId: hotel!.hotelId,
                            name: nameController.text.trim(),
                            basePrice:
                                double.tryParse(priceController.text) ?? 0,
                            maxOccupancy:
                                int.tryParse(occupancyController.text) ?? 2,
                            description: descriptionController.text.trim(),
                          );
                        }

                        if (context.mounted) Navigator.pop(context);
                        await _loadRoomTypes();

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Room type updated!'
                                    : 'Room type added!',
                              ),
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
                  : Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(RoomType roomType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Delete "${roomType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repository = ref.read(roomTypesRepositoryProvider);
                await repository.deleteRoomType(roomType.id);
                await _loadRoomTypes();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room type deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
