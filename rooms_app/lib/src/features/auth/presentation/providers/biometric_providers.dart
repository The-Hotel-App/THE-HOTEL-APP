import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/biometric_service.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/data/repositories/biometric_audit_log_repository.dart';
import 'package:rooms/src/features/auth/domain/usecases/biometric_authorizer.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Provider for BiometricService
/// Provides access to device biometric authentication functionality
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider for BiometricAuditLogRepository
/// Handles logging and retrieval of biometric verification attempts
final biometricAuditLogRepositoryProvider =
    Provider<BiometricAuditLogRepository>((ref) {
      return BiometricAuditLogRepository(
        supabaseService: SupabaseService.instance,
      );
    });

/// Provider for BiometricAuthorizer
/// Handles biometric authorization for sensitive actions with retry logic
final biometricAuthorizerProvider = Provider<BiometricAuthorizer>((ref) {
  final biometricService = ref.watch(biometricServiceProvider);
  final auditLogRepo = ref.watch(biometricAuditLogRepositoryProvider);
  return BiometricAuthorizer(biometricService, auditLogRepo);
});

/// Provider for device biometric support status
/// Returns true if device supports biometrics AND biometrics are enrolled
final biometricSupportProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  final isSupported = await service.isDeviceSupported();
  if (!isSupported) return false;
  final isEnrolled = await service.areBiometricsEnrolled();
  return isEnrolled;
});

/// Provider for user's biometric enrollment status
/// Returns true if the current user has enrolled biometrics (has_biometric=true)
final userBiometricStatusProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.hasBiometric ?? false,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Provider for checking if biometric login is available
/// Returns true if:
/// - Device supports biometrics
/// - User has enrolled biometrics (has_biometric=true)
/// - Stored credentials exist in secure storage
final canUseBiometricLoginProvider = FutureProvider<bool>((ref) async {
  // Check device support
  final deviceSupported = await ref.watch(biometricSupportProvider.future);
  if (!deviceSupported) return false;

  // Check user enrollment status
  final userEnrolled = ref.watch(userBiometricStatusProvider);
  if (!userEnrolled) return false;

  // Check if credentials are stored
  final biometricService = ref.watch(biometricServiceProvider);
  final hasCredentials = await biometricService.hasStoredCredentials();
  return hasCredentials;
});

/// Provider for available biometric types on the device
/// Returns list of BiometricType (fingerprint, face, iris)
final availableBiometricsProvider = FutureProvider<List<dynamic>>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.getAvailableBiometrics();
});
