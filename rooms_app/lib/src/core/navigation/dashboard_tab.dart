import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/widgets/add_staff_sheet.dart';
import 'package:rooms/src/core/widgets/app_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/providers/room_providers.dart';

/// Dashboard tab showing welcome card and quick stats
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  Future<void> _refresh() async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(roomsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final hotel = ref.watch(currentHotelProvider);
    final userAsync = ref.watch(currentUserProvider);

    // Show loading while hotel/user is loading to prevent staff view flash
    if (hotel == null) {
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
              const Text('Loading...'),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = userAsync.valueOrNull;
    final role = hotel.role;
    final roomsAsync = ref.watch(roomsProvider);

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
            tooltip: 'Logout',
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
              // Welcome Card
              _buildWelcomeCard(user?.name ?? 'User', role),
              const SizedBox(height: 24),

              // Room Stats Section
              _buildSectionTitle('Room Status', Icons.hotel),
              const SizedBox(height: 12),
              roomsAsync.when(
                data: (rooms) => _buildRoomStatsCards(rooms),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _buildErrorCard('Failed to load room stats'),
              ),
              const SizedBox(height: 24),

              // Quick Actions Section
              _buildSectionTitle('Quick Actions', Icons.flash_on),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(context, role),
            ],
          ),
        ),
      ),
    );
  }

  /// Build GitHub-style hotel switcher for AppBar
  Widget _buildHotelSwitcher(UserHotel hotel) {
    final hotelsAsync = ref.watch(userHotelsProvider);
    final hotelName = hotel.hotelName;
    final firstLetter = hotelName.isNotEmpty ? hotelName[0].toUpperCase() : 'H';

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
              // Hotel name (full, not truncated)
              Flexible(
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
      loading: () => buildSwitcherContent(onTap: null),
      error: (e, s) => buildSwitcherContent(onTap: null),
      data: (hotels) => buildSwitcherContent(
        onTap: () => _showHotelSwitcherSheet(hotels, hotel),
      ),
    );
  }

  /// Show hotel switcher bottom sheet
  void _showHotelSwitcherSheet(List<UserHotel> hotels, UserHotel currentHotel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: AppColors.black),
                    const SizedBox(width: 12),
                    Text(
                      'Switch Hotel',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = hotels[index];
                    final isSelected = hotel.hotelId == currentHotel.hotelId;
                    final firstLetter = hotel.hotelName.isNotEmpty
                        ? hotel.hotelName[0].toUpperCase()
                        : 'H';

                    return ListTile(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (hotel.hotelId != currentHotel.hotelId) {
                          ref.read(selectedHotelIdProvider.notifier).state =
                              hotel.hotelId;
                          ref.invalidate(userHotelsProvider);
                          ref.invalidate(currentHotelProvider);
                        }
                      },
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
                          color: isSelected
                              ? AppColors.success
                              : AppColors.black,
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
                                color: _getRoleColor(
                                  hotel.role,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                hotel.role.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getRoleColor(hotel.role),
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
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/create-hotel');
                },
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
                  'Set up another property',
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
      ),
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    await AppDialog.show(
      context: context,
      title: 'Logout',
      content: const Text('Are you sure you want to logout?'),
      primaryButtonText: 'Logout',
      onPrimaryPressed: () async {
        Navigator.pop(context);
        await ref.read(authRepositoryProvider).logout();
        if (context.mounted) context.go(AppRoutes.welcome);
      },
      secondaryButtonText: 'Cancel',
    );
  }

  Widget _buildWelcomeCard(String name, UserRole role) {
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
            child: Icon(_getRoleIcon(role), color: AppColors.grey800, size: 32),
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
                    color: _getRoleColor(role),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role.name.toUpperCase(),
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

  Widget _buildRoomStatsCards(List<Room> rooms) {
    int available = 0;
    int occupied = 0;
    int maintenance = 0;
    int cleaning = 0;

    for (final room in rooms) {
      switch (room.status) {
        case RoomStatus.free:
          available++;
          break;
        case RoomStatus.occupied:
          occupied++;
          break;
        case RoomStatus.maintenance:
        case RoomStatus.outOfService:
          maintenance++;
          break;
        case RoomStatus.cleaning:
          cleaning++;
          break;
      }
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Available',
          available.toString(),
          Icons.check_circle_outline,
          AppColors.roomFree,
        ),
        _buildStatCard(
          'Occupied',
          occupied.toString(),
          Icons.hotel,
          AppColors.roomOccupied,
        ),
        _buildStatCard(
          'Cleaning',
          cleaning.toString(),
          Icons.cleaning_services,
          AppColors.roomCleaning,
        ),
        _buildStatCard(
          'Maintenance',
          maintenance.toString(),
          Icons.build_circle,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, UserRole role) {
    final isOwner = role == UserRole.owner;
    final isOwnerOrManager = role == UserRole.owner || role == UserRole.manager;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.book_online,
          label: 'New Booking',
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.bookingSearch),
        ),
        if (isOwnerOrManager)
          _buildActionCard(
            context,
            icon: Icons.receipt_long,
            label: 'Day Book',
            color: AppColors.success,
            onTap: () => context.push(AppRoutes.daybook),
          ),
        if (isOwner)
          _buildActionCard(
            context,
            icon: Icons.person_add,
            label: 'Add Staff',
            color: AppColors.grey700,
            onTap: () => AddStaffSheet.show(context),
          ),
        if (isOwner)
          _buildActionCard(
            context,
            icon: Icons.category,
            label: 'Room Types',
            color: AppColors.grey600,
            onTap: () => context.push(AppRoutes.roomTypes),
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

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
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
