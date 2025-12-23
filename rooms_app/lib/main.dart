import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/app.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase first (critical for app)
  await SupabaseService.initialize();

  // Initialize Firebase (required for FCM push notifications)
  await _initFirebase();

  runApp(const ProviderScope(child: _AppWithNotifications()));
}

/// Initialize Firebase in background - don't block app startup
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    AppLogger.success('Firebase initialized successfully');
  } catch (e) {
    AppLogger.warning('Firebase initialization failed: $e');
    AppLogger.warning('Push notifications will not work');
  }
}

/// Wrapper widget that initializes NotificationService after ProviderScope is available
class _AppWithNotifications extends ConsumerStatefulWidget {
  const _AppWithNotifications();

  @override
  ConsumerState<_AppWithNotifications> createState() =>
      _AppWithNotificationsState();
}

class _AppWithNotificationsState extends ConsumerState<_AppWithNotifications> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after first frame (and after Firebase is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  Future<void> _initNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();

      // Set up notification tap handler
      NotificationService.onNotificationTap = (hotelId, type, data) {
        AppLogger.info(
          'Notification tapped: $type for hotel $hotelId',
          tag: 'Notification',
        );
        // Navigate to dashboard or specific screen
        // The navigation will be handled by the router based on current state
      };
    } catch (e) {
      AppLogger.warning('Notification service init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const RoomsApp();
  }
}
