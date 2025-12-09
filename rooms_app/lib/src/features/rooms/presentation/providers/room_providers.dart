import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/rooms/data/repositories/dummy_room_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/domain/repositories/room_repository.dart';

/// Provider for room repository
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return DummyRoomRepository();
});

/// Provider for all rooms
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final roomRepo = ref.watch(roomRepositoryProvider);
  final user = ref.watch(currentUserProvider).valueOrNull;
  final hotelId = user?.hotelId ?? 'hotel-001';

  return roomRepo.getRooms(hotelId);
});

/// Provider for rooms by floor
final roomsByFloorProvider = FutureProvider.family<List<Room>, String>((
  ref,
  floor,
) async {
  final roomRepo = ref.read(roomRepositoryProvider);
  final user = ref.read(currentUserProvider).valueOrNull;
  final hotelId = user?.hotelId ?? 'hotel-001';

  return roomRepo.getRoomsByFloor(hotelId, floor);
});

/// Provider for rooms by status
final roomsByStatusProvider = FutureProvider.family<List<Room>, RoomStatus>((
  ref,
  status,
) async {
  final roomRepo = ref.read(roomRepositoryProvider);
  final user = ref.read(currentUserProvider).valueOrNull;
  final hotelId = user?.hotelId ?? 'hotel-001';

  return roomRepo.getRoomsByStatus(hotelId, status);
});

/// Provider for selected room filter
final selectedFloorFilterProvider = StateProvider<String?>((ref) => null);
final selectedStatusFilterProvider = StateProvider<RoomStatus?>((ref) => null);
