import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rooms/src/core/logging/app_logger.dart';

/// Service for device biometric authentication.
/// Uses local_auth package for on-device verification and
/// flutter_secure_storage for encrypted credential storage.
class BiometricService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';

  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  /// Check if device supports biometrics.
  /// Returns true if the device has biometric hardware.
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      AppLogger.debug(
        'Device biometric support: $isSupported',
        tag: 'BiometricService',
      );
      return isSupported;
    } on PlatformException catch (e) {
      AppLogger.error(
        'Error checking device support',
        tag: 'BiometricService',
        error: e,
      );
      return false;
    }
  }

  /// Check if biometrics are enrolled on device.
  /// Returns true if user has enrolled fingerprint/face on the device.
  Future<bool> areBiometricsEnrolled() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      AppLogger.debug(
        'Biometrics enrolled: $canCheck',
        tag: 'BiometricService',
      );
      return canCheck;
    } on PlatformException catch (e) {
      AppLogger.error(
        'Error checking biometrics enrollment',
        tag: 'BiometricService',
        error: e,
      );
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris).
  /// Returns list of BiometricType available on the device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();
      AppLogger.debug(
        'Available biometrics: $biometrics',
        tag: 'BiometricService',
      );
      return biometrics;
    } on PlatformException catch (e) {
      AppLogger.error(
        'Error getting available biometrics',
        tag: 'BiometricService',
        error: e,
      );
      return [];
    }
  }

  /// Authenticate using device biometrics.
  /// Returns true if authentication succeeds.
  ///
  /// [reason] - The message shown to user explaining why authentication is needed.
  /// [biometricOnly] - If true, only biometric auth is allowed (no PIN/pattern fallback).
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      // First check if device supports biometrics
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        AppLogger.warning(
          'Device does not support biometrics',
          tag: 'BiometricService',
        );
        return false;
      }

      // Check if biometrics are enrolled
      final isEnrolled = await areBiometricsEnrolled();
      if (!isEnrolled) {
        AppLogger.warning(
          'No biometrics enrolled on device',
          tag: 'BiometricService',
        );
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: false, // Allow user to cancel without re-prompting
          biometricOnly: biometricOnly,
        ),
      );

      AppLogger.info(
        'Biometric authentication result: $authenticated',
        tag: 'BiometricService',
      );
      return authenticated;
    } on PlatformException catch (e) {
      AppLogger.error(
        'Biometric authentication error',
        tag: 'BiometricService',
        error: e,
      );
      return false;
    }
  }

  /// Store credentials securely for biometric login.
  /// Credentials are encrypted using flutter_secure_storage.
  ///
  /// [email] - User's email address.
  /// [password] - User's password.
  Future<void> storeCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _emailKey, value: email);
      await _secureStorage.write(key: _passwordKey, value: password);
      AppLogger.info('Credentials stored securely', tag: 'BiometricService');
    } catch (e) {
      AppLogger.error(
        'Error storing credentials',
        tag: 'BiometricService',
        error: e,
      );
      rethrow;
    }
  }

  /// Retrieve stored credentials after biometric auth.
  /// Returns null if no credentials are stored.
  Future<({String email, String password})?> getStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);

      if (email == null || password == null) {
        AppLogger.debug('No stored credentials found', tag: 'BiometricService');
        return null;
      }

      AppLogger.debug('Retrieved stored credentials', tag: 'BiometricService');
      return (email: email, password: password);
    } catch (e) {
      AppLogger.error(
        'Error retrieving credentials',
        tag: 'BiometricService',
        error: e,
      );
      return null;
    }
  }

  /// Clear stored credentials.
  /// Should be called when user disables biometrics or logs out.
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
      AppLogger.info('Credentials cleared', tag: 'BiometricService');
    } catch (e) {
      AppLogger.error(
        'Error clearing credentials',
        tag: 'BiometricService',
        error: e,
      );
      rethrow;
    }
  }

  /// Check if credentials are stored.
  /// Returns true if both email and password are stored.
  Future<bool> hasStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);
      final hasCredentials = email != null && password != null;
      AppLogger.debug(
        'Has stored credentials: $hasCredentials',
        tag: 'BiometricService',
      );
      return hasCredentials;
    } catch (e) {
      AppLogger.error(
        'Error checking stored credentials',
        tag: 'BiometricService',
        error: e,
      );
      return false;
    }
  }
}
