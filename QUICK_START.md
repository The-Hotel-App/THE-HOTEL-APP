# ROOMS.io - Quick Start Guide

## 🎯 What You Can Do Right Now

### 1. Run the App
```bash
cd rooms_app
flutter run
```

### 2. Test the Login Flow

The app will open to a **Login Screen** with:
- Email input field
- Password input field  
- Login button
- Quick-fill demo buttons for Owner/Manager/Staff

#### Option A: Manual Login
1. Enter email: `owner@rooms.io`
2. Enter password: `owner123`
3. Click "Login"

#### Option B: Test Dummy Login
1. Click the "Owner" button under "Quick Login (Demo)"
2. Credentials auto-fill
3. Click "Login"

### 3. Explore the Home Page

After login, you'll see:

**For Owner:**
- 6 Quick Action Cards:
  - 🏨 Rooms
  - 📖 Bookings
  - 👥 Customers
  - 📚 Day Book
  - 👨‍👩‍👧‍👦 Staff (Owner only)
  - ⚙️ Settings (Owner only)

**For Manager:**
- 4 Quick Action Cards (no Staff or Settings)

**For Staff:**
- 4 Quick Action Cards (no Staff or Settings)

### 4. Test Role-Based Access

Try logging in as different roles:

```
Owner Login:
- Email: owner@rooms.io
- Password: owner123
- See: ALL 6 cards including Staff & Settings

Manager Login:
- Email: manager@rooms.io
- Password: manager123
- See: 4 cards (Rooms, Bookings, Customers, Day Book)

Staff Login:
- Email: staff@rooms.io
- Password: staff123
- See: 4 cards (same as Manager)
```

### 5. Test Logout

Click the **Logout** icon (top-right) to return to login screen.

---

## 🎨 UI Features to Notice

### Color System
- **Primary Blue**: App bar, buttons
- **High Contrast**: Easy to read text
- **Large Touch Targets**: All buttons are 48dp minimum
- **Clean Layout**: Spacious, uncluttered design

### Login Screen Features
- Password visibility toggle (eye icon)
- Form validation (try submitting empty form)
- Error messages (try wrong credentials)
- Demo credential display card
- Smooth animations

### Home Screen Features
- Welcome message with user name
- Role display
- Color-coded action cards
- Role-based card visibility
- "Coming Soon" banner

---

## 🧪 Things to Test

### Authentication Flow
- ✅ Login with correct credentials
- ✅ Login with wrong credentials (see error)
- ✅ Empty form submission (see validation)
- ✅ Quick-fill buttons work
- ✅ Password visibility toggle
- ✅ Logout and login again

### Role-Based UI
- ✅ Owner sees 6 cards
- ✅ Manager sees 4 cards
- ✅ Staff sees 4 cards
- ✅ Welcome message shows correct name
- ✅ Role is displayed correctly

### Navigation
- ✅ After logout, redirects to login
- ✅ After login, redirects to home
- ✅ Can't access home without login

---

## 📱 Expected Screen Flow

```
[Login Screen]
    ↓
  Login
    ↓
[Home Screen]
    ↓
  Click Card → "Coming Soon" (not implemented yet)
    ↓
  Logout
    ↓
[Login Screen]
```

---

## 🐛 Known Limitations (By Design)

1. **Cards Don't Navigate Yet**: All quick action cards show "Coming Soon"
2. **No Actual Backend**: Using in-memory dummy data
3. **No Persistence**: Logout clears everything
4. **Android Only**: iOS not supported in MVP
5. **No Setup Flow Yet**: Next phase of development

---

## 🔍 Code Exploration

### Want to See How It Works?

**Authentication Logic:**
```
lib/src/features/auth/data/repositories/dummy_auth_repository.dart
```

**User Roles & Permissions:**
```
lib/src/features/auth/domain/entities/user.dart
```

**Login UI:**
```
lib/src/features/auth/presentation/pages/login_page.dart
```

**Home Page UI:**
```
lib/src/features/auth/presentation/pages/home_page.dart
```

**App Routing:**
```
lib/src/core/routing/app_router.dart
```

**Theme & Colors:**
```
lib/src/core/theme/app_theme.dart
lib/src/core/constants/app_colors.dart
```

---

## ✨ Cool Features Already Working

1. **Smart Redirects**: Try accessing home without login (auto-redirects to login)
2. **Auth Persistence**: Auth state managed by Riverpod streams
3. **Role Validation**: Permission checks built into User entity
4. **Type Safety**: No dynamic types - everything is strongly typed
5. **Clean Architecture**: Easy to add new features without touching existing code

---

## 🎓 For Developers

### Add a New Feature

1. Create feature folder: `lib/src/features/my_feature/`
2. Add layers:
   ```
   my_feature/
   ├── data/
   │   └── repositories/
   ├── domain/
   │   ├── entities/
   │   └── repositories/
   └── presentation/
       ├── pages/
       ├── widgets/
       └── providers/
   ```
3. Define domain entities (pure Dart)
4. Create repository interface
5. Implement dummy repository
6. Build UI with Riverpod providers
7. Add route to `app_router.dart`

### Run Commands

```bash
# Check for errors
flutter analyze

# Format code
flutter format .

# Hot reload (during development)
Press 'r' in terminal

# Hot restart (reset state)
Press 'R' in terminal
```

---

## 🎯 Success Criteria Met

✅ Feature-first architecture  
✅ Backend-agnostic design  
✅ Role-based access control  
✅ Clean, maintainable code  
✅ Zero analysis errors  
✅ Low-literacy friendly UI  
✅ Type-safe throughout  
✅ Easy to test and extend  

---

**Next Step**: Build the Hotel Setup Wizard flow!
