import 'package:rooms/src/features/settings/domain/entities/settings.dart';

/// Abstract repository for settings operations
abstract class SettingsRepository {
  /// Get current settings
  Future<AppSettings> getSettings(String hotelId);

  /// Update settings
  Future<void> updateSettings(AppSettings settings);

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool enabled,
    required bool sound,
  });
}
