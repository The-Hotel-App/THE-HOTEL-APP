import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';

/// Abstract repository interface for daybook operations
abstract class DayBookRepository {
  /// Get or create today's daybook summary for a hotel
  ///
  /// If no daybook exists for today, creates one with opening balance
  /// from the previous day's closing balance.
  Future<DayBookSummary> getTodaySummary(String hotelId);

  /// Get all transactions for a hotel, optionally filtered by date
  ///
  /// Returns transactions ordered by createdAt descending (newest first).
  Future<List<Transaction>> getTransactions(String hotelId, {DateTime? date});

  /// Add a new transaction to the daybook
  ///
  /// Validates that amount is positive before inserting.
  /// Updates the daybook closing balance accordingly.
  /// Returns the created transaction with generated ID.
  Future<Transaction> addTransaction(Transaction transaction);

  /// Watch transactions for real-time updates
  ///
  /// Returns a stream that emits updated transaction lists
  /// whenever changes occur in the daybook.
  Stream<List<Transaction>> watchTransactions(String hotelId, String daybookId);

  /// Get the previous day's closing balance for opening balance calculation
  ///
  /// Returns 0 if no previous daybook exists.
  Future<double> getPreviousDayClosingBalance(String hotelId, DateTime date);

  /// Delete a transaction from the daybook
  ///
  /// Updates the daybook closing balance accordingly.
  /// Only owners should be allowed to delete transactions.
  Future<void> deleteTransaction(Transaction transaction);

  /// Update the opening balance for today's daybook
  ///
  /// Also updates the closing balance by the same difference.
  /// Only owners should be allowed to update opening balance.
  Future<void> updateOpeningBalance(String daybookId, double newOpeningBalance);

  /// Get daybook summary for a specific date (historical viewing)
  ///
  /// Returns null if no daybook exists for that date.
  /// Does NOT create a new daybook (unlike getTodaySummary).
  /// Used for viewing historical records in read-only mode.
  Future<DayBookSummary?> getSummaryForDate(String hotelId, DateTime date);
}
