import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://demo-project.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'public-anon-key-placeholder';

export const isConfigured = Boolean(
  import.meta.env.VITE_SUPABASE_URL &&
    !import.meta.env.VITE_SUPABASE_URL.includes('demo-project') &&
    !import.meta.env.VITE_SUPABASE_URL.includes('your-project') &&
    import.meta.env.VITE_SUPABASE_ANON_KEY &&
    !import.meta.env.VITE_SUPABASE_ANON_KEY.includes('placeholder')
);

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});

export const BUCKETS = {
  STORY_COVERS: 'story-covers',
  PODCAST_AUDIO: 'podcast-audio',
  USER_AVATARS: 'user-avatars',
} as const;

export function getPublicStorageUrl(bucket: string, path: string): string {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  const cleanPath = path.startsWith(`${bucket}/`) ? path.replace(`${bucket}/`, '') : path;
  const { data } = supabase.storage.from(bucket).getPublicUrl(cleanPath);
  return data.publicUrl;
}
