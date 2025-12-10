import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';
import 'package:rooms/src/core/routing/app_router.dart';

/// Welcome screen - first screen shown when app opens
/// User can choose to login or create a booking (without login for biometric verification later)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 Building WelcomeScreen');

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
                    Icon(Icons.hotel, size: 120, color: AppColors.warning),
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

              // Action buttons
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('🔘 Login button tapped');
                          context.go(AppRoutes.login);
                        },
                        icon: Icon(Icons.login, color: AppColors.black),
                        label: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: AppColors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Create Booking button (for quick booking without login)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          debugPrint('🔘 Create Booking button tapped');
                          context.go(AppRoutes.bookingSearch);
                        },
                        icon: Icon(Icons.book_online, color: AppColors.warning),
                        label: Text(
                          'Create Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: BorderSide(color: AppColors.warning, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
