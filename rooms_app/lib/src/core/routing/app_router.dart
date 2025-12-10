import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/features/auth/presentation/pages/home_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/login_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/welcome_screen.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart'
    as auth_new;
import 'package:rooms/src/features/bookings/presentation/pages/bookings_page.dart';
import 'package:rooms/src/features/checkin/presentation/pages/checkin_flow_page.dart';
import 'package:rooms/src/features/checkout/presentation/pages/checkout_flow_page.dart';
import 'package:rooms/src/features/customers/presentation/pages/customers_page.dart';
import 'package:rooms/src/features/daybook/presentation/pages/daybook_page.dart';
import 'package:rooms/src/features/hotel_setup/presentation/pages/hotel_setup_wizard_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/hotel_settings_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/notifications_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/staff_page.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/pages/rooms_page.dart';

/// Route paths
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String setup = '/setup';
  static const String home = '/';
  static const String rooms = '/rooms';
  static const String checkin = '/checkin';
  static const String checkout = '/checkout';
  static const String bookings = '/bookings';
  static const String customers = '/customers';
  static const String daybook = '/daybook';
  static const String staff = '/staff';
  static const String hotelSettings = '/hotel-settings';
  static const String notifications = '/notifications';
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
    ref.watch(auth_new.currentUserProvider.future).asStream(),
  ]);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(state.error.toString())),
      ),
    ),
    redirect: (context, state) {
      debugPrint('🧭 Router redirect called for: ${state.matchedLocation}');

      final isWelcomeRoute = state.matchedLocation == AppRoutes.welcome;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isSetupRoute = state.matchedLocation == AppRoutes.setup;

      // Check auth state
      final authState = ref.read(auth_new.currentUserProvider);

      // If auth is still loading, don't redirect - let the current page load
      if (authState.isLoading) {
        debugPrint('⏳ Auth loading, staying on current route');
        return null;
      }

      final user = authState.valueOrNull;
      final isAuthenticated = user != null;

      debugPrint(
        '👤 Auth state: ${isAuthenticated ? 'Authenticated (${user.name})' : 'Not authenticated'}',
      );

      // If authenticated, check if hotel is selected
      if (isAuthenticated) {
        final selectedHotelAsync = ref.read(auth_new.currentHotelProvider);
        final hasHotel = selectedHotelAsync != null;

        // If user is on setup page, allow them to stay (they might be creating their first hotel)
        if (isSetupRoute) {
          debugPrint('✅ On setup page, allowing access');
          return null;
        }

        // If user has no hotel, redirect to setup (but only if not already there)
        if (!hasHotel) {
          // Don't redirect if we're already going to/from setup to avoid recreating the widget
          if (state.matchedLocation != AppRoutes.setup) {
            debugPrint('⚠️  No hotel selected, redirecting to setup');
            return AppRoutes.setup;
          }
          return null;
        }

        // If user has hotel and is on welcome/login, redirect to home
        if (hasHotel && (isWelcomeRoute || isLoginRoute)) {
          debugPrint('✅ Has hotel, redirecting to home');
          return AppRoutes.home;
        }
      }

      // If not authenticated and trying to access protected route
      if (!isAuthenticated &&
          !isWelcomeRoute &&
          !isLoginRoute &&
          !isSetupRoute) {
        debugPrint('🚫 Not authenticated, redirecting to welcome');
        return AppRoutes.welcome;
      }

      debugPrint('➡️  No redirect needed');
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.setup,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HotelSetupWizardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.rooms,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoomsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkin,
        pageBuilder: (context, state) {
          final room = state.extra as Room;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CheckinFlowPage(room: room),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 200),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (context, state) {
          final room = state.extra as Room;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CheckoutFlowPage(room: room),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 200),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookings,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.customers,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CustomersPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.daybook,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DayBookPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.staff,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.hotelSettings,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HotelSettingsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
    ],
  );
});
