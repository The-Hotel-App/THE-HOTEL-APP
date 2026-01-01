import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/customers/domain/repositories/customer_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-backed customer (guest) repository
class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _client;

  SupabaseCustomerRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.instance.client;

  @override
  Future<List<Customer>> getCustomers(String hotelId) async {
    try {
      AppLogger.debug('Fetching guests for hotel: $hotelId', tag: 'Customers');
      final response = await _client
          .from('guests')
          .select()
          .eq('hotel_id', hotelId)
          .order('created_at', ascending: false);

      final customers = (response as List)
          .map((json) => _customerFromJson(json))
          .toList();

      AppLogger.success('Fetched ${customers.length} guests', tag: 'Customers');
      return customers;
    } catch (e) {
      AppLogger.error('Error fetching guests', tag: 'Customers', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<Customer>> watchCustomers(String hotelId) {
    // For now, return a stream that emits once
    return Stream.fromFuture(getCustomers(hotelId));
  }

  @override
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      AppLogger.debug('Fetching guest: $customerId', tag: 'Customers');
      final response = await _client
          .from('guests')
          .select()
          .eq('id', customerId)
          .maybeSingle();

      if (response == null) return null;
      return _customerFromJson(response);
    } catch (e) {
      AppLogger.error('Error fetching guest', tag: 'Customers', error: e);
      rethrow;
    }
  }

  @override
  Future<List<Customer>> searchCustomers(String hotelId, String query) async {
    try {
      AppLogger.debug('Searching guests: $query', tag: 'Customers');
      final response = await _client
          .from('guests')
          .select()
          .eq('hotel_id', hotelId)
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .order('created_at', ascending: false);

      final customers = (response as List)
          .map((json) => _customerFromJson(json))
          .toList();

      AppLogger.success('Found ${customers.length} guests', tag: 'Customers');
      return customers;
    } catch (e) {
      AppLogger.error('Error searching guests', tag: 'Customers', error: e);
      rethrow;
    }
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    try {
      AppLogger.info('Creating guest: ${customer.name}', tag: 'Customers');
      final response = await _client
          .from('guests')
          .insert({
            'hotel_id': customer.hotelId,
            'name': customer.name,
            'phone': customer.phone,
            'email': customer.email,
            'gender': customer.gender.name,
            'id_type': customer.idType.name,
            'id_number': customer.idNumber,
            'age': customer.age,
          })
          .select()
          .single();

      AppLogger.success('Guest created', tag: 'Customers');
      return _customerFromJson(response);
    } catch (e) {
      AppLogger.error('Error creating guest', tag: 'Customers', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      AppLogger.debug('Updating guest: ${customer.id}', tag: 'Customers');
      await _client
          .from('guests')
          .update({
            'name': customer.name,
            'phone': customer.phone,
            'email': customer.email,
            'gender': customer.gender.name,
            'id_type': customer.idType.name,
            'id_number': customer.idNumber,
            'age': customer.age,
          })
          .eq('id', customer.id);

      AppLogger.success('Guest updated', tag: 'Customers');
    } catch (e) {
      AppLogger.error('Error updating guest', tag: 'Customers', error: e);
      rethrow;
    }
  }

  @override
  Future<Customer?> getCustomerByPhone(String hotelId, String phone) async {
    try {
      final response = await _client
          .from('guests')
          .select()
          .eq('hotel_id', hotelId)
          .eq('phone', phone)
          .maybeSingle();

      if (response == null) return null;
      return _customerFromJson(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Customer?> getCustomerByIdNumber(
    String hotelId,
    String idNumber,
  ) async {
    try {
      final response = await _client
          .from('guests')
          .select()
          .eq('hotel_id', hotelId)
          .eq('id_number', idNumber)
          .maybeSingle();

      if (response == null) return null;
      return _customerFromJson(response);
    } catch (e) {
      return null;
    }
  }

  Customer _customerFromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      gender: _parseGender(json['gender'] as String?),
      idType: _parseIdType(json['id_type'] as String?),
      idNumber: json['id_number'] as String? ?? '',
      age: json['age'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalVisits: 1, // Will need to count from bookings later
    );
  }

  Gender _parseGender(String? gender) {
    switch (gender) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  IdType _parseIdType(String? idType) {
    switch (idType) {
      case 'passport':
        return IdType.passport;
      case 'drivingLicense':
      case 'driversLicense':
        return IdType.drivingLicense;
      case 'aadhar':
      case 'aadhaar':
        return IdType.aadhar;
      case 'voterId':
        return IdType.voterId;
      default:
        return IdType.other;
    }
  }

  /// Get all bookings for a customer
  Future<List<Map<String, dynamic>>> getBookingsForCustomer(
    String customerId,
  ) async {
    try {
      AppLogger.debug(
        'Fetching bookings for guest: $customerId',
        tag: 'Customers',
      );

      // Get bookings where this guest is the primary guest
      final bookingsResponse = await _client
          .from('bookings')
          .select('''
            id,
            room_id,
            check_in,
            check_out,
            total_amount,
            amount_paid,
            status,
            booking_source,
            created_at,
            rooms!bookings_room_id_fkey(room_number, room_type_id, room_types(name))
          ''')
          .eq('guest_id', customerId)
          .order('check_in', ascending: false);

      // Also get bookings where this guest is in booking_guests table
      final bookingGuestsResponse = await _client
          .from('booking_guests')
          .select('''
            booking_id,
            is_primary,
            bookings(
              id,
              room_id,
              check_in,
              check_out,
              total_amount,
              amount_paid,
              status,
              booking_source,
              created_at,
              rooms!bookings_room_id_fkey(room_number, room_type_id, room_types(name))
            )
          ''')
          .eq('guest_id', customerId);

      // Combine and deduplicate bookings
      final allBookings = <String, Map<String, dynamic>>{};

      for (final booking in bookingsResponse as List) {
        allBookings[booking['id'] as String] = booking;
      }

      for (final bg in bookingGuestsResponse as List) {
        final booking = bg['bookings'];
        if (booking != null) {
          allBookings[booking['id'] as String] = booking;
        }
      }

      final result = allBookings.values.toList();
      AppLogger.success(
        'Found ${result.length} bookings for guest',
        tag: 'Customers',
      );
      return result;
    } catch (e) {
      AppLogger.error(
        'Error fetching bookings for guest',
        tag: 'Customers',
        error: e,
      );
      return [];
    }
  }

  /// Get all co-guests (guests who have shared bookings with this customer)
  Future<List<Customer>> getCoGuests(String customerId) async {
    try {
      AppLogger.debug('Fetching co-guests for: $customerId', tag: 'Customers');

      // Get all booking IDs where this guest was involved
      final bookingIdsFromPrimary = await _client
          .from('bookings')
          .select('id')
          .eq('guest_id', customerId);

      final bookingIdsFromGuests = await _client
          .from('booking_guests')
          .select('booking_id')
          .eq('guest_id', customerId);

      final allBookingIds = <String>{};
      for (final b in bookingIdsFromPrimary as List) {
        allBookingIds.add(b['id'] as String);
      }
      for (final bg in bookingIdsFromGuests as List) {
        allBookingIds.add(bg['booking_id'] as String);
      }

      if (allBookingIds.isEmpty) {
        return [];
      }

      // Get all guest IDs from these bookings (excluding current customer)
      final coGuestIds = <String>{};

      // From booking_guests table
      for (final bookingId in allBookingIds) {
        final guestsResponse = await _client
            .from('booking_guests')
            .select('guest_id')
            .eq('booking_id', bookingId)
            .neq('guest_id', customerId);

        for (final g in guestsResponse as List) {
          coGuestIds.add(g['guest_id'] as String);
        }
      }

      // From bookings table (primary guest)
      for (final bookingId in allBookingIds) {
        final bookingResponse = await _client
            .from('bookings')
            .select('guest_id')
            .eq('id', bookingId)
            .neq('guest_id', customerId)
            .maybeSingle();

        if (bookingResponse != null) {
          coGuestIds.add(bookingResponse['guest_id'] as String);
        }
      }

      if (coGuestIds.isEmpty) {
        return [];
      }

      // Fetch all co-guest details
      final coGuests = <Customer>[];
      for (final guestId in coGuestIds) {
        final guest = await getCustomerById(guestId);
        if (guest != null) {
          coGuests.add(guest);
        }
      }

      AppLogger.success('Found ${coGuests.length} co-guests', tag: 'Customers');
      return coGuests;
    } catch (e) {
      AppLogger.error('Error fetching co-guests', tag: 'Customers', error: e);
      return [];
    }
  }
}

/// Provider for Supabase customer repository
final supabaseCustomerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository();
});
