import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info(
    'Background message: ${message.notification?.title}',
    tag: 'Notification',
  );
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Service for handling push notifications via FCM
///
/// Responsibilities:
/// - Initialize Firebase & FCM
/// - Request notification permissions
/// - Register/unregister FCM tokens with Supabase
/// - Handle foreground and background notifications
/// - Navigate to correct screen on notification tap
class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _currentToken;
  bool _isInitialized = false;

  static const String _permissionAskedKey = 'notification_permission_asked';

  /// Callback for handling notification taps - set by the app
  /// Parameters: (hotelId, notificationType, data)
  static void Function(String hotelId, String type, Map<String, dynamic> data)?
  onNotificationTap;

  NotificationService(this._ref);

  /// Check if notification permissions are granted
  Future<bool> get hasPermission async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Initialize the notification service
  /// Call this on app startup
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info(
        'NotificationService already initialized',
        tag: 'Notification',
      );
      return;
    }

    try {
      AppLogger.info(
        'Initializing NotificationService...',
        tag: 'Notification',
      );

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permission
      await _requestPermissionWithRetry();

      // Check if permission was granted
      if (await hasPermission) {
        await _setupMessaging();
      } else {
        AppLogger.warning(
          'Notification permission not granted',
          tag: 'Notification',
        );
      }

      _isInitialized = true;
      AppLogger.success('NotificationService initialized', tag: 'Notification');
    } catch (e) {
      AppLogger.error(
        'Error initializing notifications',
        tag: 'Notification',
        error: e,
      );
    }
  }

  /// Request notification permission with retry logic
  Future<void> _requestPermissionWithRetry() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info(
      'Notification permission: ${settings.authorizationStatus}',
      tag: 'Notification',
    );

    // Save that we've asked
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, true);
  }

  /// Setup messaging after permission is granted
  Future<void> _setupMessaging() async {
    try {
      // Get the token with retry logic
      _currentToken = await _getTokenWithRetry();
      if (_currentToken != null) {
        AppLogger.success('FCM Token obtained', tag: 'Notification');
      } else {
        AppLogger.warning(
          'FCM Token is null after retries',
          tag: 'Notification',
        );
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      // Handle foreground messages
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      AppLogger.error(
        'Error setting up messaging',
        tag: 'Notification',
        error: e,
      );
    }
  }

  /// Get FCM token with retry logic
  Future<String?> _getTokenWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          return token;
        }
        AppLogger.warning(
          'FCM token null, retry ${i + 1}/$maxRetries...',
          tag: 'Notification',
        );
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        AppLogger.warning(
          'Error getting FCM token, retry ${i + 1}/$maxRetries',
          tag: 'Notification',
        );
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  /// Request permission again if previously denied
  /// Call this on app resume or when user tries to enable notifications
  Future<bool> requestPermissionAgain(BuildContext context) async {
    final settings = await _messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.denied &&
        context.mounted) {
      // Show dialog explaining why notifications are important
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'To receive booking alerts and room status updates, please enable notifications in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.notDetermined) {
      await _requestPermissionWithRetry();
    }

    // Re-check and setup if now authorized
    if (await hasPermission && _currentToken == null) {
      await _setupMessaging();
      return true;
    }

    return await hasPermission;
  }

  /// Register FCM token for all hotels owned by the current user
  Future<void> registerTokenForUser() async {
    if (_currentToken == null) {
      AppLogger.warning(
        'No FCM token available, cannot register',
        tag: 'Notification',
      );
      return;
    }

    try {
      final user = _ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        AppLogger.warning(
          'No authenticated user, cannot register token',
          tag: 'Notification',
        );
        return;
      }

      AppLogger.info(
        'Registering FCM token for user: ${user.id}',
        tag: 'Notification',
      );

      // Get all hotels owned by this user
      final hotelsAsync = await _ref.read(userHotelsProvider.future);
      final ownedHotels = hotelsAsync
          .where((h) => h.role.name == 'owner')
          .toList();

      if (ownedHotels.isEmpty) {
        AppLogger.info(
          'User does not own any hotels, skipping token registration',
          tag: 'Notification',
        );
        return;
      }

      AppLogger.info(
        'Found ${ownedHotels.length} owned hotels',
        tag: 'Notification',
      );

      // Register token for each owned hotel
      for (final hotel in ownedHotels) {
        AppLogger.debug(
          'Registering for hotel: ${hotel.hotelId}',
          tag: 'Notification',
        );
        await _registerTokenForHotel(user.id, hotel.hotelId);
      }

      AppLogger.success(
        'FCM token registered for ${ownedHotels.length} hotels',
        tag: 'Notification',
      );
    } catch (e) {
      AppLogger.error(
        'Error registering FCM token',
        tag: 'Notification',
        error: e,
      );
    }
  }

  /// Register token for a specific hotel
  Future<void> _registerTokenForHotel(String userId, String hotelId) async {
    try {
      await SupabaseService.instance.client.from('device_tokens').upsert({
        'user_id': userId,
        'hotel_id': hotelId,
        'fcm_token': _currentToken,
        'device_info': {
          'platform': defaultTargetPlatform.name,
          'registered_at': DateTime.now().toIso8601String(),
        },
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,hotel_id,fcm_token');
      AppLogger.success(
        'Token registered for hotel: $hotelId',
        tag: 'Notification',
      );
    } catch (e) {
      AppLogger.error(
        'Error registering token for hotel $hotelId',
        tag: 'Notification',
        error: e,
      );
    }
  }

  /// Unregister FCM tokens on logout
  Future<void> unregisterTokens() async {
    if (_currentToken == null) return;

    try {
      final user = _ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;

      // Deactivate all tokens for this user/device
      await SupabaseService.instance.client
          .from('device_tokens')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('fcm_token', _currentToken!);

      AppLogger.success('FCM tokens unregistered', tag: 'Notification');
    } catch (e) {
      AppLogger.error(
        'Error unregistering FCM tokens',
        tag: 'Notification',
        error: e,
      );
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    AppLogger.info('FCM token refreshed', tag: 'Notification');
    _currentToken = token;
    registerTokenForUser();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      'Foreground message: ${message.notification?.title}',
      tag: 'Notification',
    );
    // Show in-app notification or update badge
  }

  /// Handle notification tap (background or terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('Notification tapped', tag: 'Notification');

    final hotelId = message.data['hotel_id'] as String?;
    final type = message.data['type'] as String?;

    if (hotelId != null && type != null && onNotificationTap != null) {
      onNotificationTap!(hotelId, type, message.data);
    }
  }

  /// Dispose resources
  void dispose() {
    _foregroundSubscription?.cancel();
  }
}
