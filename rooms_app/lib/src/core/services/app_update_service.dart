import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rooms/src/core/config/app_config.dart';
import 'package:rooms/src/core/logging/app_logger.dart';

/// Service to check for app updates from GitHub releases
class AppUpdateService {
  static final Dio _dio = Dio();

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

      final url =
          'https://api.github.com/repos/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases/latest';

      final response = await _dio.get(
        url,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = data['tag_name'] as String? ?? '';
        final latestVersion = _parseVersion(tagName);

        AppLogger.info('Latest release: $latestVersion', tag: 'Update');

        if (_isNewerVersion(latestVersion, currentVersion)) {
          AppLogger.success(
            'Update available: $currentVersion → $latestVersion',
            tag: 'Update',
          );
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseUrl:
                data['html_url'] as String? ??
                'https://github.com/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases',
            releaseNotes: data['body'] as String? ?? '',
          );
        } else {
          AppLogger.info('App is up to date', tag: 'Update');
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No release yet - this is normal, not an error
        AppLogger.info('No releases found yet', tag: 'Update');
      } else {
        AppLogger.warning('Update check failed: ${e.message}', tag: 'Update');
      }
    } catch (e) {
      AppLogger.warning('Update check failed: $e', tag: 'Update');
    }

    return null;
  }

  /// Parse version from tag (removes 'v' prefix if present)
  static String _parseVersion(String tag) {
    return tag.startsWith('v') ? tag.substring(1) : tag;
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
