# Role-Based Access Control (RBAC) - Permission Summary

**Project:** ROOMS.io - Hotel Internal Operations Management System\
**Last Updated:** December 2025\
**Source:** Aligned with SRS.md requirements

---

## User Roles

| Role             | Display Name    | Description                                                                                    |
| ---------------- | --------------- | ---------------------------------------------------------------------------------------------- |
| `owner`          | Owner           | Full administrative access. Manages hotel, staff, finances, and all operations.                |
| `manager`        | Manager         | Operational manager. Handles day-to-day operations, bookings, and staff oversight (view-only). |
| `staff`          | Staff           | Front desk staff. Handles check-ins, room status, cleaning, and laundry.                       |
| `kitchenManager` | Kitchen Manager | Kitchen-only access. Manages food orders exclusively.                                          |

---

## Complete Permission Matrix

### 📋 Bookings & Customers

| Permission                         | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| ---------------------------------- | :------: | :--------: | :------: | :----------------: |
| Create Bookings (Onboard Customer) |    ✅    |     ✅     |    ✅    |         ❌         |
| Edit Current/Ongoing Bookings      |    ✅    |     ✅     |    ❌    |         ❌         |
| Edit Past Bookings                 |    ✅    |     ❌     |    ❌    |         ❌         |
| View All Customers (Historical)    |    ✅    |     ✅     |    ❌    |         ❌         |
| View Ongoing Customers Only        |    ✅    |     ✅     |    ✅    |         ❌         |

### 🏨 Rooms

| Permission                                | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| ----------------------------------------- | :------: | :--------: | :------: | :----------------: |
| Access/View Rooms                         |    ✅    |     ✅     |    ✅    |         ❌         |
| Edit Room Status (Free/Occupied/Cleaning) |    ✅    |     ✅     |    ✅    |         ❌         |
| Edit Room Configuration                   |    ✅    |     ❌     |    ❌    |         ❌         |
| Manage Room Types                         |    ✅    |     ❌     |    ❌    |         ❌         |

### 🧹 Cleaning & Maintenance

| Permission                             | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| -------------------------------------- | :------: | :--------: | :------: | :----------------: |
| Initiate Cleaning (Biometric Required) |    ✅    |     ✅     |    ✅    |         ❌         |
| Complete Cleaning (Biometric Required) |    ✅    |     ✅     |    ✅    |         ❌         |

### 📒 Day Book (Financial Ledger)

| Permission            | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| --------------------- | :------: | :--------: | :------: | :----------------: |
| View Today's Day Book |    ✅    |     ❌     |    ❌    |         ❌         |
| Edit Today's Day Book |    ✅    |     ❌     |    ❌    |         ❌         |
| View Past Day Books   |    ✅    |     ❌     |    ❌    |         ❌         |
| Edit Past Day Books   |    ✅    |     ❌     |    ❌    |         ❌         |

### 💰 Financials

| Permission                                      | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| ----------------------------------------------- | :------: | :--------: | :------: | :----------------: |
| View Money Details (Amounts, Payments)          |    ✅    |     ❌     |    ❌    |         ❌         |
| Edit Salary/Financial Info (Biometric Required) |    ✅    |     ❌     |    ❌    |         ❌         |

### 👥 Staff Management

| Permission                     | 👑 Owner |   👔 Manager   | 👤 Staff | 🍳 Kitchen Manager |
| ------------------------------ | :------: | :------------: | :------: | :----------------: |
| View Staff Database            |    ✅    | ✅ (View Only) |    ❌    |         ❌         |
| Manage Staff (Add/Edit/Remove) |    ✅    |       ❌       |    ❌    |         ❌         |

### ⚙️ Hotel Settings

| Permission          | 👑 Owner |   👔 Manager   | 👤 Staff | 🍳 Kitchen Manager |
| ------------------- | :------: | :------------: | :------: | :----------------: |
| View Hotel Settings |    ✅    | ✅ (View Only) |    ❌    |         ❌         |
| Edit Hotel Settings |    ✅    |       ❌       |    ❌    |         ❌         |

### 🍽️ Food Orders

