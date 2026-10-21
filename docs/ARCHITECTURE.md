# Khmer Horror Podcast — Technical Architecture Documentation

## 1. System Overview

**Khmer Horror Podcast** is a high-performance, production-ready digital audio platform tailored for Cambodian ghost stories, ancient folklore, legends, and audio series.

### High-Level Topology

```
+-----------------------------------------------------------+
|                      Clients Layer                        |
|                                                           |
|   +--------------------------+  +---------------------+   |
|   | Flutter Android App      |  | React Admin Web     |   |
|   | - Feature-First (Dart)   |  | - React 19 + Vite   |   |
|   | - Riverpod State         |  | - Tailwind v4 Glass |   |
|   | - just_audio & service   |  | - TanStack Query    |   |
|   | - Dio Offline Cache      |  | - Lucide Icons      |   |
|   +------------+-------------+  +----------+----------+   |
+----------------|---------------------------|--------------+
                 |                           |
                 v                           v
+-----------------------------------------------------------+
|                   Supabase Backend                        |
|                                                           |
|   +-------------------+  +----------------------------+   |
|   | Supabase Auth     |  | Storage Buckets            |   |
|   | - PKCE flow       |  | - story-covers             |   |
|   | - JWT sessions    |  | - podcast-audio            |   |
|   +-------------------+  | - user-avatars             |   |
|                          +----------------------------+   |
|   +---------------------------------------------------+   |
|   | PostgreSQL 15+ & Row Level Security (RLS)         |   |
|   | - profiles            - listening_progress        |   |
|   | - user_roles (RBAC)   - listening_events          |   |
|   | - categories          - admin_audit_logs          |   |
|   | - stories & episodes  - notifications             |   |
|   +---------------------------------------------------+   |
+-----------------------------------------------------------+
```

---

## 2. Mobile Architecture (Flutter Android)

The Flutter application follows a **Feature-First Layered Architecture**:

### Layer Breakdown
1. **Presentation Layer**:
   - `presentation/screens`: Full-screen views (e.g. `HomeScreen`, `ExploreScreen`, `StoryDetailsScreen`, `FullPlayerScreen`).
   - `presentation/widgets`: Reusable presentation widgets (e.g. `MiniPlayer`, `FeaturedStoryCard`, `EpisodeListTile`).
   - `presentation/controllers`: `StateNotifier` / `Notifier` classes exposing immutable UI state.
2. **Domain & Model Layer**:
   - `shared/models`: Strictly typed immutable entities (`StoryModel`, `EpisodeModel`, `CategoryModel`, `DownloadItemModel`, `ListeningProgressModel`).
3. **Data Layer**:
   - `data/repositories`: Data sources abstracting Supabase queries and local caching.
   - `core/storage`: `LocalStorage` wrapping encrypted SharedPreferences for guest favorites, search terms, and download registries.
4. **Core Services**:
   - `features/audio_player/data/audio_handler.dart`: Custom `KhmerAudioHandler` extending `BaseAudioHandler` with `SeekHandler` from `audio_service`, coordinating background media sessions, Android notifications, lock-screen controls, and sleep timers.
   - `features/downloads/data/download_manager.dart`: App-private sandbox download queue using `Dio` with progress tracking and size validation.

---

## 3. Web Admin Dashboard Architecture (React + Vite)

The Admin portal is completely isolated from the mobile codebase:

- **State & Data Fetching**: TanStack Query (`@tanstack/react-query`) handles query caching, mutation states, and automatic cache invalidation.
- **Client Validation**: Zod schemas validate forms before submission.
- **Security & Authorization**:
  - `AuthProvider` verifies that the logged-in user possesses `role = 'admin'` or `role = 'editor'` via the server-controlled `user_roles` table.
  - Zero service role keys in client bundle; all privileged actions are validated at the PostgreSQL RLS layer.

---

## 4. Database & Row Level Security (RLS)

- **Principle of Least Privilege**: Anonymous users can only read published stories, episodes, and active categories.
- **Role Isolation**: User self-assignment of roles is prevented by RLS on `user_roles`.
- **Private Data Protection**: Listening progress and user favorites are scoped to `auth.uid() = user_id`.
- **Immutable Audit Logging**: Actions are inserted by authenticated actors into `admin_audit_logs`, with updates and deletes restricted.
