import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
import 'package:rooms/src/features/daybook/data/repositories/supabase_daybook_repository.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';
import 'package:rooms/src/features/daybook/domain/repositories/daybook_repository.dart';

/// Provider for day book repository
final dayBookRepositoryProvider = Provider<DayBookRepository>((ref) {
  return SupabaseDayBookRepository();
});

/// Provider for current daybook ID (set when summary is loaded)
final currentDaybookIdProvider = StateProvider<String?>((ref) => null);

/// Provider for today's day book summary - with realtime updates
final todayDayBookProvider = StreamProvider<DayBookSummary>((ref) {
  final repo = ref.watch(dayBookRepositoryProvider);
  final hotelId = ref.watch(selectedHotelIdProvider);

  if (hotelId == null) {
    return Stream.error(Exception('No hotel selected'));
  }

  final client = SupabaseService.instance.client;

  AppLogger.info(
    'Setting up realtime subscription for daybook in hotel: $hotelId',
    tag: 'DayBook',
  );

  // Listen to daybook_transactions changes and refetch summary
  return client
      .from('daybook_transactions')
      .stream(primaryKey: ['id'])
      .eq('hotel_id', hotelId)
      .asyncMap((_) async {
        AppLogger.debug('Realtime update received for daybook', tag: 'DayBook');
        final summary = await repo.getTodaySummary(hotelId);
        ref.read(currentDaybookIdProvider.notifier).state = summary.id;
        return summary;
      });
});

/// Provider for all transactions (optionally filtered by date)
final transactionsProvider =
    FutureProvider.family<List<Transaction>, DateTime?>((ref, date) async {
      final repo = ref.watch(dayBookRepositoryProvider);
      final hotelId = ref.watch(selectedHotelIdProvider);

      if (hotelId == null) {
        throw Exception('No hotel selected');
      }

      return repo.getTransactions(hotelId, date: date);
    });

/// Stream provider for real-time transaction updates
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(dayBookRepositoryProvider);
  final hotelId = ref.watch(selectedHotelIdProvider);
  final daybookId = ref.watch(currentDaybookIdProvider);

  if (hotelId == null || daybookId == null) {
    return Stream.value([]);
  }

  return repo.watchTransactions(hotelId, daybookId);
});

/// Provider for adding a transaction
final addTransactionProvider = FutureProvider.family<Transaction, Transaction>((
  ref,
  transaction,
) async {
  final repo = ref.read(dayBookRepositoryProvider);
  final result = await repo.addTransaction(transaction);

  // Invalidate the summary to refresh data
  ref.invalidate(todayDayBookProvider);

  return result;
});
