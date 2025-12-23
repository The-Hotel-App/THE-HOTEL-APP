import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/app.dart';
import 'package:rooms/src/core/services/notification_service.dart';
import 'package:rooms/src/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(ProviderScope(child: const _AppWithNotifications()));
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
    // Initialize notifications after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  Future<void> _initNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();

    // Set up notification tap handler
    // TODO: This can be customized to navigate to specific screens
    NotificationService.onNotificationTap = (hotelId, type, data) {
      debugPrint('🔔 Notification tapped: $type for hotel $hotelId');
      // Navigate to dashboard or specific screen
      // The navigation will be handled by the router based on current state
    };
  }

  @override
  Widget build(BuildContext context) {
    return const RoomsApp();
  }
}
