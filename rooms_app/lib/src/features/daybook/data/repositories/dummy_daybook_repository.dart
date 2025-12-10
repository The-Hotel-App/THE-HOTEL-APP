import 'dart:async';

import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';

/// Dummy day book repository with mock data
class DummyDayBookRepository {
  final List<Transaction> _transactions = [];

  DummyDayBookRepository() {
    _initializeDummyTransactions();
  }

  void _initializeDummyTransactions() {
    final now = DateTime.now();
    _transactions.addAll([
      Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 6000,
        description: 'Room 101 - Rajesh Kumar',
        bookingId: 'book-001',
        createdAt: now.subtract(const Duration(hours: 5)),
        createdBy: 'user-002',
      ),
      Transaction(
        id: 'txn-002',
        hotelId: 'hotel-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 2000,
        description: 'Room 205 - Priya Sharma (Advance)',
        bookingId: 'book-002',
        createdAt: now.subtract(const Duration(hours: 4)),
        createdBy: 'user-002',
      ),
      Transaction(
        id: 'txn-003',
        hotelId: 'hotel-001',
        type: TransactionType.expense,
        category: TransactionCategory.supplies,
        amount: 500,
        description: 'Cleaning supplies',
        createdAt: now.subtract(const Duration(hours: 3)),
        createdBy: 'user-001',
      ),
      Transaction(
        id: 'txn-004',
        hotelId: 'hotel-001',
        type: TransactionType.income,
        category: TransactionCategory.foodService,
        amount: 350,
        description: 'Room service - Room 101',
        createdAt: now.subtract(const Duration(hours: 2)),
        createdBy: 'user-003',
      ),
      Transaction(
        id: 'txn-005',
        hotelId: 'hotel-001',
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        amount: 1200,
        description: 'Electricity bill',
        createdAt: now.subtract(const Duration(hours: 1)),
        createdBy: 'user-001',
      ),
    ]);
  }

  Future<DayBookSummary> getTodaySummary(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final today = DateTime.now();
    final todayTransactions = _transactions.where((t) {
      return t.hotelId == hotelId &&
          t.createdAt.year == today.year &&
          t.createdAt.month == today.month &&
          t.createdAt.day == today.day;
    }).toList();

    final totalIncome = todayTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = todayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return DayBookSummary(
      date: today,
      openingBalance: 25000, // Mock opening balance
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactions: todayTransactions,
    );
  }

  Future<List<Transaction>> getTransactions(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _transactions.where((t) => t.hotelId == hotelId).toList();
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.add(transaction);
    return transaction;
  }
}
