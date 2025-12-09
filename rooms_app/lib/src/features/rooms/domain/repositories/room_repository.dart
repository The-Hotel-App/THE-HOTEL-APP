import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Abstract room repository
abstract class RoomRepository {
  /// Get all rooms for a hotel
  Future<List<Room>> getRooms(String hotelId);

  /// Watch rooms stream (real-time updates)
  Stream<List<Room>> watchRooms(String hotelId);

  /// Update room status
  Future<void> updateRoomStatus(String roomId, RoomStatus status);

  /// Get room by ID
  Future<Room?> getRoomById(String roomId);

  /// Create rooms for hotel (during setup)
  Future<void> createRooms(List<Room> rooms);

  /// Get rooms by status
  Future<List<Room>> getRoomsByStatus(String hotelId, RoomStatus status);

  /// Get rooms by floor
  Future<List<Room>> getRoomsByFloor(String hotelId, String floor);
}
