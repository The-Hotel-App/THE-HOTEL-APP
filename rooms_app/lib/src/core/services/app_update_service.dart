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
      // Get current app version from package info (reads from pubspec.yaml)
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(
        'https://api.github.com/repos/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = data['tag_name'] as String? ?? '';
        final latestVersion = _parseVersion(tagName);

        AppLogger.info(
          'Current: $currentVersion, Latest: $latestVersion',
          tag: 'Update',
        );

        if (_isNewerVersion(latestVersion, currentVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseUrl: data['html_url'] as String? ??
                'https://github.com/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases',
            releaseNotes: data['body'] as String? ?? '',
          );
        }
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
      AppLogger.warning('Version parse error: $e', tag: 'Update');
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
