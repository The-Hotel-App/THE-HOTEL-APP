/// Floor configuration with room range
class FloorConfig {
  final int floor;
  final int startRoom;
  final int endRoom;

  const FloorConfig({
    required this.floor,
    required this.startRoom,
    required this.endRoom,
  });

  int get roomCount => endRoom - startRoom + 1;

  Map<String, dynamic> toJson() {
    return {'floor': floor, 'start_room': startRoom, 'end_room': endRoom};
  }

  factory FloorConfig.fromJson(Map<String, dynamic> json) {
    return FloorConfig(
      floor: json['floor'] as int,
      startRoom: json['start_room'] as int,
      endRoom: json['end_room'] as int,
    );
  }
}

/// Hotel entity
class Hotel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final int totalRooms;
  final int totalFloors;
  final List<FloorConfig>? floorConfigs;
  final String ownerId;
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
    this.floorConfigs,
    required this.ownerId,
    required this.createdAt,
    this.isSetupCompleted = false,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      totalRooms: json['total_rooms'] as int,
      totalFloors: json['total_floors'] as int,
      floorConfigs: json['floor_configs'] != null
          ? (json['floor_configs'] as List)
                .map((e) => FloorConfig.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      ownerId: json['owner_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isSetupCompleted: json['is_setup_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'total_rooms': totalRooms,
      'total_floors': totalFloors,
      'floor_configs': floorConfigs?.map((config) => config.toJson()).toList(),
      'owner_id': ownerId,
      'is_setup_completed': isSetupCompleted,
    };
  }

  Hotel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    int? totalRooms,
    int? totalFloors,
    List<FloorConfig>? floorConfigs,
    String? ownerId,
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
      floorConfigs: floorConfigs ?? this.floorConfigs,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
    );
  }
}

/// Room Type entity
class RoomType {
  final String id;
  final String hotelId;
  final String name;
  final double basePrice;
  final int maxOccupancy;
  final String? description;

  const RoomType({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.basePrice,
    required this.maxOccupancy,
    this.description,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      name: json['name'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      maxOccupancy: json['max_occupancy'] as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'name': name,
      'base_price': basePrice,
      'max_occupancy': maxOccupancy,
      'description': description,
    };
  }

  RoomType copyWith({
    String? id,
    String? hotelId,
    String? name,
    double? basePrice,
    int? maxOccupancy,
    String? description,
  }) {
    return RoomType(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      description: description ?? this.description,
    );
  }
}
