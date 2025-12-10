import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

void main() {
  group('RoomStatus', () {
    test('displayName returns correct values', () {
      expect(RoomStatus.free.displayName, 'Free');
      expect(RoomStatus.occupied.displayName, 'Occupied');
      expect(RoomStatus.cleaning.displayName, 'Cleaning');
      expect(RoomStatus.maintenance.displayName, 'Maintenance');
      expect(RoomStatus.outOfService.displayName, 'Out of Service');
    });
  });

  group('Room', () {
    test('creates room with required fields', () {
      const room = Room(
        id: 'room-1',
        hotelId: 'hotel-1',
        roomNumber: '101',
        roomType: 'Standard',
        floor: '1',
        status: RoomStatus.free,
        pricePerNight: 1000,
        maxOccupancy: 2,
      );

      expect(room.id, 'room-1');
      expect(room.roomNumber, '101');
      expect(room.status, RoomStatus.free);
    });

    test('isAvailable returns true for free rooms', () {
      const freeRoom = Room(
        id: 'room-1',
        hotelId: 'hotel-1',
        roomNumber: '101',
        roomType: 'Standard',
        floor: '1',
        status: RoomStatus.free,
        pricePerNight: 1000,
        maxOccupancy: 2,
      );

      const occupiedRoom = Room(
        id: 'room-2',
        hotelId: 'hotel-1',
        roomNumber: '102',
        roomType: 'Standard',
        floor: '1',
        status: RoomStatus.occupied,
        pricePerNight: 1000,
        maxOccupancy: 2,
      );

      expect(freeRoom.isAvailable, true);
      expect(occupiedRoom.isAvailable, false);
    });

    test('isOccupied returns true for occupied rooms', () {
      const room = Room(
        id: 'room-1',
        hotelId: 'hotel-1',
        roomNumber: '101',
        roomType: 'Standard',
        floor: '1',
        status: RoomStatus.occupied,
        pricePerNight: 1000,
        maxOccupancy: 2,
      );

      expect(room.isOccupied, true);
    });

    test('needsCleaning returns true for cleaning rooms', () {
      const room = Room(
        id: 'room-1',
        hotelId: 'hotel-1',
        roomNumber: '101',
        roomType: 'Standard',
        floor: '1',
        status: RoomStatus.cleaning,
        pricePerNight: 1000,
        maxOccupancy: 2,
      );

      expect(room.needsCleaning, true);
    });

    test('copyWith creates modified copy', () {
      const room = Room(
        id: 'room-1',
        hotelId: 'hotel-1',
        roomNumber: '101',
        roomType: 'Standard',
        floor: '1',
        status: RoomStatus.free,
        pricePerNight: 1000,
        maxOccupancy: 2,
      );

      final modifiedRoom = room.copyWith(status: RoomStatus.occupied);

      expect(modifiedRoom.id, room.id);
      expect(modifiedRoom.roomNumber, room.roomNumber);
      expect(modifiedRoom.status, RoomStatus.occupied);
    });
  });
}
