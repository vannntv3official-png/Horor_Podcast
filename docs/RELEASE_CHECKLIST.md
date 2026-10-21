# Khmer Horror Podcast — Production Release Checklist

## 1. Pre-Release Verification

- [x] **Flutter Static Analysis**: `flutter analyze` passes with 0 errors and 0 issues.
- [x] **Flutter Unit & Widget Tests**: All 14 tests pass (`flutter test`).
- [x] **Admin Static Build & Typecheck**: `npm --prefix admin run build` completes successfully.
- [x] **Admin Unit Tests**: Vitest passes (`npm --prefix admin test`).
- [x] **Database Schema**: SQL migrations tested with `security_tests.sql`.
- [x] **Android Package Name**: Configured as `com.khmerhorrorpodcast.app`.
- [x] **Android Permissions**: Media playback, foreground service, wake lock declared.
- [x] **Khmer Localization**: Authentic Khmer copy for errors, empty states, titles, and sleep timer.

---

## 2. Store Submission Checklist

- [ ] **Google Play Console Account**: Created and identity verified.
- [ ] **App Content Declarations**: News, Financial, Audio categories set.
- [ ] **Target Audience & Content Rating**: 16+ or 18+ (due to atmospheric Khmer horror content).
- [ ] **Privacy Policy URL**: Hosted and submitted in Google Play Console.
- [ ] **Store Listing Copy (Khmer & English)**:
  - App Name: `Khmer Horror Podcast`
  - Short Description: ស្តាប់រឿងខ្មោច រឿងព្រេងបុរាណ និងរឿងអាថ៌កំបាំងខ្មែរគ្រប់ពេលវេលា
- [ ] **App Screenshots**: 1080x1920 (Home feed, Player screen, Story details, Offline downloads).
- [ ] **App Icon & Feature Graphic**: 512x512 icon and 1024x500 banner.
- [ ] **Production Keystore**: Stored safely in offline password manager / CI/CD secrets.
