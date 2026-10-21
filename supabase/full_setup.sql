-- ==============================================================================
-- Khmer Horror Podcast - Complete Supabase Full Setup Script (All-in-One)
-- File: supabase/full_setup.sql
-- Description: Executes full schema creation, RLS policies, storage buckets, and seed data.
-- ==============================================================================

BEGIN;

-- ==============================================================================
-- PART 1: EXTENSIONS & INITIAL SCHEMA
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Helper: Updated At Trigger Function
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    avatar_path TEXT NULL,
    preferred_language TEXT DEFAULT 'km' CHECK (preferred_language IN ('km', 'en')),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- 2. User Roles Table (Strict RBAC)
CREATE TABLE IF NOT EXISTS public.user_roles (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'editor', 'user')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (user_id, role)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- Helper security functions for checking user role in RLS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_editor()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role IN ('admin', 'editor')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Automatically create profile and 'user' role on sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, preferred_language)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        'km'
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'user')
    ON CONFLICT (user_id, role) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_name TEXT,
    sort_order INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_categories_slug ON public.categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON public.categories(sort_order);

DROP TRIGGER IF EXISTS trg_categories_updated_at ON public.categories;
CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- 4. Stories Table
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    cover_path TEXT,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    narrator_name TEXT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    is_featured BOOLEAN DEFAULT FALSE NOT NULL,
    published_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_stories_slug ON public.stories(slug);
CREATE INDEX IF NOT EXISTS idx_stories_category_id ON public.stories(category_id);
CREATE INDEX IF NOT EXISTS idx_stories_status ON public.stories(status);
CREATE INDEX IF NOT EXISTS idx_stories_is_featured ON public.stories(is_featured);
CREATE INDEX IF NOT EXISTS idx_stories_published_at ON public.stories(published_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON public.stories(created_at DESC);

DROP TRIGGER IF EXISTS trg_stories_updated_at ON public.stories;
CREATE TRIGGER trg_stories_updated_at
    BEFORE UPDATE ON public.stories
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- 5. Episodes Table
CREATE TABLE IF NOT EXISTS public.episodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    episode_number INTEGER NOT NULL,
    audio_path TEXT NOT NULL,
    audio_mime_type TEXT DEFAULT 'audio/mpeg',
    audio_size_bytes BIGINT,
    duration_seconds INTEGER,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    allow_download BOOLEAN DEFAULT TRUE NOT NULL,
    published_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE (story_id, episode_number)
);

CREATE INDEX IF NOT EXISTS idx_episodes_story_id ON public.episodes(story_id);
CREATE INDEX IF NOT EXISTS idx_episodes_story_number ON public.episodes(story_id, episode_number);
CREATE INDEX IF NOT EXISTS idx_episodes_status ON public.episodes(status);
CREATE INDEX IF NOT EXISTS idx_episodes_published_at ON public.episodes(published_at DESC NULLS LAST);

DROP TRIGGER IF EXISTS trg_episodes_updated_at ON public.episodes;
CREATE TRIGGER trg_episodes_updated_at
    BEFORE UPDATE ON public.episodes
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- 6. Favorites Table
CREATE TABLE IF NOT EXISTS public.favorites (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (user_id, story_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_story_id ON public.favorites(story_id);

-- 7. Listening Progress Table
CREATE TABLE IF NOT EXISTS public.listening_progress (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    episode_id UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
    position_seconds INTEGER DEFAULT 0 NOT NULL CHECK (position_seconds >= 0),
    completed BOOLEAN DEFAULT FALSE NOT NULL,
    last_played_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    PRIMARY KEY (user_id, episode_id)
);

CREATE INDEX IF NOT EXISTS idx_listening_progress_user ON public.listening_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_listening_progress_last_played ON public.listening_progress(user_id, last_played_at DESC);

DROP TRIGGER IF EXISTS trg_listening_progress_updated_at ON public.listening_progress;
CREATE TRIGGER trg_listening_progress_updated_at
    BEFORE UPDATE ON public.listening_progress
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- 8. Listening Events Table
CREATE TABLE IF NOT EXISTS public.listening_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    episode_id UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('play', 'pause', 'complete', 'download', 'seek')),
    listened_seconds INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_listening_events_episode_id ON public.listening_events(episode_id);
CREATE INDEX IF NOT EXISTS idx_listening_events_created_at ON public.listening_events(created_at DESC);

-- 9. Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.admin_audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.admin_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.admin_audit_logs(created_at DESC);

-- 10. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    target_type TEXT,
    target_id UUID,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);


