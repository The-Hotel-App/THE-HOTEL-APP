import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

/// Hotel Selection Page - Shows all hotels user has access to
/// Displayed after login when user has multiple hotels
class HotelSelectionPage extends ConsumerWidget {
  const HotelSelectionPage({super.key});

  String _getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return AppRoutes.ownerDashboard;
      case UserRole.manager:
        return AppRoutes.managerDashboard;
      case UserRole.staff:
        return AppRoutes.staffDashboard;
      case UserRole.kitchenManager:
        return AppRoutes.kitchenDashboard;
    }
  }

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

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Icons.star;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.staff:
        return Icons.person;
      case UserRole.kitchenManager:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotelsAsync = ref.watch(userHotelsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Select Hotel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              await authRepo.logout();
              if (context.mounted) {
                context.go(AppRoutes.welcome);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: hotelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading hotels: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userHotelsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (hotels) {
          if (hotels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel, size: 64, color: AppColors.grey400),
                  const SizedBox(height: 16),
                  Text(
                    'No hotels found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have access to any hotels yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.black, AppColors.grey800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${currentUser?.name ?? 'User'}! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have access to ${hotels.length} hotels. Select one to continue.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section title
                Text(
                  'Your Hotels',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Hotel cards
                ...hotels.map(
                  (hotel) => _HotelCard(
                    hotel: hotel,
                    roleColor: _getRoleColor(hotel.role),
                    roleIcon: _getRoleIcon(hotel.role),
                    onTap: () async {
                      AppLogger.info(
                        'Selected hotel: ${hotel.hotelName}',
                        tag: 'Auth',
                      );
                      ref.read(selectedHotelIdProvider.notifier).state =
                          hotel.hotelId;

                      // Register FCM token for push notifications (Owners only)
                      final notificationService = ref.read(
                        notificationServiceProvider,
                      );
                      await notificationService.registerTokenForUser();

                      if (context.mounted) {
                        context.go(_getDashboardRoute(hotel.role));
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Show + button for owners only
      floatingActionButton: hotelsAsync.maybeWhen(
        data: (hotels) {
          // Show + button if user is owner of at least one hotel
          if (hotels.any((h) => h.role == UserRole.owner)) {
            return FloatingActionButton(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              onPressed: () => context.push(AppRoutes.createHotel),
              tooltip: 'Create New Hotel',
              child: const Icon(Icons.add),
            );
          }
          return null;
        },
        orElse: () => null,
      ),
    );
  }
}

/// Individual hotel card widget
class _HotelCard extends StatelessWidget {
  final UserHotel hotel;
  final Color roleColor;
  final IconData roleIcon;
  final VoidCallback onTap;

  const _HotelCard({
    required this.hotel,
    required this.roleColor,
    required this.roleIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200, width: 1),
            ),
            child: Row(
              children: [
                // Hotel icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hotel, size: 32, color: roleColor),
                ),
                const SizedBox(width: 16),

                // Hotel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.hotelName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 14, color: roleColor),
                            const SizedBox(width: 4),
                            Text(
                              hotel.role.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
