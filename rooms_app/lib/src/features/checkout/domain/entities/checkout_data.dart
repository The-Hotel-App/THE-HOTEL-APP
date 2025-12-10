/// Checkout data entity for billing and settlement
class CheckoutData {
  final String bookingId;
  final String roomId;
  final double roomCharges;
  final double additionalCharges;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final String paymentMode;
  final DateTime checkoutTime;
  final String? notes;

  const CheckoutData({
    required this.bookingId,
    required this.roomId,
    required this.roomCharges,
    this.additionalCharges = 0,
    required this.taxAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    this.paymentMode = 'cash',
    required this.checkoutTime,
    this.notes,
  });

  CheckoutData copyWith({
    String? bookingId,
    String? roomId,
    double? roomCharges,
    double? additionalCharges,
    double? taxAmount,
    double? totalAmount,
    double? amountPaid,
    double? balanceDue,
    String? paymentMode,
    DateTime? checkoutTime,
    String? notes,
  }) {
    return CheckoutData(
      bookingId: bookingId ?? this.bookingId,
      roomId: roomId ?? this.roomId,
      roomCharges: roomCharges ?? this.roomCharges,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      paymentMode: paymentMode ?? this.paymentMode,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      notes: notes ?? this.notes,
    );
  }

  bool get isFullyPaid => balanceDue <= 0;
}
