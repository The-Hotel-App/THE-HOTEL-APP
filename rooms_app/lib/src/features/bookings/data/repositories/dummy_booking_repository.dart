import 'dart:async';

import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/domain/repositories/booking_repository.dart';

/// Dummy booking repository with mock data
class DummyBookingRepository implements BookingRepository {
  final List<Booking> _bookings = [];
  final _bookingsController = StreamController<List<Booking>>.broadcast();

  DummyBookingRepository() {
    _initializeDummyBookings();
  }

  void _initializeDummyBookings() {
    final now = DateTime.now();
    _bookings.addAll([
      Booking(
        id: 'book-001',
        hotelId: 'hotel-001',
        roomId: 'room_101',
        customerId: 'cust-001',
        roomNumber: '101',
        customerName: 'Rajesh Kumar',
        checkIn: now.subtract(const Duration(days: 2)),
        checkOut: now.add(const Duration(days: 1)),
        guestCount: 2,
        totalAmount: 6000,
        paidAmount: 6000,
        status: BookingStatus.checkedIn,
        paymentStatus: PaymentStatus.paid,
        createdAt: now.subtract(const Duration(days: 3)),
        createdBy: 'user-002',
      ),
      Booking(
        id: 'book-002',
        hotelId: 'hotel-001',
        roomId: 'room_205',
        customerId: 'cust-002',
        roomNumber: '205',
        customerName: 'Priya Sharma',
        checkIn: now.subtract(const Duration(days: 1)),
        checkOut: now.add(const Duration(days: 2)),
        guestCount: 1,
        totalAmount: 4000,
        paidAmount: 2000,
        status: BookingStatus.checkedIn,
        paymentStatus: PaymentStatus.partial,
        createdAt: now.subtract(const Duration(days: 2)),
        createdBy: 'user-002',
      ),
      Booking(
        id: 'book-003',
        hotelId: 'hotel-001',
        roomId: 'room_308',
        customerId: 'cust-003',
        roomNumber: '308',
        customerName: 'Amit Patel',
        checkIn: now,
        checkOut: now.add(const Duration(days: 3)),
        guestCount: 4,
        totalAmount: 15000,
        paidAmount: 0,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
        createdBy: 'user-001',
      ),
      Booking(
        id: 'book-004',
        hotelId: 'hotel-001',
        roomId: 'room_102',
        customerId: 'cust-004',
        roomNumber: '102',
        customerName: 'Sunita Devi',
        checkIn: now.subtract(const Duration(days: 5)),
        checkOut: now.subtract(const Duration(days: 2)),
        guestCount: 2,
        totalAmount: 6000,
        paidAmount: 6000,
        status: BookingStatus.checkedOut,
        paymentStatus: PaymentStatus.paid,
        createdAt: now.subtract(const Duration(days: 6)),
        createdBy: 'user-003',
      ),
    ]);
  }

  @override
  Future<List<Booking>> getBookings(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _bookings.where((b) => b.hotelId == hotelId).toList();
  }

  @override
  Stream<List<Booking>> watchBookings(String hotelId) {
    _bookingsController.add(
      _bookings.where((b) => b.hotelId == hotelId).toList(),
    );
    return _bookingsController.stream;
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _bookings.firstWhere((b) => b.id == bookingId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Booking>> getActiveBookings(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bookings
        .where(
          (b) => b.hotelId == hotelId && b.status == BookingStatus.checkedIn,
        )
        .toList();
  }

  @override
  Future<List<Booking>> getBookingsForRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bookings.where((b) => b.roomId == roomId).toList();
  }

  @override
  Future<List<Booking>> getBookingsForCustomer(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bookings.where((b) => b.customerId == customerId).toList();
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _bookings.add(booking);
    _bookingsController.add(List.from(_bookings));
    return booking;
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _bookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      _bookings[index] = booking;
      _bookingsController.add(List.from(_bookings));
    }
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status);
      _bookingsController.add(List.from(_bookings));
    }
  }

  @override
  Future<void> updatePayment(String bookingId, double amount) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final booking = _bookings[index];
      final newPaidAmount = booking.paidAmount + amount;
      final newPaymentStatus = newPaidAmount >= booking.totalAmount
          ? PaymentStatus.paid
          : newPaidAmount > 0
          ? PaymentStatus.partial
          : PaymentStatus.pending;

      _bookings[index] = booking.copyWith(
        paidAmount: newPaidAmount,
        paymentStatus: newPaymentStatus,
      );
      _bookingsController.add(List.from(_bookings));
    }
  }

  @override
  Future<List<Booking>> getTodayCheckIns(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return _bookings.where((b) {
      return b.hotelId == hotelId &&
          b.checkIn.year == today.year &&
          b.checkIn.month == today.month &&
          b.checkIn.day == today.day;
    }).toList();
  }

  @override
  Future<List<Booking>> getTodayCheckOuts(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return _bookings.where((b) {
      return b.hotelId == hotelId &&
          b.checkOut.year == today.year &&
          b.checkOut.month == today.month &&
          b.checkOut.day == today.day;
    }).toList();
  }

  void dispose() {
    _bookingsController.close();
  }
}
