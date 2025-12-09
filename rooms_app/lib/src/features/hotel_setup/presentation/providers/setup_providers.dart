import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/hotel_setup/data/repositories/local_hotel_setup_repository.dart';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel.dart';
import 'package:rooms/src/features/hotel_setup/domain/repositories/hotel_setup_repository.dart';

/// Provider for hotel setup repository
final hotelSetupRepositoryProvider = Provider<HotelSetupRepository>((ref) {
  return LocalHotelSetupRepository();
});

/// Provider to check if setup is completed
final isSetupCompletedProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(hotelSetupRepositoryProvider);
  return repo.isSetupCompleted();
});

/// Provider for current hotel
final currentHotelProvider = FutureProvider<Hotel?>((ref) async {
  final repo = ref.read(hotelSetupRepositoryProvider);
  return repo.getCurrentHotel();
});

/// Provider for room types
final roomTypesProvider = FutureProvider<List<RoomType>>((ref) async {
  final repo = ref.read(hotelSetupRepositoryProvider);
  return repo.getRoomTypes();
});
