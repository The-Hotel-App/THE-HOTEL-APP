import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

/// Welcome screen - Tabbed login page with Credentials and Fingerprint options
/// Similar to HDFC Bank app design
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricLoading = false;

  late TabController _tabController;
  bool _hasStoredCredentials = false;
  bool _isCheckingCredentials = true;

  // Hardcoded test accounts for development
  static const List<Map<String, String>> _testAccounts = [
    {'email': 'owner@rooms.io', 'label': 'Owner', 'password': '123456'},
    {'email': 'manager@rooms.io', 'label': 'Manager', 'password': '123456'},
    {'email': 'staff@rooms.io', 'label': 'Staff', 'password': '123456'},
    {'email': 'kitchen@rooms.io', 'label': 'Kitchen', 'password': '123456'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkStoredCredentials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkStoredCredentials() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);
      final hasCredentials = await biometricService.hasStoredCredentials();
      if (mounted) {
        setState(() {
          _hasStoredCredentials = hasCredentials;
          _isCheckingCredentials = false;
        });
      }
    } catch (e) {
      AppLogger.error(
        'Error checking stored credentials',
        tag: 'WelcomeScreen',
        error: e,
      );
      if (mounted) {
        setState(() {
          _hasStoredCredentials = false;
          _isCheckingCredentials = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      AppLogger.success('Login successful for: ${user.email}', tag: 'Auth');

      final hotels = await authRepo.getUserHotels(user.id);

      if (!mounted) return;

      AppLogger.info('User has ${hotels.length} hotels', tag: 'Auth');

      ref.invalidate(userHotelsProvider);

      if (hotels.isEmpty) {
        _showError('No hotels found for your account.');
        await authRepo.logout();
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      setState(() => _isLoading = false);

      // Check if biometric is not already set up - prompt to enable
      if (!_hasStoredCredentials && mounted) {
        await _promptBiometricSetup(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      // Navigate to hotel selection page
      AppLogger.navigation('Navigating to hotel selection');
      if (mounted) {
        context.go(AppRoutes.hotelSelection);
      }
    } catch (e) {
      AppLogger.error('Login failed', tag: 'Auth', error: e);
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _promptBiometricSetup(String email, String password) async {
    // Check if device supports biometrics
    final biometricService = ref.read(biometricServiceProvider);
    final isSupported = await biometricService.isDeviceSupported();
    final isEnrolled = await biometricService.areBiometricsEnrolled();

    if (!isSupported || !isEnrolled) {
      AppLogger.info(
        'Device does not support biometrics or none enrolled',
        tag: 'Auth',
      );
      return;
    }

    if (!mounted) return;

    // Show prompt dialog
    final shouldEnable = await CustomDialog.showConfirmation(
      context: context,
      title: 'Enable Fingerprint Login?',
      message:
          'Would you like to enable fingerprint login for faster access next time?',
      confirmText: 'Enable',
      cancelText: 'Maybe Later',
      icon: Icons.fingerprint,
    );

    if (shouldEnable != true || !mounted) return;

    // Try to authenticate and store credentials
    try {
      final authenticated = await biometricService.authenticate(
        reason: 'Verify your fingerprint to enable quick login',
        biometricOnly: false,
      );

      if (!authenticated) {
        _showError('Fingerprint verification failed');
        return;
      }

      // Store credentials
      await biometricService.storeCredentials(email: email, password: password);

      // Update user profile
      final authRepo = ref.read(authRepositoryProvider);
      final user = await ref.read(currentUserProvider.future);
      if (user != null) {
        await authRepo.updateBiometricStatus(
          userId: user.id,
          hasBiometric: true,
        );
        // Refresh the user provider
        ref.invalidate(currentUserProvider);
      }

      setState(() => _hasStoredCredentials = true);

      AppLogger.success('Biometric login enabled', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Failed to enable biometric', tag: 'Auth', error: e);
      // Silent fail - user can enable later
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isBiometricLoading) return;

    // Check if credentials are stored
    if (!_hasStoredCredentials) {
      _showSetupRequiredDialog();
      return;
    }

    setState(() => _isBiometricLoading = true);

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // First authenticate with device biometric
      final authenticated = await biometricService.authenticate(
        reason: 'Login to ROOMS.io',
        biometricOnly: false,
      );

      if (!authenticated) {
        AppLogger.warning('Biometric authentication failed', tag: 'Auth');
        if (mounted) {
          setState(() => _isBiometricLoading = false);
          _showError('Fingerprint verification failed');
        }
        return;
      }

      // Get stored credentials
      final credentials = await biometricService.getStoredCredentials();
      if (credentials == null) {
        AppLogger.warning('No stored credentials found', tag: 'Auth');
        if (mounted) {
          setState(() {
            _isBiometricLoading = false;
            _hasStoredCredentials = false;
          });
          _showSetupRequiredDialog();
        }
        return;
      }

      // Login with stored credentials
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(
        email: credentials.email,
        password: credentials.password,
      );

      if (!mounted) return;

      AppLogger.success(
        'Biometric login successful for: ${user.email}',
        tag: 'Auth',
      );

      final hotels = await authRepo.getUserHotels(user.id);

      if (!mounted) return;

      ref.invalidate(userHotelsProvider);

      if (hotels.isEmpty) {
        _showError('No hotels found for your account.');
        await authRepo.logout();
        if (mounted) {
          setState(() => _isBiometricLoading = false);
        }
        return;
      }

      if (mounted) {
        setState(() => _isBiometricLoading = false);
        context.go(AppRoutes.hotelSelection);
      }
    } catch (e) {
      AppLogger.error('Biometric login failed', tag: 'Auth', error: e);
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  void _showSetupRequiredDialog() {
    CustomDialog.showInfo(
      context: context,
      title: 'Setup Required',
      message:
          'Please login with email and password first, then enable biometric login in your account settings.',
      icon: Icons.fingerprint,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.navigation('Building WelcomeScreen');

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and title
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Tab bar
                  _buildTabBar(),
                  const SizedBox(height: 24),

                  // Tab content
                  _buildTabContent(),

                  const SizedBox(height: 24),

                  // Sign Up link
                  _buildSignUpLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/new_images/yellow_logo_on_transparent_bg.png',
          height: 100,
          width: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.hotel, size: 100, color: AppColors.warning),
        ),
        const SizedBox(height: 16),
        Text(
          'ROOMS.io',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hotel Operations Management',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.grey400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.info,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.grey400,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, size: 18),
                SizedBox(width: 8),
                Text('Credentials'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fingerprint, size: 18),
                SizedBox(width: 8),
                Text('Fingerprint'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return IndexedStack(
          index: _tabController.index,
          children: [_buildCredentialsTab(), _buildFingerprintTab()],
        );
      },
    );
  }

  Widget _buildCredentialsTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 16, color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: const TextStyle(color: AppColors.grey400),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppColors.grey400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey600),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey600),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.info, width: 2),
              ),
              filled: true,
              fillColor: AppColors.grey900,
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
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16, color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: AppColors.grey400),
              prefixIcon: const Icon(
                Icons.lock_outlined,
                color: AppColors.grey400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey600),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.grey600),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.info, width: 2),
              ),
              filled: true,
              fillColor: AppColors.grey900,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.grey400,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
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
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 16),
          _buildQuickFillSection(),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
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
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFingerprintTab() {
    if (_isCheckingCredentials) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: AppColors.white)),
      );
    }

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fingerprint icon
            GestureDetector(
              onTap: _hasStoredCredentials && !_isBiometricLoading
                  ? _handleBiometricLogin
                  : !_hasStoredCredentials
                  ? () =>
                        _tabController.animateTo(0) // Switch to credentials tab
                  : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _hasStoredCredentials
                      ? AppColors.info.withValues(alpha: 0.15)
                      : AppColors.grey800,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _hasStoredCredentials
                        ? AppColors.info
                        : AppColors.grey600,
                    width: 2,
                  ),
                ),
                child: _isBiometricLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.info,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.fingerprint,
                        size: 40,
                        color: _hasStoredCredentials
                            ? AppColors.info
                            : AppColors.grey500,
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Status text
            GestureDetector(
              onTap: !_hasStoredCredentials
                  ? () => _tabController.animateTo(0)
                  : null,
              child: Text(
                _hasStoredCredentials ? 'Tap to login' : 'Not set up',
                style: TextStyle(
                  color: _hasStoredCredentials
                      ? AppColors.info
                      : AppColors.grey400,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Additional content based on state
            if (_hasStoredCredentials) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: _isBiometricLoading ? null : _handleResetFingerprint,
                child: Text(
                  'Reset',
                  style: TextStyle(color: AppColors.grey400, fontSize: 13),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _tabController.animateTo(0),
                child: Text(
                  'Tap to login with credentials',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.info,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleResetFingerprint() async {
    // Show confirmation dialog
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Reset Fingerprint',
      message:
          'To reset your fingerprint, you need to verify with your current '
          'fingerprint first, then login with your password to set up again.',
      confirmText: 'Continue',
      cancelText: 'Cancel',
      icon: Icons.refresh,
    );

    if (confirmed != true) return;

    setState(() => _isBiometricLoading = true);

    try {
      // Verify with current biometric
      final biometricService = ref.read(biometricServiceProvider);
      final authenticated = await biometricService.authenticate(
        reason: 'Verify your identity to reset fingerprint',
        biometricOnly: true,
      );

      if (!authenticated) {
        _showError('Verification failed. Please try again.');
        return;
      }

      // Clear stored credentials
      await biometricService.clearCredentials();

      AppLogger.info('Fingerprint reset - credentials cleared', tag: 'Auth');

      // Update state
      setState(() {
        _hasStoredCredentials = false;
      });

      // Show success and switch to credentials tab
      if (mounted) {
        _tabController.animateTo(0);
        CustomDialog.showInfo(
          context: context,
          title: 'Fingerprint Reset',
          message:
              'Your fingerprint has been reset. Please login with your '
              'email and password, then enable biometric login in your account settings.',
          icon: Icons.check_circle_outline,
        );
      }
    } catch (e) {
      AppLogger.error('Error resetting fingerprint', tag: 'Auth', error: e);
      _showError('Failed to reset fingerprint. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  Widget _buildQuickFillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Login (Test Accounts)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _testAccounts.map((account) {
            return InkWell(
              onTap: () {
                _emailController.text = account['email']!;
                _passwordController.text = account['password']!;
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grey600),
                ),
                child: Text(
                  account['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: AppColors.grey400),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.signup),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
