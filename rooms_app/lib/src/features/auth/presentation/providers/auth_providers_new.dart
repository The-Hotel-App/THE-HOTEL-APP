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
      if (hotels.isEmpty) {
        return null; // No hotels available - return null instead of throwing
      }
      
      if (selectedHotelId == null) {
        // Auto-select first hotel if available
        // Schedule the update after the build
        Future.microtask(
          () => ref.read(selectedHotelIdProvider.notifier).state =
              hotels.first.hotelId,
        );
        return hotels.first;
      }

      // Try to find the selected hotel
      try {
        return hotels.firstWhere((h) => h.hotelId == selectedHotelId);
      } catch (e) {
        // Selected hotel not found - auto-select first
        Future.microtask(
          () => ref.read(selectedHotelIdProvider.notifier).state =
              hotels.first.hotelId,
        );
        return hotels.first;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (e, s) => false,
  );
});
