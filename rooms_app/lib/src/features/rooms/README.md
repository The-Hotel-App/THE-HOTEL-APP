# Rooms Feature

## Overview
Room management including room grid view, status updates, and room operations.

## Structure
```
rooms/
├── data/
│   └── repositories/
│       ├── dummy_room_repository.dart     # Mock implementation
│       └── supabase_room_repository.dart  # Supabase implementation
├── domain/
│   ├── entities/
│   │   └── room.dart                      # Room entity with status
│   └── repositories/
│       └── room_repository.dart           # Repository interface
└── presentation/
    ├── pages/
    │   ├── rooms_management_page.dart     # Room CRUD management
    │   └── rooms_page.dart                # Room grid/list view
    └── providers/
        └── room_providers.dart            # Riverpod providers
```

## Room Status
- `free` - Available for booking (Green)
- `occupied` - Guest currently staying (Red)
- `cleaning` - Being cleaned after checkout (Yellow)
- `maintenance` - Under maintenance (Orange)
- `outOfService` - Not available (Grey)

## Key Providers
- `roomRepositoryProvider` - Provider for room repository
- `allRoomsProvider` - StreamProvider for real-time room updates
- `roomsByFloorProvider` - Provider for grouped room view
- `roomsByStatusProvider` - Provider for filtered room view

## Usage
```dart
// Watch all rooms
final rooms = ref.watch(allRoomsProvider);

// Update room status
await ref.read(roomRepositoryProvider).updateRoomStatus(roomId, RoomStatus.cleaning);

// Get rooms by floor
final floorRooms = ref.watch(roomsByFloorProvider('1'));
```

## UI Guidelines
- Color is primary status indicator
- Always include icon + short text label
- Grid view for quick overview
- Tap for detailed actions sheet
