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
  /// SRS: Manager and Kitchen Manager only (NOT Owner)
  bool get canViewFoodOrders {
    return this == UserRole.manager || this == UserRole.kitchenManager;
  }

  /// Can manage food orders (update status, etc.)
  /// SRS: Manager and Kitchen Manager only
  bool get canManageFoodOrders {
    return this == UserRole.manager || this == UserRole.kitchenManager;
  }

  // ============================================================
  // LAUNDRY PERMISSIONS
  // ============================================================

  /// Can view laundry requests
  /// SRS: Manager and Staff only
  bool get canViewLaundryRequests {
    return this == UserRole.manager || this == UserRole.staff;
  }

  /// Can manage laundry requests (update status, etc.)
  /// SRS: Manager and Staff only
  bool get canManageLaundryRequests {
    return this == UserRole.manager || this == UserRole.staff;
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
