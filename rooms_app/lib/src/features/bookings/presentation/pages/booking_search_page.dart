import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/bookings/presentation/pages/booking_floor_rooms_page.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';

/// Booking Search Page - Simple page to search and filter available rooms
class BookingSearchPage extends ConsumerStatefulWidget {
  const BookingSearchPage({super.key});

  @override
  ConsumerState<BookingSearchPage> createState() => _BookingSearchPageState();
}

class _BookingSearchPageState extends ConsumerState<BookingSearchPage> {
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _guestCount = 1;
  bool _isLoadingTypes = true;
  List<RoomType> _roomTypes = [];
  String? _hotelId;

  // Track available room counts per room type
  Map<String, int> _availableRoomCounts = {};
  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    try {
      final response = await SupabaseService.instance.client
          .from('hotels')
          .select('id')
          .limit(1)
          .single();

      _hotelId = response['id'] as String;

      final repository = ref.read(roomTypesRepositoryProvider);
      final roomTypes = await repository.getRoomTypes(_hotelId!);

      setState(() {
        _roomTypes = roomTypes;
        _isLoadingTypes = false;
      });

      // Load available room counts
      _loadAvailableCounts();
    } catch (e) {
      AppLogger.error('Error loading room types', tag: 'Bookings', error: e);
      setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _loadAvailableCounts() async {
    if (_hotelId == null) return;

    setState(() => _isLoadingCounts = true);

    try {
      final repository = ref.read(roomsRepositoryProvider);
      final counts = <String, int>{};

      // Get all available rooms
      final allRooms = await repository.getAvailableRooms(
        hotelId: _hotelId!,
        checkIn: _checkIn,
        checkOut: _checkOut,
      );

      // Count by room type
      for (final room in allRooms) {
        final typeId = room.roomTypeId ?? 'unknown';
        counts[typeId] = (counts[typeId] ?? 0) + 1;
      }

      // Also store total count
      counts['all'] = allRooms.length;

      setState(() {
        _availableRoomCounts = counts;
        _isLoadingCounts = false;
      });
    } catch (e) {
      AppLogger.error('Error loading room counts', tag: 'Bookings', error: e);
      setState(() => _isLoadingCounts = false);
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
        title: const Text('New Booking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dates Section
            _buildDatesSection(),
            const SizedBox(height: 20),
            // Guests Section
            _buildGuestsSection(),
            const SizedBox(height: 24),
            // Room Types Section
            _buildRoomTypesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stay Dates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDateCard('Check In', _checkIn, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateCard('Check Out', _checkOut, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime date, bool isCheckIn) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: isCheckIn ? DateTime.now() : _checkIn,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            if (isCheckIn) {
              _checkIn = picked;
              if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
                _checkOut = _checkIn.add(const Duration(days: 1));
              }
            } else {
              _checkOut = picked;
            }
          });
          _loadAvailableCounts();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Number of Guests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$_guestCount',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Minus Button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _guestCount > 1
                        ? () => setState(() => _guestCount--)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey200,
                      foregroundColor: AppColors.black,
                      disabledBackgroundColor: AppColors.grey100,
                      disabledForegroundColor: AppColors.grey400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.remove, size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Plus Button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _guestCount++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Select Room Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_isLoadingTypes)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else ...[
          // All Rooms Button
          _buildRoomTypeButton(
            name: 'All Rooms',
            description: 'View all available rooms',
            count: _availableRoomCounts['all'] ?? 0,
            icon: Icons.grid_view,
            onTap: () => _searchAndNavigate(null),
          ),
          const SizedBox(height: 12),
          // Individual Room Type Buttons
          ..._roomTypes.map((type) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRoomTypeButton(
              name: type.name,
              description: 'Up to ${type.maxOccupancy} guests • ₹${type.basePrice.toStringAsFixed(0)}/night',
              count: _availableRoomCounts[type.id] ?? 0,
              icon: Icons.bed,
              onTap: () => _searchAndNavigate(type.id),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildRoomTypeButton({
    required String name,
    required String description,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasRooms = count > 0;

    return InkWell(
      onTap: hasRooms ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasRooms ? AppColors.white : AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
          border: hasRooms ? null : Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: hasRooms ? AppColors.black : AppColors.grey300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: hasRooms ? AppColors.white : AppColors.grey500,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasRooms ? AppColors.black : AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasRooms ? AppColors.textSecondary : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            // Count Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasRooms ? AppColors.success.withValues(alpha: 0.15) : AppColors.grey200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isLoadingCounts ? '...' : '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasRooms ? AppColors.success : AppColors.grey500,
                ),
              ),
            ),
            if (hasRooms) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndNavigate(String? roomTypeId) async {
    if (_hotelId == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );

    try {
      final repository = ref.read(roomsRepositoryProvider);
      final rooms = await repository.getAvailableRooms(
        hotelId: _hotelId!,
        checkIn: _checkIn,
        checkOut: _checkOut,
        roomTypeId: roomTypeId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (rooms.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No rooms available for selected dates'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        // Group by floor and navigate
        final Map<String, List<ManagedRoom>> roomsByFloor = {};
        for (final room in rooms) {
          roomsByFloor.putIfAbsent(room.floor.toString(), () => []).add(room);
        }

        final floors = roomsByFloor.keys.toList();
        floors.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

        // Navigate to floor selection or directly to rooms
        _showFloorSelection(floors, roomsByFloor, rooms.length);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showFloorSelection(
    List<String> floors,
    Map<String, List<ManagedRoom>> roomsByFloor,
    int totalRooms,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Select Floor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalRooms rooms',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Floor List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: floors.length,
                itemBuilder: (context, index) {
                  final floor = floors[index];
                  final rooms = roomsByFloor[floor]!;
                  return _buildFloorTile(floor, rooms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorTile(String floor, List<ManagedRoom> rooms) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookingFloorRoomsPage(
                floor: floor,
                rooms: rooms,
                checkIn: _checkIn,
                checkOut: _checkOut,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    floor,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floor $floor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${rooms.length} ${rooms.length == 1 ? 'room' : 'rooms'} available',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
