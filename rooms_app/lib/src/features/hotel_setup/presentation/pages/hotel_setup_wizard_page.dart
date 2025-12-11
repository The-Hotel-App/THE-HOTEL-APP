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

  // Step 0: Owner Profile (user already logged in)
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
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
  void initState() {
    super.initState();
    _initializeOwnerData();
  }

  void _initializeOwnerData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(auth_new.currentUserProvider).valueOrNull;
      if (currentUser != null) {
        setState(() {
          _ownerId = currentUser.id;
          if (currentUser.name.isNotEmpty && currentUser.name != 'User') {
            _ownerNameController.text = currentUser.name;
          }
          if (currentUser.phone != null && currentUser.phone!.isNotEmpty) {
            _ownerPhoneController.text = currentUser.phone!;
          }
        });
        debugPrint('✅ Logged-in user ID: $_ownerId');
      } else {
        debugPrint('⚠️ No logged-in user found');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
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
      if (_ownerNameController.text.trim().isEmpty ||
          _ownerPhoneController.text.trim().isEmpty) {
        _showErrorDialog('Please fill in all required fields');
        return;
      }

      if (_ownerId == null) {
        _showErrorDialog('You must be logged in to continue');
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
                children: [
                  OwnerRegistrationStep(
                    nameController: _ownerNameController,
                    phoneController: _ownerPhoneController,
                  ),
                  HotelProfileStep(
                    nameController: _nameController,
                    addressController: _addressController,
                    phoneController: _phoneController,
                    emailController: _emailController,
                  ),
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
                  RoomTypesStep(
                    roomTypes: _roomTypes,
                    onAddRoomType: _showAddRoomTypeDialog,
                    onRemoveRoomType: (index) =>
                        setState(() => _roomTypes.removeAt(index)),
                  ),
                ],
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
}
