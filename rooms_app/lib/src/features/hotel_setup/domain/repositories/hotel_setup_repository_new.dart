import 'package:rooms/src/features/hotel_setup/domain/entities/hotel_new.dart';

/// Hotel setup repository interface
abstract class HotelSetupRepository {
  /// Create a new hotel with owner
  Future<Hotel> createHotel({
    required String name,
    required String address,
    String? phone,
    String? email,
    required int totalFloors,
    required List<FloorConfig> floorConfigs,
    required String ownerId,
    String? hotelCode,
  });

  /// Get hotel by ID
  Future<Hotel?> getHotel(String hotelId);

  /// Update hotel information
  Future<void> updateHotel(Hotel hotel);

  /// Mark hotel setup as completed
  Future<void> completeSetup(String hotelId);

  /// Create room types for hotel
  Future<void> createRoomTypes({
    required String hotelId,
    required List<RoomType> roomTypes,
  });

  /// Get room types for hotel
  Future<List<RoomType>> getRoomTypes(String hotelId);

  /// Create rooms for hotel based on floor configs
  Future<void> createRooms({
    required String hotelId,
    required List<FloorConfig> floorConfigs,
    required Map<String, String>
    roomTypeAssignments, // room_number -> room_type_id
  });
}
