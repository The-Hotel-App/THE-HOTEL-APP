# App Versioning & Updates

## 🚀 Releasing an Update

1. **Bump version** in `pubspec.yaml`:
   ```yaml
   version: 1.1.0+2 # was 1.0.0+1
   ```

2. **Commit & push**:
   ```bash
   git add .
   git commit -m "v1.1.0 - your changes"
   git push
   ```

3. **Done!** → GitHub builds APK → Teammates see update dialog

---

## 📲 Getting Updates (For Testers)

1. Open the app → dialog appears if update available
2. Tap **"Update Now"** → downloads from GitHub
3. Install the new APK

---

## 🔧 Toggle Update Checks

```dart
// lib/src/core/config/app_config.dart
static const bool enableUpdateCheck = true;  // false = no prompts
```

---

## Version Format

```
1.2.3+4
│ │ │ └─ Build number (increment each build)
│ │ └─── Patch (bug fixes)
│ └───── Minor (new features)
└─────── Major (breaking changes)
```