-- ==============================================================================
-- PART 2: ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

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

-- Profiles Policies
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_own_or_admin"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id OR public.is_editor());

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- User Roles Policies
DROP POLICY IF EXISTS "user_roles_select" ON public.user_roles;
CREATE POLICY "user_roles_select"
    ON public.user_roles FOR SELECT
    USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "user_roles_insert_admin" ON public.user_roles;
CREATE POLICY "user_roles_insert_admin"
    ON public.user_roles FOR INSERT
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "user_roles_update_admin" ON public.user_roles;
CREATE POLICY "user_roles_update_admin"
    ON public.user_roles FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "user_roles_delete_admin" ON public.user_roles;
CREATE POLICY "user_roles_delete_admin"
    ON public.user_roles FOR DELETE
    USING (public.is_admin());

-- Categories Policies
DROP POLICY IF EXISTS "categories_select_public" ON public.categories;
CREATE POLICY "categories_select_public"
    ON public.categories FOR SELECT
    USING (is_active = TRUE OR public.is_editor());

DROP POLICY IF EXISTS "categories_insert_editor" ON public.categories;
CREATE POLICY "categories_insert_editor"
    ON public.categories FOR INSERT
    WITH CHECK (public.is_editor());

DROP POLICY IF EXISTS "categories_update_editor" ON public.categories;
CREATE POLICY "categories_update_editor"
    ON public.categories FOR UPDATE
    USING (public.is_editor())
    WITH CHECK (public.is_editor());

DROP POLICY IF EXISTS "categories_delete_admin" ON public.categories;
CREATE POLICY "categories_delete_admin"
    ON public.categories FOR DELETE
    USING (public.is_admin());

-- Stories Policies
DROP POLICY IF EXISTS "stories_select_public" ON public.stories;
CREATE POLICY "stories_select_public"
    ON public.stories FOR SELECT
    USING (status = 'published' OR public.is_editor());

DROP POLICY IF EXISTS "stories_insert_editor" ON public.stories;
CREATE POLICY "stories_insert_editor"
    ON public.stories FOR INSERT
    WITH CHECK (public.is_editor());

DROP POLICY IF EXISTS "stories_update_editor" ON public.stories;
CREATE POLICY "stories_update_editor"
    ON public.stories FOR UPDATE
    USING (public.is_editor())
    WITH CHECK (public.is_editor());

DROP POLICY IF EXISTS "stories_delete_admin" ON public.stories;
CREATE POLICY "stories_delete_admin"
    ON public.stories FOR DELETE
    USING (public.is_admin());

-- Episodes Policies
DROP POLICY IF EXISTS "episodes_select_public" ON public.episodes;
CREATE POLICY "episodes_select_public"
    ON public.episodes FOR SELECT
    USING (
        (status = 'published' AND EXISTS (
            SELECT 1 FROM public.stories s
            WHERE s.id = story_id AND s.status = 'published'
        ))
        OR public.is_editor()
    );

DROP POLICY IF EXISTS "episodes_insert_editor" ON public.episodes;
CREATE POLICY "episodes_insert_editor"
    ON public.episodes FOR INSERT
    WITH CHECK (public.is_editor());

DROP POLICY IF EXISTS "episodes_update_editor" ON public.episodes;
CREATE POLICY "episodes_update_editor"
    ON public.episodes FOR UPDATE
    USING (public.is_editor())
    WITH CHECK (public.is_editor());

DROP POLICY IF EXISTS "episodes_delete_admin" ON public.episodes;
CREATE POLICY "episodes_delete_admin"
    ON public.episodes FOR DELETE
    USING (public.is_admin());

-- Favorites Policies
DROP POLICY IF EXISTS "favorites_select_own" ON public.favorites;
CREATE POLICY "favorites_select_own"
    ON public.favorites FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_insert_own" ON public.favorites;
CREATE POLICY "favorites_insert_own"
    ON public.favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_delete_own" ON public.favorites;
CREATE POLICY "favorites_delete_own"
    ON public.favorites FOR DELETE
    USING (auth.uid() = user_id);

