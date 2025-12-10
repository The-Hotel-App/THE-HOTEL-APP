import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart'
    as auth_new;
import 'package:rooms/src/features/hotel_setup/data/repositories/supabase_hotel_setup_repository.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel_new.dart'
    as hotel_new;
import 'package:rooms/src/features/hotel_setup/presentation/widgets/floor_range_input.dart';
import 'package:rooms/src/features/hotel_setup/presentation/widgets/setup_form_widgets.dart';

/// Hotel Setup Wizard - Multi-step wizard for setting up a new hotel
class HotelSetupWizardPage extends ConsumerStatefulWidget {
  const HotelSetupWizardPage({super.key});

  @override
  ConsumerState<HotelSetupWizardPage> createState() =>
      _HotelSetupWizardPageState();
}

class _HotelSetupWizardPageState extends ConsumerState<HotelSetupWizardPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  // Step 0: Owner Registration
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _ownerId;

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
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _ownerPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _nextPage() async {
    if (_currentPage == 0) {
      if (_ownerNameController.text.isEmpty ||
          _ownerEmailController.text.isEmpty ||
          _ownerPhoneController.text.isEmpty ||
          _ownerPasswordController.text.isEmpty) {
        _showErrorDialog('Please fill in all required fields');
        return;
      }

      if (_ownerPasswordController.text != _confirmPasswordController.text) {
        _showErrorDialog('Passwords do not match');
        return;
      }

      if (_ownerPasswordController.text.length < 6) {
        _showErrorDialog('Password must be at least 6 characters');
        return;
      }

      await _registerOwner();
      if (_ownerId == null) return;
    }

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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Error',
        content: Text(message),
        primaryButtonText: 'OK',
      ),
    );
  }

  Future<void> _registerOwner() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final authRepo = SupabaseAuthRepository();
      final user = await authRepo.signUp(
        email: _ownerEmailController.text.trim(),
        password: _ownerPasswordController.text,
        name: _ownerNameController.text.trim(),
        phone: _ownerPhoneController.text.trim(),
      );

      setState(() {
        _ownerId = user.id;
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Registration failed: ${e.toString()}');
      }
    }
  }

  Future<void> _completeSetup() async {
    if (_ownerId == null) {
      _showErrorDialog('Owner registration required');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final floorConfigs = <hotel_new.FloorConfig>[];
      for (int floor = 1; floor <= _totalFloors; floor++) {
        final start = int.tryParse(_startRoomControllers[floor]?.text ?? '');
        final end = int.tryParse(_endRoomControllers[floor]?.text ?? '');
        if (start != null && end != null && end >= start) {
          floorConfigs.add(
            hotel_new.FloorConfig(floor: floor, startRoom: start, endRoom: end),
          );
        }
      }

      final supabaseHotelRepo = SupabaseHotelSetupRepository();
      final createdHotel = await supabaseHotelRepo.createHotel(
        ownerId: _ownerId!,
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
      );

      // Create room types
      List<hotel_new.RoomType> createdRoomTypes = [];
      if (_roomTypes.isNotEmpty) {
        final roomTypesData = _roomTypes
            .map(
              (rt) => hotel_new.RoomType(
                id: '',
                hotelId: createdHotel.id,
                name: rt.name,
                basePrice: rt.basePrice,
                maxOccupancy: rt.maxOccupancy,
                description: null,
              ),
            )
            .toList();
        await supabaseHotelRepo.createRoomTypes(
          hotelId: createdHotel.id,
          roomTypes: roomTypesData,
        );
        createdRoomTypes = await supabaseHotelRepo.getRoomTypes(
          createdHotel.id,
        );
      }

      // Create rooms
      final roomTypeAssignments = <String, String>{};
      if (createdRoomTypes.isNotEmpty) {
        final defaultRoomTypeId = createdRoomTypes.first.id;
        for (final config in floorConfigs) {
          for (
            int roomNum = config.startRoom;
            roomNum <= config.endRoom;
            roomNum++
          ) {
            roomTypeAssignments[roomNum.toString()] = defaultRoomTypeId;
          }
        }
      }

      await supabaseHotelRepo.createRooms(
        hotelId: createdHotel.id,
        floorConfigs: floorConfigs,
        roomTypeAssignments: roomTypeAssignments,
      );

      await supabaseHotelRepo.completeSetup(createdHotel.id);

      if (mounted) {
        Navigator.pop(context);

        ref.invalidate(auth_new.currentUserProvider);
        ref.invalidate(auth_new.userHotelsProvider);
        ref.invalidate(auth_new.selectedHotelIdProvider);
        ref.read(auth_new.selectedHotelIdProvider.notifier).state =
            createdHotel.id;

        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => AppDialog(
            title: 'Success!',
            content: Text(
              'Hotel "${_nameController.text}" has been created successfully!',
            ),
            primaryButtonText: 'Continue',
          ),
        );
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Failed to create hotel: ${e.toString()}');
      }
    }
  }

  void _updateFloors(int newValue) {
    setState(() {
      final oldFloors = _totalFloors;
      _totalFloors = newValue;

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
  }

  void _validateAndRestoreDefaults(int floor) {
    final startController = _startRoomControllers[floor];
    final endController = _endRoomControllers[floor];

    if (startController == null || endController == null) return;

    final startText = startController.text.trim();
    final endText = endController.text.trim();

    final defaultStart = '${floor * 100 + 1}';
    final defaultEnd = '${floor * 100 + 10}';

    if (startText.isEmpty && endText.isEmpty) {
      startController.text = defaultStart;
      endController.text = defaultEnd;
      return;
    }

    final start = int.tryParse(startText);
    final end = int.tryParse(endText);

    if (start == null ||
        end == null ||
        end < start ||
        start < 1 ||
        end > 9999) {
      startController.text = defaultStart;
      endController.text = defaultEnd;
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _currentPage == 0
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
                onPressed: () => context.go(AppRoutes.welcome),
                tooltip: 'Back to Welcome',
              ),
              title: const Text(
                'Create New Hotel',
                style: TextStyle(color: AppColors.black),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildOwnerRegistrationPage(),
                  _buildHotelProfilePage(),
                  _buildFloorsRoomsPage(),
                  _buildRoomTypesPage(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
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
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
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
                _currentPage == _totalPages - 1 ? 'Complete Setup' : 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerRegistrationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👤 Owner Account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your owner account to manage your hotel',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          SetupTextField(
            controller: _ownerNameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: _ownerEmailController,
            label: 'Email',
            hint: 'Enter your email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: _ownerPhoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            required: true,
          ),
          const SizedBox(height: 16),
          PasswordTextField(
            controller: _ownerPasswordController,
            label: 'Password',
            hint: 'Enter password (min. 6 characters)',
            isVisible: _isPasswordVisible,
            onToggleVisibility: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          const SizedBox(height: 16),
          PasswordTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            isVisible: _isConfirmPasswordVisible,
            onToggleVisibility: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
            ),
            prefixIcon: Icons.lock_outline,
          ),
        ],
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
          SetupTextField(
            controller: _nameController,
            label: 'Hotel Name',
            hint: 'Enter hotel name',
            icon: Icons.business,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter full address',
            icon: Icons.location_on,
            maxLines: 2,
            required: true,
          ),
          const SizedBox(height: 16),
          SetupTextField(
            controller: _phoneController,
            label: 'Phone',
            hint: 'Enter phone number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SetupTextField(
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
          NumberSelector(
            label: 'Total Floors',
            value: _totalFloors,
            onChanged: _updateFloors,
            min: 1,
            max: 20,
          ),
          const SizedBox(height: 16),
          ...List.generate(_totalFloors, (index) {
            final floor = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloorRangeInput(
                floor: floor,
                startController: _startRoomControllers[floor]!,
                endController: _endRoomControllers[floor]!,
                startFocusNode: _startRoomFocusNodes[floor],
                endFocusNode: _endRoomFocusNodes[floor],
                onChanged: () => setState(() {}),
                onSubmitted: () => _validateAndRestoreDefaults(floor),
                roomCount: _getRoomCount(floor),
              ),
            );
          }),
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
            _buildEmptyRoomTypesCard()
          else
            ..._roomTypes.asMap().entries.map(
              (e) => _buildRoomTypeCard(e.key, e.value),
            ),
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

  Widget _buildEmptyRoomTypesCard() {
    return Container(
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first room type to continue',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(int index, RoomType roomType) {
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
          onPressed: () => setState(() => _roomTypes.removeAt(index)),
        ),
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
