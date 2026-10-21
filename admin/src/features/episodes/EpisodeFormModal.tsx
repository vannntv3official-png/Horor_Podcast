import React, { useState, useEffect, useRef } from 'react';
import { supabase, BUCKETS, getPublicStorageUrl } from '../../lib/supabase';
import { useAuth } from '../auth/AuthContext';
import { formatBytes, formatDuration } from '../../lib/utils';
import type { Episode, Story, StoryStatus } from '../../types';
import { X, Loader2, Music, Play, Pause, AlertCircle } from 'lucide-react';

interface EpisodeFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  episodeToEdit?: Episode | null;
  onSaved: () => void;
  defaultStoryId?: string;
}

export const EpisodeFormModal: React.FC<EpisodeFormModalProps> = ({
  isOpen,
  onClose,
  episodeToEdit,
  onSaved,
  defaultStoryId,
}) => {
  const { user } = useAuth();
  const [stories, setStories] = useState<Story[]>([]);
  const [storyId, setStoryId] = useState(defaultStoryId || '');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [episodeNumber, setEpisodeNumber] = useState(1);
  const [audioPath, setAudioPath] = useState('');
  const [audioSizeBytes, setAudioSizeBytes] = useState<number | null>(null);
  const [durationSeconds, setDurationSeconds] = useState<number | null>(null);
  const [status, setStatus] = useState<StoryStatus>('draft');
  const [allowDownload, setAllowDownload] = useState(true);

  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Audio Preview state
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [isPlayingPreview, setIsPlayingPreview] = useState(false);

  useEffect(() => {
    supabase
      .from('stories')
      .select('id, title')
      .order('title', { ascending: true })
      .then(({ data }) => setStories((data as Story[]) || []));
  }, []);

  useEffect(() => {
    if (episodeToEdit) {
      setStoryId(episodeToEdit.story_id);
      setTitle(episodeToEdit.title);
      setDescription(episodeToEdit.description || '');
      setEpisodeNumber(episodeToEdit.episode_number);
      setAudioPath(episodeToEdit.audio_path);
      setAudioSizeBytes(episodeToEdit.audio_size_bytes);
      setDurationSeconds(episodeToEdit.duration_seconds);
      setStatus(episodeToEdit.status);
      setAllowDownload(episodeToEdit.allow_download);
    } else {
      setStoryId(defaultStoryId || '');
      setTitle('');
      setDescription('');
      setEpisodeNumber(1);
      setAudioPath('');
      setAudioSizeBytes(null);
      setDurationSeconds(null);
      setStatus('draft');
      setAllowDownload(true);
    }
    setUploadProgress(0);
    setIsPlayingPreview(false);
  }, [episodeToEdit, isOpen, defaultStoryId]);

  if (!isOpen) return null;

  const handleAudioUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.includes('audio') && !file.name.endsWith('.mp3')) {
      setError('សូមជ្រើសរើសឯកសារសំឡេង MP3 ឬ M4A។');
      return;
    }

    if (file.size > 50 * 1024 * 1024) {
      setError(`ទំហំឯកសារធំលើសកំណត់ 50MB (${(file.size / (1024 * 1024)).toFixed(1)}MB)។ គម្រោង Supabase Free Tier កំណត់ទំហំបង្ហោះអតិបរមា 50MB ក្នុងមួយឯកសារ។ សូមបង្រួមឯកសារ MP3 (Bitrate 96kbps ឬ 128kbps) ឬបែងចែកជាភាគខ្លីៗ។`);
      return;
    }

    setUploading(true);
    setUploadProgress(10);
    setError(null);

    try {
      const ext = file.name.split('.').pop() || 'mp3';
      const fileName = `audio_${Date.now()}_${Math.random().toString(36).substring(7)}.${ext}`;

      // Calculate audio duration using client Audio API
      const objectUrl = URL.createObjectURL(file);
      const tempAudio = new Audio(objectUrl);
      tempAudio.onloadedmetadata = () => {
        if (tempAudio.duration) {
          setDurationSeconds(Math.round(tempAudio.duration));
        }
      };

      setUploadProgress(40);

      const { error: uploadError } = await supabase.storage
        .from(BUCKETS.PODCAST_AUDIO)
        .upload(fileName, file, { cacheControl: '3600', upsert: true });

      if (uploadError) {
        if (uploadError.message.toLowerCase().includes('exceeded') || uploadError.message.includes('413')) {
          throw new Error('ទំហំឯកសារធំលើសដែនកំណត់របស់ Supabase (អតិបរមា 50MB)។ សូមបង្រួម Bitrate នៃឯកសារ MP3 (ឧ. 96kbps ឬ 128kbps) ឬបែងចែកជាភាគខ្លីៗ។');
        }
        throw uploadError;
      }

      setUploadProgress(100);
      setAudioPath(fileName);
      setAudioSizeBytes(file.size);
    } catch (err: unknown) {
      setError((err as Error).message || 'ការបង្ហោះសំឡេងបរាជ័យ');
    } finally {
      setUploading(false);
    }
  };

  const togglePreview = () => {
    if (!audioRef.current) return;
    if (isPlayingPreview) {
      audioRef.current.pause();
      setIsPlayingPreview(false);
    } else {
      audioRef.current.play();
      setIsPlayingPreview(true);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!storyId) {
      setError('សូមជ្រើសរើសរឿងសម្រាប់ភាគនេះ');
      return;
    }
    if (!title.trim()) {
      setError('សូមបញ្ចូលចំណងជើងភាគ');
      return;
    }
    if (!audioPath) {
      setError('សូមបង្ហោះឯកសារសំឡេង MP3 ជាមុនសិន');
      return;
    }

    setSaving(true);
    setError(null);

    const payload = {
      story_id: storyId,
      title: title.trim(),
      description: description.trim() || null,
      episode_number: Number(episodeNumber),
      audio_path: audioPath,
      audio_mime_type: 'audio/mpeg',
      audio_size_bytes: audioSizeBytes,
      duration_seconds: durationSeconds,
      status,
      allow_download: allowDownload,
      published_at: status === 'published' ? new Date().toISOString() : null,
      updated_at: new Date().toISOString(),
    };

    try {
      if (episodeToEdit) {
        const { error: updateErr } = await supabase
          .from('episodes')
          .update(payload)
          .eq('id', episodeToEdit.id);

        if (updateErr) throw updateErr;

        await supabase.from('admin_audit_logs').insert({
          actor_user_id: user?.id,
          action: 'UPDATE_EPISODE',
          entity_type: 'episodes',
          entity_id: episodeToEdit.id,
          metadata: { title },
        });
      } else {
        const { data, error: insertErr } = await supabase
          .from('episodes')
          .insert({
            ...payload,
            created_by: user?.id,
          })
          .select()
          .single();

        if (insertErr) throw insertErr;

        if (data) {
          await supabase.from('admin_audit_logs').insert({
            actor_user_id: user?.id,
            action: 'CREATE_EPISODE',
            entity_type: 'episodes',
            entity_id: data.id,
            metadata: { title },
          });
        }
      }

      onSaved();
      onClose();
    } catch (err: unknown) {
      setError((err as Error).message || 'ការរក្សាទុកទិន្នន័យបរាជ័យ');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
      <div className="w-full max-w-2xl bg-[#FBF9F5] border border-[#E2DCEB] rounded-3xl shadow-2xl overflow-hidden my-8">
        {/* Header */}
        <div className="px-6 py-4 border-b border-[#E2DCEB] flex items-center justify-between bg-white/70">
          <h3 className="font-bold text-base text-[#1D102F]">
            {episodeToEdit ? 'កែប្រែភាគនិទាន (Edit Episode)' : 'បង្ហោះភាគថ្មី (Upload Episode)'}
          </h3>
          <button onClick={onClose} className="p-1 rounded-lg text-[#8A7B9B] hover:bg-gray-100 cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </div>

        {error && (
          <div className="m-6 mb-0 p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-700 flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-red-600 flex-shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">រឿង (Assign Story) *</label>
              <select
                value={storyId}
                onChange={(e) => setStoryId(e.target.value)}
                required
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              >
                <option value="">-- ជ្រើសរើសរឿង --</option>
                {stories.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.title}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">លេខវគ្គ (Episode Number) *</label>
              <input
                type="number"
                min={1}
                value={episodeNumber}
                onChange={(e) => setEpisodeNumber(Number(e.target.value))}
                required
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#1D102F] mb-1">ចំណងជើងភាគ (Episode Title) *</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              placeholder="ឧ. ភាគ ១៖ ទ្វារឈើដែលបើកដោយខ្លួនឯង"
              className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#1D102F] mb-1">សេចក្តីសង្ខេបភាគ (Description)</label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="រៀបរាប់ត្រួសៗអំពីភាគនេះ..."
              className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
            />
          </div>

          {/* Audio Upload Box */}
          <div className="p-4 rounded-2xl border border-[#E2DCEB] bg-white/70">
            <label className="block text-xs font-semibold text-[#1D102F] mb-2">ឯកសារសំឡេង MP3 (Audio File) *</label>

            {audioPath ? (
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 rounded-xl bg-[#EDE8F5]/60 border border-[#E2DCEB]">
                  <div className="flex items-center gap-3">
                    <button
                      type="button"
                      onClick={togglePreview}
                      className="w-10 h-10 rounded-xl bg-[#1D102F] text-[#C89B3C] flex items-center justify-center cursor-pointer shadow-sm"
                    >
                      {isPlayingPreview ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5" />}
                    </button>
                    <div>
                      <p className="text-xs font-bold text-[#1D102F] truncate max-w-xs">{audioPath}</p>
                      <p className="text-[11px] text-[#635C6E]">
                        ទំហំ: {formatBytes(audioSizeBytes)} • រយៈពេល: {formatDuration(durationSeconds)}
                      </p>
                    </div>
                  </div>
                  <label className="text-xs font-semibold text-[#C89B3C] hover:underline cursor-pointer">
                    ប្តូរឯកសារ
                    <input type="file" accept="audio/mpeg,audio/mp3,audio/m4a" onChange={handleAudioUpload} className="hidden" />
                  </label>
                </div>
                <audio
                  ref={audioRef}
                  src={getPublicStorageUrl(BUCKETS.PODCAST_AUDIO, audioPath)}
                  onEnded={() => setIsPlayingPreview(false)}
                  className="hidden"
                />
              </div>
            ) : (
              <div>
                <label className="border-2 border-dashed border-[#E2DCEB] hover:border-[#1D102F] rounded-2xl p-6 flex flex-col items-center justify-center cursor-pointer bg-white transition-colors">
                  <div className="w-12 h-12 rounded-full bg-[#EDE8F5] text-[#1D102F] flex items-center justify-center mb-2">
                    {uploading ? <Loader2 className="w-6 h-6 animate-spin text-[#C89B3C]" /> : <Music className="w-6 h-6" />}
                  </div>
                  <span className="text-xs font-semibold text-[#1D102F]">
                    {uploading ? 'កំពុងបង្ហោះសំឡេង...' : 'ចុចទីនេះដើម្បីជ្រើសរើសឯកសារ MP3'}
                  </span>
                  <span className="text-[11px] text-[#8A7B9B] mt-0.5">គាំទ្រ MP3, M4A ទំហំអតិបរមា 100MB</span>
                  <input type="file" accept="audio/mpeg,audio/mp3,audio/m4a" onChange={handleAudioUpload} className="hidden" />
                </label>
                {uploading && (
                  <div className="w-full bg-[#EDE8F5] h-1.5 rounded-full overflow-hidden mt-3">
                    <div className="bg-[#C89B3C] h-full transition-all duration-300" style={{ width: `${uploadProgress}%` }} />
                  </div>
                )}
              </div>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ស្ថានភាព (Status)</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as StoryStatus)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              >
                <option value="draft">ព្រាងទុក (Draft)</option>
                <option value="published">ផ្សព្វផ្សាយ (Published)</option>
                <option value="archived">ទុកក្នុងបណ្ណសារ (Archived)</option>
              </select>
            </div>

            <div className="flex items-center pt-6">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={allowDownload}
                  onChange={(e) => setAllowDownload(e.target.checked)}
                  className="w-4 h-4 rounded text-[#1D102F] focus:ring-[#1D102F]"
                />
                <span className="text-xs font-semibold text-[#1D102F]">អនុញ្ញាតឱ្យទាញយក Offline (Allow Download)</span>
              </label>
            </div>
          </div>

          {/* Actions */}
          <div className="pt-4 border-t border-[#E2DCEB] flex flex-col-reverse sm:flex-row items-stretch sm:items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="w-full sm:w-auto px-4 py-2.5 rounded-xl text-xs font-semibold text-[#635C6E] hover:bg-gray-100 cursor-pointer text-center"
            >
              បោះបង់
            </button>
            <button
              type="submit"
              disabled={saving || uploading}
              className="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer"
            >
              {saving && <Loader2 className="w-3.5 h-3.5 animate-spin text-[#C89B3C]" />}
              <span>រក្សាទុក (Save Episode)</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
