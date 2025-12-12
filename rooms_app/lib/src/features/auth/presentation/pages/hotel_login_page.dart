import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hotel Login Page - Journey 2: Login to Hotel
/// Step 1: Enter hotel code
/// Step 2: Enter credentials (email/phone + password) or use fingerprint
class HotelLoginPage extends ConsumerStatefulWidget {
  const HotelLoginPage({super.key});

  @override
  ConsumerState<HotelLoginPage> createState() => _HotelLoginPageState();
}

class _HotelLoginPageState extends ConsumerState<HotelLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _hotelCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hotelCodeVerified = false;
  String? _hotelName;
  String? _hotelId;

  @override
  void initState() {
    super.initState();
    _loadLastHotelCode();
  }

  Future<void> _loadLastHotelCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCode = prefs.getString('last_hotel_code');
      if (lastCode != null && lastCode.isNotEmpty) {
        _hotelCodeController.text = lastCode;
      }
    } catch (e) {
      debugPrint('Error loading last hotel code: $e');
    }
  }

  Future<void> _saveLastHotelCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_hotel_code', code);
    } catch (e) {
      debugPrint('Error saving last hotel code: $e');
    }
  }

  @override
  void dispose() {
    _hotelCodeController.dispose();
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

  Future<void> _verifyHotelCode() async {
    final code = _hotelCodeController.text.trim().toLowerCase();
    if (code.isEmpty) {
      _showError('Please enter a hotel code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final hotel = await authRepo.getHotelByCode(code);

      if (hotel != null) {
        await _saveLastHotelCode(code);
        setState(() {
          _hotelCodeVerified = true;
          _hotelName = hotel['name'] as String?;
          _hotelId = hotel['id'] as String?;
          _isLoading = false;
        });
      } else {
        _showError('Hotel code not found. Please check and try again.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error verifying hotel code: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.login(email: email, password: password);

      if (!mounted) return;

      debugPrint('✅ Login successful: ${user.name}');
      debugPrint('👤 User ID: ${user.id}');
      debugPrint('🏨 Looking for hotel ID: $_hotelId');

      // Get user's hotels
      final hotels = await ref.read(userHotelsProvider.future);

      if (!mounted) return;

      debugPrint('📋 User has access to ${hotels.length} hotels:');
      for (final h in hotels) {
        debugPrint('   - ${h.hotelName} (${h.hotelId}) - role: ${h.role.displayName}, isOwner: ${h.isOwner}');
      }

      // Find the hotel matching our hotel code
      final matchingHotel = hotels.where((h) => h.hotelId == _hotelId).toList();

      if (matchingHotel.isEmpty) {
        debugPrint('❌ No matching hotel found! User does not have access to $_hotelId');
        _showError('You do not have access to this hotel.');
        await authRepo.logout();
        setState(() => _isLoading = false);
        return;
      }

      // Set the selected hotel
      ref.read(selectedHotelIdProvider.notifier).state = _hotelId;

      final role = matchingHotel.first.role;
      debugPrint('✅ Access granted with role: ${role.displayName}');
      final dashboardRoute = _getDashboardRoute(role);

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        context.go(dashboardRoute);
      }
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
      setState(() => _isLoading = false);
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
          onPressed: () {
            if (_hotelCodeVerified) {
              setState(() {
                _hotelCodeVerified = false;
                _hotelName = null;
                _hotelId = null;
              });
            } else {
              context.go(AppRoutes.welcome);
            }
          },
          tooltip: 'Back',
        ),
        title: Text(
          _hotelCodeVerified ? 'Login' : 'Enter Hotel Code',
          style: const TextStyle(color: AppColors.black),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _hotelCodeVerified
                  ? _buildLoginForm()
                  : _buildHotelCodeForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotelCodeForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.business, size: 80, color: AppColors.info),
        const SizedBox(height: 24),
        Text(
          'Enter Hotel Code',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the hotel code provided by your employer',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _hotelCodeController,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          style: const TextStyle(fontSize: 18, letterSpacing: 1),
          decoration: InputDecoration(
            labelText: 'Hotel Code',
            hintText: 'e.g., taj-chennai',
            prefixIcon: const Icon(Icons.qr_code),
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
          onFieldSubmitted: (_) => _verifyHotelCode(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyHotelCode,
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
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hotel info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: AppColors.info, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hotelName ?? 'Hotel',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _hotelCodeController.text.trim(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _hotelCodeVerified = false;
                      _hotelName = null;
                      _hotelId = null;
                    });
                  },
                  tooltip: 'Change hotel',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

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
                borderSide: const BorderSide(color: AppColors.black, width: 2),
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
                borderSide: const BorderSide(color: AppColors.black, width: 2),
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
          const SizedBox(height: 32),

          // Login button
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
    );
  }
}