-- Listening Progress Policies
DROP POLICY IF EXISTS "listening_progress_select_own" ON public.listening_progress;
CREATE POLICY "listening_progress_select_own"
    ON public.listening_progress FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "listening_progress_insert_own" ON public.listening_progress;
CREATE POLICY "listening_progress_insert_own"
    ON public.listening_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "listening_progress_update_own" ON public.listening_progress;
CREATE POLICY "listening_progress_update_own"
    ON public.listening_progress FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "listening_progress_delete_own" ON public.listening_progress;
CREATE POLICY "listening_progress_delete_own"
    ON public.listening_progress FOR DELETE
    USING (auth.uid() = user_id);

-- Listening Events Policies
DROP POLICY IF EXISTS "listening_events_select" ON public.listening_events;
CREATE POLICY "listening_events_select"
    ON public.listening_events FOR SELECT
    USING (public.is_admin() OR auth.uid() = user_id);

DROP POLICY IF EXISTS "listening_events_insert" ON public.listening_events;
CREATE POLICY "listening_events_insert"
    ON public.listening_events FOR INSERT
    WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- Admin Audit Logs Policies
DROP POLICY IF EXISTS "audit_logs_select_admin" ON public.admin_audit_logs;
CREATE POLICY "audit_logs_select_admin"
    ON public.admin_audit_logs FOR SELECT
    USING (public.is_admin());

DROP POLICY IF EXISTS "audit_logs_insert_admin" ON public.admin_audit_logs;
CREATE POLICY "audit_logs_insert_admin"
    ON public.admin_audit_logs FOR INSERT
    WITH CHECK (public.is_editor() AND actor_user_id = auth.uid());

-- Notifications Policies
DROP POLICY IF EXISTS "notifications_select_user" ON public.notifications;
CREATE POLICY "notifications_select_user"
    ON public.notifications FOR SELECT
    USING (user_id = auth.uid() OR user_id IS NULL OR public.is_admin());

