import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/bookings/domain/entities/booking.dart';
import 'package:rooms/src/features/bookings/domain/repositories/booking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of BookingRepository
class SupabaseBookingRepository implements BookingRepository {
  final SupabaseClient _client;

  SupabaseBookingRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Parse booking status from database string to enum
  static BookingStatus _parseStatus(String status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'checked_in':
        return BookingStatus.checkedIn;
      case 'checked_out':
        return BookingStatus.checkedOut;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.confirmed;
    }
  }

  /// Convert enum to database string
  static String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.checkedIn:
        return 'checked_in';
      case BookingStatus.checkedOut:
        return 'checked_out';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Parse payment status based on amounts
  static PaymentStatus _calculatePaymentStatus(double total, double paid) {
    if (paid <= 0) return PaymentStatus.pending;
    if (paid >= total) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }

  /// Convert database row to Booking entity
  Booking _fromJson(Map<String, dynamic> json) {
    final guest = json['guests'] as Map<String, dynamic>?;
    final room = json['rooms'] as Map<String, dynamic>?;
    final totalAmount = (json['total_amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (json['amount_paid'] as num?)?.toDouble() ?? 0;

    return Booking(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      roomId: json['room_id'] as String,
      customerId: json['guest_id'] as String,
      roomNumber: room?['room_number'] as String? ?? '',
      customerName: guest?['name'] as String? ?? 'Guest',
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: DateTime.parse(json['check_out'] as String),
      guestCount: json['number_of_guests'] as int? ?? 1,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      status: _parseStatus(json['status'] as String? ?? 'confirmed'),
      paymentStatus: _calculatePaymentStatus(totalAmount, paidAmount),
      notes: json['booking_source'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String? ?? '',
    );
  }

  @override
  Future<List<Booking>> getBookings(String hotelId) async {
    try {
      debugPrint('📦 Fetching bookings for hotel: $hotelId');
      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .order('check_in', ascending: false);

      final bookings =
          (response as List).map((json) => _fromJson(json)).toList();
      debugPrint('✅ Fetched ${bookings.length} bookings');
      return bookings;
    } catch (e) {
      debugPrint('❌ Error fetching bookings: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Booking>> watchBookings(String hotelId) {
    return _client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .asyncMap((data) async {
          // Need to fetch related data for each booking
          final bookings = <Booking>[];
          for (final row in data) {
            try {
              final fullData = await _client
                  .from('bookings')
                  .select('*, guests(name), rooms(room_number)')
                  .eq('id', row['id'])
                  .single();
              bookings.add(_fromJson(fullData));
            } catch (e) {
              debugPrint('Error fetching booking details: $e');
            }
          }
          return bookings;
        });
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      return _fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching booking by ID: $e');
      return null;
    }
  }

  @override
  Future<List<Booking>> getActiveBookings(String hotelId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .eq('status', 'checked_in')
          .order('check_in', ascending: false);

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching active bookings: $e');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getBookingsForRoom(String roomId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('room_id', roomId)
          .order('check_in', ascending: false);

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching bookings for room: $e');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getBookingsForCustomer(String customerId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('guest_id', customerId)
          .order('check_in', ascending: false);

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching bookings for customer: $e');
      rethrow;
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      debugPrint('📦 Creating booking for room: ${booking.roomNumber}');
      final response = await _client
          .from('bookings')
          .insert({
            'hotel_id': booking.hotelId,
            'guest_id': booking.customerId,
            'room_id': booking.roomId,
            'check_in': booking.checkIn.toIso8601String(),
            'check_out': booking.checkOut.toIso8601String(),
            'number_of_guests': booking.guestCount,
            'total_amount': booking.totalAmount,
            'amount_paid': booking.paidAmount,
            'status': _statusToString(booking.status),
            'booking_source': booking.notes,
            'created_by': booking.createdBy,
          })
          .select('*, guests(name), rooms(room_number)')
          .single();

      debugPrint('✅ Booking created');
      return _fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating booking: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    try {
      await _client
          .from('bookings')
          .update({
            'check_in': booking.checkIn.toIso8601String(),
            'check_out': booking.checkOut.toIso8601String(),
            'number_of_guests': booking.guestCount,
            'total_amount': booking.totalAmount,
            'amount_paid': booking.paidAmount,
            'status': _statusToString(booking.status),
          })
          .eq('id', booking.id);
      debugPrint('✅ Booking updated');
    } catch (e) {
      debugPrint('❌ Error updating booking: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _client
          .from('bookings')
          .update({'status': _statusToString(status)})
          .eq('id', bookingId);
      debugPrint('✅ Booking status updated to ${status.name}');
    } catch (e) {
      debugPrint('❌ Error updating booking status: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePayment(String bookingId, double amount) async {
    try {
      // First get current paid amount
      final booking = await _client
          .from('bookings')
          .select('amount_paid')
          .eq('id', bookingId)
          .single();

      final currentPaid = (booking['amount_paid'] as num?)?.toDouble() ?? 0;
      final newPaid = currentPaid + amount;

      await _client
          .from('bookings')
          .update({'amount_paid': newPaid})
          .eq('id', bookingId);
      debugPrint('✅ Payment updated: +$amount (total: $newPaid)');
    } catch (e) {
      debugPrint('❌ Error updating payment: $e');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getTodayCheckIns(String hotelId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .order('check_in');

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching today check-ins: $e');
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getTodayCheckOuts(String hotelId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('bookings')
          .select('*, guests(name), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .gte('check_out', startOfDay.toIso8601String())
          .lt('check_out', endOfDay.toIso8601String())
          .order('check_out');

      return (response as List).map((json) => _fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching today check-outs: $e');
      rethrow;
    }
  }

  /// Checkout any active (checked_in) bookings for a specific room
  Future<void> checkoutActiveBookingForRoom(String roomId) async {
    try {
      debugPrint('📦 Checking out active booking(s) for room: $roomId');
      
      // Update ALL active bookings for this room to checked_out
      // Only update status, don't change check_out date to avoid constraint issues
      await _client
          .from('bookings')
          .update({'status': 'checked_out'})
          .eq('room_id', roomId)
          .eq('status', 'checked_in');
      
      debugPrint('✅ Active booking(s) checked out for room');
    } catch (e) {
      debugPrint('❌ Error checking out active booking: $e');
      rethrow;
    }
  }
}
