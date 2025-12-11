import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      debugPrint('📦 Fetching guests for hotel: $hotelId');
      final response = await _client
          .from('guests')
          .select()
          .eq('hotel_id', hotelId)
          .order('created_at', ascending: false);

      final customers = (response as List)
          .map((json) => _customerFromJson(json))
          .toList();

      debugPrint('✅ Fetched ${customers.length} guests');
      return customers;
    } catch (e) {
      debugPrint('❌ Error fetching guests: $e');
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
      debugPrint('📦 Fetching guest: $customerId');
      final response = await _client
          .from('guests')
          .select()
          .eq('id', customerId)
          .maybeSingle();

      if (response == null) return null;
      return _customerFromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching guest: $e');
      rethrow;
    }
  }

  @override
  Future<List<Customer>> searchCustomers(String hotelId, String query) async {
    try {
      debugPrint('📦 Searching guests: $query');
      final response = await _client
          .from('guests')
          .select()
          .eq('hotel_id', hotelId)
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .order('created_at', ascending: false);

      final customers = (response as List)
          .map((json) => _customerFromJson(json))
          .toList();

      debugPrint('✅ Found ${customers.length} guests');
      return customers;
    } catch (e) {
      debugPrint('❌ Error searching guests: $e');
      rethrow;
    }
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    try {
      debugPrint('📦 Creating guest: ${customer.name}');
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

      debugPrint('✅ Guest created');
      return _customerFromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating guest: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      debugPrint('📦 Updating guest: ${customer.id}');
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

      debugPrint('✅ Guest updated');
    } catch (e) {
      debugPrint('❌ Error updating guest: $e');
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
