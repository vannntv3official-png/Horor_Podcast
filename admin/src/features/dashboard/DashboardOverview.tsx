import React, { useEffect, useState, useTransition } from 'react';
import { supabase } from '../../lib/supabase';
import { formatBytes, formatDuration, formatDate } from '../../lib/utils';
import type { Story, Episode } from '../../types';
import {
  BookOpen,
  Headphones,
  Play,
  Plus,
  Loader2,
  HardDrive,
  TrendingUp,
  Clock,
  RefreshCw,
  CheckCircle2,
  Clock3,
  Star,
  ExternalLink,
} from 'lucide-react';

interface DashboardOverviewProps {
  onNavigate: (tab: string) => void;
}

interface TrendDay {
  label: string;
  dateKey: string;
  count: number;
}

export const DashboardOverview: React.FC<DashboardOverviewProps> = ({ onNavigate }) => {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [, startTransition] = useTransition();

  const [metrics, setMetrics] = useState({
    storiesCount: 0,
    publishedStoriesCount: 0,
    featuredStoriesCount: 0,
    episodesCount: 0,
    publishedEpisodesCount: 0,
    categoriesCount: 0,
    usersCount: 0,
    listeningEventsCount: 0,
    totalAudioBytes: 0,
    totalDurationSeconds: 0,
  });

  const [trendData, setTrendData] = useState<TrendDay[]>([]);
  const [recentStories, setRecentStories] = useState<Story[]>([]);
  const [recentEpisodes, setRecentEpisodes] = useState<Episode[]>([]);

  const fetchDashboardData = async () => {
    try {
      // 1. Fetch counts & data in parallel
      const [
        storiesRes,
        episodesRes,
        categoriesRes,
        usersRes,
        eventsRes,
        allEpisodesData,
        recentStoriesRes,
        recentEpisodesRes,
        recentEventsRes,
      ] = await Promise.all([
        supabase.from('stories').select('id, status, is_featured'),
        supabase.from('episodes').select('id, status, duration_seconds, audio_size_bytes'),
        supabase.from('categories').select('*', { count: 'exact', head: true }),
        supabase.from('profiles').select('*', { count: 'exact', head: true }),
        supabase.from('listening_events').select('*', { count: 'exact', head: true }),
        supabase.from('episodes').select('audio_size_bytes, duration_seconds'),
        supabase.from('stories').select('*, categories(name)').order('created_at', { ascending: false }).limit(5),
        supabase.from('episodes').select('*, stories(title)').order('created_at', { ascending: false }).limit(5),
        // Fetch last 7 days of listening events for trend
        supabase
          .from('listening_events')
          .select('created_at')
          .gte('created_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()),
      ]);

      const storiesList = (storiesRes.data as Array<{ id: string; status: string; is_featured: boolean }>) || [];
      const episodesList = (episodesRes.data as Array<{ id: string; status: string; duration_seconds: number | null; audio_size_bytes: number | null }>) || [];

      // Calculate totals
      let totalBytes = 0;
      let totalSeconds = 0;
      (allEpisodesData.data || []).forEach((ep) => {
        totalBytes += ep.audio_size_bytes || 0;
        totalSeconds += ep.duration_seconds || 0;
      });

      const publishedStories = storiesList.filter((s) => s.status === 'published').length;
      const featuredStories = storiesList.filter((s) => s.is_featured).length;
      const publishedEpisodes = episodesList.filter((e) => e.status === 'published').length;

      // Build 7-day trend array
      const daysMap: Record<string, number> = {};
      const daysArr: TrendDay[] = [];
      const dayNames = ['អាទិត្យ', 'ចន្ទ', 'អង្គារ', 'ពុធ', 'ព្រហ', 'សុក្រ', 'សៅរ៍'];

      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const key = d.toISOString().split('T')[0];
        const dayLabel = dayNames[d.getDay()];
        daysMap[key] = 0;
        daysArr.push({ label: dayLabel, dateKey: key, count: 0 });
      }

      (recentEventsRes.data || []).forEach((evt: { created_at: string }) => {
        const key = evt.created_at ? evt.created_at.split('T')[0] : '';
        if (daysMap[key] !== undefined) {
          daysMap[key]++;
        }
      });

      daysArr.forEach((d) => {
        d.count = daysMap[d.dateKey] || 0;
      });

      startTransition(() => {
        setMetrics({
          storiesCount: storiesList.length,
          publishedStoriesCount: publishedStories,
          featuredStoriesCount: featuredStories,
          episodesCount: episodesList.length,
          publishedEpisodesCount: publishedEpisodes,
          categoriesCount: categoriesRes.count || 0,
          usersCount: usersRes.count || 0,
          listeningEventsCount: eventsRes.count || 0,
          totalAudioBytes: totalBytes,
          totalDurationSeconds: totalSeconds,
        });

        setTrendData(daysArr);
        setRecentStories((recentStoriesRes.data as Story[]) || []);
        setRecentEpisodes((recentEpisodesRes.data as Episode[]) || []);
      });
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchDashboardData();
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center h-80 gap-3">
        <Loader2 className="w-10 h-10 animate-spin text-[#C89B3C]" />
        <p className="text-xs font-semibold text-[#8A7B9B]">កំពុងទាញយកទិន្នន័យ Dashboard...</p>
      </div>
    );
  }

  // Calculate storage quota (Free tier 1GB Storage limit benchmark)
  const storageLimitBytes = 1024 * 1024 * 1024; // 1 GB
  const storageUsedPercent = Math.min(100, Math.round((metrics.totalAudioBytes / storageLimitBytes) * 100));

  // Max value for SVG trend chart scaling
  const maxTrend = Math.max(...trendData.map((t) => t.count), 5);

  const statCards = [
    {
      title: 'រឿងសរុប (Stories)',
      subtitle: `${metrics.publishedStoriesCount} ផ្សព្វផ្សាយ • ${metrics.featuredStoriesCount} ពិសេស`,
      count: metrics.storiesCount,
      icon: BookOpen,
      tab: 'stories',
      color: 'bg-indigo-50 text-indigo-700',
    },
    {
      title: 'ភាគសរុប (Episodes)',
      subtitle: `${metrics.publishedEpisodesCount} ផ្សព្វផ្សាយ (${metrics.episodesCount - metrics.publishedEpisodesCount} ព្រាង)`,
      count: metrics.episodesCount,
      icon: Headphones,
      tab: 'episodes',
      color: 'bg-purple-50 text-purple-700',
    },
    {
      title: 'រយៈពេលសំឡេងសរុប',
      subtitle: 'ម៉ោង : នាទី : វិនាទី',
      count: formatDuration(metrics.totalDurationSeconds),
      icon: Clock,
      tab: 'episodes',
      color: 'bg-amber-50 text-amber-700',
    },
    {
      title: 'ទំហំផ្ទុក MP3 (Storage)',
      subtitle: `${storageUsedPercent}% នៃ 1GB Free Quota`,
      count: formatBytes(metrics.totalAudioBytes),
      icon: HardDrive,
      tab: 'settings',
      color: 'bg-emerald-50 text-emerald-700',
    },
    {
      title: 'ចំនួនស្តាប់សរុប (Plays)',
      subtitle: `${metrics.usersCount} គណនីបានចុះឈ្មោះ`,
      count: metrics.listeningEventsCount,
      icon: Play,
      tab: 'dashboard',
      color: 'bg-rose-50 text-rose-700',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Action Header Banner */}
      <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-xl font-bold text-[#1D102F]">Khmer Horror Podcast Content Hub</h2>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold">
              Live Production
            </span>
          </div>
          <p className="text-xs text-[#635C6E] mt-1">
            គ្រប់គ្រងរឿងខ្មោច ឯកសារសំឡេង MP3 និងត្រួតពិនិត្យស្ថិតិនៃការស្តាប់របស់ប្រព័ន្ធ
          </p>
        </div>

        <div className="flex items-center flex-wrap gap-2.5">
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="flex items-center gap-1.5 px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-[#1D102F] text-xs font-semibold hover:bg-white/80 transition-all cursor-pointer shadow-sm disabled:opacity-50"
            title="Refresh metrics"
          >
            <RefreshCw className={`w-3.5 h-3.5 text-[#8A7B9B] ${refreshing ? 'animate-spin text-[#C89B3C]' : ''}`} />
            <span className="hidden sm:inline">ផ្ទុកទិន្នន័យឡើងវិញ</span>
          </button>

          <button
            onClick={() => onNavigate('stories')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#1D102F] text-white text-xs font-semibold hover:bg-[#2E1A47] transition-all cursor-pointer shadow-md"
          >
            <Plus className="w-4 h-4 text-[#C89B3C]" />
            <span>បន្ថែមរឿងថ្មី</span>
          </button>

          <button
            onClick={() => onNavigate('episodes')}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#C89B3C] text-[#1D102F] text-xs font-bold hover:bg-[#b88c32] transition-all cursor-pointer shadow-md"
          >
            <Plus className="w-4 h-4 text-[#1D102F]" />
            <span>បង្ហោះភាគ MP3</span>
          </button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {statCards.map((card, i) => {
          const Icon = card.icon;
          return (
            <div
              key={i}
              onClick={() => onNavigate(card.tab)}
              className="glass-card p-5 rounded-2xl border border-[#E2DCEB] hover:shadow-lg transition-all cursor-pointer flex flex-col justify-between"
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-[#635C6E] truncate">{card.title}</span>
                <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${card.color}`}>
                  <Icon className="w-4 h-4" />
                </div>
              </div>
              <div>
                <div className="text-2xl font-black text-[#1D102F] tracking-tight">{card.count}</div>
                <div className="text-[11px] text-[#8A7B9B] mt-1 truncate">{card.subtitle}</div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Visual Analytics Row: 7-Day Trend & Content Storage Health */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 7-Day Trend Chart */}
        <div className="lg:col-span-2 glass-panel p-6 rounded-3xl border border-[#E2DCEB] flex flex-col justify-between">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-800 flex items-center justify-center">
                <TrendingUp className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-bold text-sm text-[#1D102F]">ស្ថិតិនៃការស្តាប់ ៧ថ្ងៃចុងក្រោយ</h3>
                <p className="text-[11px] text-[#8A7B9B]">ចំនួនដងនៃការចាក់ស្តាប់ភាគរឿង (Plays per day)</p>
              </div>
            </div>
            <span className="text-xs font-bold text-[#1D102F] bg-white px-3 py-1 rounded-full border border-[#E2DCEB]">
              សរុប {trendData.reduce((acc, cur) => acc + cur.count, 0)} ដង
            </span>
          </div>

          {/* SVG Bar Chart Visualization */}
          <div className="h-44 flex items-end justify-between gap-2 pt-6 pb-2 px-2">
            {trendData.map((day, idx) => {
              const heightPercent = maxTrend > 0 ? Math.max(12, Math.round((day.count / maxTrend) * 100)) : 12;
              return (
                <div key={idx} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                  <span className="text-[10px] font-bold text-[#1D102F] opacity-0 group-hover:opacity-100 transition-opacity">
                    {day.count}
                  </span>
                  <div className="w-full max-w-[42px] bg-slate-100 rounded-xl overflow-hidden flex flex-col justify-end h-full">
                    <div
                      className="w-full bg-gradient-to-t from-[#1D102F] to-[#43236B] rounded-xl transition-all duration-500 group-hover:from-[#C89B3C] group-hover:to-[#E5B558]"
                      style={{ height: `${heightPercent}%` }}
                    />
                  </div>
                  <span className="text-[11px] font-semibold text-[#635C6E] truncate">{day.label}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Content Health & Storage Meter */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB] flex flex-col justify-between space-y-5">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-lg bg-amber-100 text-amber-800 flex items-center justify-center">
                <HardDrive className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-bold text-sm text-[#1D102F]">ទំហំផ្ទុក & ស្ថានភាពមាតិកា</h3>
                <p className="text-[11px] text-[#8A7B9B]">Supabase Storage & Story Lifecycle</p>
              </div>
            </div>

            {/* Storage Progress */}
            <div className="p-4 rounded-2xl bg-white border border-[#E2DCEB] space-y-2">
              <div className="flex items-center justify-between text-xs font-semibold">
                <span className="text-[#635C6E]">Audio Storage Used:</span>
                <span className="text-[#1D102F] font-bold">
                  {formatBytes(metrics.totalAudioBytes)} / 1.0 GB
                </span>
              </div>
              <div className="w-full bg-[#EDE8F5] h-2.5 rounded-full overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all duration-500 ${
                    storageUsedPercent > 85 ? 'bg-rose-500' : storageUsedPercent > 60 ? 'bg-amber-500' : 'bg-[#C89B3C]'
                  }`}
                  style={{ width: `${Math.max(4, storageUsedPercent)}%` }}
                />
              </div>
              <p className="text-[10px] text-[#8A7B9B]">
                {storageUsedPercent}% នៃកម្រិតទំហំផ្ទុកឥតគិតថ្លៃ (Free Tier Quota)
              </p>
            </div>
          </div>

          {/* Quick Content Status Badges */}
          <div className="space-y-2.5">
            <div className="flex items-center justify-between p-2.5 rounded-xl bg-emerald-50/70 border border-emerald-200 text-xs">
              <div className="flex items-center gap-2 text-emerald-900 font-semibold">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>រឿងផ្សព្វផ្សាយរួច (Published)</span>
              </div>
              <span className="font-bold text-emerald-950">{metrics.publishedStoriesCount}</span>
            </div>

            <div className="flex items-center justify-between p-2.5 rounded-xl bg-amber-50/70 border border-amber-200 text-xs">
              <div className="flex items-center gap-2 text-amber-900 font-semibold">
                <Clock3 className="w-4 h-4 text-amber-600" />
                <span>រឿងព្រាងទុក (Drafts)</span>
              </div>
              <span className="font-bold text-amber-950">
                {metrics.storiesCount - metrics.publishedStoriesCount}
              </span>
            </div>

            <div className="flex items-center justify-between p-2.5 rounded-xl bg-purple-50/70 border border-purple-200 text-xs">
              <div className="flex items-center gap-2 text-purple-900 font-semibold">
                <Star className="w-4 h-4 text-purple-600" />
                <span>រឿងពិសេស (Featured)</span>
              </div>
              <span className="font-bold text-purple-950">{metrics.featuredStoriesCount}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Two Columns: Recent Stories & Recent Episodes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Stories */}
        <div className="glass-panel p-6 rounded-3xl border border-[#E2DCEB]">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <BookOpen className="w-4 h-4 text-[#C89B3C]" />
              <h3 className="font-bold text-[#1D102F] text-base">រឿងដែលទើបបង្កើតថ្មី (Recent Stories)</h3>
            </div>
            <button
              onClick={() => onNavigate('stories')}
              className="inline-flex items-center gap-1 text-xs font-semibold text-[#C89B3C] hover:underline cursor-pointer"
            >
              <span>មើលទាំងអស់</span>
              <ExternalLink className="w-3 h-3" />
            </button>
          </div>

          {recentStories.length === 0 ? (
            <div className="py-12 text-center text-xs text-[#9B94A6]">មិនទាន់មានទិន្នន័យរឿងទេ</div>
          ) : (
            <div className="divide-y divide-[#E2DCEB]/50">
              {recentStories.map((s) => (
                <div key={s.id} className="py-3 flex items-center justify-between gap-4">
                  <div className="min-w-0">
                    <div className="flex items-center gap-1.5">
                      <p className="font-semibold text-sm text-[#1D102F] truncate">{s.title}</p>
                      {s.is_featured && <Star className="w-3.5 h-3.5 text-[#C89B3C] fill-current flex-shrink-0" />}
                    </div>
                    <span className="text-xs text-[#635C6E]">
                      {s.categories?.name || 'គ្មានប្រភេទ'} • {formatDate(s.created_at)}
                    </span>
                  </div>
                  <span
                    className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider flex-shrink-0 ${
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
            <div className="flex items-center gap-2">
              <Headphones className="w-4 h-4 text-[#C89B3C]" />
              <h3 className="font-bold text-[#1D102F] text-base">ភាគដែលទើបបង្ហោះ (Recent Episodes)</h3>
            </div>
            <button
              onClick={() => onNavigate('episodes')}
              className="inline-flex items-center gap-1 text-xs font-semibold text-[#C89B3C] hover:underline cursor-pointer"
            >
              <span>មើលទាំងអស់</span>
              <ExternalLink className="w-3 h-3" />
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
                      {ep.stories?.title || 'Story'} • វគ្គ #{ep.episode_number} • {formatDuration(ep.duration_seconds)}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <span className="text-[11px] text-[#8A7B9B] hidden sm:inline">
                      {formatBytes(ep.audio_size_bytes)}
                    </span>
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
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
