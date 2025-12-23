# GitHub Actions APK Build

## What It Does

- Builds arm64-v8a APK on push to main/master
- Uploads to GitHub Releases automatically

## Triggers

Only runs when these change:

- `rooms_app/lib/**` (Dart code)
- `rooms_app/pubspec.yaml` (dependencies)
- `rooms_app/android/**` (Android config)

## Usage

1. Push to `main` or `master`
2. Wait ~5 min for build
3. Download APK from **Releases** tab

## Download APK

`Repo → Releases → Latest → app-arm64-v8a-release.apk`

## Manual Trigger

Not enabled. Push code to trigger build.

## Troubleshooting

- **Build failed**: Check Actions tab for logs
- **No release created**: Ensure changes are in tracked paths
- **Wrong version**: Update `version:` in `pubspec.yaml`
