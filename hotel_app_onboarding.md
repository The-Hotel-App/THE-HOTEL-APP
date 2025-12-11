# Hotel App - Onboarding & Login Flow

## 📱 App Opens for the First Time

### Welcome Screen

```
┌─────────────────────────────┐
│                             │
│    🏨 Hotel Manager App     │
│                             │
│   ┌─────────────────────┐   │
│   │   Create New Hotel  │   │  ← For new hotel owners
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │   Login to Hotel    │   │  ← For existing users
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │   Join a Hotel      │   │  ← For new employees
│   └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

---

## 🎯 Three User Journeys

### Journey 1: CREATE NEW HOTEL (New Owner)

#### Step 1: Basic Info
```
┌─────────────────────────────┐
│ Hotel Name: ____________    │
│ City: __________________    │
│ Your Name: _____________    │
└─────────────────────────────┘
```

#### Step 2: Create Hotel Code
```
┌─────────────────────────────┐
│ Create a unique code for    │
│ your hotel (like a username)│
│                             │
│ Hotel Code: taj-chennai_    │
│ ✓ Available                 │
│                             │
│ (Employees will use this    │
│  code to join your hotel)   │
└─────────────────────────────┘
```

#### Step 3: Your Login Details
```
┌─────────────────────────────┐
│ Email (optional): _______   │
│ Phone (optional): _______   │
│ Password: _______________   │
│                             │
│ [Must provide email OR phone]│
└─────────────────────────────┘
```

#### Step 4: Register Fingerprint
```
┌─────────────────────────────┐
│  Place finger on sensor     │
│         👆                  │
│                             │
│  This will be used for      │
│  quick login & verification │
└─────────────────────────────┘
```

#### ✅ Hotel Created!
```
┌─────────────────────────────┐
│ Your hotel "Taj Chennai"    │
│ is ready!                   │
│                             │
│ Hotel Code: taj-chennai     │
│                             │
│ Share this code with your   │
│ employees to join.          │
│                             │
│ [ Continue to Dashboard ]   │
└─────────────────────────────┘
```

---

### Journey 2: LOGIN TO HOTEL (Existing User)

#### Step 1: Which Hotel?
```
┌─────────────────────────────┐
│ Enter Hotel Code:           │
│ ________________________    │
│                             │
│ (e.g., taj-chennai)         │
└─────────────────────────────┘
```

#### Step 2: Quick Login
```
┌─────────────────────────────┐
│    👆 Use Fingerprint       │
│                             │
│ - OR -                      │
│                             │
│ Email/Phone: ___________    │
│ Password: ______________    │
└─────────────────────────────┘
```

#### ✅ Logged In!

**Smart Features:**
- App remembers last used hotel code
- Staff can login with just fingerprint
- Owner/Manager can use email/phone + password

---

### Journey 3: JOIN A HOTEL (New Employee)

#### Step 1: Get Join Code
```
┌─────────────────────────────┐
│ Ask your manager for:       │
│                             │
│ 1. Hotel Code              │
│ 2. Join Code               │
└─────────────────────────────┘
```

#### Step 2: Enter Codes
```
┌─────────────────────────────┐
│ Hotel Code: ____________    │
│ Join Code: _____________    │
│                             │
│ [ Verify ]                  │
└─────────────────────────────┘
```

#### Step 3: Create Your Account
```
┌─────────────────────────────┐
│ Your Name: _____________    │
│ Email (optional): _______   │
│ Phone (optional): _______   │
│ Password: _______________   │
│                             │
│ [Must provide email OR phone]│
└─────────────────────────────┘
```

#### Step 4: Register Fingerprint
```
┌─────────────────────────────┐
│  Place finger on sensor     │
│         👆                  │
└─────────────────────────────┘
```

#### Step 5: Wait for Approval
```
┌─────────────────────────────┐
│ ⏳ Request Sent!            │
│                             │
│ Manager will assign your    │
│ role and approve shortly.   │
│                             │
│ You'll get a notification   │
│ when approved.              │
└─────────────────────────────┘
```

---

## 🔑 How Join Codes Work (Simple System)

### Owner/Manager Generates Join Code

```
Dashboard → Add Employee
┌─────────────────────────────┐
│ [ Generate Join Code ]      │
│                             │
│ Code: HOTEL2024            │
│                             │
│ Valid for: 7 days          │
│ Max uses: 10 people        │
│                             │
│ [ Copy & Share ]           │
└─────────────────────────────┘
```

### What Happens When Someone Joins

**Owner/Manager gets notification:**
```
┌─────────────────────────────┐
│ 🔔 New Join Request         │
│                             │
│ Name: Rajesh Kumar          │
│ Phone: +91 98xxx xxxxx      │
│                             │
│ Assign Role:                │
│ ○ Manager                   │
│ ○ Staff                     │
│ ○ Kitchen Team              │
│                             │
│ [ Approve ]  [ Reject ]     │
└─────────────────────────────┘
```

**Employee gets notification:**
```
✅ Approved! You're now Staff at Taj Chennai
```

---

## 🏨 Multi-Hotel for Same Owner

### Owner Creates 2nd Hotel

```
Dashboard → [ + New Hotel ]
┌─────────────────────────────┐
│ Hotel Name: Grand Palace    │
│ Hotel Code: grand-mumbai    │
│                             │
│ [ Create ]                  │
└─────────────────────────────┘
        ↓
