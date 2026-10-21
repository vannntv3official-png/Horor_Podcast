import React, { useState, useEffect } from 'react';
import { supabase, BUCKETS, getPublicStorageUrl } from '../../lib/supabase';
import { compressImage } from '../../lib/imageCompressor';
import { useAuth } from '../auth/AuthContext';
import type { Story, Category, StoryStatus } from '../../types';
import { X, Upload, Loader2, Image as ImageIcon } from 'lucide-react';

interface StoryFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  storyToEdit?: Story | null;
  onSaved: () => void;
}

export const StoryFormModal: React.FC<StoryFormModalProps> = ({
  isOpen,
  onClose,
  storyToEdit,
  onSaved,
}) => {
  const { user } = useAuth();
  const [categories, setCategories] = useState<Category[]>([]);
  const [title, setTitle] = useState('');
  const [slug, setSlug] = useState('');
  const [description, setDescription] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [narratorName, setNarratorName] = useState('');
  const [status, setStatus] = useState<StoryStatus>('draft');
  const [isFeatured, setIsFeatured] = useState(false);
  const [coverPath, setCoverPath] = useState('');

  const [uploadingCover, setUploadingCover] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .then(({ data }) => setCategories((data as Category[]) || []));
  }, []);

  useEffect(() => {
    if (storyToEdit) {
      setTitle(storyToEdit.title);
      setSlug(storyToEdit.slug);
      setDescription(storyToEdit.description || '');
      setCategoryId(storyToEdit.category_id || '');
      setNarratorName(storyToEdit.narrator_name || '');
      setStatus(storyToEdit.status);
      setIsFeatured(storyToEdit.is_featured);
      setCoverPath(storyToEdit.cover_path || '');
    } else {
      setTitle('');
      setSlug('');
      setDescription('');
      setCategoryId('');
      setNarratorName('');
      setStatus('draft');
      setIsFeatured(false);
      setCoverPath('');
    }
  }, [storyToEdit, isOpen]);

  if (!isOpen) return null;

  const handleTitleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setTitle(val);
    if (!storyToEdit) {
      // Auto-generate basic slug
      const generated = val
        .toLowerCase()
        .replace(/[^\w\s-]/g, '')
        .trim()
        .replace(/\s+/g, '-');
      setSlug(generated || `story-${Date.now()}`);
    }
  };

  const handleCoverUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawFile = e.target.files?.[0];
    if (!rawFile) return;

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(rawFile.type)) {
      setError('ទម្រង់រូបភាពមិនត្រឹមត្រូវទេ។ សូមប្រើប្រាស់ JPG, PNG ឬ WebP។');
      return;
    }

    if (rawFile.size > 20 * 1024 * 1024) {
      setError('ទំហំរូបភាពធំលើសកំណត់ 20MB។');
      return;
    }

    setUploadingCover(true);
    setError(null);

    try {
      // Automatically compress and resize high-res images to under 1MB WebP
      const file = await compressImage(rawFile, 1600, 1600, 0.85);

      const ext = file.name.split('.').pop() || 'webp';
      const fileName = `cover_${Date.now()}_${Math.random().toString(36).substring(7)}.${ext}`;
      const { error: uploadError } = await supabase.storage
        .from(BUCKETS.STORY_COVERS)
        .upload(fileName, file, { cacheControl: '3600', upsert: true });

      if (uploadError) {
        if (uploadError.message.toLowerCase().includes('exceeded') || uploadError.message.includes('413')) {
          throw new Error('ទំហំរូបភាពលើសកំណត់របស់ Supabase។ ប្រព័ន្ធបានព្យាយាមបង្រួមរួចហើយ សូមជ្រើសរើសរូបភាពដែលមាន resolution ទាបជាងនេះ។');
        }
        throw uploadError;
      }

      setCoverPath(fileName);
    } catch (err: unknown) {
      setError((err as Error).message || 'ការបង្ហោះរូបភាពបរាជ័យ');
    } finally {
      setUploadingCover(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !slug.trim()) {
      setError('សូមបំពេញចំណងជើង និង Slug');
      return;
    }

    setSaving(true);
    setError(null);

    const payload = {
      title: title.trim(),
      slug: slug.trim(),
      description: description.trim() || null,
      category_id: categoryId || null,
      narrator_name: narratorName.trim() || null,
      status,
      is_featured: isFeatured,
      cover_path: coverPath || null,
      published_at: status === 'published' ? new Date().toISOString() : null,
      updated_at: new Date().toISOString(),
    };

    try {
      if (storyToEdit) {
        const { error: updateErr } = await supabase
          .from('stories')
          .update(payload)
          .eq('id', storyToEdit.id);

        if (updateErr) throw updateErr;

        // Log audit
        await supabase.from('admin_audit_logs').insert({
          actor_user_id: user?.id,
          action: 'UPDATE_STORY',
          entity_type: 'stories',
          entity_id: storyToEdit.id,
          metadata: { title },
        });
      } else {
        const { data, error: insertErr } = await supabase
          .from('stories')
          .insert({
            ...payload,
            created_by: user?.id,
          })
          .select()
          .single();

        if (insertErr) throw insertErr;

        // Log audit
        if (data) {
          await supabase.from('admin_audit_logs').insert({
            actor_user_id: user?.id,
            action: 'CREATE_STORY',
            entity_type: 'stories',
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
            {storyToEdit ? 'កែប្រែព័ត៌មានរឿង (Edit Story)' : 'បង្កើតរឿងថ្មី (Create Story)'}
          </h3>
          <button onClick={onClose} className="p-1 rounded-lg text-[#8A7B9B] hover:bg-gray-100 cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </div>

        {error && (
          <div className="m-6 mb-0 p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-700">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ចំណងជើងរឿង (Title) *</label>
              <input
                type="text"
                value={title}
                onChange={handleTitleChange}
                required
                placeholder="ឧ. វិញ្ញាណវិលវល់នៅផ្ទះបុរាណ..."
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">Slug (URL Identifier) *</label>
              <input
                type="text"
                value={slug}
                onChange={(e) => setSlug(e.target.value)}
                required
                placeholder="ghost-ancient-house"
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">ប្រភេទរឿង (Category)</label>
              <select
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              >
                <option value="">-- ជ្រើសរើសប្រភេទ --</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#1D102F] mb-1">អ្នកនិទាន (Narrator)</label>
              <input
                type="text"
                value={narratorName}
                onChange={(e) => setNarratorName(e.target.value)}
                placeholder="ឧ. លោក សុខ រ៉ាវី"
                className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#1D102F] mb-1">សេចក្តីសង្ខេបរឿង (Description)</label>
            <textarea
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="រៀបរាប់ត្រួសៗអំពីសាច់រឿង..."
              className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
            />
          </div>

          {/* Cover Art Upload */}
          <div>
            <label className="block text-xs font-semibold text-[#1D102F] mb-1">រូបភាពគម្របរឿង (Cover Image)</label>
            <div className="flex items-center gap-4">
              <div className="w-20 h-20 rounded-2xl border border-[#E2DCEB] bg-white overflow-hidden flex items-center justify-center flex-shrink-0 shadow-sm">
                {coverPath ? (
                  <img
                    src={getPublicStorageUrl(BUCKETS.STORY_COVERS, coverPath)}
                    alt="Cover preview"
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <ImageIcon className="w-8 h-8 text-[#8A7B9B]" />
                )}
              </div>
              <div className="flex-1">
                <label className="inline-flex items-center gap-2 px-3.5 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs font-medium text-[#1D102F] hover:bg-gray-50 cursor-pointer shadow-sm">
                  {uploadingCover ? (
                    <Loader2 className="w-4 h-4 animate-spin text-[#C89B3C]" />
                  ) : (
                    <Upload className="w-4 h-4 text-[#8A7B9B]" />
                  )}
                  <span>{uploadingCover ? 'កំពុងបង្ហោះ...' : 'ជ្រើសរើសរូបភាព (Upload)'}</span>
                  <input type="file" accept="image/jpeg,image/png,image/webp" onChange={handleCoverUpload} className="hidden" />
                </label>
                <p className="text-[11px] text-[#8A7B9B] mt-1">ទំហំអតិបរមា 5MB (JPG, PNG, WebP)</p>
              </div>
            </div>
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
                  checked={isFeatured}
                  onChange={(e) => setIsFeatured(e.target.checked)}
                  className="w-4 h-4 rounded text-[#1D102F] focus:ring-[#1D102F]"
                />
                <span className="text-xs font-semibold text-[#1D102F]">រឿងពិសេសប្រចាំសប្តាហ៍ (Featured Story)</span>
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
              disabled={saving || uploadingCover}
              className="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer"
            >
              {saving && <Loader2 className="w-3.5 h-3.5 animate-spin text-[#C89B3C]" />}
              <span>រក្សាទុក (Save Story)</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
