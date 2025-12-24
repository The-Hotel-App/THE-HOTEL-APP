import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/widgets/custom_dialog.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/auth/presentation/providers/biometric_providers.dart';

/// Hotel Selection Page - Shows all hotels user has access to
/// Displayed after login when user has multiple hotels
class HotelSelectionPage extends ConsumerStatefulWidget {
  const HotelSelectionPage({super.key});

  @override
  ConsumerState<HotelSelectionPage> createState() => _HotelSelectionPageState();
}

class _HotelSelectionPageState extends ConsumerState<HotelSelectionPage> {
  bool _isBiometricLoading = false;

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

  Future<void> _handleBiometricToggle() async {
    final hasBiometric = ref.read(userBiometricStatusProvider);

    if (hasBiometric) {
      // Disable biometric - require fingerprint verification first
      setState(() => _isBiometricLoading = true);

      try {
        final biometricService = ref.read(biometricServiceProvider);

        // Verify fingerprint first
        final authenticated = await biometricService.authenticate(
          reason: 'Verify your identity to disable fingerprint login',
          biometricOnly: false,
        );

        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Fingerprint verified - proceed to disable
        await biometricService.clearCredentials();

        final user = await ref.read(currentUserProvider.future);
        if (user != null) {
          final authRepo = ref.read(authRepositoryProvider);
          await authRepo.updateBiometricStatus(
            userId: user.id,
            hasBiometric: false,
          );
        }

        // Refresh the user provider to update the toggle
        ref.invalidate(currentUserProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint login disabled'),
              backgroundColor: AppColors.black,
            ),
          );
        }
      } catch (e) {
        AppLogger.error(
          'Error disabling biometric',
          tag: 'HotelSelection',
          error: e,
        );
      } finally {
        if (mounted) setState(() => _isBiometricLoading = false);
      }
    } else {
      // Enable biometric - prompt for password inline
      final password = await _showPasswordDialog();
      if (password == null) return;

      setState(() => _isBiometricLoading = true);

      try {
        final biometricService = ref.read(biometricServiceProvider);

        // Check device support
        final isSupported = await biometricService.isDeviceSupported();
        final isEnrolled = await biometricService.areBiometricsEnrolled();

        if (!isSupported || !isEnrolled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fingerprint not available on this device'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Authenticate with fingerprint
        final authenticated = await biometricService.authenticate(
          reason: 'Verify your fingerprint to enable quick login',
          biometricOnly: false,
        );

        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fingerprint verification failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        // Store credentials
        final user = await ref.read(currentUserProvider.future);
        if (user != null) {
          await biometricService.storeCredentials(
            email: user.email,
            password: password,
          );

          final authRepo = ref.read(authRepositoryProvider);
          await authRepo.updateBiometricStatus(
            userId: user.id,
            hasBiometric: true,
          );

          // Refresh the user provider to update the toggle
          ref.invalidate(currentUserProvider);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fingerprint login enabled'),
                backgroundColor: AppColors.black,
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.error(
          'Error enabling biometric',
          tag: 'HotelSelection',
          error: e,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enable fingerprint: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isBiometricLoading = false);
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await CustomDialog.showConfirmation(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDestructive: true,
      icon: Icons.logout,
    );

    if (confirmed != true) return;

    // Navigate first to avoid flash
    if (mounted) {
      context.go(AppRoutes.welcome);
    }

    // Then logout in background
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
  }

  Widget _buildFingerprintCard(bool hasBiometric) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.fingerprint, color: AppColors.black, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fingerprint Login',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_isBiometricLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: hasBiometric,
              onChanged: (_) => _handleBiometricToggle(),
              activeThumbColor: AppColors.black,
              activeTrackColor: AppColors.grey400,
              inactiveThumbColor: AppColors.grey400,
              inactiveTrackColor: AppColors.grey200,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(userHotelsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final hasBiometric = ref.watch(userBiometricStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: const Text('Select Hotel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
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
                const SizedBox(height: 16),

                // Fingerprint setup card - prominent and visible
                _buildFingerprintCard(hasBiometric),
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
              border: Border.all(color: Colors.black, width: 1),
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
