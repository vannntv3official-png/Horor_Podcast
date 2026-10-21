# Khmer Horror Podcast (កម្មវិធីស្តាប់រឿងខ្មោចខ្មែរ)

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-blue.svg)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-19-61dafb.svg)](https://react.dev)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%2015-3ecf8e.svg)](https://supabase.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

> A production-grade digital audio platform dedicated to Khmer ghost stories, ancient folklore, supernatural mysteries, bedtime stories, and serialized audio podcasts in the Khmer language.

---

## 🌟 Features Overview

### 📱 Android Mobile App (Flutter)
- **Design System**: Premium Glassmorphic aesthetic with Soft Ivory (`#FBF9F5`) and Deep Violet (`#1D102F`) theme.
- **Home Feed**: Dynamic featured story hero banner, continue listening progress, category filter pills, trending stories, and recently added series.
- **Advanced Audio Player**:
  - Background audio playback and lockscreen media notifications via `just_audio` & `audio_service`.
  - Sleep timer with 15m, 30m, 45m, 60m, and "End of Episode" modes.
  - Playback speeds (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  - Scrubbing seek bar with debounced progress synchronization.
- **Offline Download Manager**:
  - App-private storage sandbox using `path_provider` & `Dio`.
  - Progress tracking, cancelable download tasks, storage usage metrics, and full offline playback.
- **Favorites & History**:
  - Seamless sync with Supabase for authenticated users.
  - Local storage fallback for guest users with automatic migration upon sign-in.
- **User Profile**:
  - Listening stats, language settings, profile customization, and GDPR-compliant account deletion workflow.

### 💻 Web Admin Dashboard (React + TypeScript + Vite)
- **Role-Based Access Control (RBAC)**: Strict server-enforced authentication verifying `admin` and `editor` roles via Supabase.
- **Story Management**: Full CRUD, slug generation, category assignment, cover image upload to `story-covers` bucket, and draft/publish toggles.
- **Episode Management**: Serialized episode uploads with direct-to-storage MP3 processing, upload progress, metadata extraction, and in-browser audio preview player.
- **Category Management**: Ordering, icon assignment, slug verification, and safe deletion checks.
- **User Role Management**: Manage user profiles and assign administrative privileges.
- **Audit Logs**: Immutable activity logging tracking all administrative creations, edits, and deletions.

---

## 🏗️ Repository Architecture

```
d:/Horror_Podcast/
├── lib/                             # Flutter Mobile App (Android)
│   ├── app/                         # App entry, router, theme, config
│   ├── core/                        # Widgets, error handling, storage, utils
│   ├── shared/                      # Models, riverpod providers
│   └── features/                    # Feature-first modules (auth, home, player, etc.)
├── admin/                           # React 19 + TypeScript + Vite Web Dashboard
│   ├── src/components/              # Glass UI & layout components
│   ├── src/features/                # Stories, Episodes, Categories, Dashboard, Users
│   └── src/lib/                     # Supabase JS client and utilities
├── supabase/                        # Database Infrastructure
│   ├── migrations/                  # Schema, RLS policies, Storage buckets
│   ├── seed.sql                     # Authentic Khmer folklore and horror stories
│   └── tests/                       # SQL RLS security verification suite
├── test/                            # Flutter Unit & Widget Tests
└── docs/                            # Comprehensive Technical Guides
    ├── ARCHITECTURE.md
    ├── SETUP_GUIDE.md
    ├── SUPABASE_SETUP.md
    ├── ANDROID_BUILD_GUIDE.md
    ├── ADMIN_DEPLOYMENT_GUIDE.md
    ├── SECURITY_CHECKLIST.md
    └── RELEASE_CHECKLIST.md
```

---

## 🚀 Quick Start

### 1. Database Setup
Follow the [Supabase Setup Guide](docs/SUPABASE_SETUP.md) to apply migrations, enable RLS, configure buckets, and seed sample stories.

### 2. Run Mobile App
```bash
flutter pub get
flutter run
```

### 3. Run Admin Dashboard
```bash
cd admin
npm install
npm run dev
```

---

## 🧪 Testing & Verification

- **Flutter Unit & Widget Tests**: `flutter test` (14/14 passed)
- **Flutter Static Analysis**: `flutter analyze` (No issues found)
- **Admin Unit Tests**: `npm --prefix admin test` (5/5 passed)
- **Admin Production Build**: `npm --prefix admin run build` (Completed with 0 errors)
