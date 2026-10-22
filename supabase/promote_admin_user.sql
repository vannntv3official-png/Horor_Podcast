-- ==============================================================================
-- Khmer Horror Podcast - Make User Admin Script
-- Run this in your Supabase Dashboard -> SQL Editor
-- ==============================================================================

DO $$
DECLARE
    target_user_id UUID;
    target_email TEXT := 'YOUR_EMAIL_HERE'; -- << ប្តូរទៅជាអ៊ីមែលដែលអ្នកបានចុះឈ្មោះ
BEGIN
    -- ស្វែងរក User ID តាមរយៈអ៊ីមែល
    SELECT id INTO target_user_id FROM auth.users WHERE email = target_email;

    IF target_user_id IS NOT NULL THEN
        -- កំណត់សិទ្ធិជា admin ក្នុង public.user_roles
        INSERT INTO public.user_roles (user_id, role)
        VALUES (target_user_id, 'admin')
        ON CONFLICT (user_id, role) DO NOTHING;

        -- ធានាថាមាន record នៅក្នុង public.profiles
        INSERT INTO public.profiles (id, display_name, preferred_language)
        VALUES (target_user_id, split_part(target_email, '@', 1), 'km')
        ON CONFLICT (id) DO NOTHING;

        RAISE NOTICE 'ជោគជ័យ! គណនី % ទទួលបានសិទ្ធិជា ADMIN រួចរាល់ហើយ។', target_email;
    ELSE
        RAISE EXCEPTION 'រកមិនឃើញគណនីអ៊ីមែល % នៅក្នុង auth.users ទេ។ សូមចុះឈ្មោះគណនីនេះជាមុនសិន។', target_email;
    END IF;
END $$;
