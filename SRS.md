# Software Requirements Specification (SRS)
### Hotel Internal Operations Mobile App (ROOMS.io)
### Version 1.0 — MVP Scope
### Platform: Flutter (Android) + Supabase Backend

---

## 1. Overview

This application is a real-time operational management system for hotels.  
It is designed exclusively for **Owners, Managers, and Staff** (not guests/customers).

Primary goals:
- **Ultra-fast hotel operations**: onboarding a customer in under **20 seconds**
- **Ease of use for low-literacy staff**: icon-driven, color-coded navigation
- **Strong action accountability**: every critical operation requires **fingerprint identity**
- **Real-time awareness**: owners receive immediate notifications of events

Supported hotels: **Multi-hotel** system (each hotel isolated by `hotel_id`).

Language: **English only** (MVP)

---

## 2. User Roles and Permissions

| Feature | Owner | Manager | Staff |
|--------|:-----:|:-------:|:----:|
| Login & use app | ✔ | ✔ | ✔ |
| Onboard customer | ✔ | ✔ | ✔ |
| Edit current booking | ✔ | ✔ | ❌ |
| Edit past bookings | ✔ | ❌ | ❌ |
| View customer database (all) | ✔ | ✔ | Limited to ongoing |
| View only current/ongoing customers | ✔ | ✔ | ✔ |
| View/Edit room status | ✔ | ✔ | ✔ |
| Initiate + complete cleaning/maintenance | ✔ | ✔ | ✔ (biometric) |
| View/Edit Day-Book Today | ✔ | ✔ | ❌ |
| View Day-Book Past | ✔ (edit) | ✔ (view only) | ❌ |
| View/Edit Staff Database | ✔ | View Only | ❌ |
| Edit Salary/Financial Info | ✔ (biometric) | ❌ | ❌ |
| Configure Hotel Settings | ✔ | View Only | ❌ |
| Receive Real-Time Notifications | ✔ (all) | Configurable | Optional |

---

## 3. Authentication & Security

### 3.1 Login Identity
- Supabase Auth (email + password)
- Each login session belongs to **one hotel_id**

### 3.2 Biometric Identity System
- **Real fingerprint matching** used to determine **who authorizes** the action
- Template-based matching, not images
- Stored in Supabase as encrypted **biometric templates**
- Matching happens **on-device**
- Device-independent → any employee can verify on any hotel device

> Accountability: every financial or high-impact action is linked to **biometric user**, not just who is logged-in.

### 3.3 Biometric Required Actions
- Confirm booking / Initial payment
- Payment adjustment / Refunds / Cancellation / Room swap
- Cleaning start + cleaning completion
- Changing sensitive financial records (salary, dues)
- Undoing or editing past day-books

### 3.4 Audit & Logs
Every sensitive operation stores:
- `biometric_user_id` (responsible)
- `session_user_id` (device user)
- Timestamp, action type, entity affected

---

## 4. Key Modules & Workflows

### 4.1 Room Management
- Room Grid with strong color indicators:
  - Green: Free  
  - Red: Occupied  
  - Orange: Cleaning / Maintenance  
  - Grey: Out-of-Service
- Filters by floor, type, status
- Details show:
  - Current booking
  - Maintenance history
  - Status changes timeline

Status transitions allowed:
- Free → Occupied
- Free → Maintenance
- Occupied → Maintenance
- Maintenance → Free
- Occupied → Free (checkout)

---

### 4.2 Customer & Booking Management

#### DB View 1 — Personal & Booking Info
- Name, gender, phone
- ID type, ID number, stored ID photo
- Check-in / check-out
- Number of guests, booking source
- Editable only for:
  - Owner (anytime)
  - Manager (current bookings only)

#### DB View 2 — Payments & Accounting
- Total bill, taxes, extra charges
- Amount paid, pending amount
- Payment modes
- History linked to **Day-Book**

#### Booking Onboarding Workflow (≤20 seconds)
1. Select Free room → Confirm
2. Scan government ID → OCR autofill
3. Fingerprint verify (confirm action)
4. Enter payment received (if any)
5. Confirm Check-In → Room becomes **Occupied**
6. Optional: immediate room swap/upgrade with payment adjustments
7. Owner receives notification

#### Checkout Workflow
- Add final charges
- Final payment collection
- Fingerprint confirmation
- Set room → Cleaning or Free
- Owner notification

---

