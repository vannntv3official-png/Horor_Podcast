import React, { useEffect, useState, useRef } from 'react';
import { supabase, BUCKETS, getPublicStorageUrl } from '../../lib/supabase';
import { formatBytes, formatDuration, formatDate } from '../../lib/utils';
import type { Episode, Story, StoryStatus } from '../../types';
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
  RotateCcw,
  RotateCw,
  X,
  Volume2,
  VolumeX,
} from 'lucide-react';

export const EpisodeList: React.FC = () => {
  const [episodes, setEpisodes] = useState<Episode[]>([]);
  const [stories, setStories] = useState<Story[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedStoryId, setSelectedStoryId] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [episodeToEdit, setEpisodeToEdit] = useState<Episode | null>(null);

  // Audio Playback Dock State
  const [activeEpisode, setActiveEpisode] = useState<Episode | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [isMuted, setIsMuted] = useState(false);
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

      if (statusFilter !== 'all') {
        query = query.eq('status', statusFilter);
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
  }, [selectedStoryId, statusFilter, search]);

  const handlePlayToggle = (ep: Episode) => {
    if (!audioRef.current) return;

    if (activeEpisode?.id === ep.id) {
      if (isPlaying) {
        audioRef.current.pause();
        setIsPlaying(false);
      } else {
        audioRef.current.play().then(() => setIsPlaying(true)).catch(console.error);
      }
    } else {
      setActiveEpisode(ep);
      const url = getPublicStorageUrl(BUCKETS.PODCAST_AUDIO, ep.audio_path);
      audioRef.current.src = url;
      audioRef.current.load();
      audioRef.current.play().then(() => setIsPlaying(true)).catch(console.error);
    }
  };

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const time = Number(e.target.value);
    setCurrentTime(time);
    if (audioRef.current) {
      audioRef.current.currentTime = time;
    }
  };

  const handleSkip = (seconds: number) => {
    if (!audioRef.current) return;
    const newTime = Math.max(0, Math.min(duration, audioRef.current.currentTime + seconds));
    audioRef.current.currentTime = newTime;
    setCurrentTime(newTime);
  };

  const handleToggleMute = () => {
    if (!audioRef.current) return;
    audioRef.current.muted = !isMuted;
    setIsMuted(!isMuted);
  };

  const handleStopPlayback = () => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.src = '';
    }
    setActiveEpisode(null);
    setIsPlaying(false);
    setCurrentTime(0);
    setDuration(0);
  };

  const handleDelete = async (ep: Episode) => {
    if (!window.confirm(`តើអ្នកពិតជាចង់លុបភាគ "${ep.title}" មែនទេ?`)) return;

    try {
      if (activeEpisode?.id === ep.id) {
        handleStopPlayback();
      }
      const { error } = await supabase.from('episodes').delete().eq('id', ep.id);
      if (error) throw error;
      fetchEpisodes();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to delete episode');
    }
  };

  const handleTogglePublish = async (ep: Episode) => {
    const nextStatus: StoryStatus = ep.status === 'published' ? 'draft' : 'published';
    try {
      const { error } = await supabase
        .from('episodes')
        .update({
          status: nextStatus,
          published_at: nextStatus === 'published' ? new Date().toISOString() : null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', ep.id);

      if (error) throw error;
      fetchEpisodes();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to toggle status');
    }
  };

  const totalFilteredSeconds = episodes.reduce((acc, ep) => acc + (ep.duration_seconds || 0), 0);
  const totalFilteredBytes = episodes.reduce((acc, ep) => acc + (ep.audio_size_bytes || 0), 0);

  return (
    <div className="space-y-6 pb-28">
      {/* Hidden Audio Element */}
      <audio
        ref={audioRef}
        onTimeUpdate={() => {
          if (audioRef.current) {
            setCurrentTime(audioRef.current.currentTime);
          }
        }}
        onLoadedMetadata={() => {
          if (audioRef.current) {
            setDuration(audioRef.current.duration || 0);
          }
        }}
        onEnded={() => {
          setIsPlaying(false);
          setCurrentTime(0);
        }}
        onError={() => {
          setIsPlaying(false);
        }}
      />

      {/* Controls & Filter Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 flex-1 max-w-3xl">
          {/* Search Box */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
            <input
              type="text"
              placeholder="ស្វែងរកតាមចំណងជើងភាគ..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
            />
          </div>

          {/* Story Filter */}
          <select
            value={selectedStoryId}
            onChange={(e) => setSelectedStoryId(e.target.value)}
            className="px-3 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F] truncate"
          >
            <option value="all">រឿងទាំងអស់ ({stories.length} រឿង)</option>
            {stories.map((s) => (
              <option key={s.id} value={s.id}>
                {s.title}
              </option>
            ))}
          </select>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
          >
            <option value="all">ស្ថានភាពទាំងអស់ (Status: All)</option>
            <option value="published">ផ្សព្វផ្សាយ (Published)</option>
            <option value="draft">ព្រាងទុក (Draft)</option>
            <option value="archived">ទុកក្នុងបណ្ណសារ (Archived)</option>
          </select>
        </div>

        <button
          onClick={() => {
            setEpisodeToEdit(null);
            setIsModalOpen(true);
          }}
          className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold shadow-md transition-all cursor-pointer w-full lg:w-auto flex-shrink-0"
        >
          <Plus className="w-4 h-4 text-[#C89B3C]" />
          <span>បង្ហោះភាគថ្មី (Upload Episode)</span>
        </button>
      </div>

      {/* Summary Chips */}
      <div className="flex items-center flex-wrap gap-2 text-xs text-[#635C6E]">
        <span className="px-3 py-1 rounded-full bg-white border border-[#E2DCEB] font-semibold text-[#1D102F]">
          សរុប: {episodes.length} ភាគ
        </span>
        <span className="px-3 py-1 rounded-full bg-white border border-[#E2DCEB]">
          រយៈពេលសរុប: {formatDuration(totalFilteredSeconds)}
        </span>
        <span className="px-3 py-1 rounded-full bg-white border border-[#E2DCEB]">
          ទំហំឯកសារសរុប: {formatBytes(totalFilteredBytes)}
        </span>
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
            <table className="w-full text-left text-xs min-w-[760px]">
              <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
                <tr>
                  <th className="py-3.5 px-4 w-12 text-center">ស្តាប់</th>
                  <th className="py-3.5 px-4 w-14">វគ្គទី</th>
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
                  const isCurrent = activeEpisode?.id === ep.id;
                  const isCurrentlyPlaying = isCurrent && isPlaying;

                  return (
                    <tr
                      key={ep.id}
                      className={`hover:bg-white/40 transition-colors ${
                        isCurrent ? 'bg-[#EDE8F5]/50' : ''
                      }`}
                    >
                      <td className="py-3 px-4 text-center">
                        <button
                          onClick={() => handlePlayToggle(ep)}
                          className={`w-8 h-8 rounded-full inline-flex items-center justify-center cursor-pointer transition-all ${
                            isCurrentlyPlaying
                              ? 'bg-[#1D102F] text-[#C89B3C] shadow-md ring-2 ring-[#C89B3C]'
                              : isCurrent
                              ? 'bg-[#1D102F] text-white'
                              : 'bg-[#EDE8F5] text-[#1D102F] hover:bg-[#1D102F] hover:text-white'
                          }`}
                          title={isCurrentlyPlaying ? 'ផ្អាកការចាក់' : 'ចាក់ស្តាប់'}
                        >
                          {isCurrentlyPlaying ? (
                            <Pause className="w-3.5 h-3.5" />
                          ) : (
                            <Play className="w-3.5 h-3.5 ml-0.5" />
                          )}
                        </button>
                      </td>
                      <td className="py-3 px-4 font-bold text-[#1D102F]">
                        #{ep.episode_number}
                      </td>
                      <td className="py-3 px-4">
                        <div className="font-bold text-sm text-[#1D102F] flex items-center gap-1.5">
                          <span>{ep.title}</span>
                          {isCurrent && (
                            <span className="w-2 h-2 rounded-full bg-[#C89B3C] animate-pulse" />
                          )}
                        </div>
                        {ep.allow_download && (
                          <span className="inline-flex items-center gap-1 text-[10px] text-emerald-700 font-medium mt-0.5">
                            <Download className="w-3 h-3" /> Offline Enabled
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 font-medium text-[#1D102F]">
                        {ep.stories?.title || '-'}
                      </td>
                      <td className="py-3 px-4 text-[#635C6E] font-mono">
                        {formatDuration(ep.duration_seconds)}
                      </td>
                      <td className="py-3 px-4 text-[#635C6E]">
                        {formatBytes(ep.audio_size_bytes)}
                      </td>
                      <td className="py-3 px-4">
                        <button
                          onClick={() => handleTogglePublish(ep)}
                          className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider cursor-pointer transition-all ${
                            ep.status === 'published'
                              ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-200'
                              : ep.status === 'draft'
                              ? 'bg-amber-100 text-amber-800 hover:bg-amber-200'
                              : 'bg-gray-100 text-gray-800'
                          }`}
                          title="ចុចដើម្បីប្តូរស្ថានភាព"
                        >
                          {ep.status}
                        </button>
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

      {/* Floating Audio Dock Player */}
      {activeEpisode && (
        <div className="fixed bottom-4 left-4 right-4 md:left-72 md:right-8 z-40 bg-[#1D102F]/95 backdrop-blur-xl border border-white/10 text-white p-3.5 rounded-2xl shadow-2xl flex flex-col md:flex-row md:items-center justify-between gap-3 animate-in slide-in-from-bottom duration-300">
          {/* Episode Info */}
          <div className="flex items-center gap-3 min-w-0 md:max-w-xs">
            <div className="w-10 h-10 rounded-xl bg-[#2E1A47] flex items-center justify-center flex-shrink-0 text-[#C89B3C]">
              <Headphones className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <p className="text-xs font-bold text-white truncate">{activeEpisode.title}</p>
              <p className="text-[10px] text-[#A69BB5] truncate">
                {activeEpisode.stories?.title || 'Story'} • វគ្គ #{activeEpisode.episode_number}
              </p>
            </div>
          </div>

          {/* Center Playback Controls & Scrubber */}
          <div className="flex-1 max-w-xl flex flex-col items-center gap-1.5">
            <div className="flex items-center gap-3">
              <button
                onClick={() => handleSkip(-10)}
                className="p-1.5 rounded-lg text-[#A69BB5] hover:text-white transition-colors cursor-pointer"
                title="ថយក្រោយ 10 វិនាទី"
              >
                <RotateCcw className="w-4 h-4" />
              </button>

              <button
                onClick={() => handlePlayToggle(activeEpisode)}
                className="w-9 h-9 rounded-full bg-[#C89B3C] text-[#1D102F] flex items-center justify-center cursor-pointer hover:scale-105 transition-all shadow-md"
              >
                {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
              </button>

              <button
                onClick={() => handleSkip(10)}
                className="p-1.5 rounded-lg text-[#A69BB5] hover:text-white transition-colors cursor-pointer"
                title="ទៅមុខ 10 វិនាទី"
              >
                <RotateCw className="w-4 h-4" />
              </button>
            </div>

            {/* Scrubber slider */}
            <div className="w-full flex items-center gap-2 text-[10px] font-mono text-[#A69BB5]">
              <span className="w-10 text-right">{formatDuration(Math.round(currentTime))}</span>
              <input
                type="range"
                min={0}
                max={duration || activeEpisode.duration_seconds || 1}
                value={currentTime}
                onChange={handleSeek}
                className="flex-1 h-1.5 rounded-lg bg-white/20 accent-[#C89B3C] cursor-pointer"
              />
              <span className="w-10">{formatDuration(Math.round(duration || activeEpisode.duration_seconds || 0))}</span>
            </div>
          </div>

          {/* Right controls: Mute & Close */}
          <div className="flex items-center justify-end gap-2">
            <button
              onClick={handleToggleMute}
              className="p-2 rounded-xl text-[#A69BB5] hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
              title={isMuted ? 'បើកសំឡេង' : 'បិទសំឡេង'}
            >
              {isMuted ? <VolumeX className="w-4 h-4 text-rose-400" /> : <Volume2 className="w-4 h-4" />}
            </button>
            <button
              onClick={handleStopPlayback}
              className="p-2 rounded-xl text-[#A69BB5] hover:text-white hover:bg-white/10 transition-colors cursor-pointer"
              title="បិទ Player"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

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
