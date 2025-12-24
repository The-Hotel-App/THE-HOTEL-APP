import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Provider for today's day book summary
final todayDayBookProvider = FutureProvider<DayBookSummary>((ref) async {
  final repo = ref.watch(dayBookRepositoryProvider);
  final hotelId = ref.watch(selectedHotelIdProvider);

  if (hotelId == null) {
    throw Exception('No hotel selected');
  }

  final summary = await repo.getTodaySummary(hotelId);

  // Store the daybook ID for real-time updates
  ref.read(currentDaybookIdProvider.notifier).state = summary.id;

  return summary;
});

/// Provider for all transactions (optionally filtered by date)
final transactionsProvider = FutureProvider.family<List<Transaction>, DateTime?>(
  (ref, date) async {
    final repo = ref.watch(dayBookRepositoryProvider);
    final hotelId = ref.watch(selectedHotelIdProvider);

    if (hotelId == null) {
      throw Exception('No hotel selected');
    }

    return repo.getTransactions(hotelId, date: date);
  },
);

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
final addTransactionProvider = FutureProvider.family<Transaction, Transaction>(
  (ref, transaction) async {
    final repo = ref.read(dayBookRepositoryProvider);
    final result = await repo.addTransaction(transaction);

    // Invalidate the summary to refresh data
    ref.invalidate(todayDayBookProvider);

    return result;
  },
);
