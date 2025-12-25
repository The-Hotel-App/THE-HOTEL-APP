import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/app_update_service.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/widgets/add_staff_sheet.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/core/widgets/update_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

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
    // Register FCM token and check for updates after dashboard is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationsForOwner();
      _checkForUpdates();
    });
  }

  /// Check for app updates
  Future<void> _checkForUpdates() async {
    AppLogger.info('>>> Dashboard _checkForUpdates() CALLED', tag: 'Update');
    try {
      final updateInfo = await AppUpdateService.checkForUpdate();
      AppLogger.info(
        '>>> Update result: ${updateInfo != null ? "UPDATE AVAILABLE" : "null"}',
        tag: 'Update',
      );
      if (updateInfo != null && mounted) {
        AppLogger.success('>>> SHOWING UPDATE DIALOG', tag: 'Update');
        UpdateDialog.show(context, updateInfo);
      }
    } catch (e) {
      AppLogger.warning('Update check error: $e', tag: 'Update');
    }
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
      AppLogger.error(
        'Error initializing notifications for owner',
        tag: 'Notification',
        error: e,
      );
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
        titleSpacing: 8,
        title: _buildHotelSwitcher(hotel),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
            tooltip: 'Logout',
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

  /// Build GitHub-style hotel switcher for AppBar
  Widget _buildHotelSwitcher(UserHotel? hotel) {
    final hotelsAsync = ref.watch(userHotelsProvider);
    final hotelName = hotel?.hotelName ?? 'Select Hotel';
    final firstLetter = hotelName.isNotEmpty ? hotelName[0].toUpperCase() : 'H';

    // Build the switcher widget
    Widget buildSwitcherContent({required VoidCallback? onTap}) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hotel avatar with first letter
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Hotel name (truncated)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  hotelName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Dropdown indicator
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      );
    }

    return hotelsAsync.when(
      loading: () => buildSwitcherContent(onTap: null), // Show but not tappable
      error: (error, stackTrace) =>
          buildSwitcherContent(onTap: null), // Show but not tappable
      data: (hotels) => buildSwitcherContent(
        onTap: () => _showHotelSwitcherSheet(hotels, hotel),
      ),
    );
  }

  /// Show hotel switcher bottom sheet
  void _showHotelSwitcherSheet(
    List<UserHotel> hotels,
    UserHotel? currentHotel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HotelSwitcherSheet(
        hotels: hotels,
        currentHotelId: currentHotel?.hotelId,
        onSelect: (hotel) {
          Navigator.pop(ctx);
          if (hotel.hotelId != currentHotel?.hotelId) {
            ref.read(selectedHotelIdProvider.notifier).state = hotel.hotelId;
            ref.invalidate(userHotelsProvider);
            ref.invalidate(currentHotelProvider);
          }
        },
        onAddNewHotel: () {
          Navigator.pop(ctx);
          context.push('/create-hotel');
        },
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
          onTap: () => AddStaffSheet.show(context),
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
                : AppColors.grey500.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: hasBiometric
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.grey500.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: hasBiometric ? AppColors.success : AppColors.grey500,
                  size: 32,
                ),
                if (hasBiometric)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 8,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
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

/// Hotel Switcher Bottom Sheet
class _HotelSwitcherSheet extends StatelessWidget {
  final List<UserHotel> hotels;
  final String? currentHotelId;
  final void Function(UserHotel hotel) onSelect;
  final VoidCallback onAddNewHotel;

  const _HotelSwitcherSheet({
    required this.hotels,
    required this.currentHotelId,
    required this.onSelect,
    required this.onAddNewHotel,
  });

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return AppColors.warning;
      case UserRole.manager:
        return AppColors.info;
      case UserRole.staff:
        return AppColors.success;
      case UserRole.kitchenManager:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: AppColors.black),
                  const SizedBox(width: 12),
                  Text(
                    'Switch Hotel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Hotel list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: hotels.length,
                itemBuilder: (context, index) {
                  final hotel = hotels[index];
                  final isSelected = hotel.hotelId == currentHotelId;
                  final roleColor = _getRoleColor(hotel.role);
                  final firstLetter = hotel.hotelName.isNotEmpty
                      ? hotel.hotelName[0].toUpperCase()
                      : 'H';

                  return ListTile(
                    onTap: () => onSelect(hotel),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      hotel.hotelName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? AppColors.success : AppColors.black,
                      ),
                    ),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hotel.role.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          )
                        : const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.grey400,
                          ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Add New Hotel button
            ListTile(
              onTap: onAddNewHotel,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_business, color: AppColors.info),
              ),
              title: const Text(
                'Add New Hotel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              subtitle: const Text(
                'Set up another hotel property',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.info,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
