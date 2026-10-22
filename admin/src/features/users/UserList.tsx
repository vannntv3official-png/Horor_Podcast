import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { formatDate } from '../../lib/utils';
import { useAuth } from '../auth/AuthContext';
import type { UserProfile, UserRole } from '../../types';
import {
  Users,
  Shield,
  Loader2,
  Search,
  AlertCircle,
  RefreshCw,
  Copy,
  Check,
  Database,
  Crown,
} from 'lucide-react';

export const UserList: React.FC = () => {
  const { user: currentUser, isAdmin } = useAuth();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [vipFilter, setVipFilter] = useState<string>('all');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [copiedSql, setCopiedSql] = useState(false);

  const syncSqlCode = `-- Run this in Supabase Dashboard -> SQL Editor to sync all users and setup VIP:
INSERT INTO public.profiles (id, display_name, preferred_language)
SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'display_name', split_part(email, '@', 1)), 
    'km'
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
    display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name);

INSERT INTO public.user_roles (user_id, role)
SELECT id, 'user'
FROM auth.users
ON CONFLICT (user_id, role) DO NOTHING;`;

  const fetchUsers = async () => {
    setLoading(true);
    setErrorMessage(null);
    try {
      // 1. Auto-ensure current logged-in admin has a row in public.profiles
      if (currentUser) {
        await supabase
          .from('profiles')
          .upsert(
            {
              id: currentUser.id,
              display_name:
                currentUser.user_metadata?.display_name ||
                currentUser.email?.split('@')[0] ||
                'Admin',
              preferred_language: 'km',
            },
            { onConflict: 'id' }
          );
      }

      // 2. Fetch profiles
      const { data: profilesData, error: profilesError } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });

      if (profilesError) throw profilesError;

      // 3. Fetch user roles in parallel
      const { data: rolesData, error: rolesError } = await supabase
        .from('user_roles')
        .select('user_id, role');

      if (rolesError) {
        console.warn('Could not fetch roles from user_roles:', rolesError.message);
      }

      // 4. Map user roles to user IDs
      const roleMap = new Map<string, UserRole>();
      (rolesData || []).forEach((r) => {
        const existing = roleMap.get(r.user_id);
        if (!existing || r.role === 'admin' || (r.role === 'editor' && existing === 'user')) {
          roleMap.set(r.user_id, r.role as UserRole);
        }
      });

      // 5. Build user list from profiles
      const formatted: UserProfile[] = (profilesData || []).map((p) => ({
        ...p,
        role: roleMap.get(p.id) || 'user',
        is_vip: Boolean(p.is_vip),
      }));

      // 6. If any users exist in user_roles but not yet in profiles, include them as fallbacks
      const existingProfileIds = new Set(formatted.map((p) => p.id));
      (rolesData || []).forEach((r) => {
        if (!existingProfileIds.has(r.user_id)) {
          existingProfileIds.add(r.user_id);
          formatted.push({
            id: r.user_id,
            display_name:
              r.user_id === currentUser?.id
                ? currentUser?.email?.split('@')[0] || 'Admin'
                : 'User (Auth Registered)',
            avatar_path: null,
            preferred_language: 'km',
            notifications_enabled: true,
            role: r.role as UserRole,
            is_vip: false,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          });
        }
      });

      setUsers(formatted);
    } catch (err: unknown) {
      console.error('Failed to load users:', err);
      setErrorMessage(
        (err as Error).message ||
          'មិនអាចទាញយកបញ្ជីអ្នកប្រើប្រាស់បានទេ។ សូមប្រាកដថាគណនីរបស់អ្នកមានសិទ្ធិជា Admin ក្នុង Supabase។'
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [currentUser]);

  const handleRoleChange = async (targetUserId: string, newRole: UserRole) => {
    if (!isAdmin) {
      alert('មានតែ Admin ប៉ុណ្ណោះដែលអាចផ្លាស់ប្តូរ Role បាន។');
      return;
    }

    setUpdatingId(targetUserId);
    try {
      const { error } = await supabase
        .from('user_roles')
        .upsert({ user_id: targetUserId, role: newRole }, { onConflict: 'user_id,role' });

      if (error) throw error;

      await supabase
        .from('user_roles')
        .delete()
        .eq('user_id', targetUserId)
        .neq('role', newRole);

      await supabase.from('admin_audit_logs').insert({
        actor_user_id: currentUser?.id,
        action: 'UPDATE_USER_ROLE',
        entity_type: 'user_roles',
        entity_id: targetUserId,
        metadata: { assigned_role: newRole },
      });

      fetchUsers();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to update role');
    } finally {
      setUpdatingId(null);
    }
  };

  const handleToggleVip = async (user: UserProfile) => {
    if (!isAdmin) {
      alert('មានតែ Admin ប៉ុណ្ណោះដែលអាចកែប្រែសិទ្ធិ VIP បាន។');
      return;
    }

    setUpdatingId(user.id);
    try {
      const nextVip = !user.is_vip;
      const expiresAt = nextVip
        ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
        : null;

      const { error } = await supabase
        .from('profiles')
        .update({
          is_vip: nextVip,
          vip_expires_at: expiresAt,
        })
        .eq('id', user.id);

      if (error) throw error;

      await supabase.from('admin_audit_logs').insert({
        actor_user_id: currentUser?.id,
        action: nextVip ? 'GRANT_VIP' : 'REVOKE_VIP',
        entity_type: 'profiles',
        entity_id: user.id,
        metadata: { is_vip: nextVip, expires_at: expiresAt },
      });

      fetchUsers();
    } catch (err: unknown) {
      alert((err as Error).message || 'Failed to update VIP status');
    } finally {
      setUpdatingId(null);
    }
  };

  const copySqlToClipboard = () => {
    navigator.clipboard.writeText(syncSqlCode);
    setCopiedSql(true);
    setTimeout(() => setCopiedSql(false), 2500);
  };

  const vipUsersCount = users.filter((u) => u.is_vip).length;

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      !search.trim() ||
      (u.display_name && u.display_name.toLowerCase().includes(search.toLowerCase())) ||
      u.id.toLowerCase().includes(search.toLowerCase());

    const matchesRole = roleFilter === 'all' || u.role === roleFilter;
    const matchesVip =
      vipFilter === 'all' ||
      (vipFilter === 'vip' && u.is_vip) ||
      (vipFilter === 'free' && !u.is_vip);

    return matchesSearch && matchesRole && matchesVip;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-[#1D102F]">អ្នកប្រើប្រាស់ & VIP Membership</h2>
            <span className="px-2.5 py-0.5 rounded-full bg-amber-100 text-amber-900 font-bold text-[11px] flex items-center gap-1">
              <Crown className="w-3 h-3 text-[#C89B3C]" />
              <span>{vipUsersCount} VIPs</span>
            </span>
          </div>
          <p className="text-xs text-[#635C6E]">ត្រួតពិនិត្យបញ្ជីអ្នកប្រើប្រាស់ កំណត់ Role និងបើកសិទ្ធិ VIP</p>
        </div>

        <div className="flex items-center flex-wrap gap-2.5">
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
            <input
              type="text"
              placeholder="ស្វែងរកតាមឈ្មោះ ឬ ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9 pr-4 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F] w-48 sm:w-56"
            />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-3 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
          >
            <option value="all">Role ទាំងអស់ ({users.length})</option>
            <option value="admin">Admin</option>
            <option value="editor">Editor</option>
            <option value="user">User</option>
          </select>

          <select
            value={vipFilter}
            onChange={(e) => setVipFilter(e.target.value)}
            className="px-3 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F]"
          >
            <option value="all">គម្រោងទាំងអស់</option>
            <option value="vip">👑 VIP សកម្ម ({vipUsersCount})</option>
            <option value="free">សមាជិកធម្មតា ({users.length - vipUsersCount})</option>
          </select>

          <button
            onClick={fetchUsers}
            className="p-2 rounded-xl bg-white border border-[#E2DCEB] text-[#1D102F] hover:bg-gray-50 transition-colors cursor-pointer"
            title="Refresh Users"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {errorMessage && (
        <div className="p-4 rounded-2xl bg-amber-50 border border-amber-300 text-xs text-amber-900 flex items-start justify-between gap-3 shadow-sm">
          <div className="flex items-start gap-2.5">
            <AlertCircle className="w-5 h-5 flex-shrink-0 text-amber-600 mt-0.5" />
            <div>
              <p className="font-bold text-amber-950 mb-0.5">បញ្ហាក្នុងការទាញយកអ្នកប្រើប្រាស់</p>
              <p>{errorMessage}</p>
            </div>
          </div>
          <button
            onClick={fetchUsers}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white border border-amber-300 font-semibold text-[#1D102F] hover:bg-amber-100 transition-colors cursor-pointer flex-shrink-0"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>ព្យាយាមម្តងទៀត</span>
          </button>
        </div>
      )}

      {/* Sync Users Notice Banner */}
      <div className="p-4 rounded-2xl bg-[#EDE8F5]/60 border border-[#E2DCEB] flex flex-col md:flex-row md:items-center justify-between gap-3">
        <div className="flex items-start gap-2.5">
          <Database className="w-5 h-5 text-[#C89B3C] flex-shrink-0 mt-0.5" />
          <div className="text-xs">
            <p className="font-bold text-[#1D102F]">ធ្វើសមកាលកម្មគណនី (Sync Users from Supabase Auth)</p>
            <p className="text-[#635C6E]">
              ប្រសិនបើមានអ្នកប្រើប្រាស់ទើបចុះឈ្មោះក្នុង Auth តែមិនទាន់បង្ហាញក្នុង Profiles សូមចម្លងកូដ SQL នេះទៅ Run ក្នុង Supabase SQL Editor។
            </p>
          </div>
        </div>
        <button
          onClick={copySqlToClipboard}
          className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs font-semibold text-[#1D102F] hover:bg-gray-50 transition-colors cursor-pointer shadow-xs flex-shrink-0"
        >
          {copiedSql ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5 text-[#C89B3C]" />}
          <span>{copiedSql ? 'បានចម្លងរួច!' : 'ចម្លងកូដ SQL (Copy)'}</span>
        </button>
      </div>

      <div className="glass-panel rounded-3xl border border-[#E2DCEB] overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-[#C89B3C]" />
          </div>
        ) : filteredUsers.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <Users className="w-12 h-12 text-[#8A7B9B] mb-3" />
            <p className="font-semibold text-sm text-[#1D102F]">មិនមានអ្នកប្រើប្រាស់ត្រូវតាមលក្ខខណ្ឌទេ</p>
            <p className="text-xs text-[#8A7B9B] mt-1 max-w-md">
              {users.length === 0
                ? 'មិនទាន់មានទិន្នន័យក្នុងតារាង profiles ទេ។ សូមចុច "ចម្លងកូដ SQL" ខាងលើ រួច Run ក្នុង Supabase Dashboard ដើម្បី Sync គណនីទាំងអស់ភ្លាមៗ។'
                : 'សូមសាកល្បងផ្លាស់ប្តូរពាក្យស្វែងរក ឬ Filter។'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[760px]">
              <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
                <tr>
                  <th className="py-3.5 px-4">ឈ្មោះបង្ហាញ</th>
                  <th className="py-3.5 px-4">User ID</th>
                  <th className="py-3.5 px-4">ស្ថានភាព VIP</th>
                  <th className="py-3.5 px-4">ថ្ងៃបង្កើត</th>
                  <th className="py-3.5 px-4">តួនាទី (Role)</th>
                  <th className="py-3.5 px-4 text-right">សកម្មភាព VIP</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E2DCEB]/60">
                {filteredUsers.map((u) => {
                  const isSelf = u.id === currentUser?.id;
                  const isUpdating = updatingId === u.id;
                  return (
                    <tr key={u.id} className="hover:bg-white/40 transition-colors">
                      <td className="py-3 px-4 font-bold text-[#1D102F]">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded-full bg-[#1D102F] text-[#C89B3C] text-xs font-bold flex items-center justify-center">
                            {u.display_name?.[0]?.toUpperCase() || 'U'}
                          </div>
                          <span>{u.display_name || 'Anonymous User'}</span>
                          {isSelf && (
                            <span className="text-[10px] text-[#C89B3C] font-semibold">(You)</span>
                          )}
                        </div>
                      </td>
                      <td className="py-3 px-4 text-[#8A7B9B] font-mono text-[11px]">
                        {u.id}
                      </td>
                      <td className="py-3 px-4">
                        {u.is_vip ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-amber-100 text-amber-900 font-bold text-[10px] border border-amber-300">
                            <Crown className="w-3 h-3 text-[#C89B3C]" />
                            <span>VIP Member</span>
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-full bg-gray-100 text-gray-600 font-medium text-[10px]">
                            ធម្មតា (Free)
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-[#635C6E]">
                        {formatDate(u.created_at)}
                      </td>
                      <td className="py-3 px-4">
                        {isUpdating ? (
                          <Loader2 className="w-4 h-4 animate-spin text-[#C89B3C]" />
                        ) : (
                          <div className="flex items-center gap-2">
                            <Shield className="w-3.5 h-3.5 text-[#8A7B9B]" />
                            <select
                              value={u.role || 'user'}
                              disabled={!isAdmin || isSelf}
                              onChange={(e) => handleRoleChange(u.id, e.target.value as UserRole)}
                              className="px-2.5 py-1 rounded-lg bg-white border border-[#E2DCEB] text-xs font-semibold text-[#1D102F] focus:outline-none focus:ring-1 focus:ring-[#1D102F] disabled:opacity-60 cursor-pointer"
                            >
                              <option value="user">User (អ្នកស្តាប់)</option>
                              <option value="editor">Editor (អ្នករៀបរៀង)</option>
                              <option value="admin">Admin (អ្នកគ្រប់គ្រង)</option>
                            </select>
                          </div>
                        )}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <button
                          onClick={() => handleToggleVip(u)}
                          disabled={!isAdmin || isUpdating}
                          className={`px-3 py-1.5 rounded-xl text-[11px] font-bold transition-all cursor-pointer inline-flex items-center gap-1 shadow-xs disabled:opacity-50 ${
                            u.is_vip
                              ? 'bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200'
                              : 'bg-amber-50 text-amber-800 hover:bg-amber-100 border border-amber-300'
                          }`}
                        >
                          <Crown className="w-3 h-3 text-[#C89B3C]" />
                          <span>{u.is_vip ? 'ដកសិទ្ធិ VIP' : 'ផ្តល់ VIP ៣០ថ្ងៃ'}</span>
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
