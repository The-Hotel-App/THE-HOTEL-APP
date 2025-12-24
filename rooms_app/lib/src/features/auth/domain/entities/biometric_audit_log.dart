/// Types of actions that require biometric verification
enum BiometricActionType {
  login('login'),
  roomStatusChange('room_status_change'),
  checkIn('check_in'),
  checkOut('check_out'),
  payment('payment');

  final String value;
  const BiometricActionType(this.value);

  /// Create BiometricActionType from database string value
  static BiometricActionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'login':
        return BiometricActionType.login;
      case 'room_status_change':
        return BiometricActionType.roomStatusChange;
      case 'check_in':
        return BiometricActionType.checkIn;
      case 'check_out':
        return BiometricActionType.checkOut;
      case 'payment':
        return BiometricActionType.payment;
      default:
        throw ArgumentError('Invalid biometric action type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case BiometricActionType.login:
        return 'Login';
      case BiometricActionType.roomStatusChange:
        return 'Room Status Change';
      case BiometricActionType.checkIn:
        return 'Check In';
      case BiometricActionType.checkOut:
        return 'Check Out';
      case BiometricActionType.payment:
        return 'Payment';
    }
  }
}

/// Represents a biometric verification audit log entry
class BiometricAuditLog {
  final String id;
  final String hotelId;
  final String userId;
  final String actionType;
  final String? referenceId;
  final DateTime verifiedAt;
  final Map<String, dynamic>? deviceInfo;
  final bool success;

  const BiometricAuditLog({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.actionType,
    this.referenceId,
    required this.verifiedAt,
    this.deviceInfo,
    required this.success,
  });

  /// Create BiometricAuditLog from Supabase JSON data
  factory BiometricAuditLog.fromJson(Map<String, dynamic> json) {
    return BiometricAuditLog(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      referenceId: json['reference_id'] as String?,
      verifiedAt: DateTime.parse(json['verified_at'] as String),
      deviceInfo: json['device_info'] as Map<String, dynamic>?,
      success: json['success'] as bool,
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'user_id': userId,
      'action_type': actionType,
      'reference_id': referenceId,
      'verified_at': verifiedAt.toIso8601String(),
      'device_info': deviceInfo,
      'success': success,
    };
  }

  /// Convert to JSON for insert (without id, let database generate it)
  Map<String, dynamic> toInsertJson() {
    return {
      'hotel_id': hotelId,
      'user_id': userId,
      'action_type': actionType,
      'reference_id': referenceId,
      'verified_at': verifiedAt.toIso8601String(),
      'device_info': deviceInfo,
      'success': success,
    };
  }

  BiometricAuditLog copyWith({
    String? id,
    String? hotelId,
    String? userId,
    String? actionType,
    String? referenceId,
    DateTime? verifiedAt,
    Map<String, dynamic>? deviceInfo,
    bool? success,
  }) {
    return BiometricAuditLog(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      userId: userId ?? this.userId,
      actionType: actionType ?? this.actionType,
      referenceId: referenceId ?? this.referenceId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      success: success ?? this.success,
    );
  }

  @override
  String toString() {
    return 'BiometricAuditLog(id: $id, hotelId: $hotelId, userId: $userId, '
        'actionType: $actionType, referenceId: $referenceId, '
        'verifiedAt: $verifiedAt, success: $success)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BiometricAuditLog &&
        other.id == id &&
        other.hotelId == hotelId &&
        other.userId == userId &&
        other.actionType == actionType &&
        other.referenceId == referenceId &&
        other.verifiedAt == verifiedAt &&
        other.success == success;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      hotelId,
      userId,
      actionType,
      referenceId,
      verifiedAt,
      success,
    );
  }
}
