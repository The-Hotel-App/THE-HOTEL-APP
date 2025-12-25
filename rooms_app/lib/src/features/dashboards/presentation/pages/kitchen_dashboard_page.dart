import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/app_update_service.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/core/widgets/update_dialog.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

/// Kitchen Manager Dashboard - Food orders only, no access to rooms/bookings/customers
class KitchenDashboardPage extends ConsumerStatefulWidget {
  const KitchenDashboardPage({super.key});

  @override
  ConsumerState<KitchenDashboardPage> createState() =>
      _KitchenDashboardPageState();
}

class _KitchenDashboardPageState extends ConsumerState<KitchenDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    AppLogger.info(
      '>>> Kitchen Dashboard _checkForUpdates() CALLED',
      tag: 'Update',
    );
    try {
      final updateInfo = await AppUpdateService.checkForUpdate();
      if (updateInfo != null && mounted) {
        UpdateDialog.show(context, updateInfo);
      }
    } catch (e) {
      AppLogger.warning('Update check error: $e', tag: 'Update');
    }
  }

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
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.black,
        title: Row(
          children: [
            Icon(Icons.restaurant, size: 24),
            const SizedBox(width: 8),
            Text(hotel?.hotelName ?? 'Kitchen Dashboard'),
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
              _buildWelcomeCard(user?.name ?? 'Kitchen Manager'),
              const SizedBox(height: 24),

              // Food Orders section
              _buildSectionTitle('Food Orders', Icons.restaurant_menu),
              const SizedBox(height: 12),
              _buildOrdersSection(),
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
          colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.black,
            child: Icon(Icons.restaurant, color: AppColors.warning, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.black,
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
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'KITCHEN MANAGER',
                    style: TextStyle(
                      color: AppColors.warning,
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

  Widget _buildOrdersSection() {
    // Placeholder for food orders - will be implemented later
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No Pending Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Food orders from guests will appear here',
            style: TextStyle(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountGrid(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => context.push(AppRoutes.changePassword),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: AppColors.grey600, size: 32),
                const SizedBox(width: 16),
                Text(
                  'Change Password',
                  style: TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.grey500),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildBiometricCard(context),
      ],
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
                : AppColors.grey300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.fingerprint,
              color: hasBiometric ? AppColors.success : AppColors.grey600,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              hasBiometric ? 'Biometric On' : 'Biometric Login',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (hasBiometric)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Enabled',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}
