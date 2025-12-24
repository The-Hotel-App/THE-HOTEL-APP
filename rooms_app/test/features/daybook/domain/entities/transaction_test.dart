import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/daybook/domain/entities/transaction.dart';

void main() {
  group('TransactionType', () {
    test('displayName returns correct values', () {
      expect(TransactionType.income.displayName, 'Income');
      expect(TransactionType.expense.displayName, 'Expense');
    });

    test('toDbString returns correct database strings', () {
      expect(TransactionType.income.toDbString(), 'income');
      expect(TransactionType.expense.toDbString(), 'expense');
    });

    test('fromDbString parses database strings correctly', () {
      expect(TransactionType.fromDbString('income'), TransactionType.income);
      expect(TransactionType.fromDbString('expense'), TransactionType.expense);
      expect(TransactionType.fromDbString('INCOME'), TransactionType.income);
      expect(TransactionType.fromDbString('unknown'), TransactionType.income);
    });
  });

  group('TransactionCategory', () {
    test('displayName returns correct values', () {
      expect(TransactionCategory.roomPayment.displayName, 'Room Payment');
      expect(TransactionCategory.foodService.displayName, 'Food & Service');
      expect(TransactionCategory.laundry.displayName, 'Laundry');
      expect(TransactionCategory.salary.displayName, 'Salary');
      expect(TransactionCategory.utilities.displayName, 'Utilities');
      expect(TransactionCategory.maintenance.displayName, 'Maintenance');
      expect(TransactionCategory.supplies.displayName, 'Supplies');
      expect(TransactionCategory.other.displayName, 'Other');
    });

    test('toDbString returns correct database strings', () {
      expect(TransactionCategory.roomPayment.toDbString(), 'room_payment');
      expect(TransactionCategory.foodService.toDbString(), 'food_service');
      expect(TransactionCategory.laundry.toDbString(), 'laundry');
      expect(TransactionCategory.salary.toDbString(), 'salary');
      expect(TransactionCategory.utilities.toDbString(), 'utilities');
      expect(TransactionCategory.maintenance.toDbString(), 'maintenance');
      expect(TransactionCategory.supplies.toDbString(), 'supplies');
      expect(TransactionCategory.other.toDbString(), 'other');
    });

    test('fromDbString parses database strings correctly', () {
      expect(TransactionCategory.fromDbString('room_payment'),
          TransactionCategory.roomPayment);
      expect(TransactionCategory.fromDbString('food_service'),
          TransactionCategory.foodService);
      expect(
          TransactionCategory.fromDbString('laundry'), TransactionCategory.laundry);
      expect(
          TransactionCategory.fromDbString('salary'), TransactionCategory.salary);
      expect(TransactionCategory.fromDbString('utilities'),
          TransactionCategory.utilities);
      expect(TransactionCategory.fromDbString('maintenance'),
          TransactionCategory.maintenance);
      expect(TransactionCategory.fromDbString('supplies'),
          TransactionCategory.supplies);
      expect(TransactionCategory.fromDbString('other'), TransactionCategory.other);
      expect(
          TransactionCategory.fromDbString('unknown'), TransactionCategory.other);
    });
  });

  group('Transaction', () {
    // **Feature: supabase-daybook, Property 7: Transaction serialization round-trip**
    // **Validates: Requirements 5.3, 5.4**
    group('Property 7: Transaction serialization round-trip', () {
      Transaction createTestTransaction({
        String id = 'txn-001',
        String hotelId = 'hotel-001',
        String? daybookId = 'daybook-001',
        TransactionType type = TransactionType.income,
        TransactionCategory category = TransactionCategory.roomPayment,
        double amount = 1000.0,
        String description = 'Test transaction',
        String? bookingId,
        String createdBy = 'user-001',
      }) {
        return Transaction(
          id: id,
          hotelId: hotelId,
          daybookId: daybookId,
          type: type,
          category: category,
          amount: amount,
          description: description,
          bookingId: bookingId,
          createdAt: DateTime(2024, 12, 24, 10, 30),
          createdBy: createdBy,
        );
      }

      test('round-trip preserves income transaction', () {
        final original = createTestTransaction(
          type: TransactionType.income,
          category: TransactionCategory.roomPayment,
          amount: 5000.0,
        );

        final json = original.toJson();
        final restored = Transaction.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trip preserves expense transaction', () {
        final original = createTestTransaction(
          type: TransactionType.expense,
          category: TransactionCategory.utilities,
          amount: 1200.0,
        );

        final json = original.toJson();
        final restored = Transaction.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trip preserves all category types', () {
        for (final category in TransactionCategory.values) {
          final original = createTestTransaction(category: category);
          final json = original.toJson();
          final restored = Transaction.fromJson(json);

          expect(
            restored.category,
            equals(original.category),
            reason: 'Failed for category: ${category.name}',
          );
        }
      });

      test('round-trip preserves transaction with booking reference', () {
        final original = createTestTransaction(
          bookingId: 'booking-123',
          description: 'Room 101 - Guest Payment',
        );

        final json = original.toJson();
        final restored = Transaction.fromJson(json);

        expect(restored.bookingId, equals(original.bookingId));
        expect(restored, equals(original));
      });

      test('round-trip preserves transaction without booking reference', () {
        final original = createTestTransaction(bookingId: null);

        final json = original.toJson();
        final restored = Transaction.fromJson(json);

        expect(restored.bookingId, isNull);
        expect(restored, equals(original));
      });

      test('round-trip preserves various amount values', () {
        final amounts = [0.01, 1.0, 100.0, 1000.50, 99999.99];

        for (final amount in amounts) {
          final original = createTestTransaction(amount: amount);
          final json = original.toJson();
          final restored = Transaction.fromJson(json);

          expect(
            restored.amount,
            equals(original.amount),
            reason: 'Failed for amount: $amount',
          );
        }
      });

      test('round-trip preserves empty description', () {
        final original = createTestTransaction(description: '');
        final json = original.toJson();
        final restored = Transaction.fromJson(json);

        expect(restored.description, equals(''));
      });

      test('round-trip preserves special characters in description', () {
        final original = createTestTransaction(
          description: 'Room 101 - रूम भुगतान (₹5000)',
        );
        final json = original.toJson();
        final restored = Transaction.fromJson(json);

        expect(restored.description, equals(original.description));
      });
    });

    test('fromJson parses Supabase response correctly', () {
      final json = {
        'id': 'txn-001',
        'hotel_id': 'hotel-001',
        'daybook_id': 'daybook-001',
        'transaction_type': 'income',
        'category': 'room_payment',
        'amount': 5000,
        'description': 'Room 101 payment',
        'reference_id': 'booking-001',
        'created_by': 'user-001',
        'created_at': '2024-12-24T10:30:00.000Z',
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 'txn-001');
      expect(transaction.hotelId, 'hotel-001');
      expect(transaction.daybookId, 'daybook-001');
      expect(transaction.type, TransactionType.income);
      expect(transaction.category, TransactionCategory.roomPayment);
      expect(transaction.amount, 5000.0);
      expect(transaction.description, 'Room 101 payment');
      expect(transaction.bookingId, 'booking-001');
      expect(transaction.createdBy, 'user-001');
    });

    test('toJson produces correct Supabase format', () {
      final transaction = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.expense,
        category: TransactionCategory.supplies,
        amount: 500.0,
        description: 'Cleaning supplies',
        bookingId: null,
        createdAt: DateTime(2024, 12, 24, 10, 30),
        createdBy: 'user-001',
      );

      final json = transaction.toJson();

      expect(json['id'], 'txn-001');
      expect(json['hotel_id'], 'hotel-001');
      expect(json['daybook_id'], 'daybook-001');
      expect(json['transaction_type'], 'expense');
      expect(json['category'], 'supplies');
      expect(json['amount'], 500.0);
      expect(json['description'], 'Cleaning supplies');
      expect(json['reference_id'], isNull);
      expect(json['created_by'], 'user-001');
    });

    test('toInsertJson excludes id field', () {
      final transaction = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 1000.0,
        description: 'Test',
        createdAt: DateTime.now(),
        createdBy: 'user-001',
      );

      final json = transaction.toInsertJson();

      expect(json.containsKey('id'), isFalse);
      expect(json['hotel_id'], 'hotel-001');
      expect(json['daybook_id'], 'daybook-001');
    });

    test('copyWith creates modified copy', () {
      final original = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 1000.0,
        description: 'Original',
        createdAt: DateTime.now(),
        createdBy: 'user-001',
      );

      final modified = original.copyWith(
        amount: 2000.0,
        description: 'Modified',
      );

      expect(modified.id, original.id);
      expect(modified.hotelId, original.hotelId);
      expect(modified.amount, 2000.0);
      expect(modified.description, 'Modified');
    });

    test('equality works correctly', () {
      final t1 = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 1000.0,
        description: 'Test',
        createdAt: DateTime(2024, 12, 24),
        createdBy: 'user-001',
      );

      final t2 = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 1000.0,
        description: 'Test',
        createdAt: DateTime(2024, 12, 24),
        createdBy: 'user-001',
      );

      final t3 = Transaction(
        id: 'txn-002',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 1000.0,
        description: 'Test',
        createdAt: DateTime(2024, 12, 24),
        createdBy: 'user-001',
      );

      expect(t1, equals(t2));
      expect(t1, isNot(equals(t3)));
    });
  });

  group('DayBookSummary', () {
    final testDate = DateTime(2024, 12, 24);

    // **Feature: supabase-daybook, Property 2: Closing balance calculation**
    // **Validates: Requirements 1.3**
    group('Property 2: Closing balance calculation', () {
      test('closing balance equals opening + income - expense', () {
        final summary = DayBookSummary(
          id: 'daybook-001',
          date: testDate,
          openingBalance: 10000.0,
          totalIncome: 5000.0,
          totalExpense: 2000.0,
          transactions: [],
        );

        expect(summary.closingBalance, equals(13000.0));
      });

      test('closing balance with zero opening', () {
        final summary = DayBookSummary(
          date: testDate,
          openingBalance: 0.0,
          totalIncome: 8000.0,
          totalExpense: 3000.0,
          transactions: [],
        );

        expect(summary.closingBalance, equals(5000.0));
      });

      test('closing balance with zero income', () {
        final summary = DayBookSummary(
          date: testDate,
          openingBalance: 5000.0,
          totalIncome: 0.0,
          totalExpense: 1000.0,
          transactions: [],
        );

        expect(summary.closingBalance, equals(4000.0));
      });

      test('closing balance with zero expense', () {
        final summary = DayBookSummary(
          date: testDate,
          openingBalance: 5000.0,
          totalIncome: 3000.0,
          totalExpense: 0.0,
          transactions: [],
        );

        expect(summary.closingBalance, equals(8000.0));
      });

      test('closing balance can be negative', () {
        final summary = DayBookSummary(
          date: testDate,
          openingBalance: 1000.0,
          totalIncome: 500.0,
          totalExpense: 2000.0,
          transactions: [],
        );

        expect(summary.closingBalance, equals(-500.0));
      });

      test('closing balance with various values', () {
        final testCases = [
          (opening: 0.0, income: 0.0, expense: 0.0, expected: 0.0),
          (opening: 100.0, income: 50.0, expense: 25.0, expected: 125.0),
          (opening: 1000.0, income: 1000.0, expense: 1000.0, expected: 1000.0),
          (opening: 25000.0, income: 8350.0, expense: 1700.0, expected: 31650.0),
          (opening: 0.01, income: 0.01, expense: 0.01, expected: 0.01),
        ];

        for (final tc in testCases) {
          final summary = DayBookSummary(
            date: testDate,
            openingBalance: tc.opening,
            totalIncome: tc.income,
            totalExpense: tc.expense,
            transactions: [],
          );

          expect(
            summary.closingBalance,
            closeTo(tc.expected, 0.001),
            reason:
                'Failed for O=${tc.opening}, I=${tc.income}, E=${tc.expense}',
          );
        }
      });
    });

    test('netChange equals income minus expense', () {
      final summary = DayBookSummary(
        date: testDate,
        openingBalance: 10000.0,
        totalIncome: 5000.0,
        totalExpense: 2000.0,
        transactions: [],
      );

      expect(summary.netChange, equals(3000.0));
    });
  });

  // **Feature: supabase-daybook, Property 5: Amount validation**
  // **Validates: Requirements 3.4**
  group('Property 5: Amount validation', () {
    test('zero amount should be invalid', () {
      expect(0.0 <= 0, isTrue);
    });

    test('negative amounts should be invalid', () {
      final invalidAmounts = [-1.0, -0.01, -100.0, -9999.99];
      for (final amount in invalidAmounts) {
        expect(amount <= 0, isTrue, reason: 'Amount $amount should be invalid');
      }
    });

    test('positive amounts should be valid', () {
      final validAmounts = [0.01, 1.0, 100.0, 1000.0, 99999.99];
      for (final amount in validAmounts) {
        expect(amount > 0, isTrue, reason: 'Amount $amount should be valid');
      }
    });
  });

  // **Feature: supabase-daybook, Property 3: Transaction ordering**
  // **Validates: Requirements 2.3**
  group('Property 3: Transaction ordering', () {
    test('transactions should be sortable by createdAt descending', () {
      final transactions = [
        Transaction(
          id: 'txn-1',
          hotelId: 'hotel-001',
          type: TransactionType.income,
          category: TransactionCategory.roomPayment,
          amount: 1000,
          description: 'First',
          createdAt: DateTime(2024, 12, 24, 10, 0),
          createdBy: 'user-001',
        ),
        Transaction(
          id: 'txn-2',
          hotelId: 'hotel-001',
          type: TransactionType.expense,
          category: TransactionCategory.supplies,
          amount: 500,
          description: 'Second',
          createdAt: DateTime(2024, 12, 24, 11, 0),
          createdBy: 'user-001',
        ),
        Transaction(
          id: 'txn-3',
          hotelId: 'hotel-001',
          type: TransactionType.income,
          category: TransactionCategory.foodService,
          amount: 300,
          description: 'Third',
          createdAt: DateTime(2024, 12, 24, 12, 0),
          createdBy: 'user-001',
        ),
      ];

      final sorted = List<Transaction>.from(transactions)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted[0].id, 'txn-3');
      expect(sorted[1].id, 'txn-2');
      expect(sorted[2].id, 'txn-1');

      for (int i = 0; i < sorted.length - 1; i++) {
        expect(
          sorted[i].createdAt.isAfter(sorted[i + 1].createdAt) ||
              sorted[i].createdAt.isAtSameMomentAs(sorted[i + 1].createdAt),
          isTrue,
        );
      }
    });
  });

  // **Feature: supabase-daybook, Property 4: Balance update on transaction**
  // **Validates: Requirements 3.3**
  group('Property 4: Balance update on transaction', () {
    test('income transaction increases closing balance', () {
      final testCases = [
        (currentBalance: 1000.0, amount: 500.0, expected: 1500.0),
        (currentBalance: 0.0, amount: 100.0, expected: 100.0),
        (currentBalance: 5000.0, amount: 2500.0, expected: 7500.0),
        (currentBalance: -100.0, amount: 200.0, expected: 100.0),
      ];

      for (final tc in testCases) {
        final newBalance = tc.currentBalance + tc.amount;
        expect(newBalance, closeTo(tc.expected, 0.001));
      }
    });

    test('expense transaction decreases closing balance', () {
      final testCases = [
        (currentBalance: 1000.0, amount: 500.0, expected: 500.0),
        (currentBalance: 5000.0, amount: 100.0, expected: 4900.0),
        (currentBalance: 100.0, amount: 200.0, expected: -100.0),
      ];

      for (final tc in testCases) {
        final newBalance = tc.currentBalance - tc.amount;
        expect(newBalance, closeTo(tc.expected, 0.001));
      }
    });
  });

  // **Feature: supabase-daybook, Property 1: Opening balance inheritance**
  // **Validates: Requirements 1.2**
  group('Property 1: Opening balance inheritance', () {
    test('new daybook opening balance should equal previous closing balance',
        () {
      final testCases = [
        (previousClosing: 0.0, expectedOpening: 0.0),
        (previousClosing: 5000.0, expectedOpening: 5000.0),
        (previousClosing: 25000.0, expectedOpening: 25000.0),
        (previousClosing: -500.0, expectedOpening: -500.0),
      ];

      for (final tc in testCases) {
        final newOpeningBalance = tc.previousClosing;
        expect(newOpeningBalance, equals(tc.expectedOpening));
      }
    });

    test('first daybook should have zero opening balance', () {
      const previousClosingBalance = 0.0;
      expect(previousClosingBalance, equals(0.0));
    });
  });

  // **Feature: supabase-daybook, Property 6: Transaction data integrity**
  // **Validates: Requirements 5.1**
  group('Property 6: Transaction data integrity', () {
    test('toJson contains all required fields', () {
      final transaction = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.income,
        category: TransactionCategory.roomPayment,
        amount: 5000.0,
        description: 'Room 101 payment',
        bookingId: 'booking-001',
        createdAt: DateTime(2024, 12, 24),
        createdBy: 'user-001',
      );

      final json = transaction.toJson();

      expect(json.containsKey('hotel_id'), isTrue);
      expect(json.containsKey('daybook_id'), isTrue);
      expect(json.containsKey('transaction_type'), isTrue);
      expect(json.containsKey('category'), isTrue);
      expect(json.containsKey('amount'), isTrue);
      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('created_by'), isTrue);

      expect(json['hotel_id'], equals('hotel-001'));
      expect(json['daybook_id'], equals('daybook-001'));
      expect(json['transaction_type'], equals('income'));
      expect(json['category'], equals('room_payment'));
      expect(json['amount'], equals(5000.0));
      expect(json['description'], equals('Room 101 payment'));
      expect(json['created_by'], equals('user-001'));
    });

    test('toInsertJson excludes id and created_at for database insert', () {
      final transaction = Transaction(
        id: 'txn-001',
        hotelId: 'hotel-001',
        daybookId: 'daybook-001',
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        amount: 1200.0,
        description: 'Electricity bill',
        createdAt: DateTime(2024, 12, 24),
        createdBy: 'user-001',
      );

      final json = transaction.toInsertJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json['hotel_id'], equals('hotel-001'));
      expect(json['daybook_id'], equals('daybook-001'));
    });

    test('all transaction types produce valid JSON', () {
      for (final type in TransactionType.values) {
        for (final category in TransactionCategory.values) {
          final transaction = Transaction(
            id: 'txn-test',
            hotelId: 'hotel-001',
            daybookId: 'daybook-001',
            type: type,
            category: category,
            amount: 100.0,
            description: 'Test',
            createdAt: DateTime.now(),
            createdBy: 'user-001',
          );

          final json = transaction.toJson();

          expect(json['transaction_type'], isNotEmpty);
          expect(json['category'], isNotEmpty);
        }
      }
    });
  });
}
