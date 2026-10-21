# Khmer Horror Podcast — Local Development Setup Guide

## 1. Prerequisites

- **Flutter SDK**: 3.47+ (Dart 3.13+)
- **Node.js**: v20+ or v24+
- **npm**: 10+
- **Android Studio / Android SDK**: Platform API 34+, Android SDK Build-Tools
- **Supabase Account**: Local CLI or cloud Supabase project.

---

## 2. Setting Up the Flutter Mobile Application

### Step 1: Install Dependencies
From the repository root:
```bash
flutter pub get
```

### Step 2: Environment Configuration
Copy `.env.example` to `.env` or pass `--dart-define` at runtime:
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Step 3: Run the App
Launch in Android emulator or connected device:
```bash
flutter run
```

### Step 4: Run Flutter Tests & Linting
```bash
flutter analyze
flutter test
```

---

## 3. Setting Up the Admin Web Dashboard

### Step 1: Navigate and Install Dependencies
```bash
cd admin
npm install
```

### Step 2: Configure Environment Variables
Create `admin/.env.local`:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-public-anon-key
```
> **Warning**: NEVER put the Supabase `service_role` key into `admin/.env.local`. Vite bundles `VITE_*` variables into the browser bundle!

### Step 3: Run the Admin Development Server
```bash
npm run dev
```
Open `http://localhost:5173` in your browser.

### Step 4: Run Admin Tests & Production Build
```bash
npm test
npm run build
```
