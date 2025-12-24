import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/features/auth/domain/usecases/biometric_authorizer.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

/// Dialog for biometric verification of sensitive actions.
/// Shows biometric prompt with reason text, tracks attempt count (max 3),
/// and shows password fallback after 3 failed attempts.
///
/// Requirements: 3.1, 3.4, 3.5, 3.6
class BiometricVerificationDialog extends ConsumerStatefulWidget {
  /// The reason text shown to the user explaining why verification is needed
  final String reason;

  /// The hotel ID for audit logging
  final String hotelId;

  /// The action type for audit logging (e.g., 'room_status_change', 'check_in')
  final String actionType;

  /// Optional reference ID for the entity being acted upon
  final String? referenceId;

  const BiometricVerificationDialog({
    super.key,
    required this.reason,
    required this.hotelId,
    required this.actionType,
    this.referenceId,
  });

  /// Show the verification dialog and return the result
  static Future<AuthorizationResult> show({
    required BuildContext context,
    required String reason,
    required String hotelId,
    required String actionType,
    String? referenceId,
  }) async {
    final result = await showDialog<AuthorizationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BiometricVerificationDialog(
        reason: reason,
        hotelId: hotelId,
        actionType: actionType,
        referenceId: referenceId,
      ),
    );
    return result ??
        AuthorizationResult.failed(errorMessage: 'Verification cancelled');
  }

  @override
  ConsumerState<BiometricVerificationDialog> createState() =>
      _BiometricVerificationDialogState();
}

class _BiometricVerificationDialogState
    extends ConsumerState<BiometricVerificationDialog> {
  bool _isVerifying = false;
  bool _showPasswordFallback = false;
  int _biometricAttempts = 0;
  String? _errorMessage;
  List<BiometricType> _availableBiometrics = [];

  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricTypes();
    // Auto-start biometric verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBiometricVerification();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricTypes() async {
    final biometricService = ref.read(biometricServiceProvider);
    final types = await biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _availableBiometrics = types;
      });
    }
  }

  Future<void> _startBiometricVerification() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        _handleError('User not authenticated');
        return;
      }

      final authorizer = ref.read(biometricAuthorizerProvider);
      final result = await authorizer.authorize(
        hotelId: widget.hotelId,
        userId: user.id,
        actionType: widget.actionType,
        referenceId: widget.referenceId,
        reason: widget.reason,
      );

      if (result.success) {
        AppLogger.success(
          'Biometric verification successful',
          tag: 'BiometricVerification',
        );
        if (mounted) {
          Navigator.of(context).pop(result);
        }
        return;
      }

      // Update attempt count
      _biometricAttempts = result.biometricAttempts;

      if (result.shouldOfferPasswordFallback) {
        AppLogger.info(
          'Offering password fallback after $_biometricAttempts failed attempts',
          tag: 'BiometricVerification',
        );
        setState(() {
          _isVerifying = false;
          _showPasswordFallback = true;
          _errorMessage =
              'Biometric verification failed. Please enter your password.';
        });
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage =
              result.errorMessage ?? 'Verification failed. Tap to retry.';
        });
      }
    } catch (e) {
      AppLogger.error(
        'Biometric verification error',
        tag: 'BiometricVerification',
        error: e,
      );
      _handleError('Verification error: $e');
    }
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        _handleError('User not authenticated');
        return;
      }

      final authRepo = ref.read(authRepositoryProvider);
      final authorizer = ref.read(biometricAuthorizerProvider);

      final result = await authorizer.verifyPasswordAndAuthorize(
        hotelId: widget.hotelId,
        userId: user.id,
        actionType: widget.actionType,
        referenceId: widget.referenceId,
        email: user.email,
        password: password,
        verifyPasswordCallback: (email, pwd) =>
            authRepo.verifyPassword(email: email, password: pwd),
      );

      if (result.success) {
        AppLogger.success(
          'Password verification successful',
          tag: 'BiometricVerification',
        );
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = result.errorMessage ?? 'Invalid password';
        });
      }
    } catch (e) {
      AppLogger.error(
        'Password verification error',
        tag: 'BiometricVerification',
        error: e,
      );
      _handleError('Verification error: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isVerifying = false;
        _errorMessage = message;
      });
    }
  }

  void _handleCancel() {
    AppLogger.info('User cancelled verification', tag: 'BiometricVerification');
    Navigator.of(
      context,
    ).pop(AuthorizationResult.failed(errorMessage: 'Verification cancelled'));
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
        child: _showPasswordFallback
            ? _buildPasswordFallbackContent()
            : _buildBiometricContent(),
      ),
    );
  }

  Widget _buildBiometricContent() {
    final biometricType = _getBiometricTypeText();
    final attemptsRemaining =
        BiometricAuthorizer.maxBiometricAttempts - _biometricAttempts;

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
          child: _isVerifying
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(_getBiometricIcon(), size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'Verify Your Identity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          widget.reason,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (_biometricAttempts > 0 && attemptsRemaining > 0) ...[
          const SizedBox(height: 8),
          Text(
            '$attemptsRemaining attempt${attemptsRemaining == 1 ? '' : 's'} remaining',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        if (!_isVerifying) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startBiometricVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Use $biometricType'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isVerifying ? null : _handleCancel,
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFallbackContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_outline, size: 48, color: AppColors.warning),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter Password',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Biometric verification failed. Please enter your password to continue.',
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
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isVerifying,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          onSubmitted: (_) => _verifyPassword(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isVerifying
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
                : const Text('Verify'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isVerifying ? null : _handleCancel,
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
