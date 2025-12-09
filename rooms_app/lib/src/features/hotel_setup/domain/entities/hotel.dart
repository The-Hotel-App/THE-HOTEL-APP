/// Hotel entity
class Hotel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final int totalRooms;
  final int totalFloors;
  final DateTime createdAt;
  final bool isSetupCompleted;

  const Hotel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    required this.totalRooms,
    required this.totalFloors,
    required this.createdAt,
    this.isSetupCompleted = false,
  });

  Hotel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    int? totalRooms,
    int? totalFloors,
    DateTime? createdAt,
    bool? isSetupCompleted,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      totalRooms: totalRooms ?? this.totalRooms,
      totalFloors: totalFloors ?? this.totalFloors,
      createdAt: createdAt ?? this.createdAt,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
    );
  }
}

/// Room Type entity
class RoomType {
  final String id;
  final String name;
  final double basePrice;
  final int maxOccupancy;
  final String? description;

  const RoomType({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.maxOccupancy,
    this.description,
  });

  RoomType copyWith({
    String? id,
    String? name,
    double? basePrice,
    int? maxOccupancy,
    String? description,
  }) {
    return RoomType(
      id: id ?? this.id,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      description: description ?? this.description,
    );
  }
}
