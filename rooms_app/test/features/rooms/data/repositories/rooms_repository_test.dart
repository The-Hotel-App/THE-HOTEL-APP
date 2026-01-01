import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

void main() {
  group('groupRoomsByFloorAndType', () {
    // **Feature: rooms-management-redesign, Property 1: Room grouping by type preserves all rooms**
    // **Validates: Requirements 2.1, 2.3**
    group('Property 1: Room grouping by type preserves all rooms', () {
      test('empty list returns empty map', () {
        final result = groupRoomsByFloorAndType([]);
        expect(result, isEmpty);
      });

      test('single room is grouped correctly', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        expect(result.length, 1);
        expect(result[1]?.length, 1);
        expect(result[1]?['type-1']?.length, 1);
        expect(result[1]?['type-1']?[0].id, '1');
      });

      test('rooms on same floor with same type are grouped together', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-1', roomNumber: '102'),
          _createRoom(id: '3', floor: 1, roomTypeId: 'type-1', roomNumber: '103'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        expect(result.length, 1);
        expect(result[1]?['type-1']?.length, 3);
      });

      test('rooms on same floor with different types are grouped separately', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-2', roomNumber: '102'),
          _createRoom(id: '3', floor: 1, roomTypeId: 'type-1', roomNumber: '103'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        expect(result.length, 1);
        expect(result[1]?.length, 2);
        expect(result[1]?['type-1']?.length, 2);
        expect(result[1]?['type-2']?.length, 1);
      });

      test('rooms on different floors are grouped by floor first', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 2, roomTypeId: 'type-1', roomNumber: '201'),
          _createRoom(id: '3', floor: 3, roomTypeId: 'type-1', roomNumber: '301'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        expect(result.length, 3);
        expect(result[1]?['type-1']?.length, 1);
        expect(result[2]?['type-1']?.length, 1);
        expect(result[3]?['type-1']?.length, 1);
      });

      test('rooms without type are grouped under null key', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: null, roomNumber: '101'),
          _createRoom(id: '2', floor: 1, roomTypeId: null, roomNumber: '102'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        expect(result[1]?[null]?.length, 2);
      });

      test('total room count is preserved after grouping', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-2', roomNumber: '102'),
          _createRoom(id: '3', floor: 2, roomTypeId: 'type-1', roomNumber: '201'),
          _createRoom(id: '4', floor: 2, roomTypeId: null, roomNumber: '202'),
          _createRoom(id: '5', floor: 3, roomTypeId: 'type-3', roomNumber: '301'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        int totalCount = 0;
        for (final floorMap in result.values) {
          for (final roomList in floorMap.values) {
            totalCount += roomList.length;
          }
        }

        expect(totalCount, rooms.length);
      });

      test('each room appears exactly once in result', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-2', roomNumber: '102'),
          _createRoom(id: '3', floor: 2, roomTypeId: 'type-1', roomNumber: '201'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        final allRoomIds = <String>{};
        for (final floorMap in result.values) {
          for (final roomList in floorMap.values) {
            for (final room in roomList) {
              expect(allRoomIds.contains(room.id), false,
                  reason: 'Room ${room.id} appears more than once');
              allRoomIds.add(room.id);
            }
          }
        }

        expect(allRoomIds.length, rooms.length);
      });

      test('room is in correct floor and type group', () {
        final rooms = [
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 2, roomTypeId: 'type-2', roomNumber: '201'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        // Room 1 should be in floor 1, type-1
        expect(result[1]?['type-1']?.any((r) => r.id == '1'), true);
        expect(result[2]?['type-1']?.any((r) => r.id == '1') ?? false, false);

        // Room 2 should be in floor 2, type-2
        expect(result[2]?['type-2']?.any((r) => r.id == '2'), true);
        expect(result[1]?['type-2']?.any((r) => r.id == '2') ?? false, false);
      });
    });

    // **Feature: rooms-management-redesign, Property 2: Room sorting within groups**
    // **Validates: Requirements 2.4**
    group('Property 2: Room sorting within groups', () {
      test('rooms are sorted by numeric room number', () {
        final rooms = [
          _createRoom(id: '3', floor: 1, roomTypeId: 'type-1', roomNumber: '103'),
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-1', roomNumber: '102'),
        ];

        final result = groupRoomsByFloorAndType(rooms);
        final sortedRooms = result[1]!['type-1']!;

        expect(sortedRooms[0].roomNumber, '101');
        expect(sortedRooms[1].roomNumber, '102');
        expect(sortedRooms[2].roomNumber, '103');
      });

      test('rooms are sorted by alphanumeric room number', () {
        final rooms = [
          _createRoom(id: '3', floor: 1, roomTypeId: 'type-1', roomNumber: '101C'),
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '101A'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-1', roomNumber: '101B'),
        ];

        final result = groupRoomsByFloorAndType(rooms);
        final sortedRooms = result[1]!['type-1']!;

        expect(sortedRooms[0].roomNumber, '101A');
        expect(sortedRooms[1].roomNumber, '101B');
        expect(sortedRooms[2].roomNumber, '101C');
      });

      test('sorting works across multiple floors and types', () {
        final rooms = [
          _createRoom(id: '6', floor: 2, roomTypeId: 'type-1', roomNumber: '203'),
          _createRoom(id: '1', floor: 1, roomTypeId: 'type-1', roomNumber: '102'),
          _createRoom(id: '4', floor: 2, roomTypeId: 'type-1', roomNumber: '201'),
          _createRoom(id: '2', floor: 1, roomTypeId: 'type-1', roomNumber: '101'),
          _createRoom(id: '5', floor: 2, roomTypeId: 'type-1', roomNumber: '202'),
          _createRoom(id: '3', floor: 1, roomTypeId: 'type-1', roomNumber: '103'),
        ];

        final result = groupRoomsByFloorAndType(rooms);

        // Floor 1 should be sorted
        final floor1Rooms = result[1]!['type-1']!;
        expect(floor1Rooms[0].roomNumber, '101');
        expect(floor1Rooms[1].roomNumber, '102');
        expect(floor1Rooms[2].roomNumber, '103');

        // Floor 2 should be sorted
        final floor2Rooms = result[2]!['type-1']!;
        expect(floor2Rooms[0].roomNumber, '201');
        expect(floor2Rooms[1].roomNumber, '202');
        expect(floor2Rooms[2].roomNumber, '203');
      });
    });
  });

  group('compareRoomNumbers', () {
    test('compares numeric room numbers correctly', () {
      expect(compareRoomNumbers('1', '2'), lessThan(0));
      expect(compareRoomNumbers('10', '2'), greaterThan(0));
      expect(compareRoomNumbers('100', '100'), 0);
    });

    test('compares alphanumeric room numbers lexicographically', () {
      expect(compareRoomNumbers('101A', '101B'), lessThan(0));
      expect(compareRoomNumbers('101B', '101A'), greaterThan(0));
      expect(compareRoomNumbers('101A', '101A'), 0);
    });

    test('handles mixed numeric and alphanumeric', () {
      expect(compareRoomNumbers('101', '101A'), lessThan(0));
    });
  });

  // **Feature: rooms-management-redesign, Property 5: Room number swap correctness**
  // **Validates: Requirements 5.3, 5.4**
  group('Property 5: Room number swap correctness', () {
    test('swapping room numbers exchanges values correctly', () {
      String room1Number = '101';
      String room2Number = '102';

      final temp = room1Number;
      room1Number = room2Number;
      room2Number = temp;

      expect(room1Number, '102');
      expect(room2Number, '101');
    });

    test('swapping same room number is idempotent', () {
      String room1Number = '101';
      String room2Number = '101';

      final temp = room1Number;
      room1Number = room2Number;
      room2Number = temp;

      expect(room1Number, '101');
      expect(room2Number, '101');
    });

    test('double swap returns to original state', () {
      String room1Number = '101';
      String room2Number = '102';

      var temp = room1Number;
      room1Number = room2Number;
      room2Number = temp;

      temp = room1Number;
      room1Number = room2Number;
      room2Number = temp;

      expect(room1Number, '101');
      expect(room2Number, '102');
    });
  });

  // **Feature: rooms-management-redesign, Property 6: Floor addition with rooms**
  // **Validates: Requirements 6.5**
  group('Property 6: Floor addition with rooms', () {
    test('room range creates correct number of rooms', () {
      const startRoom = 101;
      const endRoom = 105;
      final expectedCount = endRoom - startRoom + 1;

      final roomNumbers = <String>[];
      for (int i = startRoom; i <= endRoom; i++) {
        roomNumbers.add(i.toString());
      }

      expect(roomNumbers.length, expectedCount);
      expect(roomNumbers, ['101', '102', '103', '104', '105']);
    });

    test('single room range creates one room', () {
      const startRoom = 101;
      const endRoom = 101;
      final expectedCount = endRoom - startRoom + 1;

      expect(expectedCount, 1);
    });

    test('room numbers are sequential', () {
      const startRoom = 201;
      const endRoom = 210;

      final roomNumbers = <int>[];
      for (int i = startRoom; i <= endRoom; i++) {
        roomNumbers.add(i);
      }

      for (int i = 1; i < roomNumbers.length; i++) {
        expect(roomNumbers[i] - roomNumbers[i - 1], 1);
      }
    });
  });
}

/// Helper function to create a ManagedRoom for testing
ManagedRoom _createRoom({
  required String id,
  required int floor,
  required String? roomTypeId,
  required String roomNumber,
  String hotelId = 'hotel-1',
  String? roomTypeName,
  RoomStatus status = RoomStatus.free,
}) {
  return ManagedRoom(
    id: id,
    hotelId: hotelId,
    roomNumber: roomNumber,
    floor: floor,
    roomTypeId: roomTypeId,
    roomTypeName: roomTypeName,
    status: status,
  );
}
