import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';

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

  /// Callback for handling notification taps - set by the app
  /// Parameters: (hotelId, notificationType, data)
  static void Function(String hotelId, String type, Map<String, dynamic> data)?
  onNotificationTap;

  NotificationService(this._ref);

  /// Initialize the notification service
  /// Call this on app startup
  Future<void> initialize() async {
    try {
      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get the token
        _currentToken = await _messaging.getToken();
        debugPrint('📱 FCM Token: ${_currentToken?.substring(0, 20)}...');

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
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Register FCM token for all hotels owned by the current user
  Future<void> registerTokenForUser() async {
    if (_currentToken == null) {
      debugPrint('⚠️ No FCM token available');
      return;
    }

    try {
      final user = _ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        debugPrint('⚠️ No authenticated user');
        return;
      }

      // Get all hotels owned by this user
      final hotelsAsync = await _ref.read(userHotelsProvider.future);
      final ownedHotels = hotelsAsync
          .where((h) => h.role.name == 'owner')
          .toList();

      if (ownedHotels.isEmpty) {
        debugPrint('ℹ️ User does not own any hotels');
        return;
      }

      // Register token for each owned hotel
      for (final hotel in ownedHotels) {
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
    } catch (e) {
      debugPrint('❌ Error registering token for hotel $hotelId: $e');
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
    debugPrint('🔄 FCM token refreshed');
    _currentToken = token;
    registerTokenForUser();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Foreground message: ${message.notification?.title}');

    // Show in-app notification (you can customize this)
    // For now, we just log it - the notification will be stored in Supabase
    // and shown in the notifications page

    // Optionally trigger a refresh of notifications in the app
    // This could show a snackbar or update a badge
  }

  /// Handle notification tap (background or terminated state)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.data}');

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
