# 🗄️ Supabase Configuration - Hotel App

## 📋 Project Details

| Property | Value |
|----------|-------|
| **Project Name** | Hotel-App |
| **Project ID** | `nqlcagdgkiekanclxumz` |
| **Project URL** | https://nqlcagdgkiekanclxumz.supabase.co |
| **Anon Key** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xbGNhZ2Rna2lla2FuY2x4dW16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjUwNDYsImV4cCI6MjA4MDk0MTA0Nn0.CzmVdBwEqg1WdjO5IAnqF67xnje8nNYuIbo4P3S4GHA` |

---

## 🛠️ CLI Usage

```bash
npx supabase <command>
```

Use the Supabase CLI for database migrations, functions, and deployments.

---

## 📊 Database Schema

### Core Tables (Public Schema)

#### **hotels**
Central hotel entity table.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `name` | text | Hotel name | Required |
| `address` | text | Hotel address | Required |
| `phone` | text | Contact phone | NULL |
| `email` | text | Contact email | NULL |
| `total_rooms` | integer | Total room count | `0` |
| `total_floors` | integer | Number of floors | `1` |
| `floor_configs` | jsonb | Floor configuration data | NULL |
| `owner_id` | uuid | Reference to owner (auth.users) | Required |
| `hotel_code` | text | Unique hotel identifier | NULL |
| `is_setup_completed` | boolean | Setup completion status | `false` |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

**Constraints:**
- Unique: `hotel_code`

---

#### **hotel_staff**
Maps users to hotels with roles.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `user_id` | uuid | Reference to auth.users | Required |
| `role` | staff_role (enum) | Staff role | Required |
| `is_active` | boolean | Active status | `true` |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `created_by` | uuid | Creator user ID | NULL |

**Enums:**
- `staff_role`: `owner`, `manager`, `receptionist`, `housekeeping`

**Constraints:**
- Unique: (`user_id`, `hotel_id`)

---

#### **user_profiles**
Extended user information beyond auth.users.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key (matches auth.users.id) | Required |
| `name` | text | User display name | Required |
| `phone` | text | Contact phone | NULL |
| `is_active` | boolean | Active status | `true` |
| `has_biometric` | boolean | Biometric enrollment flag | `false` |
| `biometric_enrolled_at` | timestamptz | Biometric enrollment time | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

---

#### **room_types**
Room type definitions for pricing and capacity.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `name` | text | Room type name | Required |
| `base_price` | numeric | Base price per night | `0` |
| `max_occupancy` | integer | Maximum guests | `2` |
| `description` | text | Room type description | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

---

#### **rooms**
Individual room inventory.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `room_number` | text | Room identifier | Required |
| `floor` | integer | Floor number | Required |
| `room_type_id` | uuid | Reference to room_types | NULL |
| `status` | room_status (enum) | Current status | `'free'` |
| `updated_by` | uuid | Last updater user ID | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

**Enums:**
- `room_status`: `free`, `occupied`, `maintenance`, `dirty`, `cleaning`

**Constraints:**
- Unique: (`hotel_id`, `room_number`)

---

#### **guests**
Guest information database.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `name` | text | Guest name | Required |
| `phone` | text | Contact phone | NULL |
| `email` | text | Email address | NULL |
| `gender` | text | Guest gender | NULL |
| `id_type` | text | ID document type | NULL |
| `id_number` | text | ID document number | NULL |
| `id_photo_url` | text | ID photo URL | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

---

#### **bookings**
Reservation and occupancy records.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `guest_id` | uuid | Reference to guests | Required |
| `room_id` | uuid | Reference to rooms | Required |
| `check_in` | timestamptz | Check-in date/time | Required |
| `check_out` | timestamptz | Check-out date/time | Required |
| `number_of_guests` | integer | Guest count | `1` |
| `booking_source` | text | Booking origin | NULL |
| `status` | booking_status (enum) | Booking status | `'confirmed'` |
| `total_amount` | numeric | Total booking amount | `0` |
| `amount_paid` | numeric | Amount paid | `0` |
| `amount_pending` | numeric | Pending amount | NULL |
| `created_by` | uuid | Creator user ID | NULL |
| `checked_in_by` | uuid | Check-in staff ID | NULL |
| `checked_in_biometric_verified` | boolean | Check-in biometric flag | `false` |
| `checked_out_by` | uuid | Check-out staff ID | NULL |
| `checked_out_biometric_verified` | boolean | Check-out biometric flag | `false` |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

**Enums:**
- `booking_status`: `confirmed`, `checked_in`, `checked_out`, `cancelled`, `no_show`

---

#### **payments**
Payment transaction records.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `booking_id` | uuid | Reference to bookings | Required |
| `amount` | numeric | Payment amount | Required |
| `payment_mode` | payment_mode (enum) | Payment method | Required |
| `payment_date` | timestamptz | Payment timestamp | `now()` |
| `notes` | text | Payment notes | NULL |
| `created_by` | uuid | Creator user ID | NULL |
| `biometric_verified` | boolean | Biometric verification flag | `false` |
| `verified_by` | uuid | Verifier user ID | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |

**Enums:**
- `payment_mode`: `cash`, `card`, `upi`, `bank_transfer`, `other`

---

#### **daybooks**
Daily financial records per hotel.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `date` | date | Daybook date | Required |
| `opening_balance` | numeric | Opening balance | `0` |
| `closing_balance` | numeric | Closing balance | `0` |
| `created_by` | uuid | Creator user ID | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

**Constraints:**
- Unique: (`hotel_id`, `date`)

---

#### **daybook_transactions**
Individual transactions within a daybook.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `daybook_id` | uuid | Reference to daybooks | Required |
| `hotel_id` | uuid | Reference to hotels | Required |
| `transaction_type` | text | Type: `income` or `expense` | Required |
| `category` | text | Transaction category | Required |
| `amount` | numeric | Transaction amount | Required |
| `description` | text | Transaction description | NULL |
| `reference_id` | uuid | Related entity reference | NULL |
| `created_by` | uuid | Creator user ID | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |

---

#### **room_status_logs**
Audit trail for room status changes.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `room_id` | uuid | Reference to rooms | Required |
| `old_status` | room_status (enum) | Previous status | NULL |
| `new_status` | room_status (enum) | New status | Required |
| `changed_by` | uuid | User who made change | NULL |
| `changed_at` | timestamptz | Change timestamp | `now()` |
| `notes` | text | Change notes | NULL |

---

#### **maintenance_objects**
Maintenance-related items/equipment.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `name` | text | Object name | Required |
| `description` | text | Object description | NULL |
| `created_at` | timestamptz | Creation timestamp | `now()` |

---

#### **service_history**
Service and maintenance activity logs.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `room_id` | uuid | Reference to rooms | Required |
| `service_type` | text | Type of service | Required |
| `maintenance_object_id` | uuid | Related maintenance object | NULL |
| `status` | text | Service status | Required |
| `started_at` | timestamptz | Service start time | NULL |
| `completed_at` | timestamptz | Service completion time | NULL |
| `notes` | text | Service notes | NULL |
| `started_by` | uuid | Staff who started | NULL |
| `started_biometric_verified` | boolean | Start biometric flag | `false` |
| `completed_by` | uuid | Staff who completed | NULL |
| `completed_biometric_verified` | boolean | Completion biometric flag | `false` |
| `created_at` | timestamptz | Creation timestamp | `now()` |

---

### Biometric & Security Tables

#### **employee_biometrics**
Biometric enrollment data for staff.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `user_id` | uuid | Reference to auth.users | Required |
| `hotel_id` | uuid | Reference to hotels | Required |
| `biometric_template` | text | Encrypted biometric data | NULL |
| `enrolled_at` | timestamptz | Enrollment timestamp | `now()` |
| `enrolled_by` | uuid | Enrolling staff ID | NULL |
| `is_active` | boolean | Active status | `true` |
| `last_verified_at` | timestamptz | Last verification time | NULL |

**Constraints:**
- Unique: (`user_id`, `hotel_id`)

---

#### **biometric_audit_logs**
Audit trail for biometric verifications.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `uuid_generate_v4()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `user_id` | uuid | User being verified | Required |
| `action_type` | text | Action performed | Required |
| `reference_id` | uuid | Related entity reference | NULL |
| `verified_at` | timestamptz | Verification timestamp | `now()` |
| `device_info` | jsonb | Device information | NULL |
| `success` | boolean | Verification success | `true` |

