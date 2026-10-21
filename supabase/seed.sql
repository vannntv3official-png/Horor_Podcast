-- ==============================================================================
-- Khmer Horror Podcast - Production Seed Data
-- Seed file: seed.sql
-- Description: Authentic Cambodian folklore, ghost stories, episodes & sample data
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- 1. Seed Categories
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 2. Seed Stories
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 3. Seed Episodes
-- -----------------------------------------------------------------------------
INSERT INTO public.episodes (id, story_id, title, description, episode_number, audio_path, audio_mime_type, audio_size_bytes, duration_seconds, status, allow_download, published_at)
VALUES
    -- Story 1: Battambang Ancient House
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

    -- Story 2: Phnom Kulen
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

    -- Story 3: Ancient Well
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

    -- Story 4: Phantom Rice Fields
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

    -- Story 5: Bedtime Forest Tales
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
