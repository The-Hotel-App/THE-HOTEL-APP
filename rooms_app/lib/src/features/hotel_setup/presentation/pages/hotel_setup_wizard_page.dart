import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/hotel_setup/data/repositories/local_hotel_setup_repository.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel.dart';
import 'package:rooms/src/features/hotel_setup/presentation/providers/setup_providers.dart';

class HotelSetupWizardPage extends ConsumerStatefulWidget {
  const HotelSetupWizardPage({super.key});

  @override
  ConsumerState<HotelSetupWizardPage> createState() =>
      _HotelSetupWizardPageState();
}

class _HotelSetupWizardPageState extends ConsumerState<HotelSetupWizardPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Step 1: Hotel Profile
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 2: Floors & Rooms
  int _totalFloors = 1;
  final Map<int, TextEditingController> _startRoomControllers = {
    1: TextEditingController(text: '101'),
  };
  final Map<int, TextEditingController> _endRoomControllers = {
    1: TextEditingController(text: '110'),
  };
  final Map<int, FocusNode> _startRoomFocusNodes = {1: FocusNode()};
  final Map<int, FocusNode> _endRoomFocusNodes = {1: FocusNode()};

  // Step 3: Room Types
  final List<RoomType> _roomTypes = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (var c in _startRoomControllers.values) {
      c.dispose();
    }
    for (var c in _endRoomControllers.values) {
      c.dispose();
    }
    for (var f in _startRoomFocusNodes.values) {
      f.dispose();
    }
    for (var f in _endRoomFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  int _getRoomCount(int floor) {
    final start = int.tryParse(_startRoomControllers[floor]?.text ?? '');
    final end = int.tryParse(_endRoomControllers[floor]?.text ?? '');
    if (start == null || end == null || end < start) return 0;
    return end - start + 1;
  }

  int _getTotalRooms() {
    int total = 0;
    for (int i = 1; i <= _totalFloors; i++) {
      total += _getRoomCount(i);
    }
    return total;
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    final totalRooms = _getTotalRooms();

    // Build floor configurations
    final floorConfigs = <FloorConfig>[];
    for (int floor = 1; floor <= _totalFloors; floor++) {
      final start = int.tryParse(_startRoomControllers[floor]?.text ?? '');
      final end = int.tryParse(_endRoomControllers[floor]?.text ?? '');
      if (start != null && end != null && end >= start) {
        floorConfigs.add(
          FloorConfig(floor: floor, startRoom: start, endRoom: end),
        );
      }
    }

    final hotel = Hotel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      totalRooms: totalRooms,
      totalFloors: _totalFloors,
      floorConfigs: floorConfigs,
      createdAt: DateTime.now(),
      isSetupCompleted: true,
    );

    final repo =
        ref.read(hotelSetupRepositoryProvider) as LocalHotelSetupRepository;
    await repo.addHotel(hotel);
    await repo.saveRoomTypes(_roomTypes);
    await repo.markSetupCompleted();

    // Invalidate the setup provider to trigger router refresh
    ref.invalidate(isSetupCompletedProvider);
    ref.invalidate(currentHotelProvider);

    if (mounted) {
      // Navigate to login after setup is complete
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: AppColors.grey200,
                  valueColor: const AlwaysStoppedAnimation(AppColors.black),
                  minHeight: 8,
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildHotelProfilePage(),
                  _buildFloorsRoomsPage(),
                  _buildRoomTypesPage(),
                ],
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.black),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _currentPage == _totalPages - 1
                          ? _completeSetup
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? 'Complete Setup'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏨 Hotel Information',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with basic details about your hotel',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _nameController,
            label: 'Hotel Name',
            hint: 'Enter hotel name',
            icon: Icons.business,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter full address',
            icon: Icons.location_on,
            maxLines: 2,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone',
            hint: 'Enter phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter email address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildFloorsRoomsPage() {
    final totalRooms = _getTotalRooms();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏢 Floors & Rooms',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define room ranges for each floor',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalRooms > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalRooms rooms',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNumberSelector(
            label: 'Total Floors',
            value: _totalFloors,
            onChanged: (val) {
              setState(() {
                final oldFloors = _totalFloors;
                _totalFloors = val;

                // Add controllers for new floors
                for (int i = oldFloors + 1; i <= _totalFloors; i++) {
                  final floorPrefix = i * 100;
                  _startRoomControllers[i] = TextEditingController(
                    text: '${floorPrefix + 1}',
                  );
                  _endRoomControllers[i] = TextEditingController(
                    text: '${floorPrefix + 10}',
                  );
                  _startRoomFocusNodes[i] = FocusNode();
                  _endRoomFocusNodes[i] = FocusNode();
                }

                // Remove controllers for removed floors
                for (int i = _totalFloors + 1; i <= oldFloors; i++) {
                  _startRoomControllers[i]?.dispose();
                  _endRoomControllers[i]?.dispose();
                  _startRoomFocusNodes[i]?.dispose();
                  _endRoomFocusNodes[i]?.dispose();
                  _startRoomControllers.remove(i);
                  _endRoomControllers.remove(i);
                  _startRoomFocusNodes.remove(i);
                  _endRoomFocusNodes.remove(i);
                }
              });
            },
            min: 1,
            max: 20,
          ),
          const SizedBox(height: 16),
          ...List.generate(_totalFloors, (index) {
            final floor = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildFloorRangeInput(floor),
            );
          }),
        ],
      ),
    );
  }

  String _getDefaultStartRoom(int floor) => '${floor * 100 + 1}';
  String _getDefaultEndRoom(int floor) => '${floor * 100 + 10}';

  void _validateAndRestoreDefaults(int floor) {
    final startController = _startRoomControllers[floor];
    final endController = _endRoomControllers[floor];

    if (startController == null || endController == null) return;

    final startText = startController.text.trim();
    final endText = endController.text.trim();

    // If both are empty, restore defaults
    if (startText.isEmpty && endText.isEmpty) {
      startController.text = _getDefaultStartRoom(floor);
      endController.text = _getDefaultEndRoom(floor);
      return;
    }

    // Parse values
    final start = int.tryParse(startText);
    final end = int.tryParse(endText);

    // Validation: both must be valid numbers
    if (start == null || end == null) {
      startController.text = _getDefaultStartRoom(floor);
      endController.text = _getDefaultEndRoom(floor);
      return;
    }

    // Validation: end must be >= start
    if (end < start) {
      endController.text = _getDefaultEndRoom(floor);
      return;
    }

    // Validation: range should be reasonable (1-9999)
    if (start < 1 || end > 9999) {
      startController.text = _getDefaultStartRoom(floor);
      endController.text = _getDefaultEndRoom(floor);
      return;
    }

    setState(() {});
  }

  Widget _buildFloorRangeInput(int floor) {
    final roomCount = _getRoomCount(floor);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Floor $floor',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startRoomControllers[floor],
                    focusNode: _startRoomFocusNodes[floor],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: _getDefaultStartRoom(floor),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _validateAndRestoreDefaults(floor),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '—',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _endRoomControllers[floor],
                    focusNode: _endRoomFocusNodes[floor],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: _getDefaultEndRoom(floor),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _validateAndRestoreDefaults(floor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 65,
            child: Text(
              '$roomCount rooms',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛏️ Room Types',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Define your room categories and pricing',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_roomTypes.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.hotel, size: 48, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'No room types yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first room type to continue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_roomTypes.length, (index) {
              final roomType = _roomTypes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.black,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    roomType.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '₹${roomType.basePrice.toStringAsFixed(0)}/night • ${roomType.maxOccupancy} guests',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        _roomTypes.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showAddRoomTypeDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Room Type'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.black),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
      ),
    );
  }

  Widget _buildNumberSelector({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: value > min ? () => onChanged(value - 1) : null,
                    icon: const Icon(Icons.remove, size: 20),
                    color: AppColors.black,
                  ),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: value < max ? () => onChanged(value + 1) : null,
                    icon: const Icon(Icons.add, size: 20),
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomTypeDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    int maxOccupancy = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Add Room Type',
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Type Name',
                    hintText: 'e.g., Standard, Deluxe, Suite',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Base Price per Night',
                    hintText: 'e.g., 2000',
                    prefixText: '₹',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Max Occupancy:'),
                    const Spacer(),
                    IconButton(
                      onPressed: maxOccupancy > 1
                          ? () => setDialogState(() => maxOccupancy--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$maxOccupancy',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => maxOccupancy++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          secondaryButtonText: 'Cancel',
          primaryButtonText: 'Add',
          onPrimaryPressed: () {
            if (nameController.text.isNotEmpty &&
                priceController.text.isNotEmpty) {
              setState(() {
                _roomTypes.add(
                  RoomType(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    basePrice: double.parse(priceController.text),
                    maxOccupancy: maxOccupancy,
                  ),
                );
              });
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
