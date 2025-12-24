import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/utils/signup_validators.dart';
import 'package:rooms/src/features/hotel_setup/data/repositories/supabase_hotel_setup_repository.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel_new.dart';

/// Local room type for setup (before hotel is created)
class LocalRoomType {
  final String name;
  final double basePrice;
  final int maxOccupancy;
  final String? description;

  LocalRoomType({
    required this.name,
    required this.basePrice,
    required this.maxOccupancy,
    this.description,
  });
}

/// Simplified hotel creation page for the signup flow
class CreateHotelPage extends ConsumerStatefulWidget {
  const CreateHotelPage({super.key});

  @override
  ConsumerState<CreateHotelPage> createState() => _CreateHotelPageState();
}

class _CreateHotelPageState extends ConsumerState<CreateHotelPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  int _totalFloors = 1;
  final Map<int, int> _roomsPerFloor = {1: 10};
  final List<LocalRoomType> _roomTypes = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateFloors(int newValue) {
    setState(() {
      _totalFloors = newValue;
      for (int i = 1; i <= newValue; i++) {
        _roomsPerFloor.putIfAbsent(i, () => 10);
      }
      _roomsPerFloor.removeWhere((floor, _) => floor > newValue);
    });
  }

  void _showAddEditRoomTypeDialog([LocalRoomType? roomType, int? index]) {
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

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: isEditing ? 'Edit Room Type' : 'Add Room Type',
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Deluxe, Suite, Standard...',
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price/Night (₹) *',
                    hintText: '1500',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: occupancyController,
                  decoration: const InputDecoration(
                    labelText: 'Max Guests *',
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
        primaryButtonText: isEditing ? 'Update' : 'Add',
        onPrimaryPressed: () {
          if (!formKey.currentState!.validate()) return;

          final newRoomType = LocalRoomType(
            name: nameController.text.trim(),
            basePrice: double.tryParse(priceController.text) ?? 0,
            maxOccupancy: int.tryParse(occupancyController.text) ?? 2,
            description: descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
          );

          setState(() {
            if (isEditing && index != null) {
              _roomTypes[index] = newRoomType;
            } else {
              _roomTypes.add(newRoomType);
            }
          });

          Navigator.pop(context);
        },
        secondaryButtonText: 'Cancel',
        onSecondaryPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _deleteRoomType(int index) {
    CustomDialog.show(
      context: context,
      title: 'Delete Room Type?',
      icon: Icons.delete_outline,
      type: CustomDialogType.destructive,
      content: Text('Delete "${_roomTypes[index].name}"?'),
      primaryButtonText: 'Delete',
      onPrimaryPressed: () {
        setState(() => _roomTypes.removeAt(index));
        Navigator.pop(context);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );
  }

  Future<void> _createHotel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      // Build floor configs
      final floorConfigs = <FloorConfig>[];
      int currentRoomStart = 1;

      for (int floor = 1; floor <= _totalFloors; floor++) {
        final roomCount = _roomsPerFloor[floor] ?? 10;
        floorConfigs.add(
          FloorConfig(
            floor: floor,
            startRoom: currentRoomStart,
            endRoom: currentRoomStart + roomCount - 1,
          ),
        );
        currentRoomStart += roomCount;
      }

      final repository = SupabaseHotelSetupRepository();

      // Create the hotel
      final hotel = await repository.createHotel(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        totalFloors: _totalFloors,
        floorConfigs: floorConfigs,
        ownerId: user.id,
        hotelCode: null,
      );

      AppLogger.success('Hotel created: ${hotel.name}', tag: 'HotelSetup');

      // Create room types if any
      if (_roomTypes.isNotEmpty) {
        await repository.createRoomTypes(
          hotelId: hotel.id,
          roomTypes: _roomTypes
              .map(
                (rt) => RoomType(
                  id: '', // Will be generated by database
                  hotelId: hotel.id,
                  name: rt.name,
                  basePrice: rt.basePrice,
                  maxOccupancy: rt.maxOccupancy,
                  description: rt.description,
                ),
              )
              .toList(),
        );
      }

      // Create rooms
      await repository.createRooms(
        hotelId: hotel.id,
        floorConfigs: floorConfigs,
        roomTypeAssignments: {},
      );

      // Mark setup as completed
      await repository.completeSetup(hotel.id);

      AppLogger.success('Hotel setup complete!', tag: 'HotelSetup');

      // Refresh hotels list and select the new hotel
      ref.invalidate(userHotelsProvider);
      ref.read(selectedHotelIdProvider.notifier).state = hotel.id;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hotel "${hotel.name}" created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.mainShell);
      }
    } catch (e) {
      AppLogger.error('Hotel creation failed', tag: 'HotelSetup', error: e);
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Create Your Hotel',
          style: TextStyle(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Hotel Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter basic information about your hotel property.',
                  style: TextStyle(color: AppColors.grey400),
                ),
                const SizedBox(height: 24),

                // Hotel Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _buildInputDecoration(
                    labelText: 'Hotel Name *',
                    hintText: 'e.g., Grand Palace Hotel',
                    prefixIcon: Icons.hotel,
                  ),
                  validator: SignupValidators.validateHotelName,
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: AppColors.white),
                  maxLines: 2,
                  decoration: _buildInputDecoration(
                    labelText: 'Address *',
                    hintText: 'Full hotel address',
                    prefixIcon: Icons.location_on,
                  ),
                  validator: SignupValidators.validateAddress,
                ),
                const SizedBox(height: 16),

                // Phone (optional)
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: 'Hotel contact number',
                    prefixIcon: Icons.phone,
                  ),
                ),
                const SizedBox(height: 16),

                // Email (optional)
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'Hotel email address',
                    prefixIcon: Icons.email,
                  ),
                ),
                const SizedBox(height: 32),

                // Room Configuration Section
                Text(
                  'Room Configuration',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Total Floors
                _buildFloorSelector(),
                const SizedBox(height: 16),

                // Rooms per floor
                _buildRoomsPerFloorSection(),
                const SizedBox(height: 24),

                // Room Types Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room Types',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddEditRoomTypeDialog(),
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      label: const Text(
                        'Add',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional: Define room types now or add them later.',
                  style: TextStyle(color: AppColors.grey400, fontSize: 13),
                ),
                const SizedBox(height: 12),

                if (_roomTypes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey600),
                    ),
                    child: const Center(
                      child: Text(
                        'No room types added yet',
                        style: TextStyle(color: AppColors.grey500),
                      ),
                    ),
                  )
                else
                  ...List.generate(_roomTypes.length, (index) {
                    final rt = _roomTypes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.grey900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey600),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bedroom_parent,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          rt.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        subtitle: Text(
                          '₹${rt.basePrice.toStringAsFixed(0)}/night • Max ${rt.maxOccupancy} guests',
                          style: TextStyle(color: AppColors.grey400),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 18,
                                color: AppColors.grey400,
                              ),
                              onPressed: () =>
                                  _showAddEditRoomTypeDialog(rt, index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => _deleteRoomType(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Summary
                _buildSummary(),
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createHotel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Hotel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey600),
      ),
      child: Row(
        children: [
          Icon(Icons.layers, color: AppColors.grey400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Number of Floors',
              style: TextStyle(color: AppColors.white, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: _totalFloors > 1
                ? () => _updateFloors(_totalFloors - 1)
                : null,
            icon: Icon(
              Icons.remove_circle_outline,
              color: _totalFloors > 1 ? AppColors.warning : AppColors.grey600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grey800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_totalFloors',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _totalFloors < 20
                ? () => _updateFloors(_totalFloors + 1)
                : null,
            icon: Icon(
              Icons.add_circle_outline,
              color: _totalFloors < 20 ? AppColors.warning : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsPerFloorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bed, color: AppColors.grey400),
              const SizedBox(width: 12),
              Text(
                'Rooms per Floor',
                style: TextStyle(color: AppColors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_totalFloors, (index) {
            final floor = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$floor',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Floor $floor',
                      style: TextStyle(color: AppColors.grey300),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      initialValue: '${_roomsPerFloor[floor] ?? 10}',
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey600),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.grey600),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.info),
                        ),
                        filled: true,
                        fillColor: AppColors.grey800,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        final rooms = int.tryParse(value) ?? 10;
                        setState(
                          () => _roomsPerFloor[floor] = rooms.clamp(1, 100),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalRooms = _roomsPerFloor.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.summarize, color: AppColors.success),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Rooms', style: TextStyle(color: AppColors.grey400)),
              Text(
                '$totalRooms',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room Types', style: TextStyle(color: AppColors.grey400)),
              Text(
                '${_roomTypes.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Floors', style: TextStyle(color: AppColors.grey400)),
              Text(
                '$_totalFloors',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: AppColors.grey400),
      hintStyle: TextStyle(color: AppColors.grey600),
      prefixIcon: Icon(prefixIcon, color: AppColors.grey400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey600),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.info, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: AppColors.grey900,
    );
  }
}
