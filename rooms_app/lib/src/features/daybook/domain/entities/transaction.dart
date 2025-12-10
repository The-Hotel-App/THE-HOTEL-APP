/// Transaction type enumeration
enum TransactionType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }
}

/// Transaction category enumeration
enum TransactionCategory {
  roomPayment,
  foodService,
  laundry,
  salary,
  utilities,
  maintenance,
  supplies,
  other;

  String get displayName {
    switch (this) {
      case TransactionCategory.roomPayment:
        return 'Room Payment';
      case TransactionCategory.foodService:
        return 'Food & Service';
      case TransactionCategory.laundry:
        return 'Laundry';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.maintenance:
        return 'Maintenance';
      case TransactionCategory.supplies:
        return 'Supplies';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}

/// Transaction entity for day book
class Transaction {
  final String id;
  final String hotelId;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final String description;
  final String? bookingId;
  final DateTime createdAt;
  final String createdBy;

  const Transaction({
    required this.id,
    required this.hotelId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    this.bookingId,
    required this.createdAt,
    required this.createdBy,
  });

  Transaction copyWith({
    String? id,
    String? hotelId,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? description,
    String? bookingId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Transaction(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Day book summary for a single day
class DayBookSummary {
  final DateTime date;
  final double openingBalance;
  final double totalIncome;
  final double totalExpense;
  final List<Transaction> transactions;

  const DayBookSummary({
    required this.date,
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });

  double get closingBalance => openingBalance + totalIncome - totalExpense;
  double get netChange => totalIncome - totalExpense;
}
