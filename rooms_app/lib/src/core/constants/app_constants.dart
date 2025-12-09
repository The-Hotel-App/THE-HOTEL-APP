/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ROOMS.io';
  static const String appVersion = '0.1.0';

  // Timing
  static const int onboardingTargetSeconds = 20;
  static const int notificationDuration = 3000; // milliseconds

  // Storage Keys
  static const String isSetupCompletedKey = 'is_setup_completed';
  static const String currentHotelIdKey = 'current_hotel_id';
  static const String currentUserIdKey = 'current_user_id';
  static const String authTokenKey = 'auth_token';

  // UI
  static const double minTouchTarget = 48.0;
  static const double gridCrossAxisSpacing = 8.0;
  static const double gridMainAxisSpacing = 8.0;

  // Room Grid
  static const int roomGridCrossAxisCount = 3;
  static const double roomTileAspectRatio = 1.0;
}
