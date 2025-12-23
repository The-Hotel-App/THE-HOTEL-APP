import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized logger with environment-aware logging.
///
/// Usage:
/// ```dart
/// AppLogger.info('User logged in', tag: 'Auth');
/// AppLogger.error('Failed to load', tag: 'API', error: e);
/// ```
///
/// Logging is automatically disabled in release mode.
class AppLogger {
  static bool _enabled = kDebugMode;

  /// Enable or disable logging globally
  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Check if logging is enabled
  static bool get isEnabled => _enabled;

  /// Debug level - for development details
  static void debug(String message, {String? tag}) {
    if (_enabled) _log('🔍', tag, message);
  }

  /// Info level - for general information
  static void info(String message, {String? tag}) {
    if (_enabled) _log('ℹ️', tag, message);
  }

  /// Success level - for successful operations
  static void success(String message, {String? tag}) {
    if (_enabled) _log('✅', tag, message);
  }

  /// Warning level - for potential issues
  static void warning(String message, {String? tag}) {
    if (_enabled) _log('⚠️', tag, message);
  }

  /// Error level - for errors and exceptions
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _log('❌', tag, message);
      if (error != null) {
        _log('❌', tag, 'Error: $error');
      }
      if (stackTrace != null) {
        _log('❌', tag, 'Stack: $stackTrace');
      }
    }
  }

  /// Navigation logging
  static void navigation(String message) {
    if (_enabled) _log('🧭', 'Nav', message);
  }

  /// API/Network logging
  static void api(String message) {
    if (_enabled) _log('🌐', 'API', message);
  }

  /// Auth logging
  static void auth(String message) {
    if (_enabled) _log('🔐', 'Auth', message);
  }

  static void _log(String emoji, String? tag, String message) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('$emoji $prefix$message');
  }
}

/// Provider for dependency injection (optional usage)
final loggerProvider = Provider<AppLogger>((ref) => AppLogger());
