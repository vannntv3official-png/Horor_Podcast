import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { formatDate } from '../../lib/utils';
import { useAuth } from '../auth/AuthContext';
import type { UserProfile, UserRole } from '../../types';
import { Users, Shield, Loader2, Search } from 'lucide-react';

export const UserList: React.FC = () => {
  const { user: currentUser, isAdmin } = useAuth();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*, user_roles(role)')
        .order('created_at', { ascending: false });

      if (error) throw error;

      const formatted = (data || []).map((p) => {
        const roles = (p.user_roles as { role: UserRole }[]) || [];
        const role = roles.length > 0 ? roles[0].role : 'user';
        return {
          ...p,
          role,
        };
      });

      setUsers(formatted);
    } catch (err) {
      console.error('Failed to load users:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleRoleChange = async (targetUserId: string, newRole: UserRole) => {
    if (!isAdmin) {
      alert('មានតែ Admin ប៉ុណ្ណោះដែលអាចផ្លាស់ប្តូរ Role បាន។');
      return;
    }

    setUpdatingId(targetUserId);
    try {
      // Upsert into user_roles
      const { error } = await supabase
        .from('user_roles')
        .upsert({ user_id: targetUserId, role: newRole }, { onConflict: 'user_id,role' });

      if (error) throw error;

      // Clean up previous conflicting roles if downgrading
      if (newRole !== 'admin') {
        await supabase
          .from('user_roles')
          .delete()
          .eq('user_id', targetUserId)
          .neq('role', newRole);
      }

      // Log audit
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

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      !search.trim() ||
      (u.display_name && u.display_name.toLowerCase().includes(search.toLowerCase())) ||
      u.id.toLowerCase().includes(search.toLowerCase());

    const matchesRole = roleFilter === 'all' || u.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-base font-bold text-[#1D102F]">អ្នកប្រើប្រាស់ និងសិទ្ធិ (User Roles & Access)</h2>
          <p className="text-xs text-[#635C6E]">ត្រួតពិនិត្យបញ្ជីអ្នកប្រើប្រាស់ និងកំណត់សិទ្ធិ Admin ឬ Editor</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
            <input
              type="text"
              placeholder="ស្វែងរកតាមឈ្មោះ ឬ User ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9 pr-4 py-2 rounded-xl bg-white border border-[#E2DCEB] text-xs text-[#1D102F] focus:outline-none focus:ring-2 focus:ring-[#1D102F] w-56 sm:w-64"
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
        </div>
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
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[650px]">
              <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
                <tr>
                  <th className="py-3.5 px-4">ឈ្មោះបង្ហាញ</th>
                  <th className="py-3.5 px-4">User ID</th>
                  <th className="py-3.5 px-4">ភាសា</th>
                  <th className="py-3.5 px-4">ថ្ងៃបង្កើត</th>
                  <th className="py-3.5 px-4">តួនាទី (Role)</th>
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
                      <td className="py-3 px-4 uppercase font-semibold text-[#635C6E]">
                        {u.preferred_language || 'km'}
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
