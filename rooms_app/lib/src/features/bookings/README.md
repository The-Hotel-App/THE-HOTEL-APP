# Bookings Feature

## Overview
Manages room bookings, reservations, and booking search functionality.

## Structure
```
bookings/
├── data/
│   └── repositories/
│       └── dummy_booking_repository.dart  # Mock implementation
├── domain/
│   ├── entities/
│   │   └── booking.dart      # Booking entity
│   └── repositories/
│       └── booking_repository.dart  # Repository interface
└── presentation/
    ├── pages/
    │   ├── booking_search_page.dart  # Search bookings by phone/name
    │   └── bookings_page.dart        # Bookings list view
    └── providers/
        └── booking_providers.dart    # Riverpod providers
```

## Key Providers
- `bookingRepositoryProvider` - Provider for booking repository
- `allBookingsProvider` - FutureProvider for all bookings
- `activeBookingsProvider` - Provider for currently active bookings

## Booking Status
- `pending` - Reservation made, not checked in
- `checkedIn` - Guest currently staying
- `checkedOut` - Completed stay
- `cancelled` - Cancelled booking

## Usage
```dart
// Get all bookings
final bookings = ref.watch(allBookingsProvider);

// Search bookings
final results = await ref.read(bookingRepositoryProvider).searchBookings(query);

// Create booking
await ref.read(bookingRepositoryProvider).createBooking(booking);
```
