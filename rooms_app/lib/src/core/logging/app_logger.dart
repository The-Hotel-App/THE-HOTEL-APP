import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ANSI color codes for terminal output
class _AnsiColors {
  static const String reset = '\x1B[0m';
  static const String gray = '\x1B[90m';
  static const String red = '\x1B[91m';
  static const String green = '\x1B[92m';
  static const String yellow = '\x1B[93m';
  static const String blue = '\x1B[94m';
  static const String magenta = '\x1B[95m';
  static const String cyan = '\x1B[96m';
}

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
    if (_enabled) _log('🔍', tag, message, _AnsiColors.gray);
  }

  /// Info level - for general information
  static void info(String message, {String? tag}) {
    if (_enabled) _log('ℹ️', tag, message, _AnsiColors.cyan);
  }

  /// Success level - for successful operations
  static void success(String message, {String? tag}) {
    if (_enabled) _log('✅', tag, message, _AnsiColors.green);
  }

  /// Warning level - for potential issues
  static void warning(String message, {String? tag}) {
    if (_enabled) _log('⚠️', tag, message, _AnsiColors.yellow);
  }

  /// Error level - for errors and exceptions
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _log('❌', tag, message, _AnsiColors.red);
      if (error != null) {
        _log('❌', tag, 'Error: $error', _AnsiColors.red);
      }
      if (stackTrace != null) {
        _log('❌', tag, 'Stack: $stackTrace', _AnsiColors.red);
      }
    }
  }

  /// Navigation logging
  static void navigation(String message) {
    if (_enabled) _log('🧭', 'Nav', message, _AnsiColors.magenta);
  }

  /// API/Network logging
  static void api(String message) {
    if (_enabled) _log('🌐', 'API', message, _AnsiColors.blue);
  }

  /// Auth logging
  static void auth(String message) {
    if (_enabled) _log('🔐', 'Auth', message, _AnsiColors.cyan);
  }

  static void _log(String emoji, String? tag, String message, String color) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('$color$emoji $prefix$message${_AnsiColors.reset}');
  }
}

/// Provider for dependency injection (optional usage)
final loggerProvider = Provider<AppLogger>((ref) => AppLogger());
