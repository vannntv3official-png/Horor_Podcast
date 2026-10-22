export type UserRole = 'admin' | 'editor' | 'user';

export interface UserProfile {
  id: string;
  display_name: string | null;
  avatar_path: string | null;
  preferred_language: string;
  notifications_enabled: boolean;
  role?: UserRole;
  is_vip?: boolean;
  vip_expires_at?: string | null;
  created_at: string;
  updated_at: string;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  icon_name: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export type StoryStatus = 'draft' | 'published' | 'archived';

export interface Story {
  id: string;
  title: string;
  slug: string;
  description: string | null;
  cover_path: string | null;
  category_id: string | null;
  narrator_name: string | null;
  status: StoryStatus;
  is_featured: boolean;
  published_at: string | null;
  created_by?: string | null;
  created_at: string;
  updated_at: string;
  categories?: { name: string; slug: string } | null;
  episode_count?: number;
}

export interface Episode {
  id: string;
  story_id: string;
  title: string;
  description: string | null;
  episode_number: number;
  audio_path: string;
  audio_mime_type: string | null;
  audio_size_bytes: number | null;
  duration_seconds: number | null;
  status: StoryStatus;
  allow_download: boolean;
  published_at: string | null;
  created_at: string;
  updated_at: string;
  stories?: { title: string; cover_path: string | null } | null;
}

export interface AuditLog {
  id: string;
  actor_user_id: string | null;
  action: string;
  entity_type: string;
  entity_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
  profiles?: { display_name: string | null } | null;
}

export interface PaymentTransaction {
  id: string;
  user_id: string;
  plan_id: 'vip_1_month' | 'vip_3_months' | 'vip_1_year' | string;
  amount_usd: number;
  amount_khr: number;
  payment_method: string;
  transaction_ref: string | null;
  status: 'pending' | 'approved' | 'rejected';
  sender_name?: string | null;
  sender_phone?: string | null;
  slip_image_url?: string | null;
  admin_notes?: string | null;
  created_at: string;
  updated_at: string;
  user_display_name?: string;
  user_avatar?: string | null;
}

export interface DashboardMetrics {
  totalStories: number;
  totalEpisodes: number;
  totalCategories: number;
  totalUsers: number;
  totalPlays: number;
  recentStories: Story[];
  recentEpisodes: Episode[];
}
