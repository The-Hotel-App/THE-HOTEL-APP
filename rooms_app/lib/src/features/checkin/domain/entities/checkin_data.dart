/// Check-in data entity for capturing guest information
class CheckinData {
  final String? guestName;
  final String? guestPhone;
  final String? guestEmail;
  final String? idNumber;
  final String? idPhotoPath;
  final int numberOfGuests;
  final int numberOfNights;
  final double advanceAmount;
  final String paymentMode;
  final String? specialRequests;
  final DateTime checkInTime;
  final DateTime expectedCheckoutTime;

  const CheckinData({
    this.guestName,
    this.guestPhone,
    this.guestEmail,
    this.idNumber,
    this.idPhotoPath,
    this.numberOfGuests = 1,
    this.numberOfNights = 1,
    this.advanceAmount = 0,
    this.paymentMode = 'cash',
    this.specialRequests,
    required this.checkInTime,
    required this.expectedCheckoutTime,
  });

  CheckinData copyWith({
    String? guestName,
    String? guestPhone,
    String? guestEmail,
    String? idNumber,
    String? idPhotoPath,
    int? numberOfGuests,
    int? numberOfNights,
    double? advanceAmount,
    String? paymentMode,
    String? specialRequests,
    DateTime? checkInTime,
    DateTime? expectedCheckoutTime,
  }) {
    return CheckinData(
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      guestEmail: guestEmail ?? this.guestEmail,
      idNumber: idNumber ?? this.idNumber,
      idPhotoPath: idPhotoPath ?? this.idPhotoPath,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      numberOfNights: numberOfNights ?? this.numberOfNights,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      specialRequests: specialRequests ?? this.specialRequests,
      checkInTime: checkInTime ?? this.checkInTime,
      expectedCheckoutTime: expectedCheckoutTime ?? this.expectedCheckoutTime,
    );
  }

  bool get isValid =>
      guestName != null &&
      guestName!.isNotEmpty &&
      guestPhone != null &&
      guestPhone!.isNotEmpty;
}
