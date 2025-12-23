import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/core/widgets/hotel_switcher_button.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Owner Dashboard - Full access to all hotel features
class OwnerDashboardPage extends ConsumerStatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  ConsumerState<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends ConsumerState<OwnerDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Register FCM token after dashboard is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationsForOwner();
    });
  }

  /// Initialize notifications and register FCM token for the owner
  Future<void> _initNotificationsForOwner() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);

      // Check if permission is granted, if not request again
      if (!await notificationService.hasPermission) {
        if (mounted) {
          await notificationService.requestPermissionAgain(context);
        }
      }

      // Register FCM token for this owner's hotels
      await notificationService.registerTokenForUser();
    } catch (e) {
      debugPrint('❌ Error initializing notifications for owner: $e');
    }
  }

  Future<void> _refresh() async {
    // Invalidate providers to force refresh from database
    ref.invalidate(currentUserProvider);
    ref.invalidate(userHotelsProvider);
    ref.invalidate(userHotelsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    await AppDialog.show(
      context: context,
      title: 'Logout',
      content: const Text('Are you sure you want to logout?'),
      primaryButtonText: 'Logout',
      onPrimaryPressed: () async {
        Navigator.pop(context); // Close dialog
        await ref.read(authRepositoryProvider).logout();
        if (context.mounted) context.go(AppRoutes.welcome);
      },
      secondaryButtonText: 'Cancel',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotel = ref.watch(currentHotelProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hotel?.hotelName ?? 'Owner Dashboard',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Hotel switcher for users with multiple hotels
          const HotelSwitcherButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeCard(user?.name ?? 'Owner'),

              const SizedBox(height: 24),

              // Quick Actions
              _buildSectionTitle('Quick Actions', Icons.flash_on),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(context),
              const SizedBox(height: 24),

              // Management
              _buildSectionTitle('Management', Icons.settings),
              const SizedBox(height: 12),
              _buildManagementGrid(context),
              const SizedBox(height: 24),

              // Settings
              _buildSectionTitle('Settings', Icons.tune),
              const SizedBox(height: 12),
              _buildSettingsGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300, width: 1),
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
            radius: 30,
            backgroundColor: AppColors.grey100,
            child: Icon(
              Icons.admin_panel_settings,
              color: AppColors.grey800,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
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
                    color: AppColors.grey800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OWNER',
                    style: TextStyle(
                      color: AppColors.white,
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

  Widget _buildSectionTitle(String title, IconData icon) {
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

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.grid_view,
          label: 'View Rooms',
          color: AppColors.roomFree,
          onTap: () => context.push(AppRoutes.rooms),
        ),
        _buildActionCard(
          context,
          icon: Icons.book_online,
          label: 'Create Booking',
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.bookingSearch),
        ),
        _buildActionCard(
          context,
          icon: Icons.people,
          label: 'Customers',
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.customers),
        ),
        _buildActionCard(
          context,
          icon: Icons.receipt_long,
          label: 'Day Book',
          color: AppColors.success,
          onTap: () => context.push(AppRoutes.daybook),
        ),
      ],
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.bedroom_parent,
          label: 'Manage Rooms',
          color: AppColors.grey700,
          onTap: () => context.push(AppRoutes.roomsManagement),
        ),
        _buildActionCard(
          context,
          icon: Icons.category,
          label: 'Room Types',
          color: AppColors.grey600,
          onTap: () => context.push(AppRoutes.roomTypes),
        ),
        _buildActionCard(
          context,
          icon: Icons.badge,
          label: 'Staff',
          color: AppColors.grey700,
          onTap: () => context.push(AppRoutes.staff),
        ),
        _buildActionCard(
          context,
          icon: Icons.person_add,
          label: 'Add Staff',
          color: AppColors.grey600,
          onTap: () => context.push(AppRoutes.createStaff),
        ),
      ],
    );
  }

  Widget _buildSettingsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.hotel,
          label: 'Hotel Settings',
          color: AppColors.grey500,
          onTap: () => context.push(AppRoutes.hotelSettings),
        ),
        _buildActionCard(
          context,
          icon: Icons.lock,
          label: 'Change Password',
          color: AppColors.grey500,
          onTap: () => context.push(AppRoutes.changePassword),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
