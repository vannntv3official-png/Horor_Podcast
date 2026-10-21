# Khmer Horror Podcast — Security Audit & Compliance Checklist

## 1. Secrets & Credentials Management

- [x] **Zero Service Role Keys in Mobile**: The Flutter Android app uses only `SUPABASE_ANON_KEY` via `--dart-define`.
- [x] **Zero Service Role Keys in Admin Web**: The Vite React frontend uses only `VITE_SUPABASE_ANON_KEY`.
- [x] **Git Tracking Security**: `.env`, `.env.local`, `*.keystore`, and `*.jks` are explicitly listed in `.gitignore`.
- [x] **Safe Logging**: `AppLogger` omits passwords, JWT tokens, and sensitive auth payloads.

---

## 2. PostgreSQL & Row Level Security (RLS)

- [x] **RLS Enabled on All Tables**: `profiles`, `user_roles`, `categories`, `stories`, `episodes`, `favorites`, `listening_progress`, `listening_events`, `admin_audit_logs`, `notifications`.
- [x] **Strict Privilege Separation**: Users cannot modify their own roles (`user_roles_insert_admin`, `user_roles_update_admin`, `user_roles_delete_admin`).
- [x] **Private Data Isolation**: `favorites` and `listening_progress` enforce `auth.uid() = user_id`.
- [x] **Draft Content Guard**: Anonymous users cannot query draft stories or draft episodes.
- [x] **Audit Log Immutability**: No client-side UPDATE or DELETE policies are granted on `admin_audit_logs`.

---

## 3. Storage Bucket Security

- [x] **MIME Type Validation**: `story-covers` restricts to image types; `podcast-audio` restricts to audio types.
- [x] **File Size Enforced at Bucket Level**: Covers limited to 5MB, Audio limited to 100MB, Avatars limited to 2MB.
- [x] **Storage Write Guard**: Only verified editors/admins can write to `story-covers` and `podcast-audio`.

---

## 4. Mobile Client Security

- [x] **Path Traversal Protection**: Offline downloaded audio files use sanitized deterministic filenames (`ep_${id}.mp3`).
- [x] **Private Storage Sandbox**: Offline files are saved strictly in `getApplicationDocumentsDirectory()` (`app-private`).
- [x] **Safe Account Deletion**: Users have an explicit account deletion workflow cascading to their private data.
- [x] **Secure Auth Flow**: PKCE flow is enabled for Supabase Auth in `bootstrap.dart`.
