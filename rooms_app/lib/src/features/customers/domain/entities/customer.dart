/// Customer entity for hotel guests
class Customer {
  final String id;
  final String hotelId;
  final String name;
  final String phone;
  final String? email;
  final Gender gender;
  final IdType idType;
  final String idNumber;
  final String? address;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final int totalVisits;

  const Customer({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.phone,
    this.email,
    required this.gender,
    required this.idType,
    required this.idNumber,
    this.address,
    required this.createdAt,
    this.lastVisit,
    this.totalVisits = 1,
  });

  Customer copyWith({
    String? id,
    String? hotelId,
    String? name,
    String? phone,
    String? email,
    Gender? gender,
    IdType? idType,
    String? idNumber,
    String? address,
    DateTime? createdAt,
    DateTime? lastVisit,
    int? totalVisits,
  }) {
    return Customer(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      totalVisits: totalVisits ?? this.totalVisits,
    );
  }
}

enum Gender {
  male,
  female,
  other;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

enum IdType {
  aadhar,
  passport,
  drivingLicense,
  voterId,
  other;

  String get displayName {
    switch (this) {
      case IdType.aadhar:
        return 'Aadhar Card';
      case IdType.passport:
        return 'Passport';
      case IdType.drivingLicense:
        return 'Driving License';
      case IdType.voterId:
        return 'Voter ID';
      case IdType.other:
        return 'Other';
    }
  }
}
