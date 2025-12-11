import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Room type entity
class RoomType {
  final String id;
  final String hotelId;
  final String name;
  final double basePrice;
  final int maxOccupancy;
  final String? description;
  final DateTime createdAt;

  const RoomType({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.basePrice,
    required this.maxOccupancy,
    this.description,
    required this.createdAt,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      name: json['name'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      maxOccupancy: json['max_occupancy'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    DateTime? createdAt,
  }) {
    return RoomType(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Repository for room types CRUD operations
class RoomTypesRepository {
  final SupabaseClient _client;

  RoomTypesRepository({SupabaseClient? client})
    : _client = client ?? SupabaseService.instance.client;

  /// Get all room types for a hotel
  Future<List<RoomType>> getRoomTypes(String hotelId) async {
    try {
      debugPrint('📦 Fetching room types for hotel: $hotelId');
      final response = await _client
          .from('room_types')
          .select()
          .eq('hotel_id', hotelId)
          .order('name');

      final roomTypes = (response as List)
          .map((json) => RoomType.fromJson(json))
          .toList();

      debugPrint('✅ Fetched ${roomTypes.length} room types');
      return roomTypes;
    } catch (e) {
      debugPrint('❌ Error fetching room types: $e');
      rethrow;
    }
  }

  /// Create a new room type
  Future<RoomType> createRoomType({
    required String hotelId,
    required String name,
    required double basePrice,
    required int maxOccupancy,
    String? description,
  }) async {
    try {
      debugPrint('📦 Creating room type: $name');
      final response = await _client
          .from('room_types')
          .insert({
            'hotel_id': hotelId,
            'name': name,
            'base_price': basePrice,
            'max_occupancy': maxOccupancy,
            'description': description,
          })
          .select()
          .single();

      debugPrint('✅ Room type created');
      return RoomType.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating room type: $e');
      rethrow;
    }
  }

  /// Update a room type
  Future<RoomType> updateRoomType({
    required String id,
    String? name,
    double? basePrice,
    int? maxOccupancy,
    String? description,
  }) async {
    try {
      debugPrint('📦 Updating room type: $id');
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (basePrice != null) updates['base_price'] = basePrice;
      if (maxOccupancy != null) updates['max_occupancy'] = maxOccupancy;
      if (description != null) updates['description'] = description;

      final response = await _client
          .from('room_types')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      debugPrint('✅ Room type updated');
      return RoomType.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error updating room type: $e');
      rethrow;
    }
  }

  /// Delete a room type
  Future<void> deleteRoomType(String id) async {
    try {
      debugPrint('📦 Deleting room type: $id');
      await _client.from('room_types').delete().eq('id', id);

      debugPrint('✅ Room type deleted');
    } catch (e) {
      debugPrint('❌ Error deleting room type: $e');
      rethrow;
    }
  }
}

/// Provider for room types repository
final roomTypesRepositoryProvider = Provider<RoomTypesRepository>((ref) {
  return RoomTypesRepository();
});

/// Provider for room types list
final roomTypesProvider = FutureProvider.family<List<RoomType>, String>((
  ref,
  hotelId,
) async {
  final repository = ref.watch(roomTypesRepositoryProvider);
  return repository.getRoomTypes(hotelId);
});
