import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/core/constants/app_colors.dart';

/// Welcome screen - first screen shown when app opens
/// User can choose to login to existing hotel or create new hotel
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
                          context.go('/login');
                        },
                        icon: Icon(Icons.login, color: AppColors.black),
                        label: Text(
                          'Login to Your Hotel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors
                              .warning, // Changed from primary (black) to warning (yellow)
                          foregroundColor: AppColors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Create hotel button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          debugPrint('🔘 Create Hotel button tapped');
                          context.go('/setup');
                        },
                        icon: Icon(
                          Icons.add_business,
                          color: AppColors
                              .warning, // Changed from primary to warning
                        ),
                        label: Text(
                          'Create New Hotel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors
                                .warning, // Changed from primary to warning
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
