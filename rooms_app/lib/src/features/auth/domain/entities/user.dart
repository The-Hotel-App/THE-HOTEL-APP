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

/// User entity
class User {
  final String id;
  final String hotelId;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final DateTime createdAt;
  final bool isActive;

  const User({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.createdAt,
    this.isActive = true,
  });

  User copyWith({
    String? id,
    String? hotelId,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
