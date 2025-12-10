# ROOMS.io - Routing Flow Documentation

## Application Flow

### First Time Launch
```
App Start
    ↓
Hotel Setup Wizard
    ├─ Step 1: Hotel Information (name, address, phone, email)
    ├─ Step 2: Floors & Rooms configuration
    └─ Step 3: Room Types
    ↓
Login Page
```

### Subsequent Launches (After Setup)
```
App Start
    ↓
Login Page
    ↓
Login with hardcoded credentials:
    • owner@hotel.com / owner123
    • manager@hotel.com / manager123
    • staff@hotel.com / staff123
    ↓
Home/Dashboard
```

## Routing Logic

### Priority Order
1. **Setup Check** (Highest Priority)
   - If setup NOT completed → Force to Setup Wizard
   - If setup completed + on setup page → Redirect to Login

2. **Authentication Check** (After Setup)
   - If NOT authenticated + protected route → Redirect to Login
   - If authenticated + on login page → Redirect to Home

### Route Definitions
- `/setup` - Hotel Setup Wizard (first-time only)
- `/login` - Login Page
- `/` - Home/Dashboard (protected)
- `/rooms` - Rooms Management (protected)
- `/bookings` - Bookings (protected, TODO)
- `/customers` - Customers (protected, TODO)
- `/daybook` - Daybook (protected, TODO)
- `/staff` - Staff Management (protected, TODO)
- `/settings` - Settings (protected, TODO)

## Key Implementation Details

### Router Configuration
- **Initial Location**: `/setup` (checks setup status immediately)
- **Refresh Notifier**: Listens to auth state and setup completion changes
- **Redirect Logic**: Prioritizes setup completion over authentication

### State Management
- `isSetupCompletedProvider`: FutureProvider checking if hotel setup is complete
- `currentUserProvider`: FutureProvider for authenticated user
- Router automatically refreshes when these providers update

### Setup Wizard Features
- ✅ No logo display (clean professional look)
- ✅ White text on black buttons (proper contrast)
- ✅ Yellow header background with black text
- ✅ 3-step wizard process
- ✅ Progress indicator
- ✅ Persistent data storage

### Login Page Features
- ✅ Professional black & white theme
- ✅ Yellow logo on transparent background
- ✅ Demo login buttons for quick testing
- ✅ Auto-redirect to home after successful login

### Navigation
- Uses GoRouter for declarative routing
- `context.go()` for navigation (not Navigator.push/pop)
- Automatic redirects based on auth and setup state
- Back button support in rooms page

## Testing Flow

### First Launch Test
1. Open app → Should show Hotel Setup Wizard
2. Fill in hotel information
3. Configure floors and rooms
4. Define room types
5. Complete setup → Should redirect to Login
6. Login with any demo credentials → Should go to Home

### Subsequent Launch Test
1. Open app → Should show Login (setup already done)
2. Login → Should go to Home
3. Navigate to Rooms → Should show rooms grid
4. Back button → Should return to Home
5. Logout → Should return to Login

## Future Enhancements
- [ ] Real backend authentication
- [ ] Multi-hotel support (hotel selection after login)
- [ ] Owner can create manager/staff accounts
- [ ] Email/SMS invitation system
- [ ] Role-based access control (RBAC)
- [ ] Password reset flow
- [ ] Two-factor authentication (2FA)
