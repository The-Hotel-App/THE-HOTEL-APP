import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Create Staff Page - Owner can create manager/staff/kitchen_manager accounts
class CreateStaffPage extends ConsumerStatefulWidget {
  const CreateStaffPage({super.key});

  @override
  ConsumerState<CreateStaffPage> createState() => _CreateStaffPageState();
}

class _CreateStaffPageState extends ConsumerState<CreateStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.person_add, size: 24),
            SizedBox(width: 8),
            Text('Create Staff Account'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 24), _buildFormCard()],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Staff Details', Icons.person),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: (v) => v?.isEmpty ?? true ? 'Enter staff name' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number (Optional)',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Login Credentials', Icons.lock),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Enter email address';
              if (!v!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),

          _buildSectionTitle('Role Assignment', Icons.badge),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          const SizedBox(height: 24),

          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (v) {
        if (v?.isEmpty ?? true) return 'Enter password';
        if (v!.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
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
    );
  }

  Widget _buildRoleSelector() {
    final roles = [UserRole.manager, UserRole.staff, UserRole.kitchenManager];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final isSelected = _selectedRole == role;
        return InkWell(
          onTap: () => setState(() => _selectedRole = role),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.black : AppColors.grey300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(role),
                  size: 18,
                  color: isSelected ? AppColors.white : AppColors.grey600,
                ),
                const SizedBox(width: 8),
                Text(
                  role.displayName,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.staff:
        return Icons.person;
      case UserRole.kitchenManager:
        return Icons.restaurant;
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleCreateStaff,
        icon: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add),
        label: Text(_isLoading ? 'Creating...' : 'Create Staff Account'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _handleCreateStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final currentHotel = ref.read(currentHotelProvider);

      if (currentHotel == null) {
        throw Exception('No hotel selected');
      }

      await authRepo.createStaffAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedRole,
        hotelId: currentHotel.hotelId,
      );

      if (mounted) {
      // Invalidate providers to refresh with owner's data
      ref.invalidate(currentUserProvider);
      ref.invalidate(userHotelsProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedRole.displayName} account created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