---

### Push Notification Tables

#### **device_tokens**
FCM tokens for push notifications.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `gen_random_uuid()` |
| `user_id` | uuid | Reference to auth.users | Required |
| `hotel_id` | uuid | Reference to hotels | Required |
| `fcm_token` | text | Firebase token | Required |
| `device_info` | jsonb | Device metadata | `'{}'::jsonb` |
| `is_active` | boolean | Token active status | `true` |
| `created_at` | timestamptz | Creation timestamp | `now()` |
| `updated_at` | timestamptz | Last update timestamp | `now()` |

**Constraints:**
- Unique: (`user_id`, `hotel_id`, `fcm_token`)

---

#### **notifications**
In-app notification history.

| Column | Type | Description | Default |
|--------|------|-------------|---------|
| `id` | uuid | Primary key | `gen_random_uuid()` |
| `hotel_id` | uuid | Reference to hotels | Required |
| `user_id` | uuid | Recipient user ID | Required |
| `type` | text | Notification type | Required |
| `title` | text | Notification title | Required |
| `body` | text | Notification body | Required |
| `data` | jsonb | Additional data | `'{}'::jsonb` |
| `is_read` | boolean | Read status | `false` |
| `is_hidden` | boolean | Hidden status (soft delete) | `false` |
| `created_at` | timestamptz | Creation timestamp | `now()` |

