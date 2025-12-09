import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/features/auth/domain/entities/user.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/hotel_setup/presentation/providers/setup_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final hotel = ref.watch(currentHotelProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/new_images/black_logo_on_yellow_bg_new_fixed_ratio.png',
              height: 32,
            ),
            const SizedBox(width: 12),
            Text(hotel?.name ?? 'ROOMS.io'),
          ],
        ),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome, ${currentUser?.name ?? "User"}!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${currentUser?.role.displayName ?? "Unknown"}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Quick Actions Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildQuickActionCard(
                    context,
                    icon: Icons.meeting_room,
                    title: 'Rooms',
                    color: AppColors.black,
                    onTap: () {
                      context.go(AppRoutes.rooms);
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.book_online,
                    title: 'Bookings',
                    color: AppColors.success,
                    onTap: () {
                      // TODO: Navigate to bookings
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.people,
                    title: 'Customers',
                    color: AppColors.info,
                    onTap: () {
                      // TODO: Navigate to customers
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    icon: Icons.book,
                    title: 'Day Book',
                    color: AppColors.warning,
                    onTap: () {
                      // TODO: Navigate to daybook
                    },
                  ),
                  if (currentUser?.role == UserRole.owner) ...[
                    _buildQuickActionCard(
                      context,
                      icon: Icons.groups,
                      title: 'Staff',
                      color: AppColors.grey700,
                      onTap: () {
                        // TODO: Navigate to staff
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      icon: Icons.settings,
                      title: 'Settings',
                      color: AppColors.grey700,
                      onTap: () {
                        // TODO: Navigate to settings
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Coming Soon Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info),
              ),
              child: Row(
                children: [
                  Icon(Icons.construction, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Setup flow & features coming soon! Login is working.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
