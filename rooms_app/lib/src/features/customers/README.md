# Customers Feature

## Overview
Manages customer records, profiles, and guest history.

## Structure
```
customers/
├── data/
│   └── repositories/
│       └── dummy_customer_repository.dart  # Mock implementation
├── domain/
│   ├── entities/
│   │   └── customer.dart              # Customer entity
│   └── repositories/
│       └── customer_repository.dart   # Repository interface
└── presentation/
    ├── pages/
    │   └── customers_page.dart        # Customer list/search view
    └── providers/
        └── customer_providers.dart    # Riverpod providers
```

## Key Providers
- `customerRepositoryProvider` - Provider for customer repository
- `allCustomersProvider` - FutureProvider for customer list
- `customerSearchProvider` - Provider for search functionality

## Customer Data
- Personal info (name, phone, email)
- ID details (Aadhaar number, ID photo)
- Biometric template (encrypted, for future use)
- Booking history
- Preferences and notes

## Usage
```dart
// Get all customers
final customers = ref.watch(allCustomersProvider);

// Search customers
final results = await ref.read(customerRepositoryProvider).searchCustomers(query);

// Get customer by ID
final customer = await ref.read(customerRepositoryProvider).getCustomer(id);
```

## Security
- ID photos stored securely
- Biometric templates encrypted at rest
- Access controlled by user role
