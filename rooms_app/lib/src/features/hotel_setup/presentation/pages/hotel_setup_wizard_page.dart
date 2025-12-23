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
import 'package:rooms/src/features/hotel_setup/presentation/widgets/owner_auth_step.dart';
import 'package:rooms/src/features/hotel_setup/presentation/widgets/wizard_step_pages.dart';

/// Hotel Setup Wizard - Multi-step wizard for setting up a new hotel
///
/// Flow:
/// 1. Owner Auth Choice (Login or Signup)
/// 2. If Login: Login credentials → Hotels list → Create new hotel
/// 3. If Signup: Account creation → Owner profile → Hotel setup
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

  // Owner auth state
  OwnerAuthChoice _authChoice = OwnerAuthChoice.none;
  bool _isAuthenticatedOwner = false;
  List<Map<String, dynamic>> _ownerHotels = [];
  bool _isLoadingHotels = false;
  String? _loginErrorMessage;
  bool _obscureLoginPassword = true;

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Step 0 (signup only): Account Creation
  final _accountEmailController = TextEditingController();
  final _accountPasswordController = TextEditingController();
  final _accountConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 1: Owner Profile
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
    // NOTE: We intentionally do NOT check existing auth state here.
    // The "Create New Hotel" flow should ALWAYS show the LOGIN/SIGNUP choice first.
    // Even if a user has an existing Supabase session (e.g., logged in as staff),
    // they still need to explicitly choose to LOGIN or SIGNUP as an owner.
    // Hotels are only fetched AFTER the user explicitly logs in via this wizard.
    debugPrint('🏨 Hotel Setup Wizard initialized - showing auth choice');
  }

  Future<void> _fetchOwnerHotels() async {
    if (_ownerId == null) return;

    setState(() {
      _isLoadingHotels = true;
    });

    try {
      final authRepo = SupabaseAuthRepository();
      final hotels = await authRepo.getOwnerHotels(_ownerId!);

      setState(() {
        _ownerHotels = hotels;
        _isLoadingHotels = false;
      });

      debugPrint('✅ Fetched ${hotels.length} hotels for owner');
    } catch (e) {
      debugPrint('❌ Error fetching owner hotels: $e');
      setState(() {
        _isLoadingHotels = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
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

  Future<void> _nextPage() async {
    // Handle auth choice step
    if (_currentPage == 0 && _authChoice == OwnerAuthChoice.none) {
      _showErrorDialog('Please select an option to continue');
      return;
    }

    // Handle login step
    if (_authChoice == OwnerAuthChoice.login &&
        _currentPage == 1 &&
        !_isAuthenticatedOwner) {
      final success = await _performLogin();
      if (!success || !mounted) {
        return; // Return if widget disposed during async
      }

      // After successful login, the step list changes completely
      // Reset to page 0 (which will now be the hotels list)
      setState(() {
        _currentPage = 0;
      });
      _pageController.jumpToPage(0);
      return; // Don't advance further - user will see hotels list
    }

    // Handle account creation step (signup flow)
    if (_authChoice == OwnerAuthChoice.signup &&
        _currentPage == 1 &&
        !_isAuthenticatedOwner) {
      final success = await _createAccount();
      if (!success || !mounted) {
        return; // Return if widget disposed during async
      }

      // After successful account creation, the step list changes completely
      // Reset to page 0 (which will now be owner profile for signup flow)
      setState(() {
        _currentPage = 0;
      });
      _pageController.jumpToPage(0);
      return; // Don't advance further - user will see owner profile
    }

    // Handle owner profile step validation
    final ownerProfilePage = _getOwnerProfilePageIndex();
    if (_currentPage == ownerProfilePage && _isAuthenticatedOwner) {
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
      if (!success || !mounted) {
        return; // Return if widget disposed during async
      }
      debugPrint('✅ Profile updated for: $_ownerId, advancing to next page');
    }

    // Advance to next page (only if still mounted)
    if (!mounted) return;
    final steps = _buildWizardSteps();
    if (_currentPage < steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getOwnerProfilePageIndex() {
    // After authentication, the step list changes:
    // - Login flow: page 0 = HotelsList, page 1 = OwnerProfile
    // - Signup flow: page 0 = OwnerProfile (since no hotels list for new users)
    if (!_isAuthenticatedOwner) {
      return -1; // Not applicable yet
    }

    if (_authChoice == OwnerAuthChoice.login) {
      return 1; // After hotels list (page 0)
    }

    // Signup flow - owner profile is the first step after account creation
    return 0;
  }

  Future<bool> _performLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _loginErrorMessage = 'Please enter a valid email address';
      });
      return false;
    }

    if (password.isEmpty) {
      setState(() {
        _loginErrorMessage = 'Please enter your password';
      });
      return false;
    }

    try {
      debugPrint('🔐 Attempting owner login for: $email');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) =>
            const Center(child: CircularProgressIndicator()),
      );

      final authRepo = SupabaseAuthRepository();
      final user = await authRepo.login(email: email, password: password);

      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('✅ Login successful: ${user.name}');

      // Only update state if widget is still mounted
      if (!mounted) {
        debugPrint('⚠️ Widget disposed during login, but login was successful');
        return true; // Login succeeded, just can't update UI
      }

      setState(() {
        _ownerId = user.id;
        _isAuthenticatedOwner = true;
        _loginErrorMessage = null;
        if (user.name.isNotEmpty && user.name != 'User') {
          _ownerNameController.text = user.name;
        }
        if (user.phone != null && user.phone!.isNotEmpty) {
          _ownerPhoneController.text = user.phone!;
        }
      });

      debugPrint('✅ Owner logged in: $_ownerId');

      // Fetch owner's hotels
      await _fetchOwnerHotels();

      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _loginErrorMessage =
              'Login failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
      return false;
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

      // Register returns the User object directly - use it instead of provider
      // (Router redirect may dispose widget before we can read from provider)
      final newUser = await authRepo.signUp(
        email: email,
        password: password,
        name: 'New Owner', // Will be updated in next step
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      // Only update state if widget is still mounted
      // (Router refresh may dispose widget during auth state change)
      if (!mounted) {
        debugPrint(
          '⚠️ Widget disposed during signup, returning success anyway',
        );
        return true; // Signup succeeded, just can't update UI
      }

      // Use the newUser returned directly from register()
      setState(() {
        _ownerId = newUser.id;
        _isAuthenticatedOwner = true;
        // Pre-fill email if needed
        _emailController.text = email;
      });
      debugPrint('✅ Account created successfully: $_ownerId');
      return true;
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

  void _onSelectHotel(Map<String, dynamic> hotel) {
    // Navigate to the selected hotel's dashboard
    final hotelId = hotel['id'] as String;
    ref.read(auth_new.selectedHotelIdProvider.notifier).state = hotelId;
    context.go(AppRoutes.ownerDashboard);
  }

  void _onCreateNewHotel() {
    // Move to owner profile step to create a new hotel
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Check if we're on the last step of the FULL wizard (Room Types)
  bool get _isOnLastStep {
    // The last step is always Room Types, which only appears after authentication
    if (!_isAuthenticatedOwner) return false;

    final steps = _buildWizardSteps();
    return _currentPage >= steps.length - 1;
  }

  List<Widget> _buildWizardSteps() {
    final steps = <Widget>[];

    if (!_isAuthenticatedOwner) {
      // Step 0: Auth Choice (for users who aren't logged in yet)
      steps.add(
        OwnerAuthChoiceStep(
          currentChoice: _authChoice,
          onChoiceChanged: (choice) {
            setState(() {
              _authChoice = choice;
            });
          },
        ),
      );

      if (_authChoice == OwnerAuthChoice.login) {
        // Step 1: Login form
        steps.add(
          OwnerLoginStep(
            emailController: _loginEmailController,
            passwordController: _loginPasswordController,
            obscurePassword: _obscureLoginPassword,
            onTogglePassword: () {
              setState(() {
                _obscureLoginPassword = !_obscureLoginPassword;
              });
            },
            errorMessage: _loginErrorMessage,
          ),
        );
      } else if (_authChoice == OwnerAuthChoice.signup) {
        // Step 1: Account Creation
        steps.add(_buildAccountCreationStep());
      }
    }

    if (_isAuthenticatedOwner) {
      if (_authChoice == OwnerAuthChoice.login || _ownerHotels.isNotEmpty) {
        // Show hotels list for login flow
        steps.add(
          OwnerHotelsListStep(
            hotels: _ownerHotels,
            isLoading: _isLoadingHotels,
            onCreateNewHotel: _onCreateNewHotel,
            onSelectHotel: _onSelectHotel,
          ),
        );
      }

      // Owner Profile step
      steps.add(
        OwnerRegistrationStep(
          nameController: _ownerNameController,
          phoneController: _ownerPhoneController,
        ),
      );

      // Hotel Profile step
      steps.add(
        HotelProfileStep(
          nameController: _nameController,
          hotelCodeController: _hotelCodeController,
          addressController: _addressController,
          phoneController: _phoneController,
          emailController: _emailController,
        ),
      );

      // Floors & Rooms step
      steps.add(
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
      );

      // Room Types step
      steps.add(
        RoomTypesStep(
          roomTypes: _roomTypes,
          onAddRoomType: _showAddRoomTypeDialog,
          onRemoveRoomType: (index) =>
              setState(() => _roomTypes.removeAt(index)),
        ),
      );
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final wizardSteps = _buildWizardSteps();
    final actualTotalPages = wizardSteps.length;
    // Always show progress out of 6 total steps (the full wizard length)
    // This prevents the bar from showing full when only 1-2 steps are visible
    const intendedTotalPages = 6;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: _currentPage == 0
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.welcome);
                  }
                },
                tooltip: 'Back',
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
              totalPages: intendedTotalPages,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: wizardSteps,
              ),
            ),
            _buildNavigationButtons(actualTotalPages),
          ],
        ),
      ),
    );
  }

  /// Build navigation buttons with proper "Complete Setup" logic
  /// Only shows "Complete Setup" when on Room Types step (after auth)
  Widget _buildNavigationButtons(int stepCount) {
    // Only show "Complete Setup" if we're authenticated AND on the last step
    final showComplete = _isOnLastStep;

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
              onPressed: showComplete ? _completeSetup : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(showComplete ? 'Complete Setup' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  /// Account creation step widget for new users (signup flow)
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
        ],
      ),
    );
  }
}
