import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/customers/data/repositories/supabase_customer_repository.dart';
import 'package:rooms/src/features/customers/domain/entities/customer.dart';
import 'package:rooms/src/features/customers/domain/repositories/customer_repository.dart';

/// Provider for customer repository (Supabase)
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return SupabaseCustomerRepository();
});

/// Provider for all customers for current hotel - with realtime updates
final customersProvider = StreamProvider<List<Customer>>((ref) {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return Stream.value([]);
  }

  final client = SupabaseService.instance.client;
  final hotelId = hotel.hotelId;
  final repo = ref.watch(customerRepositoryProvider);

  AppLogger.info(
    'Setting up realtime subscription for guests in hotel: $hotelId',
    tag: 'Customers',
  );

  // Create a stream that emits customer updates
  return client
      .from('guests')
      .stream(primaryKey: ['id'])
      .eq('hotel_id', hotelId)
      .asyncMap((_) async {
        AppLogger.debug(
          'Realtime update received for guests',
          tag: 'Customers',
        );
        return repo.getCustomers(hotelId);
      });
});

/// Provider for customer search
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered customers - with realtime updates
final filteredCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final hotel = ref.watch(currentHotelProvider);
  if (hotel == null) {
    return Stream.value([]);
  }

  final client = SupabaseService.instance.client;
  final hotelId = hotel.hotelId;
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchQueryProvider);

  // Create a stream that emits filtered customer updates
  return client
      .from('guests')
      .stream(primaryKey: ['id'])
      .eq('hotel_id', hotelId)
      .asyncMap((_) async {
        if (query.isEmpty) {
          return repo.getCustomers(hotelId);
        }
        return repo.searchCustomers(hotelId, query);
      });
});

/// Provider for single customer
final customerByIdProvider = FutureProvider.family<Customer?, String>((
  ref,
  customerId,
) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(customerId);
});

/// Provider for customer's booking history
final customerBookingsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  customerId,
) async {
  final client =
      ref.watch(supabaseCustomerRepositoryProvider)
          as SupabaseCustomerRepository;
  return client.getBookingsForCustomer(customerId);
});

/// Provider for co-guests who have shared bookings with a customer
final customerCoGuestsProvider = FutureProvider.family<List<Customer>, String>((
  ref,
  customerId,
) async {
  final repo =
      ref.watch(supabaseCustomerRepositoryProvider)
          as SupabaseCustomerRepository;
  return repo.getCoGuests(customerId);
});
