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
import 'package:rooms/src/features/hotel_setup/presentation/widgets/wizard_step_pages.dart';

/// Hotel Setup Wizard - Multi-step wizard for setting up a new hotel
///
/// TODO: ABUSE PREVENTION - Future Enhancement Required
/// Currently, anyone can create an owner account and hotel. This could be abused by:
/// - Existing staff/managers creating competing owner accounts
/// - Spam/bot hotel registrations
/// - Users creating fake hotels
///
/// Recommended mitigations for production:
/// 1. Email verification required before hotel can go live
/// 2. Phone OTP verification during registration
/// 3. Rate limiting: max 1-2 hotels per device/IP per day
/// 4. Admin approval queue for new hotels (optional)
/// 5. Captcha/bot detection on registration
/// 6. Link detection: if email/phone already exists as staff, show warning
/// 7. Business verification for premium features
class HotelSetupWizardPage extends ConsumerStatefulWidget {
  const HotelSetupWizardPage({super.key});

  @override
  ConsumerState<HotelSetupWizardPage> createState() =>
      _HotelSetupWizardPageState();
}

class _HotelSetupWizardPageState extends ConsumerState<HotelSetupWizardPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Dynamic page count based on auth state
  bool _isNewUser = true; // Will be determined in initState
  int get _totalPages => _isNewUser
      ? 5
      : 4; // 5 for new users (includes account creation), 4 for logged-in users

  // Step 0 (new users only): Account Creation
  final _accountEmailController = TextEditingController();
  final _accountPasswordController = TextEditingController();
  final _accountConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 1: Owner Profile (or Step 0 for logged-in users)
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  String? _ownerId;

  // Step 2: Hotel Profile
  final _nameController = TextEditingController();
  final _hotelCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 3: Floors & Rooms
  int _totalFloors = 1;
  final Map<int, TextEditingController> _startRoomControllers = {
    1: TextEditingController(text: '101'),
  };
  final Map<int, TextEditingController> _endRoomControllers = {
    1: TextEditingController(text: '110'),
  };
  final Map<int, FocusNode> _startRoomFocusNodes = {1: FocusNode()};
  final Map<int, FocusNode> _endRoomFocusNodes = {1: FocusNode()};

  // Step 4: Room Types
  final List<RoomType> _roomTypes = [];

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(auth_new.currentUserProvider).valueOrNull;
      if (currentUser != null) {
        // User is already logged in - skip account creation step
        setState(() {
          _isNewUser = false;
          _ownerId = currentUser.id;
          if (currentUser.name.isNotEmpty && currentUser.name != 'User') {
            _ownerNameController.text = currentUser.name;
          }
          if (currentUser.phone != null && currentUser.phone!.isNotEmpty) {
            _ownerPhoneController.text = currentUser.phone!;
          }
        });
        debugPrint('✅ Logged-in user detected: $_ownerId');
      } else {
        // New user - needs to create account first
        setState(() {
          _isNewUser = true;
        });
        debugPrint('👤 New user - account creation required');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accountEmailController.dispose();
    _accountPasswordController.dispose();
    _accountConfirmPasswordController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _nameController.dispose();
    _hotelCodeController.dispose();
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

  /// Get the logical step index (what step we're on in the flow)
  int _getLogicalStep() {
    if (_isNewUser) {
      return _currentPage; // 0=Account, 1=Profile, 2=Hotel, 3=Rooms, 4=Types
    } else {
      return _currentPage +
          1; // Skip account step: 0=Profile(1), 1=Hotel(2), etc.
    }
  }

  Future<void> _nextPage() async {
    final logicalStep = _getLogicalStep();

    // Step 0 (new users only): Account Creation
    if (_isNewUser && _currentPage == 0) {
      final success = await _createAccount();
      if (!success) return;
    }

    // Step 1: Owner Profile validation
    if (logicalStep == 1) {
      if (_ownerNameController.text.trim().isEmpty ||
          _ownerPhoneController.text.trim().isEmpty) {
        _showErrorDialog('Please fill in all required fields');
        return;
      }

      if (_ownerId == null) {
        _showErrorDialog('Account not created. Please go back and try again.');
        return;
      }

      final success = await _updateOwnerProfile();
      if (!success) {
        debugPrint('❌ Profile update failed, not advancing page');
        return;
      }
      debugPrint('✅ Profile updated for: $_ownerId, advancing to next page');
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _createAccount() async {
    final email = _accountEmailController.text.trim();
    final password = _accountPasswordController.text;
    final confirmPassword = _accountConfirmPasswordController.text;

    // Validation
    if (email.isEmpty || !email.contains('@')) {
      _showErrorDialog('Please enter a valid email address');
      return false;
    }
    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return false;
    }
    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return false;
    }

    try {
      debugPrint('📝 Creating account for: $email');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) =>
            const Center(child: CircularProgressIndicator()),
      );

      final authRepo = SupabaseAuthRepository();
      await authRepo.register(
        email: email,
        password: password,
        name: 'New Owner', // Will be updated in next step
      );

      // Get the new user's ID
      final currentUser = await ref.read(auth_new.currentUserProvider.future);

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (currentUser != null) {
        setState(() {
          _ownerId = currentUser.id;
        });
        debugPrint('✅ Account created successfully: $_ownerId');
        return true;
      } else {
        _showErrorDialog('Account created but failed to get user info');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Account creation error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Account creation failed: ${e.toString()}');
      }
      return false;
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

  Future<bool> _updateOwnerProfile() async {
    try {
      debugPrint('📝 Updating owner profile...');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) =>
            const Center(child: CircularProgressIndicator()),
      );

      final authRepo = SupabaseAuthRepository();
      await authRepo.updateProfile(
        userId: _ownerId!,
        name: _ownerNameController.text.trim(),
        phone: _ownerPhoneController.text.trim(),
      );

      debugPrint('✅ Profile updated for user: $_ownerId');

      if (mounted) {
        Navigator.of(context).pop();
      }

      return true;
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Profile update failed: ${e.toString()}');
      }
      return false;
    }
  }

  Future<void> _completeSetup() async {
    if (_ownerId == null) {
      _showErrorDialog('Owner registration required');
      return;
    }

    debugPrint('🏨 Starting hotel setup...');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) =>
            const Center(child: CircularProgressIndicator()),
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

      debugPrint('📊 Creating hotel with ${floorConfigs.length} floors');

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
        hotelCode: _hotelCodeController.text.trim().isNotEmpty
            ? _hotelCodeController.text.trim().toLowerCase().replaceAll(
                ' ',
                '-',
              )
            : null,
        totalFloors: _totalFloors,
        floorConfigs: floorConfigs,
      );

      debugPrint('✅ Hotel created: ${createdHotel.id}');

      // Create room types
      List<hotel_new.RoomType> createdRoomTypes = [];
      if (_roomTypes.isNotEmpty) {
        debugPrint('🛏️ Creating ${_roomTypes.length} room types...');
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
        debugPrint('✅ Room types created');
      }

      // Create rooms with room type assignments
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

      debugPrint('🚪 Creating rooms...');
      await supabaseHotelRepo.createRooms(
        hotelId: createdHotel.id,
        floorConfigs: floorConfigs,
        roomTypeAssignments: roomTypeAssignments,
      );

      await supabaseHotelRepo.completeSetup(createdHotel.id);
      debugPrint('✅ Hotel setup complete!');

      if (mounted) {
        Navigator.of(context).pop();

        ref.invalidate(auth_new.currentUserProvider);
        ref.invalidate(auth_new.userHotelsProvider);
        ref.invalidate(auth_new.selectedHotelIdProvider);
        ref.read(auth_new.selectedHotelIdProvider.notifier).state =
            createdHotel.id;

        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (dialogContext) => AppDialog(
            title: 'Success!',
            content: Text(
              'Hotel "${_nameController.text}" has been created successfully!',
            ),
            primaryButtonText: 'Continue',
          ),
        );
        if (mounted) {
          context.go(AppRoutes.ownerDashboard);
        }
      }
    } catch (e) {
      debugPrint('❌ Hotel setup error: $e');
      if (mounted) {
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    // Build the list of wizard steps dynamically
    final List<Widget> wizardSteps = [
      // Step 0 (new users only): Account Creation
      if (_isNewUser) _buildAccountCreationStep(),
      // Step 1: Owner Profile
      OwnerRegistrationStep(
        nameController: _ownerNameController,
        phoneController: _ownerPhoneController,
      ),
      // Step 2: Hotel Profile
      HotelProfileStep(
        nameController: _nameController,
        hotelCodeController: _hotelCodeController,
        addressController: _addressController,
        phoneController: _phoneController,
        emailController: _emailController,
      ),
      // Step 3: Floors & Rooms
      FloorsRoomsStep(
        totalFloors: _totalFloors,
        totalRooms: _getTotalRooms(),
        onFloorsChanged: _updateFloors,
        startRoomControllers: _startRoomControllers,
        endRoomControllers: _endRoomControllers,
        startRoomFocusNodes: _startRoomFocusNodes,
        endRoomFocusNodes: _endRoomFocusNodes,
        onRoomRangeChanged: () => setState(() {}),
        onRoomRangeSubmitted: _validateAndRestoreDefaults,
        getRoomCount: _getRoomCount,
      ),
      // Step 4: Room Types
      RoomTypesStep(
        roomTypes: _roomTypes,
        onAddRoomType: _showAddRoomTypeDialog,
        onRemoveRoomType: (index) => setState(() => _roomTypes.removeAt(index)),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
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
            WizardProgressIndicator(
              currentPage: _currentPage,
              totalPages: _totalPages,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: wizardSteps,
              ),
            ),
            WizardNavigationButtons(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onBack: _previousPage,
              onNext: _nextPage,
              onComplete: _completeSetup,
            ),
          ],
        ),
      ),
    );
  }

  /// Account creation step widget for new users
  Widget _buildAccountCreationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔐 Create Your Account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an owner account to manage your hotel',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          // Email field
          TextField(
            controller: _accountEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'your@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Password field
          TextField(
            controller: _accountPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              hintText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Confirm password field
          TextField(
            controller: _accountConfirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'ll be the Owner of this hotel with full administrative access.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
