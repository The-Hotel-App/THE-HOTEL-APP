/// User role enumeration
enum UserRole {
  owner,
  manager,
  staff,
  kitchenManager;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
      case UserRole.kitchenManager:
        return 'Kitchen Manager';
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager:
        return 'manager';
      case UserRole.staff:
        return 'staff';
      case UserRole.kitchenManager:
        return 'kitchen_manager';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'staff':
        return UserRole.staff;
      case 'kitchen_manager':
        return UserRole.kitchenManager;
      default:
        throw ArgumentError('Invalid user role: $value');
    }
  }

  bool get canEditPastBookings {
    return this == UserRole.owner;
  }

  bool get canEditCurrentBookings {
    return this == UserRole.owner || this == UserRole.manager;
  }

  bool get canManageStaff {
    return this == UserRole.owner;
  }

  bool get canViewAllCustomers {
    return this == UserRole.owner || this == UserRole.manager;
  }

  bool get canEditDayBook {
    return this == UserRole.owner || this == UserRole.manager;
  }

  bool get canEditPastDayBook {
    return this == UserRole.owner;
  }

  bool get canViewMoneyDetails {
    return this == UserRole.owner;
  }

  /// Kitchen manager can only access kitchen-related features
  bool get canAccessRooms {
    return this != UserRole.kitchenManager;
  }

  bool get canCreateBookings {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  bool get canViewFoodOrders {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.kitchenManager;
  }

  bool get canManageFoodOrders {
    return this == UserRole.manager || this == UserRole.kitchenManager;
  }

  bool get canViewLaundryRequests {
    return this == UserRole.manager || this == UserRole.staff;
  }

  bool get canManageRoomTypes {
    return this == UserRole.owner;
  }

  bool get canEditRooms {
    return this == UserRole.owner;
  }
}

/// User entity - represents authenticated user with profile
class User {
  final String id; // Supabase auth user ID
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;
  final bool isActive;
  final bool hasBiometric;
  final DateTime? biometricEnrolledAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.createdAt,
    this.isActive = true,
    this.hasBiometric = false,
    this.biometricEnrolledAt,
  });

  /// Create User from Supabase data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      hasBiometric: json['has_biometric'] as bool? ?? false,
      biometricEnrolledAt: json['biometric_enrolled_at'] != null
          ? DateTime.parse(json['biometric_enrolled_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'is_active': isActive,
      'has_biometric': hasBiometric,
      'biometric_enrolled_at': biometricEnrolledAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
    bool? isActive,
    bool? hasBiometric,
    DateTime? biometricEnrolledAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      hasBiometric: hasBiometric ?? this.hasBiometric,
      biometricEnrolledAt: biometricEnrolledAt ?? this.biometricEnrolledAt,
    );
  }
}

/// User's hotel association with role
class UserHotel {
  final String hotelId;
  final String hotelName;
  final UserRole role;
  final bool isOwner;

  const UserHotel({
    required this.hotelId,
    required this.hotelName,
    required this.role,
    required this.isOwner,
  });

  factory UserHotel.fromJson(Map<String, dynamic> json) {
    return UserHotel(
      hotelId: json['hotel_id'] as String,
      hotelName: json['hotel_name'] as String,
      role: UserRole.fromString(json['user_role'] as String),
      isOwner: json['is_owner'] as bool,
    );
  }
}
