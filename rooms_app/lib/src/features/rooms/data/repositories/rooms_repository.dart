import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Extended room entity for management with room type info
class ManagedRoom {
  final String id;
  final String hotelId;
  final String roomNumber;
  final int floor;
  final String? roomTypeId;
  final String? roomTypeName;
  final double? pricePerNight;
  final int? maxOccupancy;
  final RoomStatus status;
  final String? currentBookingId;
  final DateTime? lastCleaned;
  final String? lastCleanedBy;

  const ManagedRoom({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.floor,
    this.roomTypeId,
    this.roomTypeName,
    this.pricePerNight,
    this.maxOccupancy,
    required this.status,
    this.currentBookingId,
    this.lastCleaned,
    this.lastCleanedBy,
  });

  factory ManagedRoom.fromJson(Map<String, dynamic> json) {
    final roomType = json['room_types'] as Map<String, dynamic>?;
    return ManagedRoom(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      roomNumber: json['room_number'] as String,
      floor: json['floor'] as int,
      roomTypeId: json['room_type_id'] as String?,
      roomTypeName: roomType?['name'] as String?,
      pricePerNight: (roomType?['base_price'] as num?)?.toDouble(),
      maxOccupancy: roomType?['max_occupancy'] as int?,
      status: _parseStatus(json['status'] as String),
      currentBookingId: json['current_booking_id'] as String?,
      lastCleaned: json['last_cleaned'] != null
          ? DateTime.parse(json['last_cleaned'] as String)
          : null,
      lastCleanedBy: json['last_cleaned_by'] as String?,
    );
  }

  static RoomStatus _parseStatus(String status) {
    switch (status) {
      case 'free':
        return RoomStatus.free;
      case 'occupied':
        return RoomStatus.occupied;
      case 'cleaning':
        return RoomStatus.cleaning;
      case 'maintenance':
        return RoomStatus.maintenance;
      case 'out_of_service':
        return RoomStatus.outOfService;
      default:
        return RoomStatus.free;
    }
  }

  static String _statusToString(RoomStatus status) {
    switch (status) {
      case RoomStatus.free:
        return 'free';
      case RoomStatus.occupied:
        return 'occupied';
      case RoomStatus.cleaning:
        return 'cleaning';
      case RoomStatus.maintenance:
        return 'maintenance';
      case RoomStatus.outOfService:
        return 'out_of_service';
    }
  }

  /// Convert to Room entity for check-in flow
  Room toRoom() {
    return Room(
      id: id,
      hotelId: hotelId,
      roomNumber: roomNumber,
      roomType: roomTypeName ?? 'Standard',
      floor: floor.toString(),
      status: status,
      pricePerNight: pricePerNight ?? 0,
      maxOccupancy: maxOccupancy ?? 2,
      currentBookingId: currentBookingId,
      lastCleaned: lastCleaned,
      lastCleanedBy: lastCleanedBy,
    );
  }
}

/// Repository for rooms CRUD operations
class RoomsRepository {
  final SupabaseClient _client;

  RoomsRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.instance.client;

  /// Get all rooms for a hotel with room type info
  Future<List<ManagedRoom>> getRooms(String hotelId) async {
    try {
      debugPrint('📦 Fetching rooms for hotel: $hotelId');
      final response = await _client
          .from('rooms')
          .select('*, room_types(name, base_price, max_occupancy)')
          .eq('hotel_id', hotelId)
          .order('floor')
          .order('room_number');

      final rooms = (response as List)
          .map((json) => ManagedRoom.fromJson(json))
          .toList();

      debugPrint('✅ Fetched ${rooms.length} rooms');
      return rooms;
    } catch (e) {
      debugPrint('❌ Error fetching rooms: $e');
      rethrow;
    }
  }

  /// Get rooms grouped by floor
  Future<Map<int, List<ManagedRoom>>> getRoomsByFloor(String hotelId) async {
    final rooms = await getRooms(hotelId);
    final map = <int, List<ManagedRoom>>{};
    for (final room in rooms) {
      map.putIfAbsent(room.floor, () => []).add(room);
    }
    return map;
  }