✅ Created! Now you own 2 hotels
```

### Switching Between Hotels

```
Dashboard Header:
┌─────────────────────────────┐
│ 🏨 Taj Chennai        [▼]   │  ← Tap to switch
└─────────────────────────────┘
        ↓
┌─────────────────────────────┐
│ Your Hotels:                │
│                             │
│ ✓ Taj Chennai              │
│   Grand Mumbai             │
│                             │
└─────────────────────────────┘
```

**Easy switch, separate data for each hotel.**

---

## 📊 Summary Table

| User Type | First Action | What They See |
|-----------|-------------|---------------|
| **New Owner** | "Create New Hotel" | Hotel setup → Hotel code → Login details → Fingerprint → Dashboard |
| **Existing Owner/Manager/Staff** | "Login to Hotel" | Hotel code → Fingerprint/Password → Dashboard |
| **New Employee** | "Join a Hotel" | Hotel code + Join code → Account details → Fingerprint → Wait for approval |

---

## 🎨 Visual Design Tips

Use **color coding** for simplicity:

```
🟢 Green = Create/New
🔵 Blue = Login/Existing  
🟡 Yellow = Join/Request
```

**On the welcome screen:**
- **Green button** = Create New Hotel
- **Blue button** = Login to Hotel
- **Yellow button** = Join a Hotel

---

## 🔐 Security in Simple Terms

1. **Hotel Code** = Like your hotel's username (public, employees need this)
2. **Join Code** = Temporary password to request access (owner shares this)
3. **Fingerprint** = Quick & secure way to login daily
4. **Email/Phone + Password** = Backup login method

---

## ✅ Recommendations for Join Code

**Use Multi-Use Join Codes** (simpler for MVP):
- Owner creates ONE code like `HOTEL2024`
- Valid for 7-30 days
- Multiple employees can use same code
- Owner approves each person individually
- More practical for hotels with high staff turnover

**Why not single-use?**
- Too many codes to manage
- Staff might lose their unique code
- Multi-use is still secure because owner approves each request

---

## 🔄 Complete User Flow Summary

### New Hotel Owner Journey
```
Download App
    ↓
Create New Hotel
    ↓
Enter Hotel Details
    ↓
Create Hotel Code
    ↓
Set Login Credentials
    ↓
Register Fingerprint
    ↓
Dashboard (Generate Join Codes for employees)
```

### Existing User Journey
```
Open App
    ↓
Login to Hotel
    ↓
Enter Hotel Code (or auto-fill)
    ↓
Fingerprint / Email+Password
    ↓
Dashboard (Role-based access)
```

### New Employee Journey
```
Download App
    ↓
Join a Hotel
    ↓
Enter Hotel Code + Join Code
    ↓
Create Account Details
    ↓
Register Fingerprint
    ↓
Wait for Approval
    ↓
Get Notification
    ↓
Login & Dashboard
```

---

## 📝 Key Technical Points

### Database Structure
- **Organizations Table**: Stores hotel details, hotel_code
- **Users Table**: Stores employee details, linked to organization_id, role
- **Join Codes Table**: Stores active join codes, expiry, max uses
- **Join Requests Table**: Stores pending employee requests

### Authentication Flow
1. User enters hotel_code → Validates organization exists
2. User authenticates → Validates credentials against organization
3. System checks role → Applies role-based permissions
4. Session created → Tied to user + organization

### Multi-Tenancy
- Each hotel is isolated
- Owner can own multiple hotels
- Data never crosses hotel boundaries
- Role permissions enforced at database level (Row Level Security)

---

**Document Version:** 1.0  
**Last Updated:** December 2024  
**For:** Hotel Management App MVP