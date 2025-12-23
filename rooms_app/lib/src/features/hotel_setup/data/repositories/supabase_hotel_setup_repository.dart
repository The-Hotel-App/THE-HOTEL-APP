import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel_new.dart';
import 'package:rooms/src/features/hotel_setup/domain/repositories/hotel_setup_repository_new.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of HotelSetupRepository
class SupabaseHotelSetupRepository implements HotelSetupRepository {
  final SupabaseService _supabaseService;

  SupabaseHotelSetupRepository({SupabaseService? supabaseService})
    : _supabaseService = supabaseService ?? SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<Hotel> createHotel({
    required String name,
    required String address,
    String? phone,
    String? email,
    required int totalFloors,
    required List<FloorConfig> floorConfigs,
    required String ownerId,
    String? hotelCode,
  }) async {
    try {
      AppLogger.info('Creating hotel: $name', tag: 'HotelSetup');

      final totalRooms = floorConfigs.fold<int>(
        0,
        (sum, config) => sum + config.roomCount,
      );

      final response = await _client
          .from('hotels')
          .insert({
            'name': name,
            'address': address,
            'phone': phone,
            'email': email,
            'hotel_code': hotelCode?.toLowerCase(),
            'total_floors': totalFloors,
            'total_rooms': totalRooms,
            'floor_configs': floorConfigs.map((c) => c.toJson()).toList(),
            'owner_id': ownerId,
            'is_setup_completed': false,
          })
          .select()
          .single();

      AppLogger.success('Hotel created: ${response['id']}', tag: 'HotelSetup');

      final hotel = Hotel.fromJson(response);

      // Create hotel_staff entry for owner
      await _client.from('hotel_staff').insert({
        'hotel_id': hotel.id,
        'user_id': ownerId,
        'role': 'owner',
        'is_active': true,
        'created_by': ownerId,
      });

      AppLogger.success('Owner assigned to hotel', tag: 'HotelSetup');

      return hotel;
    } catch (e) {
      AppLogger.error('Error creating hotel', tag: 'HotelSetup', error: e);
      rethrow;
    }
  }

  @override
  Future<Hotel?> getHotel(String hotelId) async {
    try {
      AppLogger.debug('Fetching hotel: $hotelId', tag: 'HotelSetup');

      final response = await _client
          .from('hotels')
          .select()
          .eq('id', hotelId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('Hotel not found', tag: 'HotelSetup');
        return null;
      }

      return Hotel.fromJson(response);
    } catch (e) {
      AppLogger.error('Error fetching hotel', tag: 'HotelSetup', error: e);
      return null;
    }
  }

  @override
  Future<void> updateHotel(Hotel hotel) async {
    try {
      AppLogger.debug('Updating hotel: ${hotel.id}', tag: 'HotelSetup');

      await _client.from('hotels').update(hotel.toJson()).eq('id', hotel.id);

      AppLogger.success('Hotel updated', tag: 'HotelSetup');
    } catch (e) {
      AppLogger.error('Error updating hotel', tag: 'HotelSetup', error: e);
      rethrow;
    }
  }

  @override
  Future<void> completeSetup(String hotelId) async {
    try {
      AppLogger.info('Completing setup for hotel: $hotelId', tag: 'HotelSetup');

      await _client
          .from('hotels')
          .update({'is_setup_completed': true})
          .eq('id', hotelId);

      AppLogger.success('Hotel setup completed', tag: 'HotelSetup');
    } catch (e) {
      AppLogger.error('Error completing setup', tag: 'HotelSetup', error: e);
      rethrow;
    }
  }

  @override
  Future<void> createRoomTypes({
    required String hotelId,
    required List<RoomType> roomTypes,
  }) async {
    try {
      AppLogger.info(
        'Creating ${roomTypes.length} room types',
        tag: 'HotelSetup',
      );

      final data = roomTypes
          .map(
            (rt) => {
              'hotel_id': hotelId,
              'name': rt.name,
              'base_price': rt.basePrice,
              'max_occupancy': rt.maxOccupancy,
              'description': rt.description,
            },
          )
          .toList();

      await _client.from('room_types').insert(data);

      AppLogger.success('Room types created', tag: 'HotelSetup');
    } catch (e) {
      AppLogger.error('Error creating room types', tag: 'HotelSetup', error: e);
      rethrow;
    }
  }

  @override
  Future<List<RoomType>> getRoomTypes(String hotelId) async {
    try {
      AppLogger.debug(
        'Fetching room types for hotel: $hotelId',
        tag: 'HotelSetup',
      );

      final response = await _client
          .from('room_types')
          .select()
          .eq('hotel_id', hotelId)
          .order('created_at');

      return (response as List)
          .map((json) => RoomType.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching room types', tag: 'HotelSetup', error: e);
      return [];
    }
  }

  @override
  Future<void> createRooms({
    required String hotelId,
    required List<FloorConfig> floorConfigs,
    required Map<String, String> roomTypeAssignments,
  }) async {
    try {
      AppLogger.info('Creating rooms for hotel: $hotelId', tag: 'HotelSetup');

      final rooms = <Map<String, dynamic>>[];

      for (final config in floorConfigs) {
        for (
          int roomNum = config.startRoom;
          roomNum <= config.endRoom;
          roomNum++
        ) {
          final roomNumber = roomNum.toString();
          rooms.add({
            'hotel_id': hotelId,
            'room_number': roomNumber,
            'floor': config.floor,
            'room_type_id': roomTypeAssignments[roomNumber],
            'status': 'free',
          });
        }
      }

      AppLogger.debug('Creating ${rooms.length} rooms', tag: 'HotelSetup');

      // Insert in batches of 100 to avoid payload size limits
      const batchSize = 100;
      for (int i = 0; i < rooms.length; i += batchSize) {
        final batch = rooms.skip(i).take(batchSize).toList();
        await _client.from('rooms').insert(batch);
        AppLogger.debug(
          'Inserted batch ${(i / batchSize).floor() + 1}',
          tag: 'HotelSetup',
        );
      }

      AppLogger.success('All rooms created', tag: 'HotelSetup');
    } catch (e) {
      AppLogger.error('Error creating rooms', tag: 'HotelSetup', error: e);
      rethrow;
    }
  }
}
