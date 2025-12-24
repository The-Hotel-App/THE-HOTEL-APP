import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/hotel_setup/presentation/providers/setup_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final hotel = ref.watch(currentHotelProvider).valueOrNull;

    // Get role for conditional UI
    final role = currentUser?.role ?? UserRole.staff;
    final isOwner = role == UserRole.owner;
    final isManager = role == UserRole.manager;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/new_images/black_logo_on_yellow_bg_new_fixed_ratio.png',
              height: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hotel?.name ?? 'ROOMS.io',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => _showSignOutConfirmation(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card with Role Badge
            _buildWelcomeCard(context, currentUser),
            const SizedBox(height: 20),

            // Quick Actions - Color coded, large icons for illiterate users
            _buildSectionTitle(context, 'Quick Actions', Icons.flash_on),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context, ref, role),
            const SizedBox(height: 24),

            // Management Section (Owner/Manager only)
            if (isOwner || isManager) ...[
              _buildSectionTitle(
                context,
                'Management',
                Icons.admin_panel_settings,
              ),
              const SizedBox(height: 12),
              _buildManagementGrid(context, ref, role),
              const SizedBox(height: 24),
            ],

            // Owner-only Settings
            if (isOwner) ...[
              _buildSectionTitle(context, 'Settings', Icons.settings),
              const SizedBox(height: 12),
              _buildSettingsGrid(context, ref),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, User? user) {
    final roleColor = _getRoleColor(user?.role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Role Icon with Color
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Icon(_getRoleIcon(user?.role), color: roleColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role.displayName ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.black),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        // ROOMS - Primary action for all roles
        _buildActionCard(
          context,
          icon: Icons.grid_view_rounded,
          label: 'Rooms',
          color: AppColors.black,
          onTap: () => context.push(AppRoutes.rooms),
        ),
      ],
    );
  }

  Widget _buildManagementGrid(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildActionCard(
          context,
          icon: Icons.book_online,
          label: 'Bookings',
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.bookings),
          compact: true,
        ),
        _buildActionCard(
          context,
          icon: Icons.people,
          label: 'Customers',
          color: AppColors.success,
          onTap: () => context.push(AppRoutes.customers),
          compact: true,
        ),
        // Day Book - Owner only (money-related)
        if (role == UserRole.owner)
          _buildActionCard(
            context,
            icon: Icons.menu_book,
            label: 'Day Book',
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.daybook),
            compact: true,
          ),
      ],
    );
  }

  Widget _buildSettingsGrid(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildActionCard(
          context,
          icon: Icons.groups,
          label: 'Staff',
          color: AppColors.grey700,
          onTap: () => context.push(AppRoutes.staff),
          compact: true,
        ),
        _buildActionCard(
          context,
          icon: Icons.business,
          label: 'Hotel',
          color: AppColors.grey700,
          onTap: () => context.push(AppRoutes.hotelSettings),
          compact: true,
        ),
        _buildActionCard(
          context,
          icon: Icons.notifications,
          label: 'Alerts',
          color: AppColors.grey700,
          onTap: () => context.push(AppRoutes.notifications),
          compact: true,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: compact ? 48 : 64,
                height: compact ? 48 : 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: compact ? 28 : 36),
              ),
              SizedBox(height: compact ? 8 : 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.owner:
        return AppColors.black;
      case UserRole.manager:
        return AppColors.info;
      case UserRole.staff:
        return AppColors.success;
      default:
        return AppColors.grey600;
    }
  }

  IconData _getRoleIcon(UserRole? role) {
    switch (role) {
      case UserRole.owner:
        return Icons.admin_panel_settings;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.staff:
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  void _showSignOutConfirmation(BuildContext context, WidgetRef ref) {
    AppDialog.show(
      context: context,
      title: 'Sign Out?',
      content: const Text('Are you sure you want to sign out?'),
      secondaryButtonText: 'Cancel',
      primaryButtonText: 'Sign Out',
      onPrimaryPressed: () async {
        Navigator.of(context).pop();
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.logout();
      },
    );
  }
}