**Notification Types:**
- `new_booking`
- `room_status_change`
- `checkout`
- `payment`
- `system`

---

## 🔐 Row Level Security (RLS)

All tables have RLS enabled with role-based policies:

### Hotel Staff Policies
- `owner`: Full access to their hotels
- `manager`: Full operational access
- `receptionist`: Booking, guest, and payment management
- `housekeeping`: Room status and service management

### Key Policy Functions
```sql
-- Check if user owns the hotel
has_hotel_access(user_id uuid, hotel_id uuid, required_role staff_role)

-- Check if user is staff at hotel
is_hotel_staff(user_id uuid, hotel_id uuid)

-- Check if user is owner
is_hotel_owner(user_id uuid, hotel_id uuid)
```

---

## 🔧 Database Functions

### Onboarding & Setup

#### `is_hotel_code_available(p_hotel_code text)`
**Purpose:** Validates if a hotel code is available for use.

**Parameters:**
- `p_hotel_code`: Hotel code to check

**Returns:** `boolean`

**Usage:**
```sql
SELECT is_hotel_code_available('taj-chennai');
```

---

#### `get_hotel_by_code(p_hotel_code text)`
**Purpose:** Retrieves hotel details by unique code.

**Parameters:**
- `p_hotel_code`: Hotel code to lookup

**Returns:** Hotel record

**Usage:**
```sql
SELECT * FROM get_hotel_by_code('taj-chennai');
```

---

#### `add_staff_to_hotel(p_hotel_id uuid, p_user_id uuid, p_role staff_role, p_created_by uuid)`
**Purpose:** Adds staff to hotel with RLS bypass and owner verification.

**Parameters:**
- `p_hotel_id`: Hotel ID
- `p_user_id`: User ID to add
- `p_role`: Staff role to assign
- `p_created_by`: User creating the staff record

**Security:** Bypasses RLS with owner verification

**Usage:**
```sql
SELECT add_staff_to_hotel(
  'hotel-uuid',
  'user-uuid',
  'receptionist'::staff_role,
  'owner-uuid'
);
```

---

### Notification Functions

#### `get_owner_fcm_tokens(p_hotel_id uuid)`
**Purpose:** Retrieves FCM tokens for all hotel owners.

**Parameters:**
- `p_hotel_id`: Hotel ID

**Returns:** Array of FCM tokens

**Usage:**
```sql
SELECT get_owner_fcm_tokens('hotel-uuid');
```

---

#### `mark_notifications_read(p_notification_ids uuid[])`
**Purpose:** Marks notifications as read.

**Parameters:**
- `p_notification_ids`: Array of notification IDs

