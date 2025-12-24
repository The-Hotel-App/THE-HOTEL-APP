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

/// Room info for a booking
class BookingRoom {
  final String roomId;
  final String roomNumber;
  final double roomPrice;
  final String? roomTypeName;
  final String? roomStatus;

  const BookingRoom({
    required this.roomId,
    required this.roomNumber,
    required this.roomPrice,
    this.roomTypeName,
    this.roomStatus,
  });
}

/// Guest info for a booking
class BookingGuest {
  final String guestId;
  final String name;
  final String? phone;
  final String? email;
  final String? idType;
  final String? idNumber;
  final String? gender;
  final int? age;
  final bool isPrimary;

  const BookingGuest({
    required this.guestId,
    required this.name,
    this.phone,
    this.email,
    this.idType,
    this.idNumber,
    this.gender,
    this.age,
    this.isPrimary = false,
  });
}

/// Booking entity
class Booking {
  final String id;
  final String hotelId;
  final String roomId;
  final String customerId;
  final String roomNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
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
  final List<BookingRoom> rooms;
  final List<BookingGuest> guests;

  /// ID of the user who performed the check-in (biometric verified)
  final String? checkedInBy;

  /// Whether the check-in was verified using biometrics
  final bool checkedInBiometricVerified;

  /// ID of the user who performed the check-out (biometric verified)
  final String? checkedOutBy;

  /// Whether the check-out was verified using biometrics
  final bool checkedOutBiometricVerified;

  const Booking({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.customerId,
    required this.roomNumber,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
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
    this.rooms = const [],
    this.guests = const [],
    this.checkedInBy,
    this.checkedInBiometricVerified = false,
    this.checkedOutBy,
    this.checkedOutBiometricVerified = false,
  });

  Booking copyWith({
    String? id,
    String? hotelId,
    String? roomId,
    String? customerId,
    String? roomNumber,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
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
    List<BookingRoom>? rooms,
    List<BookingGuest>? guests,
    String? checkedInBy,
    bool? checkedInBiometricVerified,
    String? checkedOutBy,
    bool? checkedOutBiometricVerified,
  }) {
    return Booking(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      roomId: roomId ?? this.roomId,
      customerId: customerId ?? this.customerId,
      roomNumber: roomNumber ?? this.roomNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
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
      rooms: rooms ?? this.rooms,
      guests: guests ?? this.guests,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      checkedInBiometricVerified:
          checkedInBiometricVerified ?? this.checkedInBiometricVerified,
      checkedOutBy: checkedOutBy ?? this.checkedOutBy,
      checkedOutBiometricVerified:
          checkedOutBiometricVerified ?? this.checkedOutBiometricVerified,
    );
  }

  double get pendingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount;
  int get stayDuration => checkOut.difference(checkIn).inDays;

  /// Get all room numbers as a comma-separated string
  String get allRoomNumbers {
    if (rooms.isNotEmpty) {
      return rooms.map((r) => r.roomNumber).join(', ');
    }
    return roomNumber;
  }

  /// Check if booking has multiple rooms
  bool get hasMultipleRooms => rooms.length > 1;
}
