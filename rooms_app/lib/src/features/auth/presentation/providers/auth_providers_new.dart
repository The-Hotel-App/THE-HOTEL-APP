import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:rooms/src/features/auth/domain/entities/user_new.dart';
import 'package:rooms/src/features/auth/domain/repositories/auth_repository_new.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(supabaseService: SupabaseService.instance);
});

/// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

/// User hotels provider
final userHotelsProvider = FutureProvider<List<UserHotel>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getUserHotels(user.id);
});

/// Selected hotel ID provider (stored in memory for current session)
final selectedHotelIdProvider = StateProvider<String?>((ref) => null);

/// Current hotel with role provider
final currentHotelProvider = Provider<UserHotel?>((ref) {
  final selectedHotelId = ref.watch(selectedHotelIdProvider);
  final hotelsAsync = ref.watch(userHotelsProvider);

  return hotelsAsync.when(
    data: (hotels) {
      if (selectedHotelId == null) {
        // Auto-select first hotel if available
        if (hotels.isNotEmpty) {
          // Schedule the update after the build
          Future.microtask(
            () => ref.read(selectedHotelIdProvider.notifier).state =
                hotels.first.hotelId,
          );
          return hotels.first;
        }
        return null;
      }

      return hotels.firstWhere(
        (h) => h.hotelId == selectedHotelId,
        orElse: () {
          if (hotels.isNotEmpty) {
            // Schedule hotel ID update if selected hotel not found
            Future.microtask(
              () => ref.read(selectedHotelIdProvider.notifier).state =
                  hotels.first.hotelId,
            );
            return hotels.first;
          }
          throw StateError('No hotels available');
        },
      );
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, _) => false,
  );
});
