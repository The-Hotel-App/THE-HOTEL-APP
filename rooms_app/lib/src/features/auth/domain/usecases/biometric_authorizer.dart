import 'dart:io';

import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/biometric_service.dart';
import 'package:rooms/src/features/auth/data/repositories/biometric_audit_log_repository.dart';

/// Verification method used for authorization
enum VerificationMethod {
  /// Biometric verification (fingerprint/face)
  biometric,

  /// Password fallback verification
  password,

  /// No verification completed
  none,
}

/// Result of an authorization attempt
class AuthorizationResult {
  /// Whether the authorization was successful
  final bool success;

  /// The method used for verification
  final VerificationMethod method;

  /// Error message if authorization failed
  final String? errorMessage;

  /// Number of biometric attempts made
  final int biometricAttempts;

  const AuthorizationResult({
    required this.success,
    required this.method,
    this.errorMessage,
    this.biometricAttempts = 0,
  });

  /// Create a successful result
  factory AuthorizationResult.successful(VerificationMethod method) {
    return AuthorizationResult(success: true, method: method);
  }

  /// Create a failed result
  factory AuthorizationResult.failed({
    String? errorMessage,
    int biometricAttempts = 0,
  }) {
    return AuthorizationResult(
      success: false,
      method: VerificationMethod.none,
      errorMessage: errorMessage,
      biometricAttempts: biometricAttempts,
    );
  }

  /// Check if password fallback should be offered
  bool get shouldOfferPasswordFallback =>
      !success && biometricAttempts >= BiometricAuthorizer.maxBiometricAttempts;

  @override
  String toString() {
    return 'AuthorizationResult(success: $success, method: $method, '
        'errorMessage: $errorMessage, biometricAttempts: $biometricAttempts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorizationResult &&
        other.success == success &&
        other.method == method &&
        other.errorMessage == errorMessage &&
        other.biometricAttempts == biometricAttempts;
  }

  @override
  int get hashCode {
    return Object.hash(success, method, errorMessage, biometricAttempts);
  }
}

/// Authorizes sensitive actions with biometric verification.
/// Handles retry logic and password fallback.
///
/// Usage:
/// ```dart
/// final authorizer = BiometricAuthorizer(biometricService, auditLogRepo);
/// final result = await authorizer.authorize(
///   hotelId: 'hotel-123',
///   userId: 'user-456',
///   actionType: 'room_status_change',
///   reason: 'Verify to change room status',
/// );
/// if (result.success) {
///   // Proceed with action
/// }
/// ```
class BiometricAuthorizer {
  final BiometricService _biometricService;
  final BiometricAuditLogRepository _auditLogRepository;

  /// Maximum number of biometric attempts before offering password fallback
  static const int maxBiometricAttempts = 3;

  BiometricAuthorizer(this._biometricService, this._auditLogRepository);

  /// Authorize an action with biometric verification.
  ///
  /// Returns [AuthorizationResult] with success status and verification method.
  /// After [maxBiometricAttempts] failed biometric attempts, the caller should
  /// offer password fallback using [verifyPasswordAndAuthorize].
  ///
  /// [hotelId] - The hotel context for the action
  /// [userId] - The user attempting the action
  /// [actionType] - Type of action (e.g., 'room_status_change', 'check_in')
  /// [referenceId] - Optional reference to the entity being acted upon
  /// [reason] - Message shown to user explaining why verification is needed
  Future<AuthorizationResult> authorize({
    required String hotelId,
    required String userId,
    required String actionType,
    String? referenceId,
    required String reason,
  }) async {
    AppLogger.debug(
      'Starting biometric authorization for action: $actionType',
      tag: 'BiometricAuth',
    );

    int attempts = 0;

    while (attempts < maxBiometricAttempts) {
      attempts++;
      AppLogger.debug(
        'Biometric attempt $attempts of $maxBiometricAttempts',
        tag: 'BiometricAuth',
      );

      final authenticated = await _biometricService.authenticate(
        reason: reason,
        biometricOnly: true,
      );

      if (authenticated) {
        // Log successful verification
        await _logVerification(
          hotelId: hotelId,
          userId: userId,
          actionType: actionType,
          referenceId: referenceId,
          success: true,
        );

        AppLogger.success(
          'Biometric authorization successful on attempt $attempts',
          tag: 'BiometricAuth',
        );

        return AuthorizationResult(
          success: true,
          method: VerificationMethod.biometric,
          biometricAttempts: attempts,
        );
      }

      // Log failed attempt
      await _logVerification(
        hotelId: hotelId,
        userId: userId,
        actionType: actionType,
        referenceId: referenceId,
        success: false,
      );

      AppLogger.warning(
        'Biometric attempt $attempts failed',
        tag: 'BiometricAuth',
      );
    }

    // All biometric attempts exhausted
    AppLogger.warning(
      'All $maxBiometricAttempts biometric attempts exhausted, '
      'password fallback should be offered',
      tag: 'BiometricAuth',
    );

    return AuthorizationResult.failed(
      errorMessage:
          'Biometric verification failed after $maxBiometricAttempts attempts',
      biometricAttempts: attempts,
    );
  }

