/// Booking status enumeration
enum BookingStatus {
  confirmed,
  checkedIn,
  checkedOut,
  cancelled;

  String get displayName {
    switch (this) {
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Payment status enumeration
enum PaymentStatus {
  pending,
  partial,
  paid,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Booking entity
class Booking {
  final String id;
  final String hotelId;
  final String roomId;
  final String customerId;
  final String roomNumber;
  final String customerName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final double totalAmount;
  final double paidAmount;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  const Booking({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.customerId,
    required this.roomNumber,
    required this.customerName,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  Booking copyWith({
    String? id,
    String? hotelId,
    String? roomId,
    String? customerId,
    String? roomNumber,
    String? customerName,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestCount,
    double? totalAmount,
    double? paidAmount,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Booking(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      roomId: roomId ?? this.roomId,
      customerId: customerId ?? this.customerId,
      roomNumber: roomNumber ?? this.roomNumber,
      customerName: customerName ?? this.customerName,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guestCount: guestCount ?? this.guestCount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  double get pendingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount;
  int get stayDuration => checkOut.difference(checkIn).inDays;
}
