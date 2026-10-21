import React, { useEffect, useState } from 'react';
import { supabase, BUCKETS, getPublicStorageUrl } from '../../lib/supabase';
import { formatDate } from '../../lib/utils';
import type { Story } from '../../types';
import { StoryFormModal } from './StoryFormModal';
import {
  Plus,
  Search,
  Edit2,
  Trash2,
  Star,
  Loader2,
  BookOpen,
} from 'lucide-react';

export const StoryList: React.FC = () => {
  const [stories, setStories] = useState<Story[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [storyToEdit, setStoryToEdit] = useState<Story | null>(null);

  const fetchStories = async () => {
    setLoading(true);
    try {
      let query = supabase
        .from('stories')
        .select('*, categories(name, slug)')
        .order('created_at', { ascending: false });

      if (statusFilter !== 'all') {
        query = query.eq('status', statusFilter);
      }

      if (search.trim()) {
        const q = search.trim();
        query = query.or(`title.ilike.%${q}%,narrator_name.ilike.%${q}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      setStories((data as Story[]) || []);
    } catch (err) {
      console.error('Failed to fetch stories:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStories();
  }, [statusFilter, search]);

  const handleDelete = async (story: Story) => {
    if (!window.confirm(`តើអ្នកពិតជាចង់លុបរឿង "${story.title}" មែនទេ? រាល់ភាគទាំងអស់នឹងត្រូវលុបផងដែរ។`)) {
      return;
    }

    try {
      const { error } = await supabase.from('stories').delete().eq('id', story.id);
      if (error) throw error;
      fetchStories();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to delete story');
    }
  };

  const handleTogglePublish = async (story: Story) => {
    const nextStatus = story.status === 'published' ? 'draft' : 'published';
    try {
      const { error } = await supabase
        .from('stories')
        .update({
          status: nextStatus,
          published_at: nextStatus === 'published' ? new Date().toISOString() : null,
        })
        .eq('id', story.id);

      if (error) throw error;
      fetchStories();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to update status');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 flex-1 max-w-2xl">
          <div className="relative flex-1">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
            <input
              type="text"
              placeholder="ស្វែងរកតាមចំណងជើង ឬអ្នកនិទាន..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
          >
            <option value="all">ស្ថានភាពទាំងអស់ (All)</option>
            <option value="published">ផ្សព្វផ្សាយ (Published)</option>
            <option value="draft">ព្រាងទុក (Draft)</option>
            <option value="archived">ទុកក្នុងបណ្ណសារ (Archived)</option>
          </select>
        </div>

        <button
          onClick={() => {
            setStoryToEdit(null);
            setIsModalOpen(true);
          }}
          className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold shadow-md transition-all cursor-pointer w-full sm:w-auto flex-shrink-0"
        >
          <Plus className="w-4 h-4 text-[#C89B3C]" />
          <span>បង្កើតរឿងថ្មី (Create Story)</span>
        </button>
      </div>

      {/* Stories Table */}
      <div className="glass-panel rounded-3xl border border-[#E2DCEB] overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-[#C89B3C]" />
          </div>
        ) : stories.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <BookOpen className="w-12 h-12 text-[#8A7B9B] mb-3" />
            <p className="font-semibold text-sm text-[#1D102F]">មិនមានរឿងត្រូវបានរកឃើញទេ</p>
            <p className="text-xs text-[#635C6E] mt-1">ចុចប៊ូតុង "បង្កើតរឿងថ្មី" ដើម្បីបន្ថែមរឿងដំបូងរបស់អ្នក។</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[700px]">
              <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
                <tr>
                  <th className="py-3.5 px-4">គម្របរឿង</th>
                  <th className="py-3.5 px-4">ចំណងជើងរឿង</th>
                  <th className="py-3.5 px-4">ប្រភេទ</th>
                  <th className="py-3.5 px-4">អ្នកនិទាន</th>
                  <th className="py-3.5 px-4">ស្ថានភាព</th>
                  <th className="py-3.5 px-4">កាលបរិច្ឆេទ</th>
                  <th className="py-3.5 px-4 text-right">សកម្មភាព</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DCEB]/60">
                {stories.map((story) => (
                  <tr key={story.id} className="hover:bg-white/40 transition-colors">
                    <td className="py-3 px-4">
                      <div className="w-12 h-12 rounded-xl bg-[#EDE8F5] overflow-hidden border border-[#E2DCEB] flex-shrink-0">
                        {story.cover_path ? (
                          <img
                            src={getPublicStorageUrl(BUCKETS.STORY_COVERS, story.cover_path)}
                            alt=""
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-[#8A7B9B]">
                            <BookOpen className="w-5 h-5" />
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="font-bold text-sm text-[#1D102F] flex items-center gap-1.5">
                        <span>{story.title}</span>
                        {story.is_featured && <Star className="w-3.5 h-3.5 text-[#C89B3C] fill-current" />}
                      </div>
                      <span className="text-[11px] text-[#8A7B9B]">/{story.slug}</span>
                    </td>
                    <td className="py-3 px-4 text-[#1D102F] font-medium">
                      {story.categories?.name || '-'}
                    </td>
                    <td className="py-3 px-4 text-[#635C6E]">
                      {story.narrator_name || '-'}
                    </td>
                    <td className="py-3 px-4">
                      <button
                        onClick={() => handleTogglePublish(story)}
                        className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider cursor-pointer ${
                          story.status === 'published'
                            ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                            : story.status === 'draft'
                            ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                            : 'bg-gray-100 text-gray-800'
                        }`}
                      >
                        {story.status}
                      </button>
                    </td>
                    <td className="py-3 px-4 text-[#635C6E]">
                      {formatDate(story.created_at)}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => {
                            setStoryToEdit(story);
                            setIsModalOpen(true);
                          }}
                          className="p-1.5 rounded-lg text-[#1D102F] hover:bg-white cursor-pointer"
                          title="កែប្រែ"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(story)}
                          className="p-1.5 rounded-lg text-red-600 hover:bg-red-50 cursor-pointer"
                          title="លុប"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Story Form Modal */}
      <StoryFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        storyToEdit={storyToEdit}
        onSaved={fetchStories}
      />
    </div>
  );
};
