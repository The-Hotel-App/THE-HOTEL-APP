# Hotel Setup Feature

## Overview
Initial hotel setup wizard for new hotel onboarding, including owner registration, hotel profile, and room configuration.

## Structure
```
hotel_setup/
├── data/
│   └── repositories/
│       ├── local_hotel_setup_repository.dart    # Local storage impl
│       └── supabase_hotel_setup_repository.dart # Supabase impl
├── domain/
│   ├── entities/
│   │   ├── hotel.dart       # Legacy hotel entity
│   │   ├── hotel_new.dart   # New hotel entity
│   │   └── room_type.dart   # Room type configuration
│   └── repositories/
│       └── hotel_setup_repository.dart  # Repository interface
└── presentation/
    ├── pages/
    │   └── hotel_setup_wizard_page.dart  # Multi-step wizard
    └── providers/
        └── setup_providers.dart          # Setup state management
```

## Setup Wizard Steps
1. **Owner Registration** - Create owner account (name, email, password)
2. **Hotel Profile** - Hotel name, address, contact info
3. **Floors & Rooms** - Configure floor count and room numbers per floor
4. **Room Types** - Define room categories and pricing

## Key Providers
- `setupStateProvider` - StateNotifier for wizard state
- `hotelSetupRepositoryProvider` - Provider for setup repository
- `roomTypesProvider` - Provider for room type configurations

## Usage
```dart
// Navigate to setup (redirected if no hotel selected)
context.go(AppRoutes.setup);

// Complete setup creates hotel and rooms in database
await ref.read(hotelSetupRepositoryProvider).createHotel(hotelData);
```

## Post-Setup
- Hotel created in database
- Owner linked to hotel
- Rooms generated based on configuration
- Redirect to owner dashboard
