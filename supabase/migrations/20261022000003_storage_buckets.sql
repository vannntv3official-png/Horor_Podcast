-- ==============================================================================
-- Khmer Horror Podcast - Storage Buckets & Policies Migration
-- Migration: 20261022000003_storage_buckets.sql
-- Description: Creates storage buckets and sets least-privilege security policies
-- ==============================================================================

-- 1. Create Buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('story-covers', 'story-covers', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('podcast-audio', 'podcast-audio', true, 52428800, ARRAY['audio/mpeg', 'audio/mp3', 'audio/m4a', 'audio/aac']),
    ('user-avatars', 'user-avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Storage Object RLS Policies

-- Story Covers Policies
CREATE POLICY "story_covers_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'story-covers');

CREATE POLICY "story_covers_editor_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'story-covers' AND public.is_editor());

CREATE POLICY "story_covers_editor_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'story-covers' AND public.is_editor())
    WITH CHECK (bucket_id = 'story-covers' AND public.is_editor());

CREATE POLICY "story_covers_admin_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'story-covers' AND public.is_admin());

-- Podcast Audio Policies
CREATE POLICY "podcast_audio_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'podcast-audio');

CREATE POLICY "podcast_audio_editor_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'podcast-audio' AND public.is_editor());

CREATE POLICY "podcast_audio_editor_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'podcast-audio' AND public.is_editor())
    WITH CHECK (bucket_id = 'podcast-audio' AND public.is_editor());

CREATE POLICY "podcast_audio_admin_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'podcast-audio' AND public.is_admin());

-- User Avatars Policies
CREATE POLICY "user_avatars_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'user-avatars');

CREATE POLICY "user_avatars_user_insert"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'user-avatars' AND auth.uid() IS NOT NULL);

CREATE POLICY "user_avatars_user_update"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'user-avatars' AND auth.uid() = owner)
    WITH CHECK (bucket_id = 'user-avatars' AND auth.uid() = owner);

CREATE POLICY "user_avatars_user_delete"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'user-avatars' AND auth.uid() = owner);
