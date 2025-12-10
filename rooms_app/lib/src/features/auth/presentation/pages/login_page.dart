import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/constants/app_constants.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/hotel_setup/data/repositories/local_hotel_setup_repository.dart';
import 'package:rooms/src/features/hotel_setup/presentation/providers/setup_providers.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      debugPrint('🔑 Password: ${password.replaceAll(RegExp(r'.'), '*')}');

      final authRepo = ref.read(authRepositoryProvider);
      debugPrint('🏪 Auth repository obtained');

      await authRepo.login(email: email, password: password);

      debugPrint('✅ Login successful!');

      if (mounted) {
        debugPrint('🧭 Navigation will be handled by GoRouter redirect');
        setState(() => _isLoading = false);
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

  void _fillDemoCredentials(String role) {
    setState(() {
      switch (role) {
        case 'owner':
          _emailController.text = 'owner@rooms.io';
          _passwordController.text = 'owner123';
          break;
        case 'manager':
          _emailController.text = 'manager@rooms.io';
          _passwordController.text = 'manager123';
          break;
        case 'staff':
          _emailController.text = 'staff@rooms.io';
          _passwordController.text = 'staff123';
          break;
      }
    });
  }

  Future<void> _showHotelSwitcher() async {
    final repo =
        ref.read(hotelSetupRepositoryProvider) as LocalHotelSetupRepository;
    final allHotels = await repo.getAllHotels();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
                  'Switch Hotel',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (allHotels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No other hotels registered',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...allHotels.map(
                (hotel) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.black,
                    child: Icon(Icons.hotel, color: AppColors.white),
                  ),
                  title: Text(hotel.name),
                  subtitle: Text(hotel.address),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(context);
                    await repo.switchHotel(hotel.id);
                    ref.invalidate(currentHotelProvider);
                    ref.invalidate(isSetupCompletedProvider);
                  },
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final router = GoRouter.of(context);

                navigator.pop();
                await repo.clearCurrentHotel();
                ref.invalidate(currentHotelProvider);
                ref.invalidate(isSetupCompletedProvider);

                router.go(AppRoutes.setup);
              },
              icon: Icon(Icons.add),
              label: Text('Add New Hotel'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.black),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotel = ref.watch(currentHotelProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
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
                      hotel?.name ?? AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Hotel Switcher Button
                    if (hotel != null)
                      TextButton.icon(
                        onPressed: _showHotelSwitcher,
                        icon: Icon(Icons.swap_horiz, size: 16),
                        label: Text('Switch Hotel'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.white,
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
                    const SizedBox(height: 32),

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
                    const SizedBox(height: 40),

                    // Demo Credentials Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Test Dummy Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDemoButton(
                                  label: 'Owner',
                                  icon: Icons.admin_panel_settings,
                                  onTap: () => _fillDemoCredentials('owner'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDemoButton(
                                  label: 'Manager',
                                  icon: Icons.manage_accounts,
                                  onTap: () => _fillDemoCredentials('manager'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDemoButton(
                                  label: 'Staff',
                                  icon: Icons.person,
                                  onTap: () => _fillDemoCredentials('staff'),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildDemoButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
