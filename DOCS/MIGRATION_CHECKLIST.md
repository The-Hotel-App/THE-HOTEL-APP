# ✅ ROOMS.io Supabase Migration - Task Checklist

**Use this checklist to track your progress through the migration**

---

## 🔴 CRITICAL - Must Complete First

### Database Setup
- [ ] Open Supabase Dashboard (https://supabase.com/dashboard/project/nqlcagdgkiekanclxumz)
- [ ] Navigate to SQL Editor
- [ ] Open file: `supabase/migrations/20241210_initial_schema.sql`
- [ ] Copy entire SQL content
- [ ] Paste into Supabase SQL Editor
- [ ] Click "RUN" button
- [ ] Verify success message
- [ ] Check "Table Editor" - should see 15+ tables
- [ ] Test: Go to "user_profiles" table - should exist

### Flutter Dependencies
- [ ] Open terminal in project root
- [ ] Run: `cd rooms_app`
- [ ] Run: `flutter pub get`
- [ ] Verify no errors
- [ ] Check pubspec.yaml shows `supabase_flutter: ^2.8.0`

### Initial Test
- [ ] Run: `flutter run` (or use VS Code debug)
- [ ] Check console for: "🔧 Initializing Supabase..."
- [ ] Check console for: "✅ Supabase initialized successfully"
- [ ] If errors, check main.dart has `await SupabaseService.initialize()`

---

## 🟡 HIGH PRIORITY - Core Integration

### Update App Router
File: `lib/src/core/routing/app_router.dart`

- [ ] Import new auth providers:
  ```dart
  import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
  import 'package:rooms/src/features/auth/presentation/pages/welcome_screen.dart';
  ```

- [ ] Change `initialLocation` to `/welcome`:
  ```dart
  initialLocation: AppRoutes.welcome,
  ```

- [ ] Add welcome route constant:
  ```dart
  static const String welcome = '/welcome';
  ```

- [ ] Add welcome route in routes list:
  ```dart
  GoRoute(
    path: AppRoutes.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  ```

- [ ] Update redirect logic to use `currentUserProvider` instead of old provider

- [ ] Update redirect to handle multi-hotel (check if hotel selected)

- [ ] Test: App should open to Welcome Screen now

### Update Hotel Setup Wizard
File: `lib/src/features/hotel_setup/presentation/pages/hotel_setup_wizard_page.dart`

- [ ] Import new repositories:
  ```dart
  import 'package:rooms/src/features/auth/data/repositories/supabase_auth_repository.dart';
  import 'package:rooms/src/features/hotel_setup/data/repositories/supabase_hotel_setup_repository.dart';
  ```

- [ ] Add STEP 0: Owner Registration (before hotel details)
  - [ ] Add email field (TextEditingController)
  - [ ] Add password field (TextEditingController)
  - [ ] Add name field (TextEditingController)
  - [ ] Add phone field (TextEditingController)
  - [ ] Add form validation

- [ ] Update `_completeSetup()` method:
  - [ ] Call `SupabaseAuthRepository.signUp()` with owner details
  - [ ] On success, get user ID
  - [ ] Call `SupabaseHotelSetupRepository.createHotel()` with owner ID
  - [ ] Call `createRoomTypes()` with hotel ID
  - [ ] Call `createRooms()` with hotel ID and floor configs
  - [ ] Call `completeSetup()` to mark hotel as ready
  - [ ] Owner is auto-logged in (Supabase handles this)
  - [ ] Navigate to `/` (home/rooms page)

- [ ] Test: Complete hotel setup flow end-to-end

### Update Login Page
File: `lib/src/features/auth/presentation/pages/login_page.dart`

- [ ] Import new auth repository:
  ```dart
  import 'package:rooms/src/features/auth/data/repositories/supabase_auth_repository.dart';
  import 'package:rooms/src/features/auth/presentation/providers/auth_providers_new.dart';
  ```

- [ ] Replace `_fillDemoCredentials()` method - DELETE IT

- [ ] Remove demo credential buttons from UI

- [ ] Update `_handleLogin()`:
  - [ ] Use `SupabaseAuthRepository.login()`
  - [ ] On success, fetch user hotels via `userHotelsProvider`
  - [ ] If 1 hotel: auto-select and navigate to home
  - [ ] If multiple hotels: show hotel selector dialog
  - [ ] After hotel selection: set `selectedHotelIdProvider`

- [ ] Remove hotel switcher code (moved to settings)

- [ ] Test: Login with real credentials

---

## 🟢 MEDIUM PRIORITY - Enhanced Features

### Create Hotel Selector Widget
File: `lib/src/features/auth/presentation/widgets/hotel_selector_dialog.dart`

- [ ] Create new file

- [ ] Design dialog/bottom sheet UI:
  - [ ] List all hotels from `userHotelsProvider`
  - [ ] Show hotel name, address
  - [ ] Show user's role badge (Owner/Manager/Staff)
  - [ ] Highlight currently selected hotel
  - [ ] Add selection callback

- [ ] Implement hotel selection:
  - [ ] Update `selectedHotelIdProvider`
  - [ ] Save to SharedPreferences (remember selection)
  - [ ] Close dialog
  - [ ] Optionally navigate to home

- [ ] Add to Settings > Switch Hotel option

- [ ] Test: Switch between multiple hotels

### Update Staff Management Page
File: `lib/src/features/settings/presentation/pages/staff_page.dart`

- [ ] Import Supabase repositories

- [ ] Add "Add Staff" button (Owner only)

- [ ] Create add staff dialog:
  - [ ] Email field
  - [ ] Password field (for new users)
  - [ ] OR: Email search (for existing users)
  - [ ] Name field
  - [ ] Phone field
  - [ ] Role dropdown (Manager/Staff/Kitchen Manager)

- [ ] Implement add staff logic:
  - [ ] If new user: Call `SupabaseAuthRepository.signUp()`
  - [ ] Add to `hotel_staff` table with selected role
  - [ ] Send email invite (Supabase handles this)
  - [ ] Refresh staff list

- [ ] Display current staff:
  - [ ] Query `hotel_staff` for current hotel
  - [ ] Show user details with role badge
  - [ ] Show active/inactive status
  - [ ] Owner can deactivate/activate staff

- [ ] Test: Add manager, add staff, add kitchen manager

---

## 🔵 LOW PRIORITY - Future Features

### Biometric Enrollment UI
File: `lib/src/features/auth/presentation/pages/biometric_enrollment_page.dart`

- [ ] Create new file

- [ ] Add to user profile/settings

- [ ] Show "Enroll Biometric" button

- [ ] Check if user has biometric:
  - [ ] If yes: Show "Re-enroll" and "Remove" options
  - [ ] If no: Show "Enroll Now" button

- [ ] Implement enrollment flow:
  - [ ] Use `local_auth` package for fingerprint scan
  - [ ] For now: Just show success after "scanning"
  - [ ] Call `updateBiometricStatus(userId, true)`
  - [ ] Update UI to show enrolled status

- [ ] Test: Enroll biometric, check database

### Persist Selected Hotel
File: `lib/src/features/auth/presentation/providers/auth_providers_new.dart`

- [ ] Add SharedPreferences to save `selectedHotelId`

- [ ] On hotel selection:
  - [ ] Save to SharedPreferences
  - [ ] Update state provider

- [ ] On app start:
  - [ ] Load last selected hotel from SharedPreferences
  - [ ] Auto-select if still valid

- [ ] Test: Close app, reopen, hotel still selected

---

## 🧪 TESTING PHASE

### Authentication Tests
- [ ] Sign up new owner
- [ ] Verify user in Supabase Auth dashboard
- [ ] Verify user_profile created automatically
- [ ] Login with correct credentials
- [ ] Login fails with wrong password
- [ ] Login fails with non-existent email
- [ ] Logout clears session
- [ ] Auth state persists after app restart

### Hotel Creation Tests
- [ ] Create hotel with all details
- [ ] Verify hotel in Supabase "hotels" table
- [ ] Verify owner in "hotel_staff" table
- [ ] Create room types
- [ ] Verify in "room_types" table
- [ ] Create rooms (all floors)
- [ ] Verify in "rooms" table
- [ ] Verify room count matches config
- [ ] Complete setup
- [ ] Verify `is_setup_completed = true`

### Multi-Hotel Tests
- [ ] Owner creates second hotel
- [ ] Both hotels appear in hotel list
- [ ] Switch between hotels
- [ ] Verify data changes (rooms from different hotels)
- [ ] Create booking in Hotel A
- [ ] Switch to Hotel B
- [ ] Verify booking from A not visible

### Staff Management Tests
- [ ] Owner adds manager to hotel
- [ ] Manager receives email (check Supabase Auth emails)
- [ ] Manager logs in
- [ ] Manager sees only assigned hotels
- [ ] Manager has correct permissions (can't edit past bookings)
- [ ] Owner adds staff member
- [ ] Staff logs in
- [ ] Staff has limited permissions
- [ ] Add kitchen manager
- [ ] Kitchen manager can only see food orders

### RLS (Row Level Security) Tests
- [ ] Login as Owner of Hotel A
- [ ] Try to query Hotel B's data directly (should fail)
- [ ] Login as Manager of Hotel A
- [ ] Verify can't see Hotel B's data
- [ ] Verify can't edit other hotel's records
- [ ] Test all tables respect RLS

### Edge Cases
- [ ] User with no hotels (new user)
- [ ] User removed from hotel (access revoked)
- [ ] Deactivated user tries to login
- [ ] Switching hotels during active operation
- [ ] Network errors during auth
- [ ] Supabase connection timeout

---

## 📊 Progress Tracking

**Database Setup:** [ ] Complete  
**Flutter Dependencies:** [ ] Complete  
**App Router:** [ ] Complete  
**Hotel Setup Wizard:** [ ] Complete  
**Login Page:** [ ] Complete  
**Hotel Selector:** [ ] Complete  
**Staff Management:** [ ] Complete  
**Biometric UI:** [ ] Complete  
**Testing:** [ ] Complete  

---

## 🎯 Success Criteria

Before marking as DONE:

- [ ] Can create hotel as owner with registration
- [ ] Can login with email/password
- [ ] Can switch between multiple hotels
- [ ] Can add staff to hotel
- [ ] Staff can login and see only their hotels
- [ ] All permissions working correctly
- [ ] No hardcoded demo accounts
- [ ] All data isolated per hotel
- [ ] RLS policies preventing unauthorized access
- [ ] Auth state persists correctly
- [ ] No console errors during normal flow

---

## 📝 Notes & Issues

**Document any issues you encounter here:**

---

**Last Updated:** December 10, 2024  
**Next Review:** After completing critical tasks

---

**Good luck! 🚀**