| Permission         | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| ------------------ | :------: | :--------: | :------: | :----------------: |
| View Food Orders   |    ❌    |     ✅     |    ❌    |         ✅         |
| Manage Food Orders |    ❌    |     ✅     |    ❌    |         ✅         |

### 👔 Laundry

| Permission              | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| ----------------------- | :------: | :--------: | :------: | :----------------: |
| View Laundry Requests   |    ❌    |     ✅     |    ✅    |         ❌         |
| Manage Laundry Requests |    ❌    |     ✅     |    ✅    |         ❌         |

### 🔔 Notifications

| Permission                 | 👑 Owner | 👔 Manager | 👤 Staff | 🍳 Kitchen Manager |
| -------------------------- | :------: | :--------: | :------: | :----------------: |
| Receive All Notifications  |    ✅    |     ❌     |    ❌    |         ❌         |
| Configurable Notifications |   N/A    |     ✅     |    ✅    |         ✅         |

---

## Quick Reference by Role

### 👑 Owner - Full Administrative Access

- **Full control** over all hotel operations
- **Exclusive access** to:
  - **Day Book** (view and edit, including past)
  - Money/financial details
  - Salary/financial information editing
  - Staff management (add/edit/remove)
  - Hotel settings editing
  - Room types management
  - Room configuration editing
  - Past booking editing
- Receives **all notifications**
- Does **NOT** see food orders (per SRS design)

### 👔 Manager - Operations Management

- Day-to-day operational control
- Can create and **edit current bookings** (not past)
- Can **view** staff database (no editing)
- Can **view** hotel settings (no editing)
- **Cannot** access Day Book
- **Cannot** see money/financial details
- Manages food orders and laundry requests
- Configurable notifications

### 👤 Staff - Front Desk Operations

- Create new bookings (check-in customers)
- Change room status
- Initiate and complete cleaning/maintenance
- View and manage laundry requests
- View ongoing customers only
- **Cannot** edit bookings
- **Cannot** access day book
- **Cannot** see finances or staff database

### 🍳 Kitchen Manager - Kitchen Only

- **Exclusive focus** on food orders
- **No access** to:
  - Rooms
  - Bookings
  - Customers
  - Day book
  - Finances
  - Staff database
  - Laundry
- Configurable notifications (food orders only)

---

## Biometric-Gated Actions

The following actions require **fingerprint verification** for accountability:

| Action                            | Who Can Perform       |
| --------------------------------- | --------------------- |
| Confirm Booking / Initial Payment | Owner, Manager, Staff |
| Payment Adjustment / Refunds      | Owner, Manager        |
| Booking Cancellation              | Owner, Manager        |
| Room Swap                         | Owner, Manager        |
| Start Cleaning                    | Owner, Manager, Staff |
| Complete Cleaning                 | Owner, Manager, Staff |
| Edit Salary/Financial Records     | Owner only            |
| Edit Past Day Books               | Owner only            |

---

## Code Implementation

Permissions are defined as getters on the `UserRole` enum in:

- `lib/src/features/auth/domain/entities/user_new.dart`
- `lib/src/features/auth/domain/entities/user.dart`

### Available Permission Getters

```dart
// Booking Permissions
bool get canCreateBookings
bool get canEditCurrentBookings
bool get canEditPastBookings

// Customer Permissions
bool get canViewAllCustomers
bool get canViewOngoingCustomers

// Room Permissions
bool get canAccessRooms
bool get canEditRoomStatus
bool get canEditRooms
bool get canManageRoomTypes

// Cleaning Permissions
bool get canInitiateCleaning
bool get canCompleteCleaning

// Day Book Permissions
bool get canViewDayBook
bool get canEditDayBook
bool get canViewPastDayBook
bool get canEditPastDayBook

// Financial Permissions
bool get canViewMoneyDetails
bool get canEditSalaryInfo

// Staff Permissions
bool get canViewStaffDatabase
bool get canManageStaff

// Hotel Settings Permissions
bool get canViewHotelSettings
bool get canEditHotelSettings

// Food Order Permissions
bool get canViewFoodOrders
bool get canManageFoodOrders

// Laundry Permissions
bool get canViewLaundryRequests
bool get canManageLaundryRequests

// Notification Permissions
bool get receivesAllNotifications
```

---

**End of ROLE_PERMISSIONS.md**
