import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { formatDate } from '../../lib/utils';
import type { Story, Episode } from '../../types';
import { BookOpen, Headphones, FolderTree, Users, Play, Plus, Loader2 } from 'lucide-react';

interface DashboardOverviewProps {
  onNavigate: (tab: string) => void;
}

export const DashboardOverview: React.FC<DashboardOverviewProps> = ({ onNavigate }) => {
  const [loading, setLoading] = useState(true);
  const [metrics, setMetrics] = useState({
    storiesCount: 0,
    episodesCount: 0,
    categoriesCount: 0,
    usersCount: 0,
    listeningEventsCount: 0,
  });
  const [recentStories, setRecentStories] = useState<Story[]>([]);
  const [recentEpisodes, setRecentEpisodes] = useState<Episode[]>([]);

  useEffect(() => {
    const fetchMetrics = async () => {
      setLoading(true);
      try {
        const [
          storiesRes,
          episodesRes,
          categoriesRes,
          usersRes,
          eventsRes,
          recentStoriesRes,
          recentEpisodesRes,
        ] = await Promise.all([
          supabase.from('stories').select('*', { count: 'exact', head: true }),
          supabase.from('episodes').select('*', { count: 'exact', head: true }),
          supabase.from('categories').select('*', { count: 'exact', head: true }),
          supabase.from('profiles').select('*', { count: 'exact', head: true }),
          supabase.from('listening_events').select('*', { count: 'exact', head: true }),
          supabase.from('stories').select('*, categories(name)').order('created_at', { ascending: false }).limit(5),
          supabase.from('episodes').select('*, stories(title)').order('created_at', { ascending: false }).limit(5),
        ]);

        setMetrics({
          storiesCount: storiesRes.count || 0,
          episodesCount: episodesRes.count || 0,
          categoriesCount: categoriesRes.count || 0,
          usersCount: usersRes.count || 0,
          listeningEventsCount: eventsRes.count || 0,
        });

        setRecentStories((recentStoriesRes.data as Story[]) || []);
        setRecentEpisodes((recentEpisodesRes.data as Episode[]) || []);
      } catch (err) {
        console.error('Failed to load metrics:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchMetrics();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-[#C89B3C]" />
      </div>
    );
  }

  const statCards = [
    { title: 'រឿងសរុប (Stories)', count: metrics.storiesCount, icon: BookOpen, tab: 'stories' },
    { title: 'ភាគសរុប (Episodes)', count: metrics.episodesCount, icon: Headphones, tab: 'episodes' },
    { title: 'ប្រភេទរឿង (Categories)', count: metrics.categoriesCount, icon: FolderTree, tab: 'categories' },
    { title: 'អ្នកចុះឈ្មោះ (Users)', count: metrics.usersCount, icon: Users, tab: 'users' },
    { title: 'ចំនួនស្តាប់ (Plays)', count: metrics.listeningEventsCount, icon: Play, tab: 'dashboard' },
  ];

  return (
    <div className="space-y-8">
      {/* Action Header Banner */}
      <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-[#1D102F]">Khmer Horror Podcast Content Hub</h2>
          <p className="text-sm text-[#635C6E] mt-1">គ្រប់គ្រងរឿងខ្មោច រឿងព្រេងខ្មែរ បង្ហោះឯកសារ MP3 និងពិនិត្យទិន្នន័យស្តាប់</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => onNavigate('stories')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#1D102F] text-white text-xs font-semibold hover:bg-[#2E1A47] transition-all cursor-pointer shadow-md"
          >
            <Plus className="w-4 h-4 text-[#C89B3C]" />
            <span>បន្ថែមរឿងថ្មី</span>
          </button>
          <button
            onClick={() => onNavigate('episodes')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-[#1D102F] text-xs font-semibold hover:bg-white/80 transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4 text-[#C89B3C]" />
            <span>បង្ហោះភាគ MP3</span>
          </button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        {statCards.map((card, i) => {
          const Icon = card.icon;
          return (
            <div
              key={i}
              onClick={() => onNavigate(card.tab)}
              className="glass-card p-5 rounded-2xl border border-[#E2DCEB] hover:shadow-lg transition-all cursor-pointer"
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-medium text-[#635C6E]">{card.title}</span>
                <div className="w-8 h-8 rounded-lg bg-[#EDE8F5] text-[#1D102F] flex items-center justify-center">
                  <Icon className="w-4 h-4" />
                </div>
              </div>
              <div className="text-2xl font-bold text-[#1D102F]">{card.count}</div>
            </div>
          );
        })}
      </div>

      {/* Two Columns: Recent Stories & Recent Episodes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Stories */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB]">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-[#1D102F] text-base">រឿងដែលទើបបង្កើតថ្មី (Recent Stories)</h3>
            <button
              onClick={() => onNavigate('stories')}
              className="text-xs font-semibold text-[#C89B3C] hover:underline cursor-pointer"
            >
              មើលទាំងអស់
            </button>
          </div>

          {recentStories.length === 0 ? (
            <div className="py-12 text-center text-xs text-[#9B94A6]">មិនទាន់មានទិន្នន័យរឿងទេ</div>
          ) : (
            <div className="divide-y divide-[#E2DCEB]/50">
              {recentStories.map((s) => (
                <div key={s.id} className="py-3 flex items-center justify-between gap-4">
                  <div className="min-w-0">
                    <p className="font-semibold text-sm text-[#1D102F] truncate">{s.title}</p>
                    <span className="text-xs text-[#635C6E]">
                      {s.categories?.name || 'គ្មានប្រភេទ'} • {formatDate(s.created_at)}
                    </span>
                  </div>
                  <span
                    className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      s.status === 'published'
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {s.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Recent Episodes */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB]">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-[#1D102F] text-base">ភាគដែលទើបបង្ហោះ (Recent Episodes)</h3>
            <button
              onClick={() => onNavigate('episodes')}
              className="text-xs font-semibold text-[#C89B3C] hover:underline cursor-pointer"
            >
              មើលទាំងអស់
            </button>
          </div>

          {recentEpisodes.length === 0 ? (
            <div className="py-12 text-center text-xs text-[#9B94A6]">មិនទាន់មានភាគបង្ហោះទេ</div>
          ) : (
            <div className="divide-y divide-[#E2DCEB]/50">
              {recentEpisodes.map((ep) => (
                <div key={ep.id} className="py-3 flex items-center justify-between gap-4">
                  <div className="min-w-0">
                    <p className="font-semibold text-sm text-[#1D102F] truncate">{ep.title}</p>
                    <span className="text-xs text-[#635C6E]">
                      {ep.stories?.title || 'Story'} • វគ្គ {ep.episode_number}
                    </span>
                  </div>
                  <span
                    className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      ep.status === 'published'
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {ep.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