  /// Get available rooms filtered by criteria
  Future<List<ManagedRoom>> getAvailableRooms({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    int? minOccupancy,
    String? roomTypeId,
  }) async {
    try {
      debugPrint('📦 Fetching available rooms for hotel: $hotelId');

      var query = _client
          .from('rooms')
          .select('*, room_types(name, base_price, max_occupancy)')
          .eq('hotel_id', hotelId)
          .eq('status', 'free');

      if (roomTypeId != null) {
        query = query.eq('room_type_id', roomTypeId);
      }

      final response = await query.order('floor').order('room_number');

      var rooms = (response as List)
          .map((json) => ManagedRoom.fromJson(json))
          .toList();

      // Filter by min occupancy if specified
      if (minOccupancy != null) {
        rooms = rooms
            .where((r) => (r.maxOccupancy ?? 0) >= minOccupancy)
            .toList();
      }

      debugPrint('✅ Found ${rooms.length} available rooms');
      return rooms;
    } catch (e) {
      debugPrint('❌ Error fetching available rooms: $e');
      rethrow;
    }
  }

  /// Create a new room
  Future<ManagedRoom> createRoom({
    required String hotelId,
    required String roomNumber,
    required int floor,
    String? roomTypeId,
  }) async {
    try {
      debugPrint('📦 Creating room: $roomNumber');
      final response = await _client
          .from('rooms')
          .insert({
            'hotel_id': hotelId,
            'room_number': roomNumber,
            'floor': floor,
            'room_type_id': roomTypeId,
            'status': 'free',
          })
          .select('*, room_types(name, base_price, max_occupancy)')
          .single();

      debugPrint('✅ Room created');
      return ManagedRoom.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating room: $e');
      rethrow;
    }
  }

  /// Update a room
  Future<ManagedRoom> updateRoom({
    required String id,
    String? roomTypeId,
    RoomStatus? status,
  }) async {
    try {
      debugPrint('📦 Updating room: $id');
      final updates = <String, dynamic>{};
      if (roomTypeId != null) updates['room_type_id'] = roomTypeId;
      if (status != null) {
        updates['status'] = ManagedRoom._statusToString(status);
      }

      final response = await _client
          .from('rooms')
          .update(updates)
          .eq('id', id)
          .select('*, room_types(name, base_price, max_occupancy)')
          .single();

      debugPrint('✅ Room updated');
      return ManagedRoom.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error updating room: $e');
      rethrow;
    }
  }

  /// Bulk update rooms (assign room type to multiple rooms)
  Future<void> bulkUpdateRoomType({
    required List<String> roomIds,
    required String roomTypeId,
  }) async {
    try {
      debugPrint('📦 Bulk updating ${roomIds.length} rooms');

      for (final roomId in roomIds) {
        await _client
            .from('rooms')
            .update({'room_type_id': roomTypeId})
            .eq('id', roomId);
      }

      debugPrint('✅ Bulk update complete');
    } catch (e) {
      debugPrint('❌ Error bulk updating rooms: $e');
      rethrow;
    }
  }

  /// Delete a room
  Future<void> deleteRoom(String id) async {
    try {
      debugPrint('📦 Deleting room: $id');
      await _client.from('rooms').delete().eq('id', id);
      debugPrint('✅ Room deleted');
    } catch (e) {
      debugPrint('❌ Error deleting room: $e');
      rethrow;
    }
  }
}

/// Provider for rooms repository
final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository();
});

/// Provider for rooms list
final roomsProvider = FutureProvider.family<List<ManagedRoom>, String>((
  ref,
  hotelId,
) async {
  final repository = ref.watch(roomsRepositoryProvider);
  return repository.getRooms(hotelId);
});

/// Provider for rooms grouped by floor
final roomsByFloorProvider =
    FutureProvider.family<Map<int, List<ManagedRoom>>, String>((
      ref,
      hotelId,
    ) async {
      final repository = ref.watch(roomsRepositoryProvider);
      return repository.getRoomsByFloor(hotelId);
    });
