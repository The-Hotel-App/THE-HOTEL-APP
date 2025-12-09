# ROOMS.io - Hotel Internal Operations Mobile App

Flutter-based hotel management application for Android. Built for Owners, Managers, and Staff to manage hotel operations efficiently.

## 🏗️ Project Status: Initial Development Phase

Currently implemented:
- ✅ Feature-first architecture with clean separation (data/domain/presentation)
- ✅ Authentication flow with dummy login
- ✅ Role-based access control (Owner, Manager, Staff)
- ✅ Theme system with color-coded status indicators
- ✅ GoRouter navigation with auth guards
- ✅ Riverpod state management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.38.3 or higher
- Dart 3.10.1 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. Navigate to the app directory:
```bash
cd rooms_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🔐 Demo Credentials

Use these credentials to test different user roles:

| Role    | Email               | Password    |
|---------|---------------------|-------------|
| Owner   | owner@rooms.io      | owner123    |
| Manager | manager@rooms.io    | manager123  |
| Staff   | staff@rooms.io      | staff123    |

## 📁 Project Structure

```
lib/
├── src/
│   ├── core/                 # App-wide utilities
│   │   ├── constants/        # AppColors, AppConstants
│   │   ├── routing/          # GoRouter configuration
│   │   ├── theme/            # AppTheme
│   │   ├── config/           # Environment config
│   │   ├── error/            # Error handling
│   │   └── network/          # HTTP abstractions
│   ├── shared/               # Shared widgets
│   │   └── widgets/
│   ├── features/             # Feature modules
│   │   ├── auth/             # Authentication
│   │   ├── hotel_setup/      # Hotel setup wizard
│   │   ├── rooms/            # Room management
│   │   └── bookings/         # Customer bookings
│   ├── app.dart              # Main app widget
│   └── main.dart             # App entry point
├── assets/
│   ├── images/
│   └── icons/
```

## 🎨 Design Principles

- **Low-literacy UX**: Icon-driven, color-coded navigation
- **High contrast**: Clear visual indicators for room status
- **Large touch targets**: Minimum 48x48 dp for accessibility
- **Role-based UI**: Different features based on user role

## 🛠️ Tech Stack

- **Framework**: Flutter 3.38.3
- **State Management**: Riverpod 2.6.1
- **Routing**: GoRouter 14.6.2
- **Forms**: Flutter Form Builder 10.2.0
- **Storage**: SharedPreferences, FlutterSecureStorage
- **Network**: Dio 5.7.0

## 📋 Next Steps

- [ ] Hotel setup wizard (profile, floors, rooms, room types, staff)
- [ ] Room grid with real-time status
- [ ] Customer onboarding flow
- [ ] Booking management
- [ ] Day-book (revenue/expense tracking)
- [ ] Staff management
- [ ] Biometric authentication integration
- [ ] Backend integration (Supabase or AWS - TBD)

## 🧪 Development Commands

```bash
# Run analysis
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Build APK
flutter build apk
```

## 📖 Documentation

- [SRS.md](../SRS.md) - Full Software Requirements Specification
- [best_practices.md](../best_practices.md) - Frontend development guidelines
- [INITIAL-PROMPT.md](../INITIAL-PROMPT.md) - Original project vision

## 🔄 Backend Strategy

The app is designed to be **backend-agnostic**:
- All backend calls are abstracted behind repository interfaces
- Currently using `DummyAuthRepository` for development
- Can switch to Supabase or AWS by implementing repository interfaces
- No backend-specific code in domain or presentation layers

## 👥 User Roles & Permissions

### Owner
- Full access to all features
- Can edit past bookings and day-books
- Manage staff and settings

### Manager  
- View all data
- Edit current bookings
- Cannot edit past data or manage staff salaries

### Staff
- View ongoing operations only
- Update room status
- Onboard customers
- Limited access to historical data

## 🎯 Development Workflow

1. Features are built in isolation under `lib/src/features/`
2. Each feature has `data`, `domain`, and `presentation` layers
3. Domain layer is pure Dart (no Flutter dependencies)
4. All UI code goes in `presentation/pages` and `presentation/widgets`
5. State is managed through Riverpod providers in `presentation/providers`

---

**Version**: 0.1.0+1  
**License**: Proprietary  
**Platform**: Android Only (MVP)

