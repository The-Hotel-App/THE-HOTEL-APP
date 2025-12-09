/// Room status enumeration
enum RoomStatus {
  free,
  occupied,
  cleaning,
  maintenance,
  outOfService;

  String get displayName {
    switch (this) {
      case RoomStatus.free:
        return 'Free';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.cleaning:
        return 'Cleaning';
      case RoomStatus.maintenance:
        return 'Maintenance';
      case RoomStatus.outOfService:
        return 'Out of Service';
    }
  }
}

/// Room entity
class Room {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String roomType;
  final String floor;
  final RoomStatus status;
  final String? currentBookingId;
  final double pricePerNight;
  final int maxOccupancy;
  final DateTime? lastCleaned;
  final String? lastCleanedBy;

  const Room({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.status,
    this.currentBookingId,
    required this.pricePerNight,
    required this.maxOccupancy,
    this.lastCleaned,
    this.lastCleanedBy,
  });

  Room copyWith({
    String? id,
    String? hotelId,
    String? roomNumber,
    String? roomType,
    String? floor,
    RoomStatus? status,
    String? currentBookingId,
    double? pricePerNight,
    int? maxOccupancy,
    DateTime? lastCleaned,
    String? lastCleanedBy,
  }) {
    return Room(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      lastCleaned: lastCleaned ?? this.lastCleaned,
      lastCleanedBy: lastCleanedBy ?? this.lastCleanedBy,
    );
  }

  bool get isAvailable => status == RoomStatus.free;
  bool get needsCleaning => status == RoomStatus.cleaning;
  bool get isOccupied => status == RoomStatus.occupied;
}
