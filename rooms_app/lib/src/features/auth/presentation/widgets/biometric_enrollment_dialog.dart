import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

/// Result of biometric enrollment dialog
enum BiometricEnrollmentResult {
  /// User successfully enrolled biometrics
  enrolled,

  /// User declined to enroll biometrics
  declined,

  /// Device does not support biometrics
  notSupported,

  /// Enrollment failed due to an error
  failed,
}

/// Dialog for enrolling biometric authentication after first login.
/// Shows device capability check and handles enrollment confirmation.
///
/// Requirements: 1.1, 1.3, 1.4, 1.5
class BiometricEnrollmentDialog extends ConsumerStatefulWidget {
  /// Email for storing credentials
  final String email;

  /// Password for storing credentials
  final String password;

  const BiometricEnrollmentDialog({
    super.key,
    required this.email,
    required this.password,
  });

  /// Show the enrollment dialog and return the result
  static Future<BiometricEnrollmentResult> show({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final result = await showDialog<BiometricEnrollmentResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          BiometricEnrollmentDialog(email: email, password: password),
    );
    return result ?? BiometricEnrollmentResult.declined;
  }

  @override
  ConsumerState<BiometricEnrollmentDialog> createState() =>
      _BiometricEnrollmentDialogState();
}

class _BiometricEnrollmentDialogState
    extends ConsumerState<BiometricEnrollmentDialog> {
  bool _isCheckingDevice = true;
  bool _isDeviceSupported = false;
  bool _areBiometricsEnrolled = false;
  bool _isEnrolling = false;
  List<BiometricType> _availableBiometrics = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDeviceCapability();
  }

  Future<void> _checkDeviceCapability() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);

      final isSupported = await biometricService.isDeviceSupported();
      final isEnrolled = await biometricService.areBiometricsEnrolled();
      final availableBiometrics = await biometricService
          .getAvailableBiometrics();

      AppLogger.debug(
        'Device biometric check - Supported: $isSupported, Enrolled: $isEnrolled, Types: $availableBiometrics',
        tag: 'BiometricEnrollment',
      );

      if (mounted) {
        setState(() {
          _isCheckingDevice = false;
          _isDeviceSupported = isSupported;
          _areBiometricsEnrolled = isEnrolled;
          _availableBiometrics = availableBiometrics;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error checking device capability',
        tag: 'BiometricEnrollment',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isCheckingDevice = false;
          _isDeviceSupported = false;
          _errorMessage = 'Failed to check device capability';
        });
      }
    }
  }

  Future<void> _handleEnroll() async {
    setState(() {
      _isEnrolling = true;
      _errorMessage = null;
    });

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Authenticate with biometrics to confirm enrollment
      final authenticated = await biometricService.authenticate(
        reason: 'Verify your identity to enable biometric login',
        biometricOnly: true,
      );

      if (!authenticated) {
        AppLogger.warning(
          'Biometric authentication failed during enrollment',
          tag: 'BiometricEnrollment',
        );
        if (mounted) {
          setState(() {
            _isEnrolling = false;
            _errorMessage = 'Biometric verification failed. Please try again.';
          });
        }
        return;
      }

      // Store credentials securely
      await biometricService.storeCredentials(
        email: widget.email,
        password: widget.password,
      );

      // Update user profile with biometric status
      final user = await ref.read(currentUserProvider.future);
      if (user != null) {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.updateBiometricStatus(
          userId: user.id,
          hasBiometric: true,
        );

        AppLogger.success(
          'Biometric enrollment completed for user: ${user.id}',
          tag: 'BiometricEnrollment',
        );
      }

      // Invalidate providers to refresh state
      ref.invalidate(currentUserProvider);

      if (mounted) {
        Navigator.of(context).pop(BiometricEnrollmentResult.enrolled);
      }
    } catch (e) {
      AppLogger.error(
        'Error during biometric enrollment',
        tag: 'BiometricEnrollment',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isEnrolling = false;
          _errorMessage = 'Enrollment failed. Please try again.';
        });
      }
    }
  }

  void _handleDecline() {
    AppLogger.info(
      'User declined biometric enrollment',
      tag: 'BiometricEnrollment',
    );
    Navigator.of(context).pop(BiometricEnrollmentResult.declined);
  }

  void _handleNotSupported() {
    Navigator.of(context).pop(BiometricEnrollmentResult.notSupported);
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isCheckingDevice) {
      return _buildCheckingContent();
    }

    if (!_isDeviceSupported || !_areBiometricsEnrolled) {
      return _buildNotSupportedContent();
    }

    return _buildEnrollmentContent();
  }

  Widget _buildCheckingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Checking device capability...',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotSupportedContent() {
    final message = !_isDeviceSupported
        ? 'Your device does not support biometric authentication.'
        : 'No biometrics are enrolled on your device. Please set up fingerprint or face recognition in your device settings first.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          'Biometric Not Available',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleNotSupported,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentContent() {
    final biometricType = _getBiometricTypeText();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getBiometricIcon(), size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'Enable $biometricType Login',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Use $biometricType for quick and secure login. You can also use it to verify important actions like room status changes.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isEnrolling ? null : _handleEnroll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isEnrolling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : Text('Enable $biometricType'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isEnrolling ? null : _handleDecline,
            child: Text(
              'Not Now',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
