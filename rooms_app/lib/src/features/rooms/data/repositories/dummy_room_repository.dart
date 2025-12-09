import 'dart:async';
import 'dart:math';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/domain/repositories/room_repository.dart';

/// Dummy room repository with in-memory data
class DummyRoomRepository implements RoomRepository {
  final List<Room> _rooms = [];
  final _roomsController = StreamController<List<Room>>.broadcast();

  DummyRoomRepository() {
    _initializeDummyRooms();
  }

  void _initializeDummyRooms() {
    final random = Random();
    final statuses = [
      RoomStatus.free,
      RoomStatus.occupied,
      RoomStatus.cleaning,
    ];

    // Create 30 dummy rooms across 3 floors
    for (int floor = 1; floor <= 3; floor++) {
      for (int room = 1; room <= 10; room++) {
        final roomNumber = '${floor}0$room';
        final status = statuses[random.nextInt(statuses.length)];

        _rooms.add(Room(
          id: 'room_$roomNumber',
          hotelId: 'hotel-001',
          roomNumber: roomNumber,
          roomType: room <= 3
              ? 'Deluxe'
              : room <= 7
                  ? 'Standard'
                  : 'Suite',
          floor: floor.toString(),
          status: status,
          pricePerNight: room <= 3
              ? 3000
              : room <= 7
                  ? 2000
                  : 5000,
          maxOccupancy: room <= 7 ? 2 : 4,
          lastCleaned:
              status == RoomStatus.cleaning ? null : DateTime.now().subtract(const Duration(hours: 2)),
          lastCleanedBy: status == RoomStatus.cleaning ? null : 'Staff-001',
        ));
      }
    }
  }

  @override
  Future<List<Room>> getRooms(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rooms.where((r) => r.hotelId == hotelId).toList();
  }

  @override
  Stream<List<Room>> watchRooms(String hotelId) {
    // Initially emit current rooms
    _roomsController.add(_rooms.where((r) => r.hotelId == hotelId).toList());
    return _roomsController.stream;
  }

  @override
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(
        status: status,
        lastCleaned: status == RoomStatus.free ? DateTime.now() : null,
        lastCleanedBy: status == RoomStatus.free ? 'Current-User' : null,
      );

      // Emit updated list
      _roomsController.add(List.from(_rooms));
    }
  }

  @override
  Future<Room?> getRoomById(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _rooms.firstWhere((r) => r.id == roomId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createRooms(List<Room> rooms) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rooms.addAll(rooms);
    _roomsController.add(List.from(_rooms));
  }

  @override
  Future<List<Room>> getRoomsByStatus(
      String hotelId, RoomStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rooms
        .where((r) => r.hotelId == hotelId && r.status == status)
        .toList();
  }

  @override
  Future<List<Room>> getRoomsByFloor(String hotelId, String floor) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _rooms
        .where((r) => r.hotelId == hotelId && r.floor == floor)
        .toList();
  }

  void dispose() {
    _roomsController.close();
  }
}
