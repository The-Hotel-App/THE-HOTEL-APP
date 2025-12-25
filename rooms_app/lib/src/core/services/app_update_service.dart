import 'package:package_info_plus/package_info_plus.dart';
import 'package:rooms/src/core/config/app_config.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';

/// Service to check for app updates from Supabase
class AppUpdateService {
  /// Check for available updates
  /// Returns UpdateInfo if update available, null otherwise
  static Future<UpdateInfo?> checkForUpdate() async {
    if (!AppConfig.enableUpdateCheck) {
      AppLogger.info('Update check disabled', tag: 'Update');
      return null;
    }

    try {
      // Get current app version from package info
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      AppLogger.info('Current version: $currentVersion', tag: 'Update');

      // Fetch latest version from Supabase
      final response = await SupabaseService.instance.client
          .from('app_version')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        AppLogger.info('No version info in database', tag: 'Update');
        return null;
      }

      final latestVersion = response['version'] as String? ?? '';
      final downloadUrl = response['download_url'] as String? ?? '';
      final releaseNotes = response['release_notes'] as String? ?? '';

      AppLogger.info('Latest version: $latestVersion', tag: 'Update');

      if (_isNewerVersion(latestVersion, currentVersion)) {
        AppLogger.success(
          'Update available: $currentVersion → $latestVersion',
          tag: 'Update',
        );
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseUrl: downloadUrl,
          releaseNotes: releaseNotes,
        );
      } else {
        AppLogger.info('App is up to date', tag: 'Update');
      }
    } catch (e) {
      AppLogger.warning('Update check failed: $e', tag: 'Update');
    }

    return null;
  }

  /// Compare versions: returns true if latest > current
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      // Pad to same length
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (e) {
      // Version parse error - treat as no update
    }
    return false;
  }
}

/// Information about an available update
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.releaseNotes = '',
  });
}
