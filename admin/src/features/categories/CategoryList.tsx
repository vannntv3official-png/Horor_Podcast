import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import type { Category } from '../../types';
import { Plus, Edit2, Trash2, FolderTree, Loader2, X, Check, Eye, EyeOff } from 'lucide-react';

export const CategoryList: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [categoryToEdit, setCategoryToEdit] = useState<Category | null>(null);
  const [name, setName] = useState('');
  const [slug, setSlug] = useState('');
  const [description, setDescription] = useState('');
  const [iconName, setIconName] = useState('headphones');
  const [sortOrder, setSortOrder] = useState(0);
  const [isActive, setIsActive] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('sort_order', { ascending: true });

      if (error) throw error;
      setCategories((data as Category[]) || []);
    } catch (err) {
      console.error('Failed to load categories:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const openCreateModal = () => {
    setCategoryToEdit(null);
    setName('');
    setSlug('');
    setDescription('');
    setIconName('headphones');
    setSortOrder(categories.length + 1);
    setIsActive(true);
    setError(null);
    setIsModalOpen(true);
  };

  const openEditModal = (cat: Category) => {
    setCategoryToEdit(cat);
    setName(cat.name);
    setSlug(cat.slug);
    setDescription(cat.description || '');
    setIconName(cat.icon_name || 'headphones');
    setSortOrder(cat.sort_order);
    setIsActive(cat.is_active);
    setError(null);
    setIsModalOpen(true);
  };

  const handleNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value;
    setName(val);
    if (!categoryToEdit) {
      const generated = val
        .toLowerCase()
        .replace(/[^\w\s-]/g, '')
        .trim()
        .replace(/\s+/g, '-');
      setSlug(generated || `cat-${Date.now()}`);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !slug.trim()) {
      setError('សូមបំពេញឈ្មោះ និង Slug');
      return;
    }

    setSaving(true);
    setError(null);

    const payload = {
      name: name.trim(),
      slug: slug.trim(),
      description: description.trim() || null,
      icon_name: iconName.trim() || null,
      sort_order: Number(sortOrder),
      is_active: isActive,
      updated_at: new Date().toISOString(),
    };

    try {
      if (categoryToEdit) {
        const { error: updateErr } = await supabase
          .from('categories')
          .update(payload)
          .eq('id', categoryToEdit.id);

        if (updateErr) throw updateErr;
      } else {
        const { error: insertErr } = await supabase
          .from('categories')
          .insert(payload);

        if (insertErr) throw insertErr;
      }

      setIsModalOpen(false);
      fetchCategories();
    } catch (err: unknown) {
      setError((err as Error).message || 'ការរក្សាទុកបរាជ័យ');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (cat: Category) => {
    // Check if category has stories attached
    const { count, error: countErr } = await supabase
      .from('stories')
      .select('*', { count: 'exact', head: true })
      .eq('category_id', cat.id);

    if (countErr) {
      alert(countErr.message);
      return;
    }

    if (count && count > 0) {
      alert(`មិនអាចលុបប្រភេទ "${cat.name}" បានទេ ព្រោះមានរឿងចំនួន ${count} កំពុងស្ថិតក្នុងប្រភេទនេះ។ សូមផ្លាស់ប្តូរប្រភេទរឿងជាមុនសិន។`);
      return;
    }

    if (!window.confirm(`តើអ្នកពិតជាចង់លុបប្រភេទ "${cat.name}" មែនទេ?`)) return;

    try {
      const { error } = await supabase.from('categories').delete().eq('id', cat.id);
      if (error) throw error;
      fetchCategories();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to delete category');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-bold text-[#1D102F]">ប្រភេទរឿង (Categories)</h2>
          <p className="text-xs text-[#635C6E]">គ្រប់គ្រងប្រភេទរឿង និងលំដាប់លំដោយបង្ហាញលើ App</p>
        </div>
        <button
          onClick={openCreateModal}
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold shadow-md transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4 text-[#C89B3C]" />
          <span>បង្កើតប្រភេទថ្មី (Create Category)</span>
        </button>
      </div>

      {/* Table */}
      <div className="glass-panel rounded-3xl border border-[#E2DCEB] overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-[#C89B3C]" />
          </div>
        ) : categories.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <FolderTree className="w-12 h-12 text-[#8A7B9B] mb-3" />
            <p className="font-semibold text-sm text-[#1D102F]">មិនទាន់មានប្រភេទរឿងទេ</p>
          </div>
        ) : (
          <table className="w-full text-left text-xs">
            <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
              <tr>
                <th className="py-3.5 px-4 w-14">លំដាប់</th>
                <th className="py-3.5 px-4">ឈ្មោះប្រភេទ</th>
                <th className="py-3.5 px-4">Slug</th>
                <th className="py-3.5 px-4">រូបតំណាង (Icon)</th>
                <th className="py-3.5 px-4">ស្ថានភាព</th>
                <th className="py-3.5 px-4 text-right">សកម្មភាព</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2DCEB]/60">
              {categories.map((cat) => (
                <tr key={cat.id} className="hover:bg-white/40 transition-colors">
                  <td className="py-3 px-4 font-bold text-[#8A7B9B]">
                    #{cat.sort_order}
                  </td>
                  <td className="py-3 px-4">
                    <span className="font-bold text-sm text-[#1D102F]">{cat.name}</span>
                    {cat.description && (
                      <p className="text-[11px] text-[#635C6E] truncate max-w-sm">{cat.description}</p>
                    )}
                  </td>
                  <td className="py-3 px-4 text-[#635C6E] font-mono">
                    {cat.slug}
                  </td>
                  <td className="py-3 px-4 text-[#1D102F]">
                    <span className="px-2 py-1 rounded-md bg-white border border-[#E2DCEB] font-mono text-[11px]">
                      {cat.icon_name || 'headphones'}
                    </span>
                  </td>
                  <td className="py-3 px-4">
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold ${
                        cat.is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-700'
                      }`}
                    >
                      {cat.is_active ? <Eye className="w-3 h-3" /> : <EyeOff className="w-3 h-3" />}
                      <span>{cat.is_active ? 'Active' : 'Hidden'}</span>
                    </span>
                  </td>
                  <td className="py-3 px-4 text-right">
                    <div className="flex items-center justify-end gap-1.5">
                      <button
                        onClick={() => openEditModal(cat)}
                        className="p-1.5 rounded-lg text-[#1D102F] hover:bg-white cursor-pointer"
                        title="កែប្រែ"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(cat)}
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
        )}
      </div>

      {/* Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-[#FBF9F5] border border-[#E2DCEB] rounded-3xl shadow-2xl overflow-hidden">
            <div className="px-6 py-4 border-b border-[#E2DCEB] flex items-center justify-between bg-white/70">
              <h3 className="font-bold text-base text-[#1D102F]">
                {categoryToEdit ? 'កែប្រែប្រភេទរឿង (Edit Category)' : 'បង្កើតប្រភេទថ្មី (Create Category)'}
              </h3>
              <button onClick={() => setIsModalOpen(false)} className="p-1 rounded-lg text-[#8A7B9B] hover:bg-gray-100 cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            {error && <div className="m-6 mb-0 p-3 rounded-xl bg-red-50 text-xs text-red-700">{error}</div>}

            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-[#1D102F] mb-1">ឈ្មោះប្រភេទរឿង (Name) *</label>
                <input
                  type="text"
                  value={name}
                  onChange={handleNameChange}
                  required
                  placeholder="ឧ. រឿងខ្មោចព្រាយបិសាច"
                  className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#1D102F] mb-1">Slug (URL identifier) *</label>
                <input
                  type="text"
                  value={slug}
                  onChange={(e) => setSlug(e.target.value)}
                  required
                  placeholder="khmer-ghosts"
                  className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#1D102F] mb-1">ការពិពណ៌នា (Description)</label>
                <textarea
                  rows={2}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="ការជួបប្រទះវិញ្ញាណ និងរឿងខ្មោចពិតៗ..."
                  className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-[#1D102F] mb-1">រូបតំណាង (Icon Name)</label>
                  <select
                    value={iconName}
                    onChange={(e) => setIconName(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
                  >
                    <option value="ghost">Ghost (ខ្មោច)</option>
                    <option value="book-open">Book Open (សៀវភៅ/រឿងព្រេង)</option>
                    <option value="trees">Trees (ព្រៃភ្នំ)</option>
                    <option value="search">Search (ស៊ើបអង្កេត)</option>
                    <option value="moon">Moon (ចូលគេង)</option>
                    <option value="headphones">Headphones</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-[#1D102F] mb-1">លំដាប់ (Sort Order)</label>
                  <input
                    type="number"
                    value={sortOrder}
                    onChange={(e) => setSortOrder(Number(e.target.value))}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-white border border-[#E2DCEB] text-sm text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
                  />
                </div>
              </div>

              <div className="pt-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={isActive}
                    onChange={(e) => setIsActive(e.target.checked)}
                    className="w-4 h-4 rounded text-[#1D102F] focus:ring-[#1D102F]"
                  />
                  <span className="text-xs font-semibold text-[#1D102F]">បើកដំណើរការបង្ហាញលើ App (Is Active)</span>
                </label>
              </div>

              <div className="pt-4 border-t border-[#E2DCEB] flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2.5 rounded-xl text-xs font-semibold text-[#635C6E] hover:bg-gray-100 cursor-pointer"
                >
                  បោះបង់
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="px-5 py-2.5 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white text-xs font-semibold transition-all shadow-md flex items-center gap-2 disabled:opacity-50 cursor-pointer"
                >
                  {saving ? <Loader2 className="w-3.5 h-3.5 animate-spin text-[#C89B3C]" /> : <Check className="w-3.5 h-3.5" />}
                  <span>រក្សាទុក (Save)</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
