# Settings Feature

## Overview
Application settings including hotel configuration, staff management, room types, and user preferences.

## Structure
```
settings/
├── data/
│   └── repositories/
│       └── settings_repository.dart       # Settings data operations
├── domain/
│   ├── entities/
│   │   └── settings.dart                  # Settings entity
│   └── repositories/
│       └── settings_repository.dart       # Repository interface
└── presentation/
    └── pages/
        ├── change_password_page.dart      # Password update
        ├── create_staff_page.dart         # Add new staff member
        ├── hotel_settings_page.dart       # Hotel configuration
        ├── notifications_page.dart        # Notification preferences
        ├── room_types_page.dart           # Room type management
        └── staff_page.dart                # Staff list and management
```

## Settings Pages

### Hotel Settings
- Hotel name, address, contact
- Tax configuration
- Check-in/out times
- Logo and branding

### Staff Management
- Add/edit staff members
- Assign roles
- Deactivate accounts
- Reset passwords

### Room Types
- Create room categories
- Set pricing
- Configure amenities
- Assign to rooms

### Notifications
- Push notification preferences
- Alert settings

## Key Providers
- `settingsRepositoryProvider` - Provider for settings repository
- `hotelSettingsProvider` - Provider for hotel configuration
- `staffListProvider` - Provider for staff members

## Access Control
- Hotel Settings: Owner only
- Staff Management: Owner only
- Room Types: Owner only
- Change Password: All authenticated users
