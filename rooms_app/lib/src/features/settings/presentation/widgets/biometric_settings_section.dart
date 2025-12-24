import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';
import 'package:rooms/src/features/auth/presentation/widgets/biometric_enrollment_dialog.dart';

/// Widget for managing biometric authentication settings.
/// Shows biometric toggle (enabled/disabled), enrollment date if enabled,
/// and handles enable (trigger enrollment) and disable (clear credentials).
///
/// Requirements: 6.1, 6.2, 6.3, 6.4, 6.5
class BiometricSettingsSection extends ConsumerStatefulWidget {
  const BiometricSettingsSection({super.key});

  @override
  ConsumerState<BiometricSettingsSection> createState() =>
      _BiometricSettingsSectionState();
}

class _BiometricSettingsSectionState
    extends ConsumerState<BiometricSettingsSection> {
  bool _isLoading = false;
  bool _isCheckingDevice = true;
  bool _isDeviceSupported = false;
  List<BiometricType> _availableBiometrics = [];

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

      if (mounted) {
        setState(() {
          _isCheckingDevice = false;
          _isDeviceSupported = isSupported && isEnrolled;
          _availableBiometrics = availableBiometrics;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error checking device capability',
        tag: 'BiometricSettings',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isCheckingDevice = false;
          _isDeviceSupported = false;
        });
      }
    }
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

  Future<void> _handleEnableBiometric() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      _showErrorSnackBar('User not found');
      return;
    }

    // Show password dialog to get credentials for enrollment
    final credentials = await _showPasswordDialog();
    if (credentials == null) return;

    // Show enrollment dialog
    if (!mounted) return;
    final result = await BiometricEnrollmentDialog.show(
      context: context,
      email: user.email,
      password: credentials,
    );

    if (result == BiometricEnrollmentResult.enrolled) {
      _showSuccessSnackBar('Biometric authentication enabled');
      // Refresh user data
      ref.invalidate(currentUserProvider);
    } else if (result == BiometricEnrollmentResult.failed) {
      _showErrorSnackBar('Failed to enable biometric authentication');
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Verify Password',
        icon: Icons.lock_outline,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your password to enable biometric login',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        primaryButtonText: 'Continue',
        onPrimaryPressed: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(context, controller.text);
          }
        },
        secondaryButtonText: 'Cancel',
        onSecondaryPressed: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _handleDisableBiometric() async {
    // Show confirmation dialog
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Disable Biometric Login',
      message:
          'Are you sure you want to disable biometric login? '
          'You will need to use your email and password to log in.',
      confirmText: 'Disable',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.fingerprint_outlined,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        _showErrorSnackBar('User not found');
        return;
      }

      // Clear stored credentials
      final biometricService = ref.read(biometricServiceProvider);
      await biometricService.clearCredentials();

      // Update user profile
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateBiometricStatus(
        userId: user.id,
        hasBiometric: false,
      );

      AppLogger.success(
        'Biometric disabled for user: ${user.id}',
        tag: 'BiometricSettings',
      );

      // Refresh user data
      ref.invalidate(currentUserProvider);

      _showSuccessSnackBar('Biometric authentication disabled');
    } catch (e) {
      AppLogger.error(
        'Error disabling biometric',
        tag: 'BiometricSettings',
        error: e,
      );
      _showErrorSnackBar('Failed to disable biometric authentication');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  /// Handle reset fingerprint - verify with old fingerprint first, then re-setup
  Future<void> _handleResetBiometric() async {
    final biometricType = _getBiometricTypeText();

    // Show confirmation dialog
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Reset $biometricType',
      message:
          'To reset your $biometricType, you need to verify with your '
          'current fingerprint first, then enter your password to set up again.',
      confirmText: 'Continue',
      cancelText: 'Cancel',
      icon: Icons.refresh,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Verify with current biometric
      final biometricService = ref.read(biometricServiceProvider);
      final authenticated = await biometricService.authenticate(
        reason: 'Verify your identity to reset $biometricType',
        biometricOnly: true,
      );

      if (!authenticated) {
        _showErrorSnackBar('Verification failed. Please try again.');
        return;
      }

      // Step 2: Clear old credentials
      await biometricService.clearCredentials();

      AppLogger.info(
        'Old credentials cleared for reset',
        tag: 'BiometricSettings',
      );

      // Step 3: Get new password
      setState(() => _isLoading = false);

      final newPassword = await _showPasswordDialog();
      if (newPassword == null) {
        // User cancelled - we need to re-enable biometric with old flow
        _showErrorSnackBar('Reset cancelled. Please set up biometric again.');

        // Update user profile to have no biometric since we cleared credentials
        final user = await ref.read(currentUserProvider.future);
        if (user != null) {
          final authRepo = ref.read(authRepositoryProvider);
          await authRepo.updateBiometricStatus(
            userId: user.id,
            hasBiometric: false,
          );
          ref.invalidate(currentUserProvider);
        }
        return;
      }

      // Step 4: Re-enroll with new credentials
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        _showErrorSnackBar('User not found');
        return;
      }

      if (!mounted) return;

      final result = await BiometricEnrollmentDialog.show(
        context: context,
        email: user.email,
        password: newPassword,
      );

      if (result == BiometricEnrollmentResult.enrolled) {
        _showSuccessSnackBar('$biometricType reset successfully');
        ref.invalidate(currentUserProvider);
      } else {
        _showErrorSnackBar('Failed to reset $biometricType');
        // Update user profile since we cleared credentials
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.updateBiometricStatus(
          userId: user.id,
          hasBiometric: false,
        );
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      AppLogger.error(
        'Error resetting biometric',
        tag: 'BiometricSettings',
        error: e,
      );
      _showErrorSnackBar('Failed to reset $biometricType');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) => _buildContent(user),
      loading: () => _buildLoadingState(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircularProgressIndicator(),
        title: Text('Loading biometric settings...'),
      ),
    );
  }

  Widget _buildContent(dynamic user) {
    if (user == null) return const SizedBox.shrink();

    // If still checking device capability, show loading
    if (_isCheckingDevice) {
      return _buildLoadingState();
    }

    // If device doesn't support biometrics, show unavailable state (Requirement 6.5)
    if (!_isDeviceSupported) {
      return _buildUnavailableState();
    }

    final hasBiometric = user.hasBiometric;
    final enrolledAt = user.biometricEnrolledAt;
    final biometricType = _getBiometricTypeText();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main toggle row
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasBiometric
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.grey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getBiometricIcon(),
                color: hasBiometric ? AppColors.success : AppColors.grey600,
                size: 22,
              ),
            ),
            title: Text(
              '$biometricType Login',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              hasBiometric
                  ? 'Use $biometricType for quick login and verification'
                  : 'Enable $biometricType for quick login',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            trailing: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: hasBiometric,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value) {
                              _handleEnableBiometric();
                            } else {
                              _handleDisableBiometric();
                            }
                          },
                    activeThumbColor: AppColors.success,
                  ),
          ),
          // Show enrollment date if enabled (Requirement 6.4)
          if (hasBiometric && enrolledAt != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Enrolled on ${DateFormat('MMM d, yyyy').format(enrolledAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Reset fingerprint option (when biometric is enabled)
          // TODO: Allow user to reset and re-add fingerprint
          if (hasBiometric) ...[
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.refresh, color: AppColors.info, size: 22),
              ),
              title: const Text(
                'Reset Fingerprint',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Verify with current fingerprint to re-setup',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
              onTap: _isLoading ? null : _handleResetBiometric,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.fingerprint, color: AppColors.grey500, size: 22),
        ),
        title: const Text(
          'Biometric Login',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.grey500,
          ),
        ),
        subtitle: Text(
          'Not available on this device',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: Icon(Icons.info_outline, color: AppColors.grey500, size: 20),
      ),
    );
  }
}
