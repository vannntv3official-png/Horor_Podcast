# Khmer Horror Podcast — Android Build & Release Guide

## 1. Application Configuration

- **App Name**: Khmer Horror Podcast
- **Application ID / Package**: `com.khmerhorrorpodcast.app`
- **Minimum SDK**: 23 (required for modern background audio session & notifications)
- **Target SDK**: 34
- **Main Activity**: `com.ryanheise.audioservice.AudioServiceActivity` (subclassed in `MainActivity.kt`)

---

## 2. Android Permissions

Declared in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.INTERNET`: For streaming audio, images, and API communication.
- `android.permission.WAKE_LOCK`: Prevents CPU from sleeping during background audio playback.
- `android.permission.FOREGROUND_SERVICE`: Background playback service.
- `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`: Android 14+ media playback declaration.

---

## 3. Building Debug APK

```bash
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

---

## 4. Building Production Release APK & App Bundle (AAB)

### Step 1: Create Keystore
Generate a secure release keystore (do NOT commit to git!):
```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias khmerhorror
```

### Step 2: Configure `android/key.properties`
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=khmerhorror
storeFile=../../release-keystore.jks
```

### Step 3: Build App Bundle (AAB) for Google Play
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://your-production.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-production-anon-key
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Build Split Release APK
```bash
flutter build apk --release --split-per-abi \
  --dart-define=SUPABASE_URL=https://your-production.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-production-anon-key
```
