import 'package:rooms/src/features/customers/domain/entities/customer.dart';

/// Abstract customer repository
abstract class CustomerRepository {
  /// Get all customers for a hotel
  Future<List<Customer>> getCustomers(String hotelId);

  /// Watch customers stream
  Stream<List<Customer>> watchCustomers(String hotelId);

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId);

  /// Search customers by name or phone
  Future<List<Customer>> searchCustomers(String hotelId, String query);

  /// Create a new customer
  Future<Customer> createCustomer(Customer customer);

  /// Update customer
  Future<void> updateCustomer(Customer customer);

  /// Get customer by phone (for quick lookup)
  Future<Customer?> getCustomerByPhone(String hotelId, String phone);

  /// Get customer by ID number
  Future<Customer?> getCustomerByIdNumber(String hotelId, String idNumber);
}
