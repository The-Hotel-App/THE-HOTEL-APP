import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/bookings/data/repositories/dummy_booking_repository.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/domain/repositories/booking_repository.dart';

/// Provider for booking repository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return DummyBookingRepository();
});

/// Provider for all bookings
final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookings('hotel-001');
});

/// Provider for active bookings (checked in)
final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getActiveBookings('hotel-001');
});

/// Provider for today's check-ins
final todayCheckInsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getTodayCheckIns('hotel-001');
});

/// Provider for today's check-outs
final todayCheckOutsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getTodayCheckOuts('hotel-001');
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
