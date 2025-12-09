import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rooms/src/features/hotel_setup/domain/entities/hotel.dart';
import 'package:rooms/src/features/hotel_setup/domain/repositories/hotel_setup_repository.dart';

/// Local storage implementation for hotel setup
class LocalHotelSetupRepository implements HotelSetupRepository {
  static const String _hotelKey = 'hotel_data';
  static const String _setupCompletedKey = 'setup_completed';
  static const String _roomTypesKey = 'room_types';

  @override
  Future<void> saveHotelProfile(Hotel hotel) async {
    final prefs = await SharedPreferences.getInstance();
    final hotelJson = {
      'id': hotel.id,
      'name': hotel.name,
      'address': hotel.address,
      'phone': hotel.phone,
      'email': hotel.email,
      'totalRooms': hotel.totalRooms,
      'totalFloors': hotel.totalFloors,
      'createdAt': hotel.createdAt.toIso8601String(),
      'isSetupCompleted': hotel.isSetupCompleted,
    };
    await prefs.setString(_hotelKey, jsonEncode(hotelJson));
  }

  @override
  Future<Hotel?> getCurrentHotel() async {
    final prefs = await SharedPreferences.getInstance();
    final hotelString = prefs.getString(_hotelKey);
    if (hotelString == null) return null;

    final hotelJson = jsonDecode(hotelString) as Map<String, dynamic>;
    return Hotel(
      id: hotelJson['id'] as String,
      name: hotelJson['name'] as String,
      address: hotelJson['address'] as String,
      phone: hotelJson['phone'] as String?,
      email: hotelJson['email'] as String?,
      totalRooms: hotelJson['totalRooms'] as int,
      totalFloors: hotelJson['totalFloors'] as int,
      createdAt: DateTime.parse(hotelJson['createdAt'] as String),
      isSetupCompleted: hotelJson['isSetupCompleted'] as bool? ?? false,
    );
  }

  @override
  Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupCompletedKey) ?? false;
  }

  @override
  Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupCompletedKey, true);
  }

  @override
  Future<void> saveRoomTypes(List<RoomType> roomTypes) async {
    final prefs = await SharedPreferences.getInstance();
    final roomTypesJson = roomTypes
        .map(
          (rt) => {
            'id': rt.id,
            'name': rt.name,
            'basePrice': rt.basePrice,
            'maxOccupancy': rt.maxOccupancy,
            'description': rt.description,
          },
        )
        .toList();
    await prefs.setString(_roomTypesKey, jsonEncode(roomTypesJson));
  }

  @override
  Future<List<RoomType>> getRoomTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final roomTypesString = prefs.getString(_roomTypesKey);
    if (roomTypesString == null) return [];

    final roomTypesJson = jsonDecode(roomTypesString) as List;
    return roomTypesJson
        .map(
          (json) => RoomType(
            id: json['id'] as String,
            name: json['name'] as String,
            basePrice: (json['basePrice'] as num).toDouble(),
            maxOccupancy: json['maxOccupancy'] as int,
            description: json['description'] as String?,
          ),
        )
        .toList();
  }
}
