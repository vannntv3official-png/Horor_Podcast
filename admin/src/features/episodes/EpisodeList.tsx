import React, { useEffect, useState, useRef } from 'react';
import { supabase, BUCKETS, getPublicStorageUrl } from '../../lib/supabase';
import { formatBytes, formatDuration, formatDate } from '../../lib/utils';
import type { Episode, Story } from '../../types';
import { EpisodeFormModal } from './EpisodeFormModal';
import {
  Plus,
  Search,
  Play,
  Pause,
  Edit2,
  Trash2,
  Headphones,
  Loader2,
  Download,
} from 'lucide-react';

export const EpisodeList: React.FC = () => {
  const [episodes, setEpisodes] = useState<Episode[]>([]);
  const [stories, setStories] = useState<Story[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedStoryId, setSelectedStoryId] = useState<string>('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [episodeToEdit, setEpisodeToEdit] = useState<Episode | null>(null);

  // Audio Playback
  const [playingEpisodeId, setPlayingEpisodeId] = useState<string | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    supabase
      .from('stories')
      .select('id, title')
      .order('title', { ascending: true })
      .then(({ data }) => setStories((data as Story[]) || []));
  }, []);

  const fetchEpisodes = async () => {
    setLoading(true);
    try {
      let query = supabase
        .from('episodes')
        .select('*, stories(title, cover_path)')
        .order('created_at', { ascending: false });

      if (selectedStoryId !== 'all') {
        query = query.eq('story_id', selectedStoryId);
      }

      if (search.trim()) {
        query = query.ilike('title', `%${search.trim()}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      setEpisodes((data as Episode[]) || []);
    } catch (err) {
      console.error('Failed to load episodes:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEpisodes();
  }, [selectedStoryId, search]);

  const togglePlayAudio = (ep: Episode) => {
    if (playingEpisodeId === ep.id) {
      audioRef.current?.pause();
      setPlayingEpisodeId(null);
    } else {
      if (audioRef.current) {
        audioRef.current.src = getPublicStorageUrl(BUCKETS.PODCAST_AUDIO, ep.audio_path);
        audioRef.current.play();
        setPlayingEpisodeId(ep.id);
      }
    }
  };

  const handleDelete = async (ep: Episode) => {
    if (!window.confirm(`តើអ្នកពិតជាចង់លុបភាគ "${ep.title}" មែនទេ?`)) return;

    try {
      const { error } = await supabase.from('episodes').delete().eq('id', ep.id);
      if (error) throw error;
      fetchEpisodes();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to delete episode');
    }
  };

  return (
    <div className="space-y-6">
      <audio
        ref={audioRef}
        onEnded={() => setPlayingEpisodeId(null)}
        onError={() => setPlayingEpisodeId(null)}
      />

      {/* Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 flex-1 max-w-2xl">
          <div className="relative flex-1">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
            <input
              type="text"
              placeholder="ស្វែងរកតាមចំណងជើងភាគ..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
            />
          </div>

          <select
            value={selectedStoryId}
            onChange={(e) => setSelectedStoryId(e.target.value)}
            className="px-3 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F] max-w-xs truncate"
          >
            <option value="all">រឿងទាំងអស់ (All Stories)</option>
            {stories.map((s) => (
              <option key={s.id} value={s.id}>
                {s.title}
              </option>
            ))}
          </select>
        </div>

        <button
          onClick={() => {
            setEpisodeToEdit(null);
            setIsModalOpen(true);
          }}
          className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold shadow-md transition-all cursor-pointer w-full sm:w-auto flex-shrink-0"
        >
          <Plus className="w-4 h-4 text-[#C89B3C]" />
          <span>បង្ហោះភាគថ្មី (Upload Episode)</span>
        </button>
      </div>

      {/* Episodes Table */}
      <div className="glass-panel rounded-3xl border border-[#E2DCEB] overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-[#C89B3C]" />
          </div>
        ) : episodes.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <Headphones className="w-12 h-12 text-[#8A7B9B] mb-3" />
            <p className="font-semibold text-sm text-[#1D102F]">មិនមានភាគត្រូវបានរកឃើញទេ</p>
            <p className="text-xs text-[#635C6E] mt-1">ចុចប៊ូតុង "បង្ហោះភាគថ្មី" ដើម្បីបញ្ចូលឯកសារ MP3។</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[700px]">
              <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
                <tr>
                  <th className="py-3.5 px-4 w-12">ស្តាប់</th>
                  <th className="py-3.5 px-4">វគ្គទី</th>
                  <th className="py-3.5 px-4">ចំណងជើងភាគ</th>
                  <th className="py-3.5 px-4">ចំណងជើងរឿង</th>
                  <th className="py-3.5 px-4">រយៈពេល</th>
                  <th className="py-3.5 px-4">ទំហំ</th>
                  <th className="py-3.5 px-4">ស្ថានភាព</th>
                  <th className="py-3.5 px-4">កាលបរិច្ឆេទ</th>
                  <th className="py-3.5 px-4 text-right">សកម្មភាព</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DCEB]/60">
                {episodes.map((ep) => {
                  const isPlaying = playingEpisodeId === ep.id;
                  return (
                    <tr key={ep.id} className="hover:bg-white/40 transition-colors">
                      <td className="py-3 px-4">
                        <button
                          onClick={() => togglePlayAudio(ep)}
                          className={`w-8 h-8 rounded-full flex items-center justify-center cursor-pointer transition-all ${
                            isPlaying
                              ? 'bg-[#1D102F] text-[#C89B3C]'
                              : 'bg-[#EDE8F5] text-[#1D102F] hover:bg-[#1D102F] hover:text-white'
                          }`}
                        >
                          {isPlaying ? <Pause className="w-3.5 h-3.5" /> : <Play className="w-3.5 h-3.5" />}
                        </button>
                      </td>
                      <td className="py-3 px-4 font-bold text-[#1D102F]">
                        #{ep.episode_number}
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-bold text-sm text-[#1D102F]">{ep.title}</div>
                        {ep.allow_download && (
                          <span className="inline-flex items-center gap-1 text-[10px] text-emerald-700 font-medium mt-0.5">
                            <Download className="w-3 h-3" /> Offline Enabled
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 font-medium text-[#1D102F]">
                        {ep.stories?.title || '-'}
                      </td>
                      <td className="py-3 px-4 text-[#635C6E]">
                        {formatDuration(ep.duration_seconds)}
                      </td>
                      <td className="py-3 px-4 text-[#635C6E]">
                        {formatBytes(ep.audio_size_bytes)}
                      </td>
                      <td className="py-3 px-4">
                        <span
                          className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                            ep.status === 'published'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-amber-100 text-amber-800'
                          }`}
                        >
                          {ep.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-[#635C6E]">
                        {formatDate(ep.created_at)}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            onClick={() => {
                              setEpisodeToEdit(ep);
                              setIsModalOpen(true);
                            }}
                            className="p-1.5 rounded-lg text-[#1D102F] hover:bg-white cursor-pointer"
                            title="កែប្រែ"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(ep)}
                            className="p-1.5 rounded-lg text-red-600 hover:bg-red-50 cursor-pointer"
                            title="លុប"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Episode Form Modal */}
      <EpisodeFormModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        episodeToEdit={episodeToEdit}
        defaultStoryId={selectedStoryId !== 'all' ? selectedStoryId : undefined}
        onSaved={fetchEpisodes}
      />
    </div>
  );
};
