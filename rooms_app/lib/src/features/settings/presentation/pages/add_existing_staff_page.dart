import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Add Existing Staff Page - Owner can add an existing user to their hotel
/// This is used when a user already exists in the system (e.g., owner of another hotel)
class AddExistingStaffPage extends ConsumerStatefulWidget {
  const AddExistingStaffPage({super.key});

  @override
  ConsumerState<AddExistingStaffPage> createState() =>
      _AddExistingStaffPageState();
}

class _AddExistingStaffPageState extends ConsumerState<AddExistingStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  bool _isSearching = false;
  bool _isAdding = false;
  String? _searchError;
  Map<String, dynamic>? _foundUser;

  @override
  void dispose() {
    _emailController.dispose();
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
            Icon(Icons.person_add_alt_1, size: 24),
            SizedBox(width: 8),
            Text('Add Existing User'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              _buildInfoCard(),
              const SizedBox(height: 24),
              // Search Card
              _buildSearchCard(),
              // Found User Card (shown after search)
              if (_foundUser != null) ...[
                const SizedBox(height: 16),
                _buildFoundUserCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use this to add someone who already has an account in the system. '
              'For new users, go back and select "Create New Account".',
              style: TextStyle(
                color: AppColors.grey700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
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
          // Section Title
          _buildSectionTitle('Search by Email', Icons.search),
          const SizedBox(height: 16),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _searchUser(),
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Enter email address';
              if (!v!.contains('@')) return 'Enter a valid email';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email),
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
          ),
          const SizedBox(height: 16),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchUser,
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Searching...' : 'Search User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey800,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Error message
          if (_searchError != null) ...[
            const SizedBox(height: 12),
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
                      _searchError!,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoundUserCard() {
    final user = _foundUser!;
    final userName = user['name'] as String? ?? 'Unknown';
    final userEmail = _emailController.text.trim();

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
          // Section Title
          _buildSectionTitle('User Found', Icons.check_circle_outline),
          const SizedBox(height: 16),

          // User Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Role Selection
          _buildSectionTitle('Assign Role', Icons.badge),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          const SizedBox(height: 24),

          // Add Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isAdding ? null : _addUserToHotel,
              icon: _isAdding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_isAdding ? 'Adding...' : 'Add to Hotel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
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

  Widget _buildRoleSelector() {
    final roles = [
      UserRole.owner,
      UserRole.manager,
      UserRole.staff,
      UserRole.kitchenManager,
    ];

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
              border: Border.all(color: Colors.black),
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

  Future<void> _searchUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _foundUser = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final currentHotel = ref.read(currentHotelProvider);
      final currentUserId =
          SupabaseService.instance.client.auth.currentUser?.id;

      if (currentHotel == null) {
        throw Exception('No hotel selected');
      }

      AppLogger.debug('Searching for user with email: $email', tag: 'Staff');

      // Call the RPC function to search for user by email
      final response = await SupabaseService.instance.client.rpc(
        'find_user_by_email',
        params: {
          'p_email': email,
          'p_hotel_id': currentHotel.hotelId,
          'p_requester_id': currentUserId,
        },
      );

      AppLogger.debug('Search response: $response', tag: 'Staff');

      if (response == null) {
        throw Exception('No user found with this email');
      }

      final result = response as Map<String, dynamic>;

      if (result['error'] != null) {
        throw Exception(result['error']);
      }

      if (!result['found']) {
        throw Exception('No user found with this email');
      }

      if (result['already_staff'] == true) {
        throw Exception('This user is already a staff member of this hotel');
      }

      setState(() {
        _foundUser = result;
        _isSearching = false;
      });

      AppLogger.success('Found user: ${result['name']}', tag: 'Staff');
    } catch (e) {
      AppLogger.error('Search error', tag: 'Staff', error: e);
      setState(() {
        _searchError = e.toString().replaceFirst('Exception: ', '');
        _isSearching = false;
      });
    }
  }

  Future<void> _addUserToHotel() async {
    if (_foundUser == null) return;

    setState(() => _isAdding = true);

    try {
      final currentHotel = ref.read(currentHotelProvider);
      final currentUserId =
          SupabaseService.instance.client.auth.currentUser?.id;

      if (currentHotel == null) {
        throw Exception('No hotel selected');
      }

      if (currentUserId == null) {
        throw Exception('Not logged in');
      }

      final userId = _foundUser!['user_id'] as String;

      AppLogger.info(
        'Adding user $userId to hotel ${currentHotel.hotelId} with role ${_selectedRole.dbValue}',
        tag: 'Staff',
      );

      // Use the existing RPC function to add staff
      await SupabaseService.instance.client.rpc(
        'add_staff_to_hotel',
        params: {
          'p_hotel_id': currentHotel.hotelId,
          'p_user_id': userId,
          'p_role': _selectedRole.dbValue,
          'p_created_by': currentUserId,
        },
      );

      AppLogger.success('User added to hotel successfully', tag: 'Staff');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_foundUser!['name']} added as ${_selectedRole.displayName}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Error adding user to hotel', tag: 'Staff', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}
