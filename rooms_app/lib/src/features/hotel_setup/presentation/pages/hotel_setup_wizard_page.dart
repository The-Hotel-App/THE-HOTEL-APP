import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
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
  final Map<int, int> _roomsPerFloor = {1: 10};

  // Step 3: Room Types
  final List<RoomType> _roomTypes = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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
    final totalRooms = _roomsPerFloor.values.reduce((a, b) => a + b);

    final hotel = Hotel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      totalRooms: totalRooms,
      totalFloors: _totalFloors,
      createdAt: DateTime.now(),
      isSetupCompleted: true,
    );

    final repo = ref.read(hotelSetupRepositoryProvider);
    await repo.saveHotelProfile(hotel);
    await repo.saveRoomTypes(_roomTypes);
    await repo.markSetupCompleted();

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset('assets/icons/icon_image.png', height: 60),
                  const SizedBox(height: 12),
                  Text(
                    'Hotel Setup',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentPage + 1} of $_totalPages',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

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
                        foregroundColor: AppColors.primary,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏢 Floors & Rooms',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your hotel structure',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildNumberSelector(
            label: 'Total Floors',
            value: _totalFloors,
            onChanged: (val) {
              setState(() {
                _totalFloors = val;
                // Adjust rooms per floor map
                for (int i = 1; i <= _totalFloors; i++) {
                  _roomsPerFloor.putIfAbsent(i, () => 10);
                }
                _roomsPerFloor.removeWhere((key, value) => key > _totalFloors);
              });
            },
            min: 1,
            max: 20,
          ),
          const SizedBox(height: 24),
          ...List.generate(_totalFloors, (index) {
            final floor = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildNumberSelector(
                label: 'Floor $floor - Number of Rooms',
                value: _roomsPerFloor[floor] ?? 10,
                onChanged: (val) {
                  setState(() {
                    _roomsPerFloor[floor] = val;
                  });
                },
                min: 1,
                max: 50,
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Total Rooms: ${_roomsPerFloor.values.isEmpty ? 0 : _roomsPerFloor.values.reduce((a, b) => a + b)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.black,
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.black,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.black,
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
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Room Type'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
