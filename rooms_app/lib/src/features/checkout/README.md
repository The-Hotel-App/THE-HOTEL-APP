# Checkout Feature

## Overview
Handles the guest checkout flow including billing summary, payment settlement, and room status update.

## Structure
```
checkout/
├── data/
│   └── repositories/
│       └── checkout_repository.dart  # Checkout data operations
├── domain/
│   ├── entities/
│   │   └── checkout_data.dart        # Checkout summary entity
│   └── repositories/
│       └── checkout_repository.dart  # Repository interface
└── presentation/
    └── pages/
        └── checkout_flow_page.dart   # Checkout flow screen
```

## Checkout Flow
1. Display billing summary (room charges, extras, taxes)
2. Show payment status and balance due
3. Collect final payment if needed
4. Confirm checkout and update room status to 'cleaning'

## Key Providers
- `checkoutStateProvider` - StateNotifier for checkout flow
- `checkoutBillProvider` - Provider for calculated bill

## Usage
```dart
// Navigate to checkout with room
context.push(AppRoutes.checkout, extra: room);

// Complete checkout updates room status to 'cleaning'
```

## Post-Checkout Actions
- Room status changes to 'cleaning'
- Booking status changes to 'checkedOut'
- Transaction logged in daybook
