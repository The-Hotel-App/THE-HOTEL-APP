import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

/// Staff Dashboard - Access to rooms and create bookings only, no money details
class StaffDashboardPage extends ConsumerStatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  ConsumerState<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends ConsumerState<StaffDashboardPage> {
  Future<void> _refresh() async {
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
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        title: Row(
          children: [
            Icon(Icons.person, size: 24),
            const SizedBox(width: 8),
            Text(hotel?.hotelName ?? 'Staff Dashboard'),
          ],
        ),
        actions: [
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
              _buildWelcomeCard(user?.name ?? 'Staff'),
              const SizedBox(height: 24),

              // Quick Actions
              _buildSectionTitle('Operations', Icons.work),
              const SizedBox(height: 12),
              _buildOperationsGrid(context),
              const SizedBox(height: 24),

              // Account
              _buildSectionTitle('Account', Icons.person),
              const SizedBox(height: 12),
              _buildAccountGrid(context),
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
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.white,
            child: Icon(Icons.person, color: AppColors.success, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.white,
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
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'STAFF',
                    style: TextStyle(
                      color: AppColors.success,
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

  Widget _buildOperationsGrid(BuildContext context) {
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
      ],
    );
  }

  Widget _buildAccountGrid(BuildContext context) {
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
          icon: Icons.lock,
          label: 'Change Password',
          color: AppColors.grey600,
          onTap: () => context.push(AppRoutes.changePassword),
        ),
        _buildBiometricCard(context),
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

  Widget _buildBiometricCard(BuildContext context) {
    final hasBiometric = ref.watch(userBiometricStatusProvider);

    return InkWell(
      onTap: () => context.push(AppRoutes.biometricSettings),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasBiometric
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.grey600.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              color: hasBiometric ? AppColors.success : AppColors.grey600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              hasBiometric ? 'Biometric On' : 'Biometric Login',
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
