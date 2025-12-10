/// App settings entity
class AppSettings {
  final String hotelId;
  final String hotelName;
  final String? hotelAddress;
  final String? hotelPhone;
  final String? hotelEmail;
  final double taxRate;
  final String checkInTime;
  final String checkOutTime;
  final String currency;
  final bool notificationsEnabled;
  final bool soundEnabled;

  const AppSettings({
    required this.hotelId,
    required this.hotelName,
    this.hotelAddress,
    this.hotelPhone,
    this.hotelEmail,
    this.taxRate = 0.12,
    this.checkInTime = '12:00',
    this.checkOutTime = '11:00',
    this.currency = 'INR',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
  });

  AppSettings copyWith({
    String? hotelId,
    String? hotelName,
    String? hotelAddress,
    String? hotelPhone,
    String? hotelEmail,
    double? taxRate,
    String? checkInTime,
    String? checkOutTime,
    String? currency,
    bool? notificationsEnabled,
    bool? soundEnabled,
  }) {
    return AppSettings(
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      hotelPhone: hotelPhone ?? this.hotelPhone,
      hotelEmail: hotelEmail ?? this.hotelEmail,
      taxRate: taxRate ?? this.taxRate,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
