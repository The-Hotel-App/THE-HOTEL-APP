import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/bookings/presentation/providers/new_booking_providers.dart';
import 'package:rooms/src/features/rooms/data/repositories/room_types_repository.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';

/// Page for selecting rooms for the booking
class BookingRoomsPage extends ConsumerStatefulWidget {
  const BookingRoomsPage({super.key});

  @override
  ConsumerState<BookingRoomsPage> createState() => _BookingRoomsPageState();
}

class _BookingRoomsPageState extends ConsumerState<BookingRoomsPage> {
  bool _isLoading = true;
  List<RoomType> _roomTypes = [];
  Map<String, int> _availableCounts = {};
  String? _hotelId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await SupabaseService.instance.client
          .from('hotels')
          .select('id')
          .limit(1)
          .single();

      _hotelId = response['id'] as String;

      final roomTypesRepo = ref.read(roomTypesRepositoryProvider);
      final roomTypes = await roomTypesRepo.getRoomTypes(_hotelId!);

      final bookingState = ref.read(newBookingProvider);
      final roomsRepo = ref.read(roomsRepositoryProvider);
      
      // Get available rooms
      final allRooms = await roomsRepo.getAvailableRooms(
        hotelId: _hotelId!,
        checkIn: bookingState.checkIn,
        checkOut: bookingState.checkOut,
      );

      // Count by room type
      final counts = <String, int>{};
      for (final room in allRooms) {
        final typeId = room.roomTypeId ?? 'unknown';
        counts[typeId] = (counts[typeId] ?? 0) + 1;
      }
      counts['all'] = allRooms.length;

      setState(() {
        _roomTypes = roomTypes;
        _availableCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading room data', tag: 'Bookings', error: e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(newBookingProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Select Rooms'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Selected rooms summary
                if (bookingState.selectedRooms.isNotEmpty)
                  _buildSelectedRoomsSummary(bookingState),
                // Room type list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Available Room Types',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._roomTypes.map((type) => _buildRoomTypeCard(type)),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: bookingState.selectedRooms.isNotEmpty
          ? _buildBottomBar(bookingState)
          : null,
    );
  }

  Widget _buildSelectedRoomsSummary(NewBookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.success.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${state.selectedRooms.length} ${state.selectedRooms.length == 1 ? 'room' : 'rooms'} selected',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(newBookingProvider.notifier).clearRooms();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(RoomType type) {
    final count = _availableCounts[type.id] ?? 0;
    final hasRooms = count > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasRooms ? () => _showRoomsForType(type) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasRooms ? AppColors.white : AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: hasRooms ? AppColors.black : AppColors.grey300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bed,
                  color: hasRooms ? AppColors.white : AppColors.grey500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasRooms ? AppColors.black : AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Up to ${type.maxOccupancy} guests • ₹${type.basePrice.toStringAsFixed(0)}/night',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasRooms ? AppColors.textSecondary : AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasRooms
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.grey200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasRooms ? AppColors.success : AppColors.grey500,
                  ),
                ),
              ),
              if (hasRooms) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.grey400),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoomsForType(RoomType type) async {
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
      final bookingState = ref.read(newBookingProvider);
      final roomsRepo = ref.read(roomsRepositoryProvider);
      
      final rooms = await roomsRepo.getAvailableRooms(
        hotelId: _hotelId!,
        checkIn: bookingState.checkIn,
        checkOut: bookingState.checkOut,
        roomTypeId: type.id,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        _showRoomSelectionSheet(type, rooms);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showRoomSelectionSheet(RoomType type, List<ManagedRoom> rooms) {
    final bookingState = ref.read(newBookingProvider);
    final selectedIds = bookingState.selectedRooms.map((r) => r.roomId).toSet();

    // Group by floor and sort rooms within each floor
    final Map<String, List<ManagedRoom>> roomsByFloor = {};
    for (final room in rooms) {
      roomsByFloor.putIfAbsent(room.floor.toString(), () => []).add(room);
    }
    
    // Sort rooms within each floor by room number
    for (final floor in roomsByFloor.keys) {
      roomsByFloor[floor]!.sort((a, b) {
        // Try to parse as numbers first for proper numeric sorting
        final aNum = int.tryParse(a.roomNumber.replaceAll(RegExp(r'[^0-9]'), ''));
        final bNum = int.tryParse(b.roomNumber.replaceAll(RegExp(r'[^0-9]'), ''));
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        return a.roomNumber.compareTo(b.roomNumber);
      });
    }
    
    final floors = roomsByFloor.keys.toList();
    floors.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${type.basePrice.toStringAsFixed(0)}/night',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${rooms.length} available',
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
                // Room list by floor
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: floors.length,
                    itemBuilder: (context, index) {
                      final floor = floors[index];
                      final floorRooms = roomsByFloor[floor]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Floor $floor',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.grey600,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: floorRooms.map((room) {
                              final isSelected = selectedIds.contains(room.id);
                              return InkWell(
                                onTap: () {
                                  if (isSelected) {
                                    ref.read(newBookingProvider.notifier).removeRoom(room.id);
                                    selectedIds.remove(room.id);
                                  } else {
                                    ref.read(newBookingProvider.notifier).addRoom(
                                      SelectedRoom.fromManagedRoom(room),
                                    );
                                    selectedIds.add(room.id);
                                  }
                                  setSheetState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.success
                                        : AppColors.grey100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(color: AppColors.grey300),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check : Icons.bed,
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.grey600,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        room.roomNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.white
                                              : AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
                // Done button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      // Refresh counts after selection
      _loadData();
    });
  }

  Widget _buildBottomBar(NewBookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.selectedRooms.length} ${state.selectedRooms.length == 1 ? 'room' : 'rooms'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${state.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Rooms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
