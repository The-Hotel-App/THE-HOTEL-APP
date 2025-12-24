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

  /// Convert to database string format
  String toDbString() {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }

  /// Parse from database string
  static TransactionType fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.income;
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

  /// Convert to database string format
  String toDbString() {
    switch (this) {
      case TransactionCategory.roomPayment:
        return 'room_payment';
      case TransactionCategory.foodService:
        return 'food_service';
      case TransactionCategory.laundry:
        return 'laundry';
      case TransactionCategory.salary:
        return 'salary';
      case TransactionCategory.utilities:
        return 'utilities';
      case TransactionCategory.maintenance:
        return 'maintenance';
      case TransactionCategory.supplies:
        return 'supplies';
      case TransactionCategory.other:
        return 'other';
    }
  }

  /// Parse from database string
  static TransactionCategory fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'room_payment':
        return TransactionCategory.roomPayment;
      case 'food_service':
        return TransactionCategory.foodService;
      case 'laundry':
        return TransactionCategory.laundry;
      case 'salary':
        return TransactionCategory.salary;
      case 'utilities':
        return TransactionCategory.utilities;
      case 'maintenance':
        return TransactionCategory.maintenance;
      case 'supplies':
        return TransactionCategory.supplies;
      case 'other':
      default:
        return TransactionCategory.other;
    }
  }
}

/// Transaction entity for day book
class Transaction {
  final String id;
  final String hotelId;
  final String? daybookId;
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
    this.daybookId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    this.bookingId,
    required this.createdAt,
    required this.createdBy,
  });

  /// Create Transaction from Supabase JSON response
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      hotelId: json['hotel_id'] as String,
      daybookId: json['daybook_id'] as String?,
      type: TransactionType.fromDbString(json['transaction_type'] as String),
      category: TransactionCategory.fromDbString(json['category'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      bookingId: json['reference_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String? ?? '',
    );
  }

  /// Convert Transaction to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'daybook_id': daybookId,
      'transaction_type': type.toDbString(),
      'category': category.toDbString(),
      'amount': amount,
      'description': description,
      'reference_id': bookingId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON for insert (without id, let DB generate it)
  Map<String, dynamic> toInsertJson() {
    return {
      'hotel_id': hotelId,
      'daybook_id': daybookId,
      'transaction_type': type.toDbString(),
      'category': category.toDbString(),
      'amount': amount,
      'description': description,
      'reference_id': bookingId,
      'created_by': createdBy,
    };
  }

  Transaction copyWith({
    String? id,
    String? hotelId,
    String? daybookId,
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
      daybookId: daybookId ?? this.daybookId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.hotelId == hotelId &&
        other.daybookId == daybookId &&
        other.type == type &&
        other.category == category &&
        other.amount == amount &&
        other.description == description &&
        other.bookingId == bookingId &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      hotelId,
      daybookId,
      type,
      category,
      amount,
      description,
      bookingId,
      createdBy,
    );
  }
}

/// Day book summary for a single day
class DayBookSummary {
  final String? id;
  final DateTime date;
  final double openingBalance;
  final double totalIncome;
  final double totalExpense;
  final List<Transaction> transactions;

  const DayBookSummary({
    this.id,
    required this.date,
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });

  double get closingBalance => openingBalance + totalIncome - totalExpense;
  double get netChange => totalIncome - totalExpense;
}
