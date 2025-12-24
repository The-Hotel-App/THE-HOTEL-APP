import 'package:rooms/src/core/logging/app_logger.dart';
import 'package:rooms/src/core/services/supabase_service.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';
import 'package:rooms/src/features/daybook/domain/repositories/daybook_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of DayBookRepository
class SupabaseDayBookRepository implements DayBookRepository {
  final SupabaseClient _client;

  SupabaseDayBookRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Format date for database queries (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get start of day for a given date
  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Future<DayBookSummary> getTodaySummary(String hotelId) async {
    try {
      AppLogger.debug('Fetching today daybook for hotel: $hotelId', tag: 'DayBook');
      
      final today = _startOfDay(DateTime.now());
      final dateStr = _formatDate(today);

      // Try to get existing daybook for today
      var daybookResponse = await _client
          .from('daybooks')
          .select()
          .eq('hotel_id', hotelId)
          .eq('date', dateStr)
          .maybeSingle();

      String daybookId;
      double openingBalance;

      if (daybookResponse == null) {
        // Create new daybook for today
        AppLogger.info('Creating new daybook for today', tag: 'DayBook');
        
        // Get previous day's closing balance
        openingBalance = await getPreviousDayClosingBalance(hotelId, today);
        
        final insertResponse = await _client
            .from('daybooks')
            .insert({
              'hotel_id': hotelId,
              'date': dateStr,
              'opening_balance': openingBalance,
              'closing_balance': openingBalance,
              'created_by': SupabaseService.instance.currentUserId,
            })
            .select()
            .single();
        
        daybookId = insertResponse['id'] as String;
        AppLogger.success('Created daybook: $daybookId', tag: 'DayBook');
      } else {
        daybookId = daybookResponse['id'] as String;
        openingBalance = (daybookResponse['opening_balance'] as num).toDouble();
      }

      // Fetch transactions for this daybook
      final transactionsResponse = await _client
          .from('daybook_transactions')
          .select()
          .eq('daybook_id', daybookId)
          .order('created_at', ascending: false);

      final transactions = (transactionsResponse as List)
          .map((json) => Transaction.fromJson(json))
          .toList();

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      
      for (final t in transactions) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      AppLogger.success(
        'Fetched daybook summary: ${transactions.length} transactions',
        tag: 'DayBook',
      );

      return DayBookSummary(
        id: daybookId,
        date: today,
        openingBalance: openingBalance,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        transactions: transactions,
      );
    } catch (e) {
      AppLogger.error('Error fetching daybook summary', tag: 'DayBook', error: e);
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getTransactions(String hotelId, {DateTime? date}) async {
    try {
      AppLogger.debug('Fetching transactions for hotel: $hotelId', tag: 'DayBook');

      var query = _client
          .from('daybook_transactions')
          .select()
          .eq('hotel_id', hotelId);

      if (date != null) {
        // Filter by date - get daybook for that date first
        final dateStr = _formatDate(date);
        final daybookResponse = await _client
            .from('daybooks')
            .select('id')
            .eq('hotel_id', hotelId)
            .eq('date', dateStr)
            .maybeSingle();

        if (daybookResponse == null) {
          return [];
        }

        query = query.eq('daybook_id', daybookResponse['id']);
      }

      final response = await query.order('created_at', ascending: false);

      final transactions = (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();

      AppLogger.success('Fetched ${transactions.length} transactions', tag: 'DayBook');
      return transactions;
    } catch (e) {
      AppLogger.error('Error fetching transactions', tag: 'DayBook', error: e);
      rethrow;
    }
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      // Validate amount
      if (transaction.amount <= 0) {
        throw ArgumentError('Transaction amount must be positive');
      }

      AppLogger.info(
        'Adding ${transaction.type.displayName} transaction: ₹${transaction.amount}',
        tag: 'DayBook',
      );

      // Insert transaction
      final response = await _client
          .from('daybook_transactions')
          .insert(transaction.toInsertJson())
          .select()
          .single();

      final createdTransaction = Transaction.fromJson(response);

      // Update daybook closing balance
      await _updateDaybookClosingBalance(
        transaction.daybookId!,
        transaction.type,
        transaction.amount,
      );

      AppLogger.success('Transaction added successfully', tag: 'DayBook');
      return createdTransaction;
    } catch (e) {
      AppLogger.error('Error adding transaction', tag: 'DayBook', error: e);
      rethrow;
    }
  }

  /// Update the daybook closing balance after a transaction
  Future<void> _updateDaybookClosingBalance(
    String daybookId,
    TransactionType type,
    double amount,
  ) async {
    try {
      // Get current closing balance
      final daybook = await _client
          .from('daybooks')
          .select('closing_balance')
          .eq('id', daybookId)
          .single();

      final currentBalance = (daybook['closing_balance'] as num).toDouble();
      final newBalance = type == TransactionType.income
          ? currentBalance + amount
          : currentBalance - amount;

      // Update closing balance
      await _client
          .from('daybooks')
          .update({'closing_balance': newBalance})
          .eq('id', daybookId);

      AppLogger.debug(
        'Updated closing balance: $currentBalance -> $newBalance',
        tag: 'DayBook',
      );
    } catch (e) {
      AppLogger.error('Error updating closing balance', tag: 'DayBook', error: e);
      rethrow;
    }
  }

  @override
  Stream<List<Transaction>> watchTransactions(String hotelId, String daybookId) {
    return _client
        .from('daybook_transactions')
        .stream(primaryKey: ['id'])
        .eq('daybook_id', daybookId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Transaction.fromJson(json)).toList());
  }

  @override
  Future<double> getPreviousDayClosingBalance(String hotelId, DateTime date) async {
    try {
      final previousDay = date.subtract(const Duration(days: 1));
      final dateStr = _formatDate(previousDay);

      AppLogger.debug('Getting previous day closing balance for $dateStr', tag: 'DayBook');

      final response = await _client
          .from('daybooks')
          .select('closing_balance')
          .eq('hotel_id', hotelId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) {
        AppLogger.debug('No previous daybook found, returning 0', tag: 'DayBook');
        return 0;
      }

      final balance = (response['closing_balance'] as num).toDouble();
      AppLogger.debug('Previous day closing balance: $balance', tag: 'DayBook');
      return balance;
    } catch (e) {
      AppLogger.error('Error getting previous day balance', tag: 'DayBook', error: e);
      return 0;
    }
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      AppLogger.info(
        'Deleting ${transaction.type.displayName} transaction: ₹${transaction.amount}',
        tag: 'DayBook',
      );

      // Delete the transaction
      await _client
          .from('daybook_transactions')
          .delete()
          .eq('id', transaction.id);

      // Reverse the balance update (opposite of add)
      // If it was income, we subtract; if expense, we add back
      if (transaction.daybookId != null) {
        final reverseType = transaction.type == TransactionType.income
            ? TransactionType.expense
            : TransactionType.income;
        
        await _updateDaybookClosingBalance(
          transaction.daybookId!,
          reverseType,
          transaction.amount,
        );
      }

      AppLogger.success('Transaction deleted successfully', tag: 'DayBook');
    } catch (e) {
      AppLogger.error('Error deleting transaction', tag: 'DayBook', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateOpeningBalance(String daybookId, double newOpeningBalance) async {
    try {
      AppLogger.info(
        'Updating opening balance to ₹${newOpeningBalance.toStringAsFixed(0)}',
        tag: 'DayBook',
      );

      // Get current balances
      final daybook = await _client
          .from('daybooks')
          .select('opening_balance, closing_balance')
          .eq('id', daybookId)
          .single();

      final currentOpening = (daybook['opening_balance'] as num).toDouble();
      final currentClosing = (daybook['closing_balance'] as num).toDouble();
      
      // Calculate the difference and apply to closing balance
      final difference = newOpeningBalance - currentOpening;
      final newClosing = currentClosing + difference;

      // Update both opening and closing balance
      await _client
          .from('daybooks')
          .update({
            'opening_balance': newOpeningBalance,
            'closing_balance': newClosing,
          })
          .eq('id', daybookId);

      AppLogger.success(
        'Updated opening balance: $currentOpening -> $newOpeningBalance, closing: $currentClosing -> $newClosing',
        tag: 'DayBook',
      );
    } catch (e) {
      AppLogger.error('Error updating opening balance', tag: 'DayBook', error: e);
      rethrow;
    }
  }
}
