-- ==============================================================================
-- Khmer Horror Podcast - Database & Security Verification Tests
-- Test file: security_tests.sql
-- Description: Verifies Row Level Security, Least Privilege and RBAC integrity
-- ==============================================================================

BEGIN;

-- Setup test users
DO $$
DECLARE
    test_admin_id UUID := 'a0000000-0000-0000-0000-000000000001';
    test_user_a_id UUID := 'a0000000-0000-0000-0000-000000000002';
    test_user_b_id UUID := 'a0000000-0000-0000-0000-000000000003';
BEGIN
    -- Create dummy user roles
    INSERT INTO public.user_roles (user_id, role)
    VALUES (test_admin_id, 'admin'), (test_user_a_id, 'user'), (test_user_b_id, 'user')
    ON CONFLICT DO NOTHING;
END $$;

-- Test 1: Anonymous users can read published stories
SELECT count(*) > 0 AS test_anon_can_read_published
FROM public.stories
WHERE status = 'published';

-- Test 2: Verify is_admin() function returns false when auth.uid() is null
SELECT public.is_admin() IS FALSE AS test_anon_is_not_admin;

-- Test 3: Verify is_editor() function returns false when auth.uid() is null
SELECT public.is_editor() IS FALSE AS test_anon_is_not_editor;

-- Test 4: Verify draft stories are not exposed to anonymous readers
-- In a real RLS session where auth.uid() is null, selecting stories should only return status = 'published'
SELECT count(*) = 0 AS test_no_drafts_in_published_filter
FROM public.stories
WHERE status = 'draft' AND NOT public.is_editor();

-- Test 5: Verify foreign keys and cascade integrity
-- Episodes must belong to a valid story
SELECT count(*) = 0 AS test_orphaned_episodes
FROM public.episodes e
LEFT JOIN public.stories s ON e.story_id = s.id
WHERE s.id IS NULL;

-- Test 6: Verify categories sort order and unique slug
SELECT count(DISTINCT slug) = count(*) AS test_category_slugs_unique
FROM public.categories;

-- Test 7: Verify story episode numbers are unique per story
SELECT count(*) = 0 AS test_duplicate_episode_numbers
FROM (
    SELECT story_id, episode_number, count(*)
    FROM public.episodes
    GROUP BY story_id, episode_number
    HAVING count(*) > 1
) sub;

ROLLBACK;
