# Dashboards Feature

## Overview
Role-specific dashboard views providing quick access to relevant features and stats.

## Structure
```
dashboards/
├── data/
│   └── repositories/
│       └── dashboard_repository.dart    # Stats and metrics data
├── domain/
│   ├── entities/
│   │   └── dashboard_stats.dart         # Dashboard statistics entity
│   └── repositories/
│       └── dashboard_repository.dart    # Repository interface
└── presentation/
    └── pages/
        ├── kitchen_dashboard_page.dart  # Kitchen manager view
        ├── manager_dashboard_page.dart  # Manager view
        ├── owner_dashboard_page.dart    # Owner view (full access)
        └── staff_dashboard_page.dart    # Staff view (limited)
```

## Dashboard by Role

### Owner Dashboard
- Full room grid access
- Financial overview (revenue, occupancy)
- Staff management
- All settings access

### Manager Dashboard
- Room operations
- Booking management
- Customer management
- Limited settings

### Staff Dashboard
- Room status view
- Check-in/out operations
- Basic customer lookup

### Kitchen Dashboard
- Food order queue
- Order status management
- Kitchen-specific features only

## Key Providers
- `dashboardStatsProvider` - Provider for dashboard statistics
- `roomSummaryProvider` - Quick room status counts

## Usage
```dart
// Router redirects to appropriate dashboard based on role
switch (role) {
  case UserRole.owner:
    return AppRoutes.ownerDashboard;
  case UserRole.manager:
    return AppRoutes.managerDashboard;
  // ...
}
```
