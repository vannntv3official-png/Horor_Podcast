# Khmer Horror Podcast — Supabase Backend & Database Setup Guide

## 1. Overview of Migrations

The database structure is organized in `supabase/migrations/`:

| File | Purpose |
|---|---|
| `20261022000001_initial_schema.sql` | Tables (`profiles`, `user_roles`, `categories`, `stories`, `episodes`, `favorites`, `listening_progress`, `listening_events`, `admin_audit_logs`, `notifications`), triggers & indexes |
| `20261022000002_rls_policies.sql` | Row Level Security (RLS) policies enforcing role isolation & least privilege |
| `20261022000003_storage_buckets.sql` | Storage buckets (`story-covers`, `podcast-audio`, `user-avatars`) & storage security rules |
| `seed.sql` | Seed data with authentic Khmer horror and folklore series |
| `tests/security_tests.sql` | SQL verification suite for RLS and permission boundaries |

---

## 2. Applying Migrations

### Option A: Using the Supabase Dashboard SQL Editor
1. Log in to [Supabase Dashboard](https://supabase.com/dashboard).
2. Open your project, click **SQL Editor**.
3. Copy and run the contents of `20261022000001_initial_schema.sql`.
4. Copy and run `20261022000002_rls_policies.sql`.
5. Copy and run `20261022000003_storage_buckets.sql`.
6. Copy and run `seed.sql` to populate initial categories, stories, and episodes.

### Option B: Using the Supabase CLI
```bash
supabase db push
supabase db reset
```

---

## 3. Creating Your First Admin Account

1. Register a new user in the app or via the Supabase Auth Dashboard (e.g. `admin@khmerhorror.com`).
2. Run this SQL command in the Supabase SQL Editor to grant admin privileges:

```sql
-- Find user id
SELECT id, email FROM auth.users WHERE email = 'admin@khmerhorror.com';

-- Insert admin role (replace UUID with the actual user id)
INSERT INTO public.user_roles (user_id, role)
VALUES ('YOUR_USER_UUID_HERE', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;
```

3. Log in to the Admin Dashboard at `http://localhost:5173`. You will now have full access to manage stories, upload MP3s, edit categories, and assign roles.

---

## 4. Running Database Security Tests

Run `supabase/tests/security_tests.sql` in the SQL Editor. It verifies:
- Anonymous users can read published stories but cannot read draft stories.
- Anonymous users have `is_admin() = FALSE`.
- Slugs are unique and episode numbers per story have no duplicates.
- All tests execute within a transaction and roll back automatically.
