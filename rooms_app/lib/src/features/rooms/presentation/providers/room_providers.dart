import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/data/repositories/rooms_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Provider for rooms repository (Supabase)
final roomRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository(client: SupabaseService.instance.client);
});

/// Provider for all rooms for current hotel - with realtime updates
final roomsProvider = StreamProvider<List<Room>>((ref) {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return Stream.value([]);
  }

  final client = SupabaseService.instance.client;
  final hotelId = hotel.hotelId;

  AppLogger.info(
    'Setting up realtime subscription for rooms in hotel: $hotelId',
    tag: 'Rooms',
  );

  // Create a stream that emits room updates
  return client
      .from('rooms')
      .stream(primaryKey: ['id'])
      .eq('hotel_id', hotelId)
      .map((data) {
        AppLogger.debug(
          'Realtime update received: ${data.length} rooms',
          tag: 'Rooms',
        );
        return data.map((json) => ManagedRoom.fromJson(json).toRoom()).toList();
      });
});

/// Provider for rooms by specific floor for current hotel
final roomsByFloorProvider = FutureProvider.family<List<Room>, String>((
  ref,
  floor,
) async {
  final hotel = ref.read(currentHotelProvider);
  if (hotel == null) {
    return [];
  }

  final roomsRepo = ref.read(roomRepositoryProvider);
  final managedRooms = await roomsRepo.getRooms(hotel.hotelId);

  // Filter by floor and convert to Room
  return managedRooms
      .where((mr) => mr.floor.toString() == floor)
      .map((mr) => mr.toRoom())
      .toList();
});

/// Provider for rooms by status for current hotel
final roomsByStatusProvider = FutureProvider.family<List<Room>, RoomStatus>((
  ref,
  status,
) async {
  final hotel = ref.read(currentHotelProvider);
  if (hotel == null) {
    return [];
  }

  final roomsRepo = ref.read(roomRepositoryProvider);
  final managedRooms = await roomsRepo.getRooms(hotel.hotelId);

  // Filter by status and convert to Room
  return managedRooms
      .where((mr) => mr.status == status)
      .map((mr) => mr.toRoom())
      .toList();
});

/// Provider for selected floor (for floor-wise view)
final selectedFloorProvider = StateProvider<String?>((ref) => null);

/// Provider for selected status filters (when viewing rooms in a floor)
final selectedStatusFilterProvider = StateProvider<Set<RoomStatus>>(
  (ref) => {},
);
