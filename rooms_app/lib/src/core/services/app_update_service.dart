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
    AppLogger.info('=== UPDATE CHECK STARTED ===', tag: 'Update');

    if (!AppConfig.enableUpdateCheck) {
      AppLogger.warning('Update check is DISABLED in AppConfig', tag: 'Update');
      return null;
    }

    AppLogger.info('Update check is ENABLED', tag: 'Update');

    try {
      // Get current app version from package info (reads from pubspec.yaml)
      AppLogger.info('Getting package info...', tag: 'Update');
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      AppLogger.success('Current app version: $currentVersion', tag: 'Update');

      final url =
          'https://api.github.com/repos/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases/latest';
      AppLogger.info('Fetching from: $url', tag: 'Update');

      final response = await _dio.get(
        url,
        options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}),
      );

      AppLogger.info(
        'GitHub API response status: ${response.statusCode}',
        tag: 'Update',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = data['tag_name'] as String? ?? '';
        final latestVersion = _parseVersion(tagName);

        AppLogger.info('GitHub tag: $tagName', tag: 'Update');
        AppLogger.info('Parsed latest version: $latestVersion', tag: 'Update');
        AppLogger.info(
          'Comparing: current=$currentVersion vs latest=$latestVersion',
          tag: 'Update',
        );

        final isNewer = _isNewerVersion(latestVersion, currentVersion);
        AppLogger.info('Is newer version available? $isNewer', tag: 'Update');

        if (isNewer) {
          AppLogger.success('=== UPDATE AVAILABLE! ===', tag: 'Update');
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseUrl:
                data['html_url'] as String? ??
                'https://github.com/${AppConfig.githubOwner}/${AppConfig.githubRepo}/releases',
            releaseNotes: data['body'] as String? ?? '',
          );
        } else {
          AppLogger.info('=== APP IS UP TO DATE ===', tag: 'Update');
        }
      } else {
        AppLogger.warning(
          'GitHub API returned non-200: ${response.statusCode}',
          tag: 'Update',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Update check failed',
        tag: 'Update',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  /// Parse version from tag (removes 'v' prefix if present)
  static String _parseVersion(String tag) {
    final parsed = tag.startsWith('v') ? tag.substring(1) : tag;
    AppLogger.debug('Parsed "$tag" -> "$parsed"', tag: 'Update');
    return parsed;
  }

  /// Compare versions: returns true if latest > current
  static bool _isNewerVersion(String latest, String current) {
    AppLogger.debug(
      'Comparing versions: latest="$latest" vs current="$current"',
      tag: 'Update',
    );
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      AppLogger.debug('Latest parts: $latestParts', tag: 'Update');
      AppLogger.debug('Current parts: $currentParts', tag: 'Update');

      // Pad to same length
      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        AppLogger.debug(
          'Comparing index $i: ${latestParts[i]} vs ${currentParts[i]}',
          tag: 'Update',
        );
        if (latestParts[i] > currentParts[i]) {
          AppLogger.debug('Latest[$i] > Current[$i] -> NEWER', tag: 'Update');
          return true;
        }
        if (latestParts[i] < currentParts[i]) {
          AppLogger.debug(
            'Latest[$i] < Current[$i] -> NOT NEWER',
            tag: 'Update',
          );
          return false;
        }
      }
      AppLogger.debug('All parts equal -> NOT NEWER', tag: 'Update');
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
