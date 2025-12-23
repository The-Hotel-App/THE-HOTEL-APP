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
}

/// Provider for Supabase customer repository
final supabaseCustomerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository();
});
