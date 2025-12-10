import 'package:rooms/src/features/checkout/domain/entities/checkout_data.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';

/// Abstract repository for checkout operations
abstract class CheckoutRepository {
  /// Calculate checkout bill for a room
  Future<CheckoutData> calculateBill(Room room);

  /// Process checkout
  Future<void> processCheckout({
    required Room room,
    required CheckoutData data,
  });

  /// Get checkout history for a room
  Future<List<CheckoutData>> getCheckoutHistory(String roomId);
}
