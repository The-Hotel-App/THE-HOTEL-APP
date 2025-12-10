# Auth Feature

## Overview
Handles user authentication, authorization, and session management for the hotel app.

## Structure
```
auth/
├── data/
│   └── repositories/
│       ├── dummy_auth_repository.dart    # Mock implementation for development
│       └── supabase_auth_repository.dart # Production Supabase implementation
├── domain/
│   ├── entities/
│   │   ├── user.dart      # Legacy user entity
│   │   └── user_new.dart  # New user entity with hotel associations
│   └── repositories/
│       ├── auth_repository.dart     # Legacy interface
│       └── auth_repository_new.dart # New interface with hotel support
└── presentation/
    ├── pages/
    │   ├── home_page.dart       # Main home screen
    │   ├── login_page.dart      # Login screen
    │   └── welcome_screen.dart  # Initial welcome/splash screen
    └── providers/
        ├── auth_providers.dart     # Legacy providers
        └── auth_providers_new.dart # New providers with Supabase
```

## Key Providers
- `currentUserProvider` - StreamProvider for the authenticated user
- `authRepositoryProvider` - Provider for auth repository implementation
- `currentHotelProvider` - StateProvider for selected hotel context

## User Roles
- `owner` - Full access to all features
- `manager` - Operational access, no staff/financial management
- `staff` - Limited to room operations and check-in/out
- `kitchenManager` - Kitchen and food order management only

## Usage
```dart
// Watch current user
final user = ref.watch(currentUserProvider);

// Login
await ref.read(authRepositoryProvider).login(email: email, password: password);

// Logout
await ref.read(authRepositoryProvider).signOut();
```
