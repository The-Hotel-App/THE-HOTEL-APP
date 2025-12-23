import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/bookings/data/repositories/supabase_booking_repository.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/domain/repositories/booking_repository.dart';

/// Provider for booking repository (Supabase)
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return SupabaseBookingRepository();
});

/// Provider for all bookings for current hotel
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return [];
  }
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookings(hotel.hotelId);
});

/// Provider for active bookings (checked in) for current hotel
final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return [];
  }
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getActiveBookings(hotel.hotelId);
});

/// Provider for today's check-ins for current hotel
final todayCheckInsProvider = FutureProvider<List<Booking>>((ref) async {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return [];
  }
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getTodayCheckIns(hotel.hotelId);
});

/// Provider for today's check-outs for current hotel
final todayCheckOutsProvider = FutureProvider<List<Booking>>((ref) async {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return [];
  }
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getTodayCheckOuts(hotel.hotelId);
});

/// Provider for single booking
final bookingByIdProvider = FutureProvider.family<Booking?, String>((
  ref,
  bookingId,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingById(bookingId);
});

/// Provider for bookings by room
final bookingsByRoomProvider = FutureProvider.family<List<Booking>, String>((
  ref,
  roomId,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingsForRoom(roomId);
});

/// Provider for bookings by customer
final bookingsByCustomerProvider = FutureProvider.family<List<Booking>, String>(
  (ref, customerId) async {
    final repo = ref.watch(bookingRepositoryProvider);
    return repo.getBookingsForCustomer(customerId);
  },
);