**Usage:**
```sql
SELECT mark_notifications_read(ARRAY['notif-uuid-1', 'notif-uuid-2']);
```

---

#### `toggle_notifications_visibility(p_hidden boolean)`
**Purpose:** Clears or restores notification history.

**Parameters:**
- `p_hidden`: `true` to hide, `false` to show

**Usage:**
```sql
-- Clear all notifications
SELECT toggle_notifications_visibility(true);

-- Restore all notifications
SELECT toggle_notifications_visibility(false);
```

---

## 🔔 Database Triggers

### Notification Triggers

#### `trg_notify_new_booking`
**Event:** INSERT on `bookings`

**Action:** Creates notification for hotel owners when new booking is created.

**Fires:** After insert

---

#### `trg_notify_room_status_change`
**Event:** UPDATE on `rooms.status`

**Action:** Creates notification for hotel owners when room status changes.

**Fires:** After update

---

## 🌐 Edge Functions

### `send-push-notification`

**Purpose:** Sends push notifications via Firebase HTTP v1 API.

**Method:** POST

**Endpoint:** `/functions/v1/send-push-notification`

**Required Secrets:**
- `FIREBASE_SERVICE_ACCOUNT_BASE64`: Base64-encoded Firebase service account JSON

**Request Body:**
```json
{
  "hotel_id": "uuid",
  "user_ids": ["uuid1", "uuid2"],
  "notification": {
    "title": "New Booking",
    "body": "New booking received for Room 101",
    "data": {
      "type": "new_booking",
      "booking_id": "uuid"
    }
  }
}
```

**Auto-Invoke:**
Database triggers automatically invoke this function via `pg_net.http_post` for:
- New bookings
- Room status changes

**Setup Instructions:**
```bash
# Encode Firebase service account JSON to base64
base64 -i firebase-service-account.json

# Set the secret
npx supabase secrets set FIREBASE_SERVICE_ACCOUNT_BASE64 "your-base64-encoded-json"
```

---

## 📁 Migration Files

All migrations are stored in:
```
supabase/migrations/
```

### Key Migrations

| File | Description |
|------|-------------|
| `20241212_onboarding_schema.sql` | Initial onboarding schema with hotel_code |
| `20241213_add_staff_function.sql` | Staff management function with RLS bypass |
| `20241222_remove_join_workflow.sql` | Removed deprecated join codes workflow |
| `20241223_push_notifications.sql` | Push notification infrastructure |
| `20241223_auto_invoke_edge_function.sql` | Auto-invoke Edge Functions via pg_net |
| `20241223_fix_get_owner_fcm_tokens.sql` | Fixed token retrieval from auth.users |

---

## 🔑 Required Secrets

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Base64-encoded Firebase service account JSON for push notifications |

**Setting Secrets:**
```bash
npx supabase secrets set SECRET_NAME "secret-value"
```

---

## ✨ Key Features

- ✅ Multi-hotel support with unique hotel codes
- ✅ Role-based staff management with RLS
- ✅ Real-time push notifications via Firebase
- ✅ Notification history & in-app display
- ✅ Device token management per user/hotel
- ✅ Automatic triggers for booking & room status changes
- ✅ Biometric authentication for critical operations
- ✅ Comprehensive audit logging
- ✅ Edge Functions for external API integration
- ✅ Financial daybook and transaction tracking
- ✅ Maintenance and service history tracking

---

## 🏗️ Schema Relationships

```
hotels
  ├── hotel_staff (many)
  ├── rooms (many)
  │   └── room_types (one)
  ├── guests (many)
  ├── bookings (many)
  │   ├── guest (one)
  │   ├── room (one)
  │   └── payments (many)
  ├── daybooks (many)
  │   └── daybook_transactions (many)
  ├── maintenance_objects (many)
  ├── service_history (many)
  ├── employee_biometrics (many)
  ├── biometric_audit_logs (many)
  ├── device_tokens (many)
  └── notifications (many)

auth.users
  ├── user_profiles (one-to-one)
  ├── hotel_staff (many)
  ├── employee_biometrics (many)
  └── device_tokens (many)
```
*Last Updated: December 24, 2024*
