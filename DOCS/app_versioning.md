# App Versioning & Updates

## 🚀 Releasing an Update

1. **Bump version** in `pubspec.yaml`:
   ```yaml
   version: 1.1.0+2 # was 1.0.0+1
   ```

2. **Commit & push** → GitHub builds APK → Teammates see dialog after login

---

## 📲 Getting Updates (Testers)

1. Open app & log in
2. Update dialog appears if new version available
3. Tap **"Update Now"** → downloads from GitHub
4. Install APK

---

## 🔧 Toggle Updates

```dart
// lib/src/core/config/app_config.dart
static const bool enableUpdateCheck = true;  // false = disabled
```

---

## Version Format

```
1.2.3+4
│ │ │ └─ Build number
│ │ └─── Patch (bug fixes)
│ └───── Minor (features)
└─────── Major (breaking)
```
