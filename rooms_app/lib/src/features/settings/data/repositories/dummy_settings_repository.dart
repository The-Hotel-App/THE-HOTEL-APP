import 'package:rooms/src/features/settings/domain/entities/settings.dart';
import 'package:rooms/src/features/settings/domain/repositories/settings_repository.dart';

/// Dummy implementation of SettingsRepository for development
class DummySettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings(
    hotelId: 'demo-hotel',
    hotelName: 'Demo Hotel',
    hotelAddress: '123 Demo Street',
    hotelPhone: '+91 9876543210',
    hotelEmail: 'demo@hotel.com',
  );

  @override
  Future<AppSettings> getSettings(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _settings;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = settings;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In production, validate current password and update
  }

  @override
  Future<void> updateNotificationPreferences({
    required bool enabled,
    required bool sound,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _settings = _settings.copyWith(
      notificationsEnabled: enabled,
      soundEnabled: sound,
    );
  }
}
