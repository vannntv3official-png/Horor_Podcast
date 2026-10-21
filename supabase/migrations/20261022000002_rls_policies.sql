-- ==============================================================================
-- Khmer Horror Podcast - Row Level Security (RLS) Policies
-- Migration: 20261022000002_rls_policies.sql
-- Description: Comprehensive RLS policies enforcing Least Privilege Principle
-- ==============================================================================

-- Enable RLS on all tables in public schema
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.episodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listening_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listening_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 1. Profiles Policies
-- -----------------------------------------------------------------------------
-- Allow users to read their own profile, and allow admins/editors to inspect
CREATE POLICY "profiles_select_own_or_admin"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id OR public.is_editor());

-- Allow users to update only their own profile
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow profile creation on sign-up (for the authenticated user)
CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- -----------------------------------------------------------------------------
-- 2. User Roles Policies
-- -----------------------------------------------------------------------------
-- Users can see their own assigned roles; Admins can see all user roles
CREATE POLICY "user_roles_select"
    ON public.user_roles FOR SELECT
    USING (auth.uid() = user_id OR public.is_admin());

-- Only admins can assign or modify roles. No user self-privilege escalation.
CREATE POLICY "user_roles_insert_admin"
    ON public.user_roles FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "user_roles_update_admin"
    ON public.user_roles FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

CREATE POLICY "user_roles_delete_admin"
    ON public.user_roles FOR DELETE
    USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 3. Categories Policies
-- -----------------------------------------------------------------------------
-- Public can read active categories; Admins/Editors can read all
CREATE POLICY "categories_select_public"
    ON public.categories FOR SELECT
    USING (is_active = TRUE OR public.is_editor());

-- Only Admins and Editors can create, update, or delete categories
CREATE POLICY "categories_insert_editor"
    ON public.categories FOR INSERT
    WITH CHECK (public.is_editor());

CREATE POLICY "categories_update_editor"
    ON public.categories FOR UPDATE
    USING (public.is_editor())
    WITH CHECK (public.is_editor());

CREATE POLICY "categories_delete_admin"
    ON public.categories FOR DELETE
    USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 4. Stories Policies
-- -----------------------------------------------------------------------------
-- Public can read published stories; Admins/Editors can read drafts & archives
CREATE POLICY "stories_select_public"
    ON public.stories FOR SELECT
    USING (status = 'published' OR public.is_editor());

-- Only Admins and Editors can manage stories
CREATE POLICY "stories_insert_editor"
    ON public.stories FOR INSERT
    WITH CHECK (public.is_editor());

CREATE POLICY "stories_update_editor"
    ON public.stories FOR UPDATE
    USING (public.is_editor())
    WITH CHECK (public.is_editor());

CREATE POLICY "stories_delete_admin"
    ON public.stories FOR DELETE
    USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 5. Episodes Policies
-- -----------------------------------------------------------------------------
-- Public can read published episodes of published stories; Admins/Editors see all
CREATE POLICY "episodes_select_public"
    ON public.episodes FOR SELECT
    USING (
        (status = 'published' AND EXISTS (
            SELECT 1 FROM public.stories s
            WHERE s.id = story_id AND s.status = 'published'
        ))
        OR public.is_editor()
    );

-- Only Admins and Editors can manage episodes
CREATE POLICY "episodes_insert_editor"
    ON public.episodes FOR INSERT
    WITH CHECK (public.is_editor());

CREATE POLICY "episodes_update_editor"
    ON public.episodes FOR UPDATE
    USING (public.is_editor())
    WITH CHECK (public.is_editor());

CREATE POLICY "episodes_delete_admin"
    ON public.episodes FOR DELETE
    USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 6. Favorites Policies
-- -----------------------------------------------------------------------------
-- Users can only see, add, and remove their own favorites
CREATE POLICY "favorites_select_own"
    ON public.favorites FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "favorites_insert_own"
    ON public.favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "favorites_delete_own"
    ON public.favorites FOR DELETE
    USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 7. Listening Progress Policies
-- -----------------------------------------------------------------------------
-- Users can only see and update their own progress
CREATE POLICY "listening_progress_select_own"
    ON public.listening_progress FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "listening_progress_insert_own"
    ON public.listening_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "listening_progress_update_own"
    ON public.listening_progress FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "listening_progress_delete_own"
    ON public.listening_progress FOR DELETE
    USING (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 8. Listening Events Policies (Analytics)
-- -----------------------------------------------------------------------------
-- Admins can read all events; users can read their own
CREATE POLICY "listening_events_select"
    ON public.listening_events FOR SELECT
    USING (public.is_admin() OR auth.uid() = user_id);

-- Anyone can submit listening events (for telemetry), but cannot impersonate other users
CREATE POLICY "listening_events_insert"
    ON public.listening_events FOR INSERT
    WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- Events are immutable (no updates or deletes allowed from client)

-- -----------------------------------------------------------------------------
-- 9. Admin Audit Logs Policies
-- -----------------------------------------------------------------------------
-- Strictly viewable by Admins
CREATE POLICY "audit_logs_select_admin"
    ON public.admin_audit_logs FOR SELECT
    USING (public.is_admin());

-- Editors and Admins can append audit entries
CREATE POLICY "audit_logs_insert_admin"
    ON public.admin_audit_logs FOR INSERT
    WITH CHECK (public.is_editor() AND actor_user_id = auth.uid());

-- Audit logs are immutable (no updates or deletes)

-- -----------------------------------------------------------------------------
-- 10. Notifications Policies
-- -----------------------------------------------------------------------------
-- Users see their personal notifications or broadcast notifications
CREATE POLICY "notifications_select_user"
    ON public.notifications FOR SELECT
    USING (user_id = auth.uid() OR user_id IS NULL OR public.is_admin());

-- Users can update read_at on their notifications
CREATE POLICY "notifications_update_user"
    ON public.notifications FOR UPDATE
    USING (user_id = auth.uid() OR public.is_admin())
    WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- Admins can create and delete notifications
CREATE POLICY "notifications_insert_admin"
    ON public.notifications FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "notifications_delete_admin"
    ON public.notifications FOR DELETE
    USING (public.is_admin());
