import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/routing/app_router.dart';

/// Welcome screen - first screen shown when app opens
/// Three user journeys per hotel_app_onboarding.md:
/// 1. Create New Hotel (Green) - For new hotel owners
/// 2. Login to Hotel (Blue) - For existing users
/// 3. Join a Hotel (Yellow) - For new employees
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.navigation('Building WelcomeScreen');

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo section
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Image.asset(
                      'assets/new_images/yellow_logo_on_transparent_bg.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.hotel,
                        size: 120,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ROOMS.io',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hotel Operations Management',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.grey400,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons - 3 journeys
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. Create New Hotel (Green) - For new hotel owners
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppLogger.navigation(
                            'Create New Hotel button tapped',
                          );
                          context.go(AppRoutes.setup);
                        },
                        icon: const Icon(
                          Icons.add_business,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Create New Hotel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Login to Hotel (Blue) - For existing users
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppLogger.navigation('Login to Hotel button tapped');
                          context.go(AppRoutes.hotelLogin);
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text(
                          'Login to Hotel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'Streamline your hotel operations',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grey500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
