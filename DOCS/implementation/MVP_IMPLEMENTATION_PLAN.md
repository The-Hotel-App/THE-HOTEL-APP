# MVP Implementation Plan (Without Database)
## ROOMS.io - Hotel Operations App

---

## Phase 1: Authentication & Navigation

### 1.1 Login Screens (Separate Entry Points)
- **Owner Login** → Email + Password (mock validation)
- **Manager Login** → Email + Password (mock validation)
- **Staff Login** → Email + Password (mock validation)
- Mock user credentials stored locally for testing
- Login state management (persist selected role)

### 1.2 Role-Based Navigation
After login, show role-specific dashboard:
- **Owner Dashboard** → Full menu access
- **Manager Dashboard** → Limited menu access
- **Staff Dashboard** → Minimal menu access

---

## Phase 2: Core UI Screens

### 2.1 Room Management
- **Room Grid Screen**
  - Display rooms with color coding (Green/Red/Orange/Grey)
  - Filter by floor, room type, status
  - Mock room data (hardcoded list)
  - Tap room → Room Detail Screen

- **Room Detail Screen**
  - Current booking info (if occupied)
  - Maintenance history (mock)
  - Status change buttons (Owner/Manager/Staff based on role)
  - Status timeline view

### 2.2 Customer & Booking Management
- **Customer List Screen**
  - List of all customers (mock data)
  - Search/filter by name, phone
  - Role-based visibility (Staff sees only ongoing)

- **Customer Detail Screen**
  - Personal info (name, gender, phone, ID type, ID number)
  - Booking info (check-in, check-out, guests count)
  - Payment info (total bill, paid, pending)
  - Edit buttons (Owner/Manager only, based on role)

- **Booking Detail Screen**
  - Full booking information
  - Payment history (mock transactions)
  - Room assignment
  - Edit/cancel options (role-based)

### 2.3 Employee Management (Owner Only)
- **Staff List Screen**
  - List of employees (mock data)
  - Name, role, status
  - Add/Edit/Disable buttons

- **Staff Detail Screen**
  - Personal info
  - Role assignment
  - Compensation details (salary, bonus, dues)
  - Biometric enrollment status

### 2.4 Day-Book
- **Today's Day-Book Screen**
  - Opening balance (mock)
  - List of transactions (mock data)
  - Closing balance (auto-calculated)
  - Add transaction button (Owner/Manager only)

- **Past Day-Books Screen**
  - List of past days
  - View/Edit options (Owner only can edit)

### 2.5 Notifications
- **Notification Center Screen**
  - List of mock notifications
  - Mark as read
  - Delete notifications

---

## Phase 3: Workflows (UI Only)

### 3.1 Check-In Workflow
1. Select free room from grid
2. Confirm room selection
3. ID Scan Screen (mock OCR - auto-fill customer data)
4. Customer info review/edit
5. Payment entry screen
6. Biometric verification screen (fingerprint prompt)
7. Confirmation screen → Room status changes to Occupied

### 3.2 Checkout Workflow
1. Select occupied room
2. Add final charges screen
3. Payment collection screen
4. Biometric verification screen
5. Set room status (Cleaning or Free)
6. Confirmation screen

### 3.3 Cleaning/Maintenance Workflow
1. Select room
2. Choose: Cleaning or Maintenance
3. Biometric verification screen (start)
4. Work in progress screen (timer optional)
5. Biometric verification screen (completion)
6. Set room status (Free or Occupied)
7. Confirmation screen

### 3.4 Room Swap/Upgrade Workflow
1. Select current room
2. Select new room
3. Calculate payment adjustment
4. Biometric verification screen
5. Confirmation screen

---

## Phase 4: Biometric System (Local Only)

### 4.1 Biometric Enrollment
- **Enrollment Screen**
  - Fingerprint capture UI (mock)
  - Capture multiple fingerprints (5-10 samples)
  - Store locally (SharedPreferences or local file)
  - Success/failure feedback

### 4.2 Biometric Verification
- **Verification Screen**
  - Fingerprint prompt UI
  - Mock matching logic (accept/reject)
  - Retry counter
  - Fallback option (mock PIN or password)

### 4.3 Local Storage
- Store mock biometric templates locally (not encrypted yet)
- Link to user ID and role
- Retrieve for verification flows

---

## Phase 5: Settings & Configuration

### 5.1 Hotel Settings (Owner Only)
- Hotel name, address, contact
- Number of floors
- Room types and ranges
- Basic configuration UI

### 5.2 Notification Preferences (Owner/Manager)
- Toggle notifications on/off
- Select notification types
- Mock preference storage

### 5.3 User Profile
- View/edit profile info
- Change password (mock)
- Logout

---

## Phase 6: Mock Data & State Management

### 6.1 Mock Data Structure
```
Users:
- owner@hotel.com / password123 (Owner)
- manager@hotel.com / password123 (Manager)
- staff@hotel.com / password123 (Staff)

Rooms:
- 20 rooms (5 per floor, 4 floors)
- Types: Single, Double, Suite
- Statuses: Free, Occupied, Cleaning, Maintenance

Customers:
- 10 mock customers with bookings
- Personal info, payment history

Employees:
- 5 mock staff members
- Roles, compensation info

Transactions:
- Mock daily transactions for Day-Book
```

### 6.2 State Management
- Use Provider or GetX for state management
- Store login state (role, user info)
- Store room grid state
- Store customer/booking state
- Store notification state

---

## Implementation Order

1. **Week 1**: Login screens (3 separate) + role-based navigation
2. **Week 2**: Room grid + room detail + customer list/detail
3. **Week 3**: Check-in/checkout workflows (UI only)
4. **Week 4**: Biometric enrollment/verification UI + cleaning workflow
5. **Week 5**: Day-Book screens + employee management
6. **Week 6**: Settings, notifications, polish

---

## Tech Stack (No Backend)

- **Flutter** for UI
- **Provider/GetX** for state management
- **SharedPreferences** for local storage (mock data + biometric templates)
- **Mock data** hardcoded or loaded from JSON files
- **Local notifications** for mock alerts

---

## Key Points

- All data is mock/hardcoded
- No API calls yet
- Biometric templates stored locally (unencrypted for MVP)
- Role-based UI visibility implemented
- Workflows are UI-only (no actual state transitions yet)
- Ready to integrate database later without major refactoring

