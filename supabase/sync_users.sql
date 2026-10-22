-- ==============================================================================
-- Khmer Horror Podcast - Complete User Synchronization & Trigger Fix
-- Run this ONCE in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

BEGIN;

-- 1. Sync all existing users from auth.users into public.profiles
INSERT INTO public.profiles (id, display_name, preferred_language, created_at, updated_at)
SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1)), 
    'km',
    created_at,
    NOW()
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
    display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name);

-- 2. Ensure every user has a role in public.user_roles (default to 'user' if none)
INSERT INTO public.user_roles (user_id, role, created_at)
SELECT id, 'user', created_at
FROM auth.users
ON CONFLICT (user_id, role) DO NOTHING;

-- 3. Update the trigger function to automatically create profile & role on EVERY new sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, preferred_language)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        'km'
    )
    ON CONFLICT (id) DO UPDATE SET
        display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name);

    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'user')
    ON CONFLICT (user_id, role) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Re-bind the trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 5. Foreign Key relation helper so PostgREST recognizes the link
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_profiles'
    ) THEN
        ALTER TABLE public.user_roles
        ADD CONSTRAINT fk_user_roles_profiles
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;

COMMIT;
