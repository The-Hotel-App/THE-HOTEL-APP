import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';

/// Booking Search Page - Public page to search and filter available rooms
class BookingSearchPage extends ConsumerStatefulWidget {
  const BookingSearchPage({super.key});

  @override
  ConsumerState<BookingSearchPage> createState() => _BookingSearchPageState();
}

class _BookingSearchPageState extends ConsumerState<BookingSearchPage> {
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _guestCount = 1;
  String? _selectedRoomTypeId;
  bool _isSearching = false;
  bool _isLoadingTypes = true;
  List<ManagedRoom> _filteredRooms = [];
  List<RoomType> _roomTypes = [];
  bool _hasSearched = false;
  String? _hotelId;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    try {
      // Get the first hotel from the database (for public booking)
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
    } catch (e) {
      debugPrint('Error loading room types: $e');
      setState(() => _isLoadingTypes = false);
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
          onPressed: () => context.go(AppRoutes.welcome),
        ),
        title: const Row(
          children: [
            Icon(Icons.search, size: 24),
            SizedBox(width: 8),
            Text('Find a Room'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchCard(),
            const SizedBox(height: 24),
            if (_hasSearched) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Stay Dates', Icons.calendar_today),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Check In',
                  _checkIn,
                  (d) => setState(() => _checkIn = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'Check Out',
                  _checkOut,
                  (d) => setState(() => _checkOut = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Guests', Icons.people),
          const SizedBox(height: 12),
          _buildGuestSelector(),
          const SizedBox(height: 20),
          _buildSectionTitle('Room Type (Optional)', Icons.bedroom_parent),
          const SizedBox(height: 12),
          _buildRoomTypeDropdown(),
          const SizedBox(height: 24),
          _buildSearchButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: AppColors.grey600),
          const SizedBox(width: 12),
          const Text('Number of Guests', style: TextStyle(fontSize: 16)),
          const Spacer(),
          IconButton(
            onPressed: _guestCount > 1
                ? () => setState(() => _guestCount--)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.black,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$_guestCount',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _guestCount < 10
                ? () => setState(() => _guestCount++)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeDropdown() {
    if (_isLoadingTypes) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading room types...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRoomTypeId,
          hint: const Text('Any Room Type'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Any Room Type'),
            ),
            ..._roomTypes.map(
              (type) => DropdownMenuItem<String>(
                value: type.id,
                child: Text('${type.name} (up to ${type.maxOccupancy} guests)'),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _selectedRoomTypeId = value),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSearching ? null : _searchRooms,
        icon: _isSearching
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search),
        label: Text(_isSearching ? 'Searching...' : 'Search Available Rooms'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _searchRooms() async {
    if (_hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hotel available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final repository = ref.read(roomsRepositoryProvider);
      final rooms = await repository.getAvailableRooms(
        hotelId: _hotelId!,
        checkIn: _checkIn,
        checkOut: _checkOut,
        minOccupancy: _guestCount,
        roomTypeId: _selectedRoomTypeId,
      );

      setState(() {
        _filteredRooms = rooms;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching rooms: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list, size: 20, color: AppColors.black),
            const SizedBox(width: 8),
            Text(
              'Available Rooms (${_filteredRooms.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_filteredRooms.isEmpty)
          _buildNoResultsCard()
        else
          ..._filteredRooms.map((room) => _buildRoomCard(room)),
      ],
    );
  }

  Widget _buildNoResultsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          const Text(
            'No Rooms Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(ManagedRoom room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectRoom(room),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.roomFree.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.roomFree,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    room.roomNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                      room.roomTypeName ?? 'Standard',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Floor ${room.floor} • Max ${room.maxOccupancy ?? 2} guests',
                      style: TextStyle(color: AppColors.grey600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.grey400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRoom(ManagedRoom room) {
    // Navigate to check-in flow with selected room
    context.push(AppRoutes.checkin, extra: room.toRoom());
  }
}
