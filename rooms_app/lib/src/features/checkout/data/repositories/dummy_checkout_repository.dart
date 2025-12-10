import 'package:rooms/src/features/checkout/domain/entities/checkout_data.dart';
import 'package:rooms/src/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Dummy implementation of CheckoutRepository for development
class DummyCheckoutRepository implements CheckoutRepository {
  final List<CheckoutData> _checkoutHistory = [];

  @override
  Future<CheckoutData> calculateBill(Room room) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock bill calculation
    final roomCharges = room.pricePerNight * 1; // Assuming 1 night for demo
    const taxRate = 0.12;
    final taxAmount = roomCharges * taxRate;
    final totalAmount = roomCharges + taxAmount;

    return CheckoutData(
      bookingId:
          room.currentBookingId ??
          'DEMO-${DateTime.now().millisecondsSinceEpoch}',
      roomId: room.id,
      roomCharges: roomCharges,
      additionalCharges: 0,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      amountPaid: 0,
      balanceDue: totalAmount,
      checkoutTime: DateTime.now(),
    );
  }

  @override
  Future<void> processCheckout({
    required Room room,
    required CheckoutData data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _checkoutHistory.add(data);
  }

  @override
  Future<List<CheckoutData>> getCheckoutHistory(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _checkoutHistory.where((c) => c.roomId == roomId).toList();
  }
}