DROP POLICY IF EXISTS "notifications_update_user" ON public.notifications;
CREATE POLICY "notifications_update_user"
    ON public.notifications FOR UPDATE
    USING (user_id = auth.uid() OR public.is_admin())
    WITH CHECK (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "notifications_insert_admin" ON public.notifications;
CREATE POLICY "notifications_insert_admin"
    ON public.notifications FOR INSERT
    WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "notifications_delete_admin" ON public.notifications;
CREATE POLICY "notifications_delete_admin"
    ON public.notifications FOR DELETE
    USING (public.is_admin());


-- ==============================================================================
-- PART 3: STORAGE BUCKETS & STORAGE POLICIES
-- ==============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('story-covers', 'story-covers', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('podcast-audio', 'podcast-audio', true, 104857600, ARRAY['audio/mpeg', 'audio/mp3', 'audio/m4a', 'audio/aac']),
    ('user-avatars', 'user-avatars', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage Policies
DROP POLICY IF EXISTS "story_covers_public_read" ON storage.objects;
CREATE POLICY "story_covers_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'story-covers');

DROP POLICY IF EXISTS "story_covers_editor_insert" ON storage.objects;
CREATE POLICY "story_covers_editor_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'story-covers' AND public.is_editor());

DROP POLICY IF EXISTS "story_covers_editor_update" ON storage.objects;
CREATE POLICY "story_covers_editor_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'story-covers' AND public.is_editor())
    WITH CHECK (bucket_id = 'story-covers' AND public.is_editor());

DROP POLICY IF EXISTS "story_covers_admin_delete" ON storage.objects;
CREATE POLICY "story_covers_admin_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'story-covers' AND public.is_admin());

DROP POLICY IF EXISTS "podcast_audio_public_read" ON storage.objects;
CREATE POLICY "podcast_audio_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'podcast-audio');

DROP POLICY IF EXISTS "podcast_audio_editor_insert" ON storage.objects;
CREATE POLICY "podcast_audio_editor_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'podcast-audio' AND public.is_editor());

DROP POLICY IF EXISTS "podcast_audio_editor_update" ON storage.objects;
CREATE POLICY "podcast_audio_editor_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'podcast-audio' AND public.is_editor())
    WITH CHECK (bucket_id = 'podcast-audio' AND public.is_editor());

DROP POLICY IF EXISTS "podcast_audio_admin_delete" ON storage.objects;
CREATE POLICY "podcast_audio_admin_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'podcast-audio' AND public.is_admin());

DROP POLICY IF EXISTS "user_avatars_public_read" ON storage.objects;
CREATE POLICY "user_avatars_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'user-avatars');

DROP POLICY IF EXISTS "user_avatars_user_insert" ON storage.objects;
CREATE POLICY "user_avatars_user_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'user-avatars' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "user_avatars_user_update" ON storage.objects;
CREATE POLICY "user_avatars_user_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'user-avatars' AND auth.uid() = owner)
    WITH CHECK (bucket_id = 'user-avatars' AND auth.uid() = owner);

DROP POLICY IF EXISTS "user_avatars_user_delete" ON storage.objects;
CREATE POLICY "user_avatars_user_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'user-avatars' AND auth.uid() = owner);


-- ==============================================================================
-- PART 4: SEED DATA (CATEGORIES, STORIES, EPISODES)
-- ==============================================================================

-- Categories
INSERT INTO public.categories (id, name, slug, description, icon_name, sort_order, is_active)
VALUES
    ('c1111111-1111-1111-1111-111111111111', 'រឿងខ្មោចព្រាយបិសាច', 'khmer-ghosts', 'ការជួបប្រទះវិញ្ញាណ និងរឿងខ្មោចពិតៗពីទូទាំងប្រទេសកម្ពុជា', 'ghost', 1, true),
    ('c2222222-2222-2222-2222-222222222222', 'រឿងព្រេងបុរាណខ្មែរ', 'ancient-folklore', 'រឿងព្រេងនិទានបុរាណ និងជំនឿអបិយជំនឿដូនតា', 'book-open', 2, true),
    ('c3333333-3333-3333-3333-333333333333', 'អាថ៌កំបាំងព្រៃជ្រៅ', 'deep-forest-mysteries', 'រឿងរ៉ាវព្រឺព្រួចក្នុងព្រៃស្រោង ភ្នំគូលែន និងជួរភ្នំក្រវាញ', 'trees', 3, true),
    ('c4444444-4444-4444-4444-444444444444', 'រឿងស៊ើបអង្កេតព្រឺព្រួច', 'investigation-suspense', 'ការស៊ើបអង្កេតករណីចម្លែក និងអាថ៌កំបាំងដែលមិនទាន់មានចម្លើយ', 'search', 4, true),
    ('c5555555-5555-5555-5555-555555555555', 'រឿងមុនចូលគេង', 'bedtime-tales', 'សំឡេងរណ្តំនិទានរឿងស្ងប់ស្ងាត់ សម្រាប់ស្តាប់បន្ធូរអារម្មណ៍ពេលរាត្រី', 'moon', 5, true)
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order;

-- Stories
INSERT INTO public.stories (id, title, slug, description, cover_path, category_id, narrator_name, status, is_featured, published_at)
VALUES
    (
        'a1111111-1111-1111-1111-111111111111',
        'វិញ្ញាណវិលវល់នៅផ្ទះបុរាណខេត្តបាត់ដំបង',
        'ghost-of-battambang-ancient-house',
        'រឿងរ៉ាវពិតកើតឡើងនៅភូមិវឌ្ឍនាមួយក្នុងខេត្តបាត់ដំបង ជាកន្លែងដែលផ្ទះបុរាណសង់តាំងពីសម័យមុន មានសំឡេងជើងដើរលើក្តារ និងស្រមោលសក្បុសកាត់បង្អួចរាល់យប់ថ្ងៃសីល។',
        'story-covers/battambang_ancient_house.jpg',
        'c1111111-1111-1111-1111-111111111111',
        'លោក សុខ រ៉ាវី',
        'published',
        true,
        NOW() - INTERVAL '10 days'
    ),
    (
        'a2222222-2222-2222-2222-222222222222',
        'អាថ៌កំបាំងព្រៃភ្នំគូលែន និងព្រានព្រៃបាត់ខ្លួន',
        'mystery-of-phnom-kulen-forest',
        'ដំណើរផ្សងព្រេងរបស់ក្រុមព្រានព្រៃ ៣នាក់ ដែលបានចូលទៅក្នុងតំបន់ហាមឃាត់នៃភ្នំគូលែន ហើយជួបប្រទះនឹងបាតុភូតចម្លែកដែលធ្វើឱ្យពេលវេលាហាក់ដូចជាឈប់ដើរ។',
        'story-covers/phnom_kulen_mystery.jpg',
        'c3333333-3333-3333-3333-333333333333',
        'អ្នកស្រី ចាន់ណា',
        'published',
        true,
        NOW() - INTERVAL '8 days'
    ),
    (
        'a3333333-3333-3333-3333-333333333333',
        'សំឡេងយំរណ្តំពីបាតអណ្តូងបុរាណ',
        'echo-crying-from-ancient-well',
        'អណ្តូងទឹកចាស់មួយនៅកណ្តាលភូមិដែលគេបិទជិតរាប់សិបឆ្នាំ ស្រាប់តែមានសំឡេងទឹកបោកបក់ និងសំឡេងហៅឈ្មោះអ្នកភូមិនៅរៀងរាល់ម៉ោង ៣ទៀបភ្លឺ។',
        'story-covers/ancient_well_crying.jpg',
        'c4444444-4444-4444-4444-444444444444',
        'លោក រតនា វិបុល',
        'published',
        false,
        NOW() - INTERVAL '5 days'
    ),
    (
        'a4444444-4444-4444-4444-444444444444',
        'ព្រាយកន្ទោងបាយនៅវាលស្រែស្ងាត់',
        'phantom-of-the-rice-fields',
        'រឿងនិទានប្រជាប្រិយអំពីជំនឿលើព្រាយកន្ទោងបាយ ដែលតែងតែបង្ហាញខ្លួននៅពេលយប់ខែភ្លឺតាមភ្លឺស្រែ ស្វែងរកអាហារ និងនាំឱ្យអ្នកដំណើរវង្វេងផ្លូវ។',
        'story-covers/rice_field_phantom.jpg',
        'c2222222-2222-2222-2222-222222222222',
        'លោកតា មាស ផល្លា',
        'published',
        false,
        NOW() - INTERVAL '3 days'
    ),
    (
        'a5555555-5555-5555-5555-555555555555',
        'រឿងរាត្រីស្ងប់ស្ងាត់៖ ព្រលឹងអ្នកចាំព្រៃក្រវាញ',
        'guardian-spirit-of-cardamom',
        'សាច់រឿងមុនចូលគេងបែបស្ងប់ស្ងាត់ រៀបរាប់ពីទឹកដីព្រៃស្រោងជួរភ្នំក្រវាញ សំឡេងសត្វរាត្រី និងការគោរពដូនតាម្ចាស់ទឹកម្ចាស់ដី។',
        'story-covers/cardamom_guardian.jpg',
        'c5555555-5555-5555-5555-555555555555',
        'កញ្ញា សុជាតា',
        'published',
        false,
        NOW() - INTERVAL '1 day'
    )
ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    cover_path = EXCLUDED.cover_path,
    category_id = EXCLUDED.category_id,
    narrator_name = EXCLUDED.narrator_name,
    status = EXCLUDED.status,
    is_featured = EXCLUDED.is_featured;

-- Episodes
INSERT INTO public.episodes (id, story_id, title, description, episode_number, audio_path, audio_mime_type, audio_size_bytes, duration_seconds, status, allow_download, published_at)
VALUES
    -- Story 1
    (
        'e1011111-1111-1111-1111-111111111111',
        'a1111111-1111-1111-1111-111111111111',
        'ភាគ ១៖ ទ្វារឈើដែលបើកដោយខ្លួនឯង',
        'រាត្រីដំបូងនៃការផ្លាស់ចូលស្នាក់នៅក្នុងផ្ទះឈើចំណាស់ និងសញ្ញាព្រមានដំបូងពីម្ចាស់ដើម។',
        1,
        'podcast-audio/battambang_ep1.mp3',
        'audio/mpeg',
        15728640,
        1420,
        'published',
        true,
        NOW() - INTERVAL '10 days'
    ),
    (
        'e1021111-1111-1111-1111-111111111111',
        'a1111111-1111-1111-1111-111111111111',
        'ភាគ ២៖ ស្រមោលក្រោមកាំជណ្តើរ',
        'ការរកឃើញប្រអប់ដែកបុរាណបង្កប់ក្រោមក្តារបន្ទះ និងវិញ្ញាណស្រីក្រមុំដែលបង្ហាញខ្លួន។',
        2,
        'podcast-audio/battambang_ep2.mp3',
        'audio/mpeg',
        17825792,
        1580,
        'published',
        true,
        NOW() - INTERVAL '9 days'
    ),
    (
        'e1031111-1111-1111-1111-111111111111',
        'a1111111-1111-1111-1111-111111111111',
        'ភាគ ៣៖ ពិធីរំដោះវិញ្ញាណ និងពាក្យសច្ចា',
        'ការនិមន្តព្រះសង្ឃសូត្រមន្តរំដោះកម្ម និងអាថ៌កំបាំងចុងក្រោយនៃគ្រួសារម្ចាស់ផ្ទះ។',
        3,
        'podcast-audio/battambang_ep3.mp3',
        'audio/mpeg',
        20971520,
        1890,
        'published',
        true,
        NOW() - INTERVAL '8 days'
    ),

    -- Story 2
    (
        'e2012222-2222-2222-2222-222222222222',
        'a2222222-2222-2222-2222-222222222222',
        'ភាគ ១៖ សំឡេងគោះឫស្សីកណ្តាលព្រៃ',
        'ដំណើរចូលព្រៃជ្រៅហួសព្រំដែនកំណត់ និងការបន្លឺសំឡេងចម្លែកឆ្លើយឆ្លងជាមួយព្រានព្រៃ។',
        1,
        'podcast-audio/kulen_ep1.mp3',
        'audio/mpeg',
        14680064,
        1320,
        'published',
        true,
        NOW() - INTERVAL '8 days'
    ),
    (
        'e2022222-2222-2222-2222-222222222222',
        'a2222222-2222-2222-2222-222222222222',
        'ភាគ ២៖ ភូមិបិសាចដែលបាត់បង់ក្នុងអ័ព្ទ',
        'ការប្រទះឃើញទីតាំងសំណង់ថ្មបុរាណដែលមិនមាននៅលើផែនទី និងបុរសចំណាស់ចំឡែក។',
        2,
        'podcast-audio/kulen_ep2.mp3',
        'audio/mpeg',
        18874368,
        1650,
        'published',
        true,
        NOW() - INTERVAL '7 days'
    ),

    -- Story 3
    (
        'e3013333-3333-3333-3333-333333333333',
        'a3333333-3333-3333-3333-333333333333',
        'ភាគ ១៖ ខ្យល់គួចនៅមាត់អណ្តូង',
        'ហេតុការណ៍ប្លែកៗនៅពេលយប់ និងការបាត់បង់សត្វចិញ្ចឹមជុំវិញបរិវេណអណ្តូងបុរាណ។',
        1,
        'podcast-audio/well_ep1.mp3',
        'audio/mpeg',
        12582912,
        1150,
        'published',
        true,
        NOW() - INTERVAL '5 days'
    ),

    -- Story 4
    (
        'e4014444-4444-4444-4444-444444444444',
        'a4444444-4444-4444-4444-444444444444',
        'ភាគ ១៖ ពន្លឺភ្លើងព្រលាតតាមបឹងកក់',
        'ពន្លឺពណ៌បៃតងរេរាំលើផ្ទៃទឹក និងការណែនាំពីចាស់ទុំក្នុងការការពារខ្លួនពេលដើរកាត់វាលស្រែយប់។',
        1,
        'podcast-audio/ricefield_ep1.mp3',
        'audio/mpeg',
        13631488,
        1240,
        'published',
        true,
        NOW() - INTERVAL '3 days'
    ),

    -- Story 5
    (
        'e5015555-5555-5555-5555-555555555555',
        'a5555555-5555-5555-5555-555555555555',
        'ភាគ ១៖ រាត្រីក្រោមម្លប់ដើមជ្រៃធំ',
        'សំឡេងភ្លេងធម្មជាតិ រួមផ្សំនឹងការនិទានអំពីសច្ចធម៌ និងភាពស្ងប់រម្ងាប់នៃព្រៃព្រឹក្សា។',
        1,
        'podcast-audio/bedtime_ep1.mp3',
        'audio/mpeg',
        22020096,
        2100,
        'published',
        true,
        NOW() - INTERVAL '1 day'
    )
ON CONFLICT (story_id, episode_number) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    audio_path = EXCLUDED.audio_path,
    duration_seconds = EXCLUDED.duration_seconds,
    status = EXCLUDED.status,
    allow_download = EXCLUDED.allow_download;

COMMIT;
