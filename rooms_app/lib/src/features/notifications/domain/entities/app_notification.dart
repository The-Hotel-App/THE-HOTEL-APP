/// Represents a notification in the app
///
/// This entity maps to the `notifications` table in Supabase
class AppNotification {
  final String id;
  final String hotelId;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool isHidden;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.isHidden,
    required this.createdAt,
  });

  /// Create from Supabase JSON response
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'is_hidden': isHidden,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? hotelId,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isHidden,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get hotel name from data if available
  String? get hotelName => data['hotel_name'] as String?;

  /// Get room number from data if available
  String? get roomNumber => data['room_number'] as String?;

  /// Check if this is a recent notification (within last hour)
  bool get isRecent => DateTime.now().difference(createdAt).inHours < 1;
}

/// Types of notifications
enum NotificationType {
  newBooking('new_booking'),
  roomStatusChange('room_status_change'),
  checkout('checkout'),
  payment('payment'),
  system('system');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }

  /// Get display-friendly label
  String get label {
    switch (this) {
      case NotificationType.newBooking:
        return 'New Booking';
      case NotificationType.roomStatusChange:
        return 'Room Status';
      case NotificationType.checkout:
        return 'Checkout';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.system:
        return 'System';
    }
  }

  /// Get icon for this notification type
  String get iconName {
    switch (this) {
      case NotificationType.newBooking:
        return 'event_available';
      case NotificationType.roomStatusChange:
        return 'meeting_room';
      case NotificationType.checkout:
        return 'check_circle_outline';
      case NotificationType.payment:
        return 'payment';
      case NotificationType.system:
        return 'info_outline';
    }
  }
}
