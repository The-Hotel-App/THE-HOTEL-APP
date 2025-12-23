import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 Background message: ${message.notification?.title}');
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
      debugPrint('🔔 NotificationService already initialized');
      return;
    }

    try {
      debugPrint('🔔 Initializing NotificationService...');

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
        debugPrint('⚠️ Notification permission not granted');
      }

      _isInitialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
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

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

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
        debugPrint(
          '📱 FCM Token obtained: ${_currentToken!.substring(0, 30)}...',
        );
      } else {
        debugPrint('⚠️ FCM Token is null after retries');
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
      debugPrint('❌ Error setting up messaging: $e');
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
        debugPrint('⚠️ FCM token null, retry ${i + 1}/$maxRetries...');
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint(
          '⚠️ Error getting FCM token: $e, retry ${i + 1}/$maxRetries',
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
      debugPrint('⚠️ No FCM token available, cannot register');
      return;
    }

    try {
      final user = _ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        debugPrint('⚠️ No authenticated user, cannot register token');
        return;
      }

      debugPrint(
        '📱 Registering FCM token for user: ${user.name} (${user.id})',
      );

      // Get all hotels owned by this user
      final hotelsAsync = await _ref.read(userHotelsProvider.future);
      final ownedHotels = hotelsAsync
          .where((h) => h.role.name == 'owner')
          .toList();

      if (ownedHotels.isEmpty) {
        debugPrint(
          'ℹ️ User does not own any hotels, skipping token registration',
        );
        return;
      }

      debugPrint('🏨 Found ${ownedHotels.length} owned hotels');

      // Register token for each owned hotel
      for (final hotel in ownedHotels) {
        debugPrint(
          '   Registering for hotel: ${hotel.hotelName} (${hotel.hotelId})',
        );
        await _registerTokenForHotel(user.id, hotel.hotelId);
      }

      debugPrint('✅ FCM token registered for ${ownedHotels.length} hotels');
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
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
      debugPrint('   ✅ Token registered for hotel: $hotelId');
    } catch (e) {
      debugPrint('   ❌ Error registering token for hotel $hotelId: $e');
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

      debugPrint('✅ FCM tokens unregistered');
    } catch (e) {
      debugPrint('❌ Error unregistering FCM tokens: $e');
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String token) {
    debugPrint('🔄 FCM token refreshed: ${token.substring(0, 30)}...');
    _currentToken = token;
    registerTokenForUser();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message received!');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Show in-app notification (you can customize this)
    // For now, we just log it - the notification will be stored in Supabase
    // and shown in the notifications page

    // Optionally trigger a refresh of notifications in the app
    // This could show a snackbar or update a badge
  }

  /// Handle notification tap (background or terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped!');
    debugPrint('   Data: ${message.data}');

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
