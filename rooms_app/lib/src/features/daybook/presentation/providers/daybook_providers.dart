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

/// Provider for selected date in daybook view (defaults to today)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Helper to check if selected date is today
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Provider to check if selected date is today
final isSelectedDateTodayProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final now = DateTime.now();
  return isSameDay(selectedDate, now);
});

/// Provider for daybook summary based on selected date
/// Returns null if no daybook exists for historical dates
final dayBookSummaryProvider = FutureProvider<DayBookSummary?>((ref) async {
  final repo = ref.watch(dayBookRepositoryProvider);
  final hotelId = ref.watch(selectedHotelIdProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final isToday = ref.watch(isSelectedDateTodayProvider);

  if (hotelId == null) {
    return null;
  }

  AppLogger.debug(
    'Fetching daybook for date: $selectedDate, isToday: $isToday',
    tag: 'DayBook',
  );

  if (isToday) {
    // Use getTodaySummary which creates if not exists
    final summary = await repo.getTodaySummary(hotelId);
    ref.read(currentDaybookIdProvider.notifier).state = summary.id;
    return summary;
  } else {
    // Use getSummaryForDate which returns null if not exists
    final summary = await repo.getSummaryForDate(hotelId, selectedDate);
    ref.read(currentDaybookIdProvider.notifier).state = summary?.id;
    return summary;
  }
});

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
