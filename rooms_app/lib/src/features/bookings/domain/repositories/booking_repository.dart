import 'package:rooms/src/features/bookings/domain/entities/booking.dart';

/// Abstract booking repository
abstract class BookingRepository {
  /// Get all bookings for a hotel
  Future<List<Booking>> getBookings(String hotelId);

  /// Watch bookings stream
  Stream<List<Booking>> watchBookings(String hotelId);

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId);

  /// Get active bookings (checked in)
  Future<List<Booking>> getActiveBookings(String hotelId);

  /// Get bookings for a room
  Future<List<Booking>> getBookingsForRoom(String roomId);

  /// Get bookings for a customer
  Future<List<Booking>> getBookingsForCustomer(String customerId);

  /// Create a new booking
  Future<Booking> createBooking(Booking booking);

  /// Update booking
  Future<void> updateBooking(Booking booking);

  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);

  /// Update payment
  Future<void> updatePayment(String bookingId, double amount);

  /// Get today's check-ins
  Future<List<Booking>> getTodayCheckIns(String hotelId);

  /// Get today's check-outs
  Future<List<Booking>> getTodayCheckOuts(String hotelId);
}
