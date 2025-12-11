import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Join Hotel Page - Journey 3: Join a Hotel (New Employee)
/// Step 1: Enter hotel code + join code
/// Step 2: Create account details
/// Step 3: Register fingerprint (placeholder)
/// Step 4: Wait for approval
class JoinHotelPage extends ConsumerStatefulWidget {
  const JoinHotelPage({super.key});

  @override
  ConsumerState<JoinHotelPage> createState() => _JoinHotelPageState();
}

class _JoinHotelPageState extends ConsumerState<JoinHotelPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Codes
  final _hotelCodeController = TextEditingController();
  final _joinCodeController = TextEditingController();
  String? _hotelId;
  String? _hotelName;
  String? _joinCodeId;

  // Step 2: Account details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _hotelCodeController.dispose();
    _joinCodeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  Future<void> _verifyCodes() async {
    final hotelCode = _hotelCodeController.text.trim().toLowerCase();
    final joinCode = _joinCodeController.text.trim();

    if (hotelCode.isEmpty || joinCode.isEmpty) {
      _showError('Please enter both hotel code and join code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.validateJoinCode(hotelCode, joinCode);

      if (result['is_valid'] == true) {
        setState(() {
          _hotelId = result['hotel_id'] as String?;
          _hotelName = result['hotel_name'] as String?;
          _joinCodeId = result['join_code_id'] as String?;
          _isLoading = false;
        });
        _nextStep();
      } else {
        _showError(result['error_message'] as String? ?? 'Invalid codes');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error verifying codes: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAccountAndSubmitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate email or phone
    if (_emailController.text.trim().isEmpty &&
        _phoneController.text.trim().isEmpty) {
      _showError('Please provide either email or phone number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      // Create user account
      await authRepo.register(
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : '${DateTime.now().millisecondsSinceEpoch}@temp.rooms.io',
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      // Submit join request
      await authRepo.submitJoinRequest(
        hotelId: _hotelId!,
        joinCodeId: _joinCodeId,
      );

      if (!mounted) return;

      // Go to waiting screen
      _nextStep();
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Failed to create account: ${e.toString()}');
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
          onPressed: _previousStep,
          tooltip: 'Back',
        ),
        title: Text(
          _getStepTitle(),
          style: const TextStyle(color: AppColors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  _buildCodesStep(),
                  _buildAccountStep(),
                  _buildWaitingStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter Codes';
      case 1:
        return 'Create Account';
      case 2:
        return 'Request Sent';
      default:
        return 'Join a Hotel';
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= _currentStep
                      ? AppColors.warning
                      : AppColors.grey300,
                ),
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= _currentStep
                    ? AppColors.warning
                    : AppColors.grey300,
              ),
              child: Center(
                child: i < _currentStep
                    ? const Icon(Icons.check, color: AppColors.black, size: 18)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i <= _currentStep
                              ? AppColors.black
                              : AppColors.grey500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.qr_code_2, size: 80, color: AppColors.warning),
          const SizedBox(height: 24),
          Text(
            'Get Codes From Manager',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask your manager for the hotel code and join code',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Hotel Code
          TextFormField(
            controller: _hotelCodeController,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              labelText: 'Hotel Code',
              hintText: 'e.g., taj-chennai',
              prefixIcon: const Icon(Icons.business),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Join Code
          TextFormField(
            controller: _joinCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Join Code',
              hintText: 'e.g., HOTEL2024',
              prefixIcon: const Icon(Icons.key),
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyCodes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hotel info
            if (_hotelName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Text(
                      'Joining: $_hotelName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Your Name *',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email (optional)',
                helperText: 'Provide email OR phone',
                prefixIcon: const Icon(Icons.email),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone (optional)',
                helperText: 'Provide email OR phone',
                prefixIcon: const Icon(Icons.phone),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAccountAndSubmitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Create Account & Request to Join',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty,
              size: 80,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Request Sent!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Your manager will assign your role and approve your request shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            "You'll get a notification when approved.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.welcome),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                side: const BorderSide(color: AppColors.black, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
