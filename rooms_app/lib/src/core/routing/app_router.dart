import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/features/auth/presentation/pages/home_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/login_page.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:rooms/src/features/hotel_setup/presentation/pages/hotel_setup_wizard_page.dart';
import 'package:rooms/src/features/hotel_setup/presentation/providers/setup_providers.dart';
import 'package:rooms/src/features/rooms/presentation/pages/rooms_page.dart';

/// Route paths
class AppRoutes {
  static const String login = '/login';
  static const String setup = '/setup';
  static const String home = '/';
  static const String rooms = '/rooms';
  static const String bookings = '/bookings';
  static const String customers = '/customers';
  static const String daybook = '/daybook';
  static const String staff = '/staff';
  static const String settings = '/settings';
}

/// Refresh notifier for GoRouter
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(List<Stream> streams) {
    for (final stream in streams) {
      stream.listen((_) => notifyListeners());
    }
  }
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier([
    ref.watch(currentUserProvider.future).asStream(),
    ref.watch(isSetupCompletedProvider.future).asStream(),
  ]);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      debugPrint('🧭 Router redirect called for: ${state.matchedLocation}');

      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isSetupRoute = state.matchedLocation == AppRoutes.setup;

      // Check auth state
      final authState = ref.read(currentUserProvider);
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;

      debugPrint(
        '👤 Auth state: ${isAuthenticated ? 'Authenticated (${user.name})' : 'Not authenticated'}',
      );

      // Check setup completion
      final setupStatus = ref.read(isSetupCompletedProvider);
      final isSetupCompleted = setupStatus.valueOrNull ?? false;

      debugPrint('⚙️  Setup completed: $isSetupCompleted');

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isLoginRoute) {
        debugPrint('🚫 Not authenticated, redirecting to login');
        return AppRoutes.login;
      }

      // If authenticated but setup not completed, go to setup
      if (isAuthenticated && !isSetupCompleted && !isSetupRoute) {
        debugPrint('🔧 Setup not completed, redirecting to setup');
        return AppRoutes.setup;
      }

      // If authenticated and setup completed, but on login or setup page
      if (isAuthenticated &&
          isSetupCompleted &&
          (isLoginRoute || isSetupRoute)) {
        debugPrint('✅ Authenticated and setup complete, redirecting to home');
        return AppRoutes.home;
      }

      debugPrint('➡️  No redirect needed');
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const MaterialPage(child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.setup,
        pageBuilder: (context, state) =>
            const MaterialPage(child: HotelSetupWizardPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => const MaterialPage(child: HomePage()),
      ),
      GoRoute(
        path: AppRoutes.rooms,
        pageBuilder: (context, state) => const MaterialPage(child: RoomsPage()),
      ),
      // TODO: Add more routes
    ],
  );
});
