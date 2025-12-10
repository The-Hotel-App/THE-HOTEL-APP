import 'dart:async';

import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/customers/domain/repositories/customer_repository.dart';

/// Dummy customer repository with mock data
class DummyCustomerRepository implements CustomerRepository {
  final List<Customer> _customers = [];
  final _customersController = StreamController<List<Customer>>.broadcast();

  DummyCustomerRepository() {
    _initializeDummyCustomers();
  }

  void _initializeDummyCustomers() {
    _customers.addAll([
      Customer(
        id: 'cust-001',
        hotelId: 'hotel-001',
        name: 'Rajesh Kumar',
        phone: '+91 98765 43210',
        gender: Gender.male,
        idType: IdType.aadhar,
        idNumber: '1234 5678 9012',
        address: 'Mumbai, Maharashtra',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastVisit: DateTime.now().subtract(const Duration(days: 2)),
        totalVisits: 5,
      ),
      Customer(
        id: 'cust-002',
        hotelId: 'hotel-001',
        name: 'Priya Sharma',
        phone: '+91 87654 32109',
        gender: Gender.female,
        idType: IdType.passport,
        idNumber: 'J1234567',
        address: 'Delhi, India',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastVisit: DateTime.now(),
        totalVisits: 2,
      ),
      Customer(
        id: 'cust-003',
        hotelId: 'hotel-001',
        name: 'Amit Patel',
        phone: '+91 76543 21098',
        gender: Gender.male,
        idType: IdType.drivingLicense,
        idNumber: 'DL-1234567890',
        address: 'Ahmedabad, Gujarat',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastVisit: DateTime.now().subtract(const Duration(days: 1)),
        totalVisits: 3,
      ),
      Customer(
        id: 'cust-004',
        hotelId: 'hotel-001',
        name: 'Sunita Devi',
        phone: '+91 65432 10987',
        gender: Gender.female,
        idType: IdType.voterId,
        idNumber: 'ABC1234567',
        address: 'Jaipur, Rajasthan',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        totalVisits: 1,
      ),
      Customer(
        id: 'cust-005',
        hotelId: 'hotel-001',
        name: 'Mohammed Ali',
        phone: '+91 54321 09876',
        gender: Gender.male,
        idType: IdType.aadhar,
        idNumber: '9876 5432 1098',
        address: 'Hyderabad, Telangana',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        lastVisit: DateTime.now(),
        totalVisits: 1,
      ),
    ]);
  }

  @override
  Future<List<Customer>> getCustomers(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _customers.where((c) => c.hotelId == hotelId).toList();
  }

  @override
  Stream<List<Customer>> watchCustomers(String hotelId) {
    _customersController.add(
      _customers.where((c) => c.hotelId == hotelId).toList(),
    );
    return _customersController.stream;
  }

  @override
  Future<Customer?> getCustomerById(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _customers.firstWhere((c) => c.id == customerId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Customer>> searchCustomers(String hotelId, String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowerQuery = query.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.hotelId == hotelId &&
              (c.name.toLowerCase().contains(lowerQuery) ||
                  c.phone.contains(query)),
        )
        .toList();
  }

  @override
  Future<Customer> createCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _customers.add(customer);
    _customersController.add(List.from(_customers));
    return customer;
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      _customersController.add(List.from(_customers));
    }
  }

  @override
  Future<Customer?> getCustomerByPhone(String hotelId, String phone) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _customers.firstWhere(
        (c) => c.hotelId == hotelId && c.phone == phone,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Customer?> getCustomerByIdNumber(
    String hotelId,
    String idNumber,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _customers.firstWhere(
        (c) => c.hotelId == hotelId && c.idNumber == idNumber,
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _customersController.close();
  }
}
