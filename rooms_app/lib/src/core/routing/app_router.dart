import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/presentation/pages/home_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/hotel_login_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/join_hotel_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/login_page.dart';
import 'package:rooms/src/features/auth/presentation/pages/welcome_screen.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart'
    as auth_new;
import 'package:rooms/src/features/bookings/presentation/pages/booking_search_page.dart';
import 'package:rooms/src/features/bookings/presentation/pages/bookings_page.dart';
import 'package:rooms/src/features/checkin/presentation/pages/checkin_flow_page.dart';
import 'package:rooms/src/features/checkout/presentation/pages/checkout_flow_page.dart';
import 'package:rooms/src/features/customers/presentation/pages/customers_page.dart';
import 'package:rooms/src/features/dashboards/presentation/pages/kitchen_dashboard_page.dart';
import 'package:rooms/src/features/dashboards/presentation/pages/manager_dashboard_page.dart';
import 'package:rooms/src/features/dashboards/presentation/pages/owner_dashboard_page.dart';
import 'package:rooms/src/features/dashboards/presentation/pages/staff_dashboard_page.dart';
import 'package:rooms/src/features/daybook/presentation/pages/daybook_page.dart';
import 'package:rooms/src/features/hotel_setup/presentation/pages/hotel_setup_wizard_page.dart';
import 'package:rooms/src/features/rooms/domain/entities/room.dart';
import 'package:rooms/src/features/rooms/presentation/pages/rooms_management_page.dart';
import 'package:rooms/src/features/rooms/presentation/pages/rooms_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/change_password_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/create_staff_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/hotel_settings_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/join_codes_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/notifications_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/pending_requests_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/room_types_page.dart';
import 'package:rooms/src/features/settings/presentation/pages/staff_page.dart';

/// Route paths
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String hotelLogin = '/hotel-login';
  static const String joinHotel = '/join-hotel';
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
  // New routes for role-based dashboards
  static const String bookingSearch = '/booking-search';
  static const String ownerDashboard = '/owner-dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String staffDashboard = '/staff-dashboard';
  static const String kitchenDashboard = '/kitchen-dashboard';
  static const String changePassword = '/change-password';
  static const String createStaff = '/create-staff';
  static const String roomTypes = '/room-types';
  static const String roomsManagement = '/rooms-management';
  // Join code management routes
  static const String joinCodes = '/join-codes';
  static const String pendingRequests = '/pending-requests';
}

// NOTE: We intentionally do NOT use refreshListenable tied to auth state.
// When auth state changes (login/signup), the router would reset to initialLocation,
// which breaks flows like the hotel setup wizard where we need to stay on /setup
// and continue after signup. The redirect logic handles navigation appropriately.

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    // No refreshListenable - we handle navigation explicitly
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

      // Check if user is navigating to a dashboard route
      final isDashboardRoute =
          state.matchedLocation == AppRoutes.ownerDashboard ||
          state.matchedLocation == AppRoutes.managerDashboard ||
          state.matchedLocation == AppRoutes.staffDashboard ||
          state.matchedLocation == AppRoutes.kitchenDashboard;

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

      // Define public routes that should always be accessible
      // regardless of authentication or hotel selection state
      final isHotelLoginRoute = state.matchedLocation == AppRoutes.hotelLogin;
      final isJoinHotelRoute = state.matchedLocation == AppRoutes.joinHotel;
      final isPublicRoute =
          isWelcomeRoute ||
          isLoginRoute ||
          isSetupRoute ||
          isHotelLoginRoute ||
          isJoinHotelRoute ||
          state.matchedLocation == AppRoutes.bookingSearch ||
          state.matchedLocation == AppRoutes.checkin;

      // If on a public route, allow access without any restrictions
      if (isPublicRoute) {
        debugPrint('✅ On public route, allowing access');
        return null;
      }

      // From here on, we're dealing with protected routes only
      
      // If not authenticated and trying to access protected route -> redirect to welcome
      if (!isAuthenticated) {
        debugPrint('🚫 Not authenticated, redirecting to welcome');
        return AppRoutes.welcome;
      }

      // User is authenticated and on a protected route - check hotel access
      final hotelsAsync = ref.read(auth_new.userHotelsProvider);

      // If hotels are still loading but user is explicitly navigating to dashboard,
      // don't interfere - the login page has already selected the hotel
      if (hotelsAsync.isLoading) {
        if (isDashboardRoute) {
          debugPrint(
            '⏳ Hotels loading but navigating to dashboard, allowing',
          );
          return null;
        }
        debugPrint('⏳ Hotels loading, staying on current route');
        return null;
      }

      final selectedHotelId = ref.read(auth_new.selectedHotelIdProvider);
      final selectedHotelAsync = ref.read(auth_new.currentHotelProvider);
      final hasHotel = selectedHotelAsync != null || selectedHotelId != null;

      debugPrint(
        '🏨 Selected hotel ID: $selectedHotelId, hasHotel: $hasHotel',
      );

      // If user is navigating to a dashboard and has a hotel selected, allow it
      if (isDashboardRoute && hasHotel) {
        debugPrint('✅ Navigating to dashboard with hotel selected, allowing');
        return null;
      }

      // If user has hotel and is on home route, redirect to role-based dashboard
      if (hasHotel && state.matchedLocation == AppRoutes.home) {
        final role = selectedHotelAsync?.role;
        if (role != null) {
          debugPrint(
            '✅ Has hotel with role: $role, redirecting to dashboard',
          );

          switch (role) {
            case UserRole.owner:
              return AppRoutes.ownerDashboard;
            case UserRole.manager:
              return AppRoutes.managerDashboard;
            case UserRole.staff:
              return AppRoutes.staffDashboard;
            case UserRole.kitchenManager:
              return AppRoutes.kitchenDashboard;
          }
        }
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
        path: AppRoutes.hotelLogin,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HotelLoginPage(),
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
        path: AppRoutes.joinHotel,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const JoinHotelPage(),
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
      // New routes for booking search and dashboards
      GoRoute(
        path: AppRoutes.bookingSearch,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookingSearchPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.ownerDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OwnerDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.managerDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManagerDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.kitchenDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const KitchenDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.createStaff,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateStaffPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.roomTypes,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoomTypesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.roomsManagement,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RoomsManagementPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.joinCodes,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const JoinCodesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      ),
      GoRoute(
        path: AppRoutes.pendingRequests,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PendingRequestsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
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
