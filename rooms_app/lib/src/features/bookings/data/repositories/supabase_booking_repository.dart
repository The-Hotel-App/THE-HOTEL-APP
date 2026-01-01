import 'dart:async';

import 'package:rooms/src/core/logging/app_logger.dart';
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
  Future<Booking> _fromJson(Map<String, dynamic> json) async {
    final guest = json['guests'] as Map<String, dynamic>?;
    final room = json['rooms'] as Map<String, dynamic>?;
    final totalAmount = (json['total_amount'] as num?)?.toDouble() ?? 0;
    final paidAmount = (json['amount_paid'] as num?)?.toDouble() ?? 0;
    final bookingId = json['id'] as String;

    // Fetch all rooms for this booking
    final roomsData = await _fetchBookingRooms(bookingId);

    // Fetch all guests for this booking
    final guestsData = await _fetchBookingGuests(bookingId);

    // Parse times - the database stores LOCAL times but with +00:00 suffix (incorrect)
    // We need to extract just the date/time components and treat them as local
    final checkInRaw = json['check_in'] as String;
    final checkOutRaw = json['check_out'] as String;
    
    // Parse the datetime - this will be marked as UTC due to +00:00 suffix
    final checkInParsed = DateTime.parse(checkInRaw);
    final checkOutParsed = DateTime.parse(checkOutRaw);
    
    // IMPORTANT: The DB stores local time with wrong +00:00 suffix
    // Extract the components and create a LOCAL DateTime (don't convert!)
    final checkIn = DateTime(
      checkInParsed.year,
      checkInParsed.month,
      checkInParsed.day,
      checkInParsed.hour,
      checkInParsed.minute,
      checkInParsed.second,
      checkInParsed.millisecond,
      checkInParsed.microsecond,
    );
    final checkOut = DateTime(
      checkOutParsed.year,
      checkOutParsed.month,
      checkOutParsed.day,
      checkOutParsed.hour,
      checkOutParsed.minute,
      checkOutParsed.second,
      checkOutParsed.millisecond,
      checkOutParsed.microsecond,
    );
    
    AppLogger.info('=== BOOKING TIME DEBUG ===', tag: 'BookingRepo');
    AppLogger.info('Booking ID: $bookingId', tag: 'BookingRepo');
    AppLogger.info('CheckIn (raw from DB): $checkInRaw', tag: 'BookingRepo');
    AppLogger.info('CheckIn (final local): $checkIn, isUtc: ${checkIn.isUtc}', tag: 'BookingRepo');
    AppLogger.info('Now: ${DateTime.now()}', tag: 'BookingRepo');
    AppLogger.info('==========================', tag: 'BookingRepo');

    return Booking(
      id: bookingId,
      hotelId: json['hotel_id'] as String,
      roomId: json['room_id'] as String,
      customerId: json['guest_id'] as String,
      roomNumber: room?['room_number'] as String? ?? '',
      customerName: guest?['name'] as String? ?? 'Guest',
      customerPhone: guest?['phone'] as String?,
      customerEmail: guest?['email'] as String?,
      checkIn: checkIn,
      checkOut: checkOut,
      guestCount: json['number_of_guests'] as int? ?? 1,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      status: _parseStatus(json['status'] as String? ?? 'confirmed'),
      paymentStatus: _calculatePaymentStatus(totalAmount, paidAmount),
      notes: json['booking_source'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String? ?? '',
      rooms: roomsData,
      guests: guestsData,
      checkedInBy: json['checked_in_by'] as String?,
      checkedInBiometricVerified:
          json['checked_in_biometric_verified'] as bool? ?? false,
      checkedOutBy: json['checked_out_by'] as String?,
      checkedOutBiometricVerified:
          json['checked_out_biometric_verified'] as bool? ?? false,
    );
  }

  /// Fetch all rooms associated with a booking
  Future<List<BookingRoom>> _fetchBookingRooms(String bookingId) async {
    try {
      final response = await _client
          .from('booking_rooms')
          .select(
            'room_id, room_price, rooms(room_number, status, room_type_id, room_types(name, tariff_duration_hours, tariff_amount, grace_period_hours))',
          )
          .eq('booking_id', bookingId);

      return (response as List).map((json) {
        final roomData = json['rooms'] as Map<String, dynamic>?;
        final roomTypeData = roomData?['room_types'] as Map<String, dynamic>?;
        return BookingRoom(
          roomId: json['room_id'] as String,
          roomNumber: roomData?['room_number'] as String? ?? '',
          roomPrice: (json['room_price'] as num?)?.toDouble() ?? 0,
          roomTypeName: roomTypeData?['name'] as String?,
          roomStatus: roomData?['status'] as String?,
          tariffDurationHours:
              roomTypeData?['tariff_duration_hours'] as int? ?? 24,
          tariffAmount:
              (roomTypeData?['tariff_amount'] as num?)?.toDouble() ?? 0,
          gracePeriodHours:
              (roomTypeData?['grace_period_hours'] as num?)?.toDouble() ?? 2,
        );
      }).toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching booking rooms',
        tag: 'Bookings',
        error: e,
      );
      return [];
    }
  }

  /// Fetch all guests associated with a booking
  Future<List<BookingGuest>> _fetchBookingGuests(String bookingId) async {
    try {
      final response = await _client
          .from('booking_guests')
          .select(
            'guest_id, is_primary, guests(name, phone, email, id_type, id_number, gender, age)',
          )
          .eq('booking_id', bookingId);

      return (response as List).map((json) {
        final guestData = json['guests'] as Map<String, dynamic>?;
        return BookingGuest(
          guestId: json['guest_id'] as String,
          name: guestData?['name'] as String? ?? 'Guest',
          phone: guestData?['phone'] as String?,
          email: guestData?['email'] as String?,
          idType: guestData?['id_type'] as String?,
          idNumber: guestData?['id_number'] as String?,
          gender: guestData?['gender'] as String?,
          age: guestData?['age'] as int?,
          isPrimary: json['is_primary'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching booking guests',
        tag: 'Bookings',
        error: e,
      );
      return [];
    }
  }

  @override
  Future<List<Booking>> getBookings(String hotelId) async {
    try {
      AppLogger.debug('Fetching bookings for hotel: $hotelId', tag: 'Bookings');
      final response = await _client
          .from('bookings')
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .order('check_in', ascending: false);

      final bookings = <Booking>[];
      for (final json in response as List) {
        bookings.add(await _fromJson(json));
      }
      AppLogger.success('Fetched ${bookings.length} bookings', tag: 'Bookings');
      return bookings;
    } catch (e) {
      AppLogger.error('Error fetching bookings', tag: 'Bookings', error: e);
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
                  .select('*, guests(name, phone, email), rooms(room_number)')
                  .eq('id', row['id'])
                  .single();
              bookings.add(await _fromJson(fullData));
            } catch (e) {
              AppLogger.error(
                'Error fetching booking details',
                tag: 'Bookings',
                error: e,
              );
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
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) return null;
      return await _fromJson(response);
    } catch (e) {
      AppLogger.error(
        'Error fetching booking by ID',
        tag: 'Bookings',
        error: e,
      );
      return null;
    }
  }

  @override
  Future<List<Booking>> getActiveBookings(String hotelId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .eq('status', 'checked_in')
          .order('check_in', ascending: false);

      final bookings = <Booking>[];
      for (final json in response as List) {
        bookings.add(await _fromJson(json));
      }
      return bookings;
    } catch (e) {
      AppLogger.error(
        'Error fetching active bookings',
        tag: 'Bookings',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getBookingsForRoom(String roomId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('room_id', roomId)
          .order('check_in', ascending: false);

      final bookings = <Booking>[];
      for (final json in response as List) {
        bookings.add(await _fromJson(json));
      }
      return bookings;
    } catch (e) {
      AppLogger.error(
        'Error fetching bookings for room',
        tag: 'Bookings',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<List<Booking>> getBookingsForCustomer(String customerId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('guest_id', customerId)
          .order('check_in', ascending: false);

      final bookings = <Booking>[];
      for (final json in response as List) {
        bookings.add(await _fromJson(json));
      }
      return bookings;
    } catch (e) {
      AppLogger.error(
        'Error fetching bookings for customer',
        tag: 'Bookings',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      AppLogger.info(
        'Creating booking for room: ${booking.roomNumber}',
        tag: 'Bookings',
      );
      final response = await _client
          .from('bookings')
          .insert({
            'hotel_id': booking.hotelId,
            'guest_id': booking.customerId,
            'room_id': booking.roomId,
            // Store times as local ISO strings (no UTC conversion)
            'check_in': booking.checkIn.toIso8601String(),
            'check_out': booking.checkOut.toIso8601String(),
            'number_of_guests': booking.guestCount,
            'total_amount': booking.totalAmount,
            'amount_paid': booking.paidAmount,
            'status': _statusToString(booking.status),
            'booking_source': booking.notes,
            'created_by': booking.createdBy,
            'checked_in_by': booking.checkedInBy,
            'checked_in_biometric_verified': booking.checkedInBiometricVerified,
            'checked_out_by': booking.checkedOutBy,
            'checked_out_biometric_verified':
                booking.checkedOutBiometricVerified,
          })
          .select('*, guests(name, phone, email), rooms(room_number)')
          .single();

      AppLogger.success('Booking created', tag: 'Bookings');
      return await _fromJson(response);
    } catch (e) {
      AppLogger.error('Error creating booking', tag: 'Bookings', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    try {
      await _client
          .from('bookings')
          .update({
            // Store times as local ISO strings (no UTC conversion)
            'check_in': booking.checkIn.toIso8601String(),
            'check_out': booking.checkOut.toIso8601String(),
            'number_of_guests': booking.guestCount,
            'total_amount': booking.totalAmount,
            'amount_paid': booking.paidAmount,
            'status': _statusToString(booking.status),
          })
          .eq('id', booking.id);
      AppLogger.success('Booking updated', tag: 'Bookings');
    } catch (e) {
      AppLogger.error('Error updating booking', tag: 'Bookings', error: e);
      rethrow;
    }
  }

  /// Update specific booking fields without requiring full booking object
  /// Useful for extending stays, updating checkout times, etc.
  Future<void> updateBookingFields({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalAmount,
    double? paidAmount,
    int? guestCount,
  }) async {
    try {
      final updates = <String, dynamic>{};
      // Store times as local ISO strings (no UTC conversion)
      if (checkIn != null) {
        updates['check_in'] = checkIn.toIso8601String();
      }
      if (checkOut != null) {
        updates['check_out'] = checkOut.toIso8601String();
      }
      if (totalAmount != null) updates['total_amount'] = totalAmount;
      if (paidAmount != null) updates['amount_paid'] = paidAmount;
      if (guestCount != null) updates['number_of_guests'] = guestCount;

      if (updates.isEmpty) return;

      await _client.from('bookings').update(updates).eq('id', bookingId);
      AppLogger.success('Booking fields updated', tag: 'Bookings');
    } catch (e) {
      AppLogger.error(
        'Error updating booking fields',
        tag: 'Bookings',
        error: e,
      );
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
      AppLogger.success(
        'Booking status updated to ${status.name}',
        tag: 'Bookings',
      );
    } catch (e) {
      AppLogger.error(
        'Error updating booking status',
        tag: 'Bookings',
        error: e,
      );
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
      AppLogger.success(
        'Payment updated: +$amount (total: $newPaid)',
        tag: 'Bookings',
      );
    } catch (e) {
      AppLogger.error('Error updating payment', tag: 'Bookings', error: e);
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
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .order('check_in');

      final bookings = <Booking>[];
      for (final json in response as List) {
        bookings.add(await _fromJson(json));
      }
      return bookings;
    } catch (e) {
      AppLogger.error(
        'Error fetching today check-ins',
        tag: 'Bookings',
        error: e,
      );
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
          .select('*, guests(name, phone, email), rooms(room_number)')
          .eq('hotel_id', hotelId)
          .gte('check_out', startOfDay.toIso8601String())
          .lt('check_out', endOfDay.toIso8601String())
          .order('check_out');

      final bookings = <Booking>[];
      for (final json in response as List) {
        bookings.add(await _fromJson(json));
      }
      return bookings;
    } catch (e) {
      AppLogger.error(
        'Error fetching today check-outs',
        tag: 'Bookings',
        error: e,
      );
      rethrow;
    }
  }

  /// Checkout any active (checked_in) bookings for a specific room
  Future<void> checkoutActiveBookingForRoom(String roomId) async {
    try {
      AppLogger.info(
        'Checking out active booking(s) for room: $roomId',
        tag: 'Bookings',
      );

      // Update ALL active bookings for this room to checked_out
      // Only update status, don't change check_out date to avoid constraint issues
      await _client
          .from('bookings')
          .update({'status': 'checked_out'})
          .eq('room_id', roomId)
          .eq('status', 'checked_in');

      AppLogger.success(
        'Active booking(s) checked out for room',
        tag: 'Bookings',
      );
    } catch (e) {
      AppLogger.error(
        'Error checking out active booking',
        tag: 'Bookings',
        error: e,
      );
      rethrow;
    }
  }
}
