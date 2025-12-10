# Daybook Feature

## Overview
Daily financial transaction log for tracking all payments, expenses, and cash flow.

## Structure
```
daybook/
├── data/
│   └── repositories/
│       └── dummy_daybook_repository.dart  # Mock implementation
├── domain/
│   ├── entities/
│   │   └── transaction.dart               # Transaction entity
│   └── repositories/
│       └── (to be added)                  # Repository interface
└── presentation/
    ├── pages/
    │   └── daybook_page.dart              # Transaction list view
    └── providers/
        └── daybook_providers.dart         # Riverpod providers
```

## Transaction Types
- `roomPayment` - Guest room charges
- `foodOrder` - Restaurant/room service
- `laundry` - Laundry services
- `expense` - Operational expenses
- `refund` - Customer refunds

## Key Providers
- `daybookRepositoryProvider` - Provider for daybook repository
- `todayTransactionsProvider` - FutureProvider for today's entries
- `dateRangeTransactionsProvider` - Provider for filtered transactions

## Usage
```dart
// Get today's transactions
final transactions = ref.watch(todayTransactionsProvider);

// Add new transaction
await ref.read(daybookRepositoryProvider).addTransaction(transaction);

// Get daily summary
final summary = await ref.read(daybookRepositoryProvider).getDailySummary(date);
```

## Access Control
- Owner: Full access, can edit past entries
- Manager: Can add entries, view all
- Staff: Can add entries (auto-logged)
