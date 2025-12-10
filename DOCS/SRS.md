# Software Requirements Specification (SRS)

**Project:** Hotel Internal Operations Management System (ROOMS.io)  
**Version:** 1.0 — MVP Scope  
**Platform:** Flutter (Android + Web for iOS) + Supabase Backend  
**Status:** In Development  
**Last Updated:** December 2025

---

## 1. Executive Summary

ROOMS.io is a real-time operational management system designed exclusively for hotel staff (Owners, Managers, and Staff). It streamlines guest onboarding, room operations, housekeeping workflows, and financial tracking with strong accountability through biometric verification.

**Key Objectives:**
- Ultra-fast guest onboarding (≤20 seconds)
- Icon-driven, color-coded interface for low-literacy users
- Biometric-based accountability for all critical operations
- Real-time owner notifications
- Multi-hotel support with isolated data per hotel
- In-room guest services (laundry, dining) via QR codes
- Kitchen operations management

**Supported Platforms:**
- Android native app (Flutter)
- Web app (Flutter Web) for iOS users
- Notification channels: Push notifications, Telegram, WhatsApp

**Language:** English only (MVP)

---

## 2. User Roles and Permissions

| Feature | Owner | Manager | Staff | Kitchen Manager |
|--------|:-----:|:-------:|:----:|:---------------:|
| Login & use app | ✔ | ✔ | ✔ | ✔ |
| Onboard customer | ✔ | ✔ | ✔ | ❌ |
| Edit current booking | ✔ | ✔ | ❌ | ❌ |
| Edit past bookings | ✔ | ❌ | ❌ | ❌ |
| View customer database (all) | ✔ | ✔ | Limited to ongoing | ❌ |
| View only current/ongoing customers | ✔ | ✔ | ✔ | ❌ |
| View/Edit room status | ✔ | ✔ | ✔ | ❌ |
| Initiate + complete cleaning/maintenance | ✔ | ✔ | ✔ (biometric) | ❌ |
| View/Edit Day-Book Today | ✔ | ✔ | ❌ | ❌ |
| View Day-Book Past | ✔ (edit) | ✔ (view only) | ❌ | ❌ |
| View/Edit Staff Database | ✔ | View Only | ❌ | ❌ |
| Edit Salary/Financial Info | ✔ (biometric) | ❌ | ❌ | ❌ |
| Configure Hotel Settings | ✔ | View Only | ❌ | ❌ |
| Receive Real-Time Notifications | ✔ (all) | Configurable | Optional | Configurable |
| View food orders | ❌ | ✔ | ❌ | ✔ |
| Manage food orders | ❌ | ✔ | ❌ | ✔ |
| View laundry requests | ❌ | ✔ | ✔ | ❌ |
| Manage laundry requests | ❌ | ✔ | ✔ | ❌ |

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
3. Work logged as "In Progress"
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

#### Today's Day-Book (Owner + Manager)
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

### 4.6 In-Room Guest Services (QR Code Integration)

Guests can access services via QR code placed in their room, which redirects to a web interface.

#### 4.6.1 Laundry Service
- Guest scans QR → web form
- Selects items and quantity
- Submits request
- Staff receives notification
- Laundry request logged in booking record
- Optional charge added to guest bill

#### 4.6.2 In-Room Dining
- Guest scans QR → web menu interface
- Browses available menu items
- Selects items and quantity
- Submits food order
- Manager receives order notification
- Kitchen Manager receives order in kitchen app
- Order status tracked (pending → preparing → ready → delivered)
- Food charge automatically added to guest bill
- Payment collected at checkout

#### 4.6.3 Service Request Workflow
1. Guest scans QR code in room
2. Web app loads (accessible on any device)
3. Guest selects service (laundry/dining)
4. Guest submits request
5. Manager notified in app
6. Staff/Kitchen Manager processes request
7. Status updated in real-time
8. Charge added to booking if applicable

---

### 4.7 Kitchen Operations Management

#### 4.7.1 Kitchen Manager Role
- Dedicated login for kitchen staff
- Access to food orders only
- Cannot access guest/booking information
- Receives real-time order notifications

#### 4.7.2 Kitchen Workflow
1. Kitchen Manager logs in
2. Views pending food orders
3. Marks order as "Preparing"
4. Marks order as "Ready for Delivery"
5. Staff collects and delivers to room
6. Manager marks order as "Delivered"
7. Order history maintained for audit

#### 4.7.3 Menu Management
- Owner configures menu items
- Items include: name, description, price, preparation time
- Menu accessible via QR code web interface
- Real-time availability updates

---

### 4.8 Notifications
Real-time notifications via multiple channels:

**Push Notifications (In-App):**
- New check-in / check-out
- Payment adjustments
- Room status updates
- Cleaning start / completion
- Maintenance start / completion
- Food orders received (Manager & Kitchen Manager)
- Laundry requests received (Manager & Staff)

**Telegram/WhatsApp Notifications (Owner):**
- Critical alerts (emergency button)
- High-value transactions
- System errors
- Configurable per hotel

**Recipients:**
- Owner: All notifications
- Manager: Configurable (orders, laundry, room updates)
- Kitchen Manager: Food orders only
- Staff: Laundry requests, cleaning assignments

---

## 5. Data Model (High-Level)

**Core Entities:**
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

**Guest Services Entities:**
- `menu_items` (food menu per hotel)
- `food_orders` (guest orders with status tracking)
- `laundry_requests` (guest laundry with status tracking)
- `service_requests` (generic service requests)

**Booking Extensions:**
- `booking_charges` (food, laundry, extras linked to booking)
- `booking_services` (service history per booking)

All data separated by `hotel_id`. Multi-hotel staff roles supported in future versions.

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

**Core Features:**
- Login + biometric enrollment
- Room Grid with status management
- Check-In + ID scanning + payment
- Checkout workflow
- Maintenance/cleaning with fingerprint verification
- Today's Day-Book (create/update/view)
- Employee management (basic)
- Owner push notifications

**Guest Services:**
- QR code integration for guest services
- Laundry request system
- In-room dining menu + ordering
- Service request tracking

**Kitchen Operations:**
- Kitchen Manager login
- Food order management interface
- Order status tracking (pending → preparing → ready → delivered)
- Real-time order notifications

**Notification Channels:**
- In-app push notifications
- Telegram notifications (Owner)
- WhatsApp notifications (Owner)

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
- Early booking discounts (Agoda integration)

---

## 10. Constraints & Risks

- Handling biometric templates must follow strong security best practices
- All fingerprint operations must be **device-side**
- Limited or outdated Android devices may affect enrollment quality
- QR code web interface must be responsive and work on all devices
- Kitchen operations require reliable real-time synchronization

---

## 11. Integration Points

### 11.1 Third-Party Services
- **Agoda Integration** (Future): Connect online bookings with early booking discount capability
- **Telegram API**: Owner notifications
- **WhatsApp API**: Owner notifications

### 11.2 Platform Support
- **Android**: Native Flutter app
- **iOS**: Web app via Flutter Web (QR scanning via device camera)
- **Web**: Admin dashboard and guest service portal

---

### Authorization Responsibility Statement

> All financial and operational changes are authorized solely by the **Fingerprint Identity**, ensuring undeniable accountability of the individual performing the action.

---

**End of SRS.md**
