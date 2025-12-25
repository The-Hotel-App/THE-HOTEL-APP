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

  // ============================================================
  // BOOKING PERMISSIONS
  // ============================================================

  /// Can create new bookings (onboard customers)
  /// SRS: Owner, Manager, Staff can onboard; Kitchen Manager cannot
  bool get canCreateBookings {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  /// Can edit current/ongoing bookings
  /// SRS: Owner and Manager only
  bool get canEditCurrentBookings {
    return this == UserRole.owner || this == UserRole.manager;
  }

  /// Can edit past/historical bookings
  /// SRS: Owner only
  bool get canEditPastBookings {
    return this == UserRole.owner;
  }

  // ============================================================
  // CUSTOMER PERMISSIONS
  // ============================================================

  /// Can view all customers in database (historical)
  /// SRS: Owner and Manager can view all
  bool get canViewAllCustomers {
    return this == UserRole.owner || this == UserRole.manager;
  }

  /// Can view ongoing/current customers only
  /// SRS: Owner, Manager, Staff can view ongoing; Kitchen Manager cannot
  bool get canViewOngoingCustomers {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  // ============================================================
  // ROOM PERMISSIONS
  // ============================================================

  /// Can access/view rooms
  /// SRS: Everyone except Kitchen Manager
  bool get canAccessRooms {
    return this != UserRole.kitchenManager;
  }

  /// Can edit room status (free, occupied, cleaning, etc.)
  /// SRS: Owner, Manager, Staff can change status
  bool get canEditRoomStatus {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  /// Can edit room configuration (room details, floor, etc.)
  /// SRS: Owner only
  bool get canEditRooms {
    return this == UserRole.owner;
  }

  /// Can manage room types (create, edit, delete)
  /// SRS: Owner only
  bool get canManageRoomTypes {
    return this == UserRole.owner;
  }

  // ============================================================
  // CLEANING & MAINTENANCE PERMISSIONS
  // ============================================================

  /// Can initiate cleaning/maintenance (requires biometric)
  /// SRS: Owner, Manager, Staff can initiate
  bool get canInitiateCleaning {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  /// Can complete cleaning/maintenance (requires biometric)
  /// SRS: Owner, Manager, Staff can complete
  bool get canCompleteCleaning {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  // ============================================================
  // DAY BOOK PERMISSIONS
  // ============================================================

  /// Can view today's day book
  /// Owner only
  bool get canViewDayBook {
    return this == UserRole.owner;
  }

  /// Can edit today's day book
  /// Owner only
  bool get canEditDayBook {
    return this == UserRole.owner;
  }

  /// Can view past day books
  /// Owner only
  bool get canViewPastDayBook {
    return this == UserRole.owner;
  }

  /// Can edit past day books
  /// SRS: Owner only
  bool get canEditPastDayBook {
    return this == UserRole.owner;
  }

  // ============================================================
  // FINANCIAL PERMISSIONS
  // ============================================================

  /// Can view money/financial details (amounts, payments, etc.)
  /// SRS: Owner only
  bool get canViewMoneyDetails {
    return this == UserRole.owner;
  }

  /// Can edit salary/financial info (requires biometric)
  /// SRS: Owner only
  bool get canEditSalaryInfo {
    return this == UserRole.owner;
  }

  // ============================================================
  // STAFF MANAGEMENT PERMISSIONS
  // ============================================================

  /// Can view staff database
  /// SRS: Owner (full access), Manager (view only)
  bool get canViewStaffDatabase {
    return this == UserRole.owner || this == UserRole.manager;
  }

  /// Can edit/manage staff (add, remove, change roles)
  /// SRS: Owner only
  bool get canManageStaff {
    return this == UserRole.owner;
  }

  // ============================================================
  // HOTEL SETTINGS PERMISSIONS
  // ============================================================

  /// Can view hotel settings
  /// SRS: Owner (full access), Manager (view only)
  bool get canViewHotelSettings {
    return this == UserRole.owner || this == UserRole.manager;
  }

  /// Can edit hotel settings
  /// SRS: Owner only
  bool get canEditHotelSettings {
    return this == UserRole.owner;
  }

  // ============================================================
  // FOOD ORDER PERMISSIONS
  // ============================================================

  /// Can view food orders
  /// Owner, Manager and Kitchen Manager
  bool get canViewFoodOrders {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.kitchenManager;
  }

  /// Can manage food orders (update status, etc.)
  /// Owner, Manager and Kitchen Manager
  bool get canManageFoodOrders {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.kitchenManager;
  }

  // ============================================================
  // LAUNDRY PERMISSIONS
  // ============================================================

  /// Can view laundry requests
  /// Owner, Manager and Staff
  bool get canViewLaundryRequests {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  /// Can manage laundry requests (update status, etc.)
  /// Owner, Manager and Staff
  bool get canManageLaundryRequests {
    return this == UserRole.owner ||
        this == UserRole.manager ||
        this == UserRole.staff;
  }

  // ============================================================
  // NOTIFICATION PERMISSIONS
  // ============================================================

  /// Receives all notifications
  /// SRS: Owner receives all; others are configurable
  bool get receivesAllNotifications {
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