### 4.3 Maintenance & Cleaning Workflow

Performed mainly by **Staff**:

1. Select room → Start Cleaning/Maintenance
2. Fingerprint verify
3. Work logged as “In Progress”
4. After completion → fingerprint verify again
5. Status update: **Free** or **Occupied**
6. Notification sent to Owner

Maintenance objects (AC, TV, etc.) can be attached to service history.

---

### 4.4 Employee Management (Owner Only)
- Add / disable employees
- Assign roles: Owner, Manager, Staff
- View attendance via biometric logs
- Compensation details:
  - Salary, bonus, dues ledger
- Shift schedule (basic MVP)
- Fingerprints enrollment & management

---

### 4.5 Day-Book (Revenue & Expense Ledger)

#### Today’s Day-Book (Owner + Manager)
- Opening balance
- List of all transactions today
  - Booking deposits
  - Final payments
  - Expenses
- Closing balance auto-computed

#### Past Day-Books
- Owner can edit historical days (biometric gated)
- Manager can only view history

---

### 4.6 Notifications
Real-time push notifications to **Owner** for:
- New check-in / check-out
- Payment adjustments
- Room status updates
- Cleaning start / completion
- Maintenance start / completion

---

## 5. Data Model (High-Level)

Core Entities:
- `users` (login accounts)
- `employees` (linked to hotel + optional compensation data)
- `employee_biometrics` (encrypted fingerprint templates)
- `rooms`, `room_types`, `hotels`
- `guests`, `bookings`, `payments`
- `daybooks`, `daybook_transactions`
- `maintenance_objects`
- `service_history`
- `alerts`, `notifications`
- `room_status_logs`, `biometric_audit_logs`

All data separated by `hotel_id`.

---

## 6. Non-Functional Requirements

| Category | Requirement |
|---------|-------------|
| UX | Designed for low-literacy users — icons, colors, minimal text |
| Performance | Room grid load < **1s** on stable network |
| Security | Encrypted biometric templates, strict RLS by hotel_id |
| Reliability | Real-time updates via Supabase Realtime |
| Offline | Limited caching only (room grid, active bookings) |
| Logging | Every critical action recorded with biometric identity |
| Scalability | Multi-hotel support from day one |

---

## 7. MVP Deliverables

- **Login + biometric enrollment**
- **Room Grid**
- **Check-In + ID scanning + payment**
- **Checkout workflow**
- **Maintenance/cleaning with fingerprint**
- **Today’s Day-Book (create/update/view)**
- **Employee management basic**
- **Owner notifications**

---

## 8. MVP Implementation Timeline

### Week 1: User & Lodge Setup
- User registration and login flow
- Biometric enrollment for users
- Lodge/Hotel configuration by owner
  - Hotel name, address, contact
  - Number of floors
  - Room types and ranges per floor
- Database initialization per hotel
- Basic role assignment (Owner, Manager, Staff)

### Week 2: Customer Documentation & Booking
- Customer onboarding workflow (≤20 seconds)
- Government ID scanning with OCR
- Biometric confirmation for check-in
- Reservation and booking creation
- Reservation notifications to owner
- Payment recording on check-in

### Week 3: Room Operations & Notifications
- Room swap / upgrade functionality with payment adjustments
- Room rating / feedback system
- Housekeeping notifications for cleaning/maintenance
- Emergency button (owner receives immediate notification)
- Maintenance workflow with biometric verification
- Real-time room status updates

### Week 4: Customization & Polish
- Hotel settings customization
- Day-Book configuration
- Notification preferences per role
- UI/UX refinements based on feedback
- Performance optimization

---

## 9. Future Enhancements (Post-MVP)

- Multi-hotel staff roles (same staff in multiple hotels)
- Guest special requests / alerts
- Inventory/stock management (laundry, toiletries)
- Payroll / monthly salary generation
- Analytics dashboard (occupancy trends, revenue charts)
- Multi-language UI
- Staff task assignment and tracking
- Offline full support (transaction queue)
- Subscription plans & billing

---

## 10. Constraints & Risks

- Handling biometric templates must follow strong security best practices
- All fingerprint operations must be **device-side**
- Limited or outdated Android devices may affect enrollment quality

---

### Authorization Responsibility Statement

> All financial and operational changes are authorized solely by the **Fingerprint Identity**, ensuring undeniable accountability of the individual performing the action.

---

**End of SRS.md**
