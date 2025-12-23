import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/constants/app_constants.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

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
      debugPrint('Error loading test emails: $e');
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

  Future<void> _handleLogin() async {
    debugPrint('🔐 Login attempt started');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    debugPrint('✅ Form validated');
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      debugPrint('📧 Email: $email');

      final authRepo = ref.read(authRepositoryProvider);
      debugPrint('🏪 Auth repository obtained');

      await authRepo.login(email: email, password: password);

      debugPrint('✅ Login successful!');

      if (!mounted) return;

      // Get user's hotels before any navigation
      final hotels = await ref.read(userHotelsProvider.future);

      debugPrint('🏨 User has ${hotels.length} hotel(s)');

      if (!mounted) return;

      if (hotels.isEmpty) {
        // User has no hotels - let router handle redirect to setup
        debugPrint('⚠️  User has no hotels, router will redirect to setup');
        setState(() => _isLoading = false);
        // Invalidate auth providers to trigger router refresh
        ref.invalidate(currentUserProvider);
        return;
      }

      if (hotels.length == 1) {
        // Auto-select the only hotel
        debugPrint('✅ Auto-selecting single hotel: ${hotels.first.hotelName}');
        ref.read(selectedHotelIdProvider.notifier).state = hotels.first.hotelId;

        // Register FCM token for push notifications (Owners only)
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.registerTokenForUser();

        // Get the dashboard route before any async operations
        final dashboardRoute = _getDashboardRoute(hotels.first.role);
        debugPrint('🚀 Navigating to dashboard: $dashboardRoute');

        // Small delay to ensure provider state propagates
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate first, then clear loading state
        // This prevents the router refresh from interfering with navigation
        if (mounted) {
          context.go(dashboardRoute);
          // Clear loading after navigation is initiated
          if (mounted) setState(() => _isLoading = false);
        }
        return;
      }

      // Multiple hotels - show selector
      debugPrint('🏨 Multiple hotels, showing selector');
      setState(() => _isLoading = false);
      if (mounted) {
        await _showHotelSelector(hotels);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Login failed with error: $e');
      debugPrint('📍 Stack trace: $stackTrace');

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
                      debugPrint('🏨 Selected hotel: ${hotel.hotelName}');
                      ref.read(selectedHotelIdProvider.notifier).state =
                          hotel.hotelId;

                      // Register FCM token for push notifications (Owners only)
                      final notificationService = ref.read(
                        notificationServiceProvider,
                      );
                      await notificationService.registerTokenForUser();

                      Navigator.pop(context);
                      // Navigate directly to role-based dashboard
                      final dashboardRoute = _getDashboardRoute(hotel.role);
                      debugPrint('🚀 Navigating to dashboard: $dashboardRoute');
                      context.go(dashboardRoute);
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
          onPressed: () => context.go(AppRoutes.welcome),
          tooltip: 'Back to Welcome',
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
                        onPressed: _isLoading ? null : _handleLogin,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Quick fill section with test credentials for development
  Widget _buildQuickFillSection() {
    if (_isLoadingEmails) {
      return Row(
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
      );
    }

    if (_testEmails.isEmpty) {
      return Text(
        'No test accounts found',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Fill (Dev) - Password: 123456',
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
    );
  }
}
