import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Simplified Login Page - Just email and password
/// After login:
/// - If user has 1 hotel → go directly to dashboard
/// - If user has 2+ hotels → go to hotel selection page
class HotelLoginPage extends ConsumerStatefulWidget {
  const HotelLoginPage({super.key});

  @override
  ConsumerState<HotelLoginPage> createState() => _HotelLoginPageState();
}

class _HotelLoginPageState extends ConsumerState<HotelLoginPage> {
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
    // Dev/test emails - all use password 123456
    // These are hardcoded since Supabase Auth emails aren't directly queryable
    final devEmails = [
      {'email': 'thai.adityabharti@gmail.com', 'label': 'Adi (Owner)'},
    ];

    try {
      // Try to get user names from hotel_staff to show more accounts
      final response = await SupabaseService.instance.client
          .from('hotel_staff')
          .select('user_id, user_profiles!hotel_staff_user_id_fkey(name)')
          .order('created_at');

      final staffEmails = <Map<String, String>>[];
      final seenIds = <String>{};

      for (final row in response) {
        final userId = row['user_id'] as String?;
        final profile = row['user_profiles'] as Map<String, dynamic>?;
        final name = profile?['name'] as String? ?? 'Staff';

        if (userId != null && !seenIds.contains(userId)) {
          seenIds.add(userId);
          // Show name but clicking won't work (no email)
          // The user would need to know their own email
          staffEmails.add({
            'email': '',
            'label': '$name (enter email manually)',
          });
        }
      }

      if (mounted) {
        setState(() {
          _testEmails = devEmails; // Only show dev emails that are clickable
          _isLoadingEmails = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading staff: $e');
      if (mounted) {
        setState(() {
          _testEmails = devEmails;
          _isLoadingEmails = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      debugPrint('🔐 Login attempt for: $email');

      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(email: email, password: password);

      if (!mounted) return;

      debugPrint('✅ Login successful: ${user.name}');

      // Get user's hotels directly from repository
      final hotels = await authRepo.getUserHotels(user.id);

      if (!mounted) return;

      debugPrint('🏨 User has ${hotels.length} hotels');

      // Invalidate provider for fresh data on next read
      ref.invalidate(userHotelsProvider);

      if (hotels.isEmpty) {
        // No hotels - this shouldn't normally happen
        _showError('No hotels found for your account.');
        await authRepo.logout();
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      if (hotels.length == 1) {
        // Single hotel - go directly to dashboard
        final hotel = hotels.first;
        ref.read(selectedHotelIdProvider.notifier).state = hotel.hotelId;

        debugPrint(
          '🚀 Single hotel, navigating to ${hotel.role.displayName} dashboard',
        );

        if (mounted) {
          setState(() => _isLoading = false);
          context.go(_getDashboardRoute(hotel.role));
        }
      } else {
        // Multiple hotels - go to hotel selection page
        debugPrint('🏨 Multiple hotels, navigating to selection page');

        if (mounted) {
          setState(() => _isLoading = false);
          context.go(AppRoutes.hotelSelection);
        }
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _showError('Login failed: ${e.toString().replaceAll('Exception: ', '')}');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
        title: const Text('Login', style: TextStyle(color: AppColors.black)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildLoginForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo/Icon
          Icon(Icons.login, size: 80, color: AppColors.info),
          const SizedBox(height: 24),

          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to access your hotels',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          // Email field
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
                borderSide: BorderSide(color: AppColors.info, width: 2),
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

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 16),
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.info, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
          ),
          const SizedBox(height: 16),

          // Quick Fill Section
          _buildQuickFillSection(),
          const SizedBox(height: 24),

          // Login button
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
