import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// More tab page with role-based menu options
/// Shows different options based on user role (Owner, Manager, Staff)
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotel = ref.watch(currentHotelProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = hotel?.role ?? UserRole.staff;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/new_images/black_logo_on_yellow_bg_new_fixed_ratio.png',
              height: 28,
            ),
            const SizedBox(width: 12),
            const Text('More'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          _buildUserInfoCard(user?.name ?? 'User', role),
          const SizedBox(height: 24),

          // Management Section (Owner only)
          if (role == UserRole.owner) ...[
            _buildSectionTitle('Management'),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              icon: Icons.badge,
              title: 'Staff',
              subtitle: 'Manage hotel staff members',
              color: AppColors.grey700,
              onTap: () => context.push(AppRoutes.staff),
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              icon: Icons.bedroom_parent,
              title: 'Manage Rooms',
              subtitle: 'Add, edit, or remove rooms',
              color: AppColors.grey600,
              onTap: () => context.push(AppRoutes.roomsManagement),
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              icon: Icons.category,
              title: 'Room Types',
              subtitle: 'Manage room categories',
              color: AppColors.grey600,
              onTap: () => context.push(AppRoutes.roomTypes),
            ),
            const SizedBox(height: 24),
          ],

          // Finance Section (Owner and Manager)
          if (role == UserRole.owner || role == UserRole.manager) ...[
            _buildSectionTitle('Finance'),
            const SizedBox(height: 8),
            _buildMenuCard(
              context,
              icon: Icons.receipt_long,
              title: 'Day Book',
              subtitle: 'View daily transactions',
              color: AppColors.success,
              onTap: () => context.push(AppRoutes.daybook),
            ),
            const SizedBox(height: 24),
          ],

          // Settings Section (All roles)
          _buildSectionTitle('Settings'),
          const SizedBox(height: 8),
          if (role == UserRole.owner)
            _buildMenuCard(
              context,
              icon: Icons.business,
              title: 'Hotel Settings',
              subtitle: 'Configure hotel details',
              color: AppColors.info,
              onTap: () => context.push(AppRoutes.hotelSettings),
            ),
          if (role == UserRole.owner) const SizedBox(height: 8),
          _buildMenuCard(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage alert preferences',
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(height: 8),
          _buildMenuCard(
            context,
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            color: AppColors.grey500,
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          const SizedBox(height: 24),

          // Logout Section
          _buildSectionTitle('Account'),
          const SizedBox(height: 8),
          _buildMenuCard(
            context,
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            color: AppColors.error,
            onTap: () => _showLogoutConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(String name, UserRole role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.grey100,
            child: Icon(_getRoleIcon(role), color: AppColors.grey800, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role.name.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.grey500),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    AppDialog.show(
      context: context,
      title: 'Logout',
      content: const Text('Are you sure you want to logout?'),
      primaryButtonText: 'Logout',
      onPrimaryPressed: () async {
        Navigator.pop(context); // Close dialog

        // IMPORTANT: Navigate to welcome FIRST before any state changes
        // This prevents the MainShell from re-rendering with different hotel
        if (context.mounted) {
          context.go(AppRoutes.welcome);
        }

        // Now clear state after navigation has started
        // Use Future.delayed to ensure navigation is in progress
        await Future.delayed(const Duration(milliseconds: 100));

        // Clear hotel selection
        ref.read(selectedHotelIdProvider.notifier).state = null;

        // Perform logout
        await ref.read(authRepositoryProvider).logout();
      },
      secondaryButtonText: 'Cancel',
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return AppColors.grey800;
      case UserRole.manager:
        return AppColors.info;
      case UserRole.staff:
        return AppColors.success;
      case UserRole.kitchenManager:
        return AppColors.warning;
    }
  }
}
