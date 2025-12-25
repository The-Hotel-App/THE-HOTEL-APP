import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/constants/app_constants.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/app_update_service.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/core/widgets/update_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';
import 'package:rooms/src/features/auth/presentation/widgets/biometric_enrollment_dialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _obscurePassword = true;
  List<Map<String, String>> _testEmails = [];
  bool _isLoadingEmails = true;

  @override
  void initState() {
    super.initState();
    _loadTestEmails();
  }

  Future<void> _loadTestEmails() async {
    try {
      // Fetch all customers with email from the database
      final response = await SupabaseService.instance.client
          .from('customers')
          .select('name, email')
          .not('email', 'is', null)
          .order('name');

      final emails = <Map<String, String>>[];
      for (final row in response) {
        final email = row['email'] as String?;
        final name = row['name'] as String? ?? 'Unknown';
        if (email != null && email.isNotEmpty) {
          emails.add({'email': email, 'label': name});
        }
      }

      if (mounted) {
        setState(() {
          _testEmails = emails;
          _isLoadingEmails = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading test emails', tag: 'Auth', error: e);
      if (mounted) {
        setState(() => _isLoadingEmails = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Helper to get the appropriate dashboard route based on user role
  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return AppRoutes.ownerDashboard;
      case UserRole.manager:
        return AppRoutes.managerDashboard;
      case UserRole.staff:
        return AppRoutes.staffDashboard;
      case UserRole.kitchenManager:
        return AppRoutes.kitchenDashboard;
    }
  }

  /// Check for app updates after successful login
  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await AppUpdateService.checkForUpdate();
      if (updateInfo != null && mounted) {
        // Small delay to ensure dashboard UI is ready
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          UpdateDialog.show(context, updateInfo);
        }
      }
    } catch (e) {
      AppLogger.warning('Update check error: $e', tag: 'Update');
    }
  }

  /// Check if biometric enrollment should be prompted and show dialog
  /// Requirements: 1.1 - Prompt after first successful email/password login
  /// Only shows if device supports biometrics and user hasn't enrolled
  Future<void> _checkAndPromptBiometricEnrollment(
    String email,
    String password,
  ) async {
    try {
      // Check if device supports biometrics
      final biometricService = ref.read(biometricServiceProvider);
      final isDeviceSupported = await biometricService.isDeviceSupported();
      final areBiometricsEnrolled = await biometricService
          .areBiometricsEnrolled();

      if (!isDeviceSupported || !areBiometricsEnrolled) {
        AppLogger.debug(
          'Device does not support biometrics or no biometrics enrolled',
          tag: 'BiometricEnrollment',
        );
        return;
      }

      // Check if user has already enrolled biometrics
      final user = await ref.read(currentUserProvider.future);
      if (user == null || user.hasBiometric) {
        AppLogger.debug(
          'User already has biometrics enrolled or user is null',
          tag: 'BiometricEnrollment',
        );
        return;
      }

      // Show enrollment dialog
      if (!mounted) return;

      AppLogger.info(
        'Prompting user for biometric enrollment',
        tag: 'BiometricEnrollment',
      );

      final result = await BiometricEnrollmentDialog.show(
        context: context,
        email: email,
        password: password,
      );

      AppLogger.info(
        'Biometric enrollment result: $result',
        tag: 'BiometricEnrollment',
      );

      // Refresh user state after enrollment
      if (result == BiometricEnrollmentResult.enrolled) {
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      AppLogger.error(
        'Error checking biometric enrollment',
        tag: 'BiometricEnrollment',
        error: e,
      );
      // Don't block login flow if enrollment check fails
    }
  }

  Future<void> _handleLogin() async {
    AppLogger.auth('Login attempt started');

    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('Form validation failed', tag: 'Auth');
      return;
    }

    AppLogger.debug('Form validated', tag: 'Auth');
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      AppLogger.debug('Email: $email', tag: 'Auth');

      final authRepo = ref.read(authRepositoryProvider);
      AppLogger.debug('Auth repository obtained', tag: 'Auth');

      await authRepo.login(email: email, password: password);

      AppLogger.success('Login successful!', tag: 'Auth');

      if (!mounted) return;

      // Check if we should prompt for biometric enrollment
      // Requirements: 1.1 - Prompt after first successful email/password login
      await _checkAndPromptBiometricEnrollment(email, password);

      if (!mounted) return;

      // Get user's hotels before any navigation
      final hotels = await ref.read(userHotelsProvider.future);

      AppLogger.info('User has ${hotels.length} hotel(s)', tag: 'Auth');

      if (!mounted) return;

      if (hotels.isEmpty) {
        // User has no hotels - let router handle redirect to setup
        AppLogger.warning(
          'User has no hotels, router will redirect to setup',
          tag: 'Auth',
        );
        setState(() => _isLoading = false);
        // Invalidate auth providers to trigger router refresh
        ref.invalidate(currentUserProvider);
        return;
      }

      if (hotels.length == 1) {
        // Auto-select the only hotel
        AppLogger.success(
          'Auto-selecting single hotel: ${hotels.first.hotelName}',
          tag: 'Auth',
        );
        ref.read(selectedHotelIdProvider.notifier).state = hotels.first.hotelId;

        // Register FCM token for push notifications (Owners only)
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.registerTokenForUser();

        // Get the dashboard route before any async operations
        final dashboardRoute = _getDashboardRoute(hotels.first.role);
        AppLogger.navigation('Navigating to dashboard: $dashboardRoute');

        // Small delay to ensure provider state propagates
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate first, then clear loading state
        // This prevents the router refresh from interfering with navigation
        if (mounted) {
          context.go(dashboardRoute);
          // Check for updates after successful login
          _checkForUpdates();
          // Clear loading after navigation is initiated
          if (mounted) setState(() => _isLoading = false);
        }
        return;
      }

      // Multiple hotels - show selector
      AppLogger.info('Multiple hotels, showing selector', tag: 'Auth');
      setState(() => _isLoading = false);
      if (mounted) {
        await _showHotelSelector(hotels);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Login failed',
        tag: 'Auth',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Handle biometric login
  /// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5
  Future<void> _handleBiometricLogin() async {
    AppLogger.auth('Biometric login attempt started');

    setState(() => _isBiometricLoading = true);

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Trigger biometric authentication
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to sign in to ROOMS.io',
        biometricOnly: true,
      );

      if (!authenticated) {
        AppLogger.warning('Biometric authentication failed', tag: 'Auth');
        if (mounted) {
          setState(() => _isBiometricLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Biometric authentication failed. Please try again or use email/password.',
              ),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: AppColors.white,
                onPressed: _handleBiometricLogin,
              ),
            ),
          );
        }
        return;
      }

      // Biometric succeeded - login with stored credentials
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.loginWithStoredCredentials();

      AppLogger.success('Biometric login successful!', tag: 'Auth');

      if (!mounted) return;

      // Get user's hotels before any navigation
      final hotels = await ref.read(userHotelsProvider.future);

      AppLogger.info('User has ${hotels.length} hotel(s)', tag: 'Auth');

      if (!mounted) return;

      if (hotels.isEmpty) {
        AppLogger.warning(
          'User has no hotels, router will redirect to setup',
          tag: 'Auth',
        );
        setState(() => _isBiometricLoading = false);
        ref.invalidate(currentUserProvider);
        return;
      }

      if (hotels.length == 1) {
        AppLogger.success(
          'Auto-selecting single hotel: ${hotels.first.hotelName}',
          tag: 'Auth',
        );
        ref.read(selectedHotelIdProvider.notifier).state = hotels.first.hotelId;

        // Register FCM token for push notifications
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.registerTokenForUser();

        final dashboardRoute = _getDashboardRoute(hotels.first.role);
        AppLogger.navigation('Navigating to dashboard: $dashboardRoute');

        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          context.go(dashboardRoute);
          // Check for updates after successful login
          _checkForUpdates();
          if (mounted) setState(() => _isBiometricLoading = false);
        }
        return;
      }

      // Multiple hotels - show selector
      AppLogger.info('Multiple hotels, showing selector', tag: 'Auth');
      setState(() => _isBiometricLoading = false);
      if (mounted) {
        await _showHotelSelector(hotels);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Biometric login failed',
        tag: 'Auth',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() => _isBiometricLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.white,
              onPressed: _handleBiometricLogin,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showHotelSelector(List<UserHotel> hotels) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PopScope(
        canPop: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: AppColors.black),
                  const SizedBox(width: 12),
                  Text(
                    'Select Hotel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You have access to multiple hotels. Please select one.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ...hotels.map(
                (hotel) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hotel.isOwner
                          ? AppColors.primary
                          : AppColors.black,
                      child: Icon(
                        hotel.isOwner ? Icons.star : Icons.hotel,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      hotel.hotelName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      hotel.role.displayName,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.black,
                    ),
                    onTap: () async {
                      AppLogger.info(
                        'Selected hotel: ${hotel.hotelName}',
                        tag: 'Auth',
                      );
                      ref.read(selectedHotelIdProvider.notifier).state =
                          hotel.hotelId;

                      // Register FCM token for push notifications (Owners only)
                      final notificationService = ref.read(
                        notificationServiceProvider,
                      );
                      await notificationService.registerTokenForUser();
                      if (context.mounted) {
                        Navigator.pop(context);
                        // Navigate directly to role-based dashboard
                        final dashboardRoute = _getDashboardRoute(hotel.role);
                        AppLogger.navigation(
                          'Navigating to dashboard: $dashboardRoute',
                        );
                        context.go(dashboardRoute);
                        // Check for updates after successful login
                        _checkForUpdates();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo
                    Image.asset(
                      'assets/new_images/yellow_logo_on_transparent_bg.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hotel Operations Management',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'your@email.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: AppColors.grey100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 16),
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText:
                            '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: AppColors.grey100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.black,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quick Fill - Dev/Test Credentials
                    _buildQuickFillSection(),
                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || _isBiometricLoading
                            ? null
                            : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // Biometric Login Button
                    _buildBiometricLoginButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build biometric login button
  /// Shows fingerprint/face icon based on available biometrics
  /// Only visible when user has enrolled biometrics and stored credentials
  /// Requirements: 2.1, 2.5
  Widget _buildBiometricLoginButton() {
    // Watch the canUseBiometricLogin provider to determine visibility
    final canUseBiometricAsync = ref.watch(canUseBiometricLoginProvider);
    final availableBiometricsAsync = ref.watch(availableBiometricsProvider);

    return canUseBiometricAsync.when(
      data: (canUseBiometric) {
        if (!canUseBiometric) {
          return const SizedBox.shrink();
        }

        // Get the appropriate icon based on available biometrics
        final biometricIcon = availableBiometricsAsync.when(
          data: (biometrics) {
            if (biometrics.contains(BiometricType.face)) {
              return Icons.face;
            } else if (biometrics.contains(BiometricType.fingerprint)) {
              return Icons.fingerprint;
            }
            return Icons.fingerprint;
          },
          loading: () => Icons.fingerprint,
          error: (_, _) => Icons.fingerprint,
        );

        final biometricLabel = availableBiometricsAsync.when(
          data: (biometrics) {
            if (biometrics.contains(BiometricType.face)) {
              return 'Sign in with Face ID';
            }
            return 'Sign in with Fingerprint';
          },
          loading: () => 'Sign in with Biometrics',
          error: (_, _) => 'Sign in with Biometrics',
        );

        return Column(
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isLoading || _isBiometricLoading
                    ? null
                    : _handleBiometricLogin,
                icon: _isBiometricLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.black,
                          ),
                        ),
                      )
                    : Icon(biometricIcon, size: 24),
                label: Text(
                  _isBiometricLoading ? 'Authenticating...' : biometricLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.black, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Quick fill section with test credentials for development
  Widget _buildQuickFillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Login (Dev)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Owner button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _emailController.text = 'thai.adityabharti@gmail.com';
                  _passwordController.text = '123456';
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey100,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.grey300),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Owner',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Manager button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _emailController.text = 'staff@meow.com';
                  _passwordController.text = '123456';
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey100,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.grey300),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Manager',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
        if (_isLoadingEmails) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading test accounts...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ] else if (_testEmails.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Other Accounts - Password: 123456',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _testEmails.map((cred) {
              return InkWell(
                onTap: () {
                  _emailController.text = cred['email']!;
                  _passwordController.text = '123456';
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Text(
                    cred['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