  /// Verify password as fallback and authorize the action.
  ///
  /// This should be called after [authorize] returns with
  /// [AuthorizationResult.shouldOfferPasswordFallback] = true.
  ///
  /// [hotelId] - The hotel context for the action
  /// [userId] - The user attempting the action
  /// [actionType] - Type of action (e.g., 'room_status_change', 'check_in')
  /// [referenceId] - Optional reference to the entity being acted upon
  /// [email] - User's email for password verification
  /// [password] - User's password to verify
  /// [verifyPasswordCallback] - Callback to verify password against auth system
  Future<AuthorizationResult> verifyPasswordAndAuthorize({
    required String hotelId,
    required String userId,
    required String actionType,
    String? referenceId,
    required String email,
    required String password,
    required Future<bool> Function(String email, String password)
    verifyPasswordCallback,
  }) async {
    AppLogger.debug(
      'Starting password fallback verification for action: $actionType',
      tag: 'BiometricAuth',
    );

    try {
      final isValid = await verifyPasswordCallback(email, password);

      if (isValid) {
        // Log successful password verification
        await _logVerification(
          hotelId: hotelId,
          userId: userId,
          actionType: actionType,
          referenceId: referenceId,
          success: true,
          isPasswordFallback: true,
        );

        AppLogger.success(
          'Password fallback verification successful',
          tag: 'BiometricAuth',
        );

        return AuthorizationResult(
          success: true,
          method: VerificationMethod.password,
        );
      } else {
        // Log failed password verification
        await _logVerification(
          hotelId: hotelId,
          userId: userId,
          actionType: actionType,
          referenceId: referenceId,
          success: false,
          isPasswordFallback: true,
        );

        AppLogger.warning(
          'Password fallback verification failed - invalid password',
          tag: 'BiometricAuth',
        );

        return AuthorizationResult.failed(errorMessage: 'Invalid password');
      }
    } catch (e) {
      AppLogger.error(
        'Password verification error',
        tag: 'BiometricAuth',
        error: e,
      );

      return AuthorizationResult.failed(
        errorMessage: 'Password verification failed: $e',
      );
    }
  }

  /// Log a verification attempt to the audit log
  Future<void> _logVerification({
    required String hotelId,
    required String userId,
    required String actionType,
    String? referenceId,
    required bool success,
    bool isPasswordFallback = false,
  }) async {
    try {
      await _auditLogRepository.logVerification(
        hotelId: hotelId,
        userId: userId,
        actionType: actionType,
        referenceId: referenceId,
        success: success,
        deviceInfo: _getDeviceInfo(isPasswordFallback: isPasswordFallback),
      );
    } catch (e) {
      // Don't fail the authorization if logging fails
      AppLogger.error(
        'Failed to log verification attempt',
        tag: 'BiometricAuth',
        error: e,
      );
    }
  }

  /// Get device information for audit logging
  Map<String, dynamic> _getDeviceInfo({bool isPasswordFallback = false}) {
    return {
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'verification_type': isPasswordFallback ? 'password' : 'biometric',
    };
  }
}
