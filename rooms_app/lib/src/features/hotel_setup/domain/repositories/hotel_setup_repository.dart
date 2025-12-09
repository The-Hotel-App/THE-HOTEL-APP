import 'package:rooms/src/features/hotel_setup/domain/entities/hotel.dart';

/// Abstract hotel setup repository
abstract class HotelSetupRepository {
  /// Save hotel profile
  Future<void> saveHotelProfile(Hotel hotel);

  /// Get current hotel
  Future<Hotel?> getCurrentHotel();

  /// Check if setup is completed
  Future<bool> isSetupCompleted();

  /// Mark setup as completed
  Future<void> markSetupCompleted();

  /// Save room types
  Future<void> saveRoomTypes(List<RoomType> roomTypes);

  /// Get room types
  Future<List<RoomType>> getRoomTypes();
}
