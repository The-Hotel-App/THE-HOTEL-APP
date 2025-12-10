import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/customers/data/repositories/dummy_customer_repository.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/customers/domain/repositories/customer_repository.dart';

/// Provider for customer repository
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return DummyCustomerRepository();
});

/// Provider for all customers
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers('hotel-001');
});

/// Provider for customer search
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered customers
final filteredCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchQueryProvider);

  if (query.isEmpty) {
    return repo.getCustomers('hotel-001');
  }
  return repo.searchCustomers('hotel-001', query);
});

/// Provider for single customer
final customerByIdProvider = FutureProvider.family<Customer?, String>((
  ref,
  customerId,
) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(customerId);
});
