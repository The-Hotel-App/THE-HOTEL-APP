import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms/src/features/daybook/data/repositories/dummy_daybook_repository.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';

/// Provider for day book repository
final dayBookRepositoryProvider = Provider<DummyDayBookRepository>((ref) {
  return DummyDayBookRepository();
});

/// Provider for today's day book summary
final todayDayBookProvider = FutureProvider<DayBookSummary>((ref) async {
  final repo = ref.watch(dayBookRepositoryProvider);
  return repo.getTodaySummary('hotel-001');
});

/// Provider for all transactions
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.watch(dayBookRepositoryProvider);
  return repo.getTransactions('hotel-001');
});
