import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/customers/data/repositories/supabase_customer_repository.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/customers/domain/repositories/customer_repository.dart';

/// Provider for customer repository (Supabase)
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository();
});

/// Provider for all customers for current hotel
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return [];
  }
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers(hotel.hotelId);
});

/// Provider for customer search
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered customers
final filteredCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return [];
  }

  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchQueryProvider);

  if (query.isEmpty) {
    return repo.getCustomers(hotel.hotelId);
  }
  return repo.searchCustomers(hotel.hotelId, query);
});

/// Provider for single customer
final customerByIdProvider = FutureProvider.family<Customer?, String>((
  ref,
  customerId,
) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(customerId);
});
