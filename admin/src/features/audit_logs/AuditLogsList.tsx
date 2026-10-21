import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { formatDate } from '../../lib/utils';
import type { AuditLog } from '../../types';
import { ScrollText, Loader2 } from 'lucide-react';

export const AuditLogsList: React.FC = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('admin_audit_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      setLogs((data as AuditLog[]) || []);
    } catch (err) {
      console.error('Failed to load audit logs:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-base font-bold text-[#1D102F]">កំណត់ហេតុសកម្មភាពរដ្ឋបាល (Admin Audit Logs)</h2>
        <p className="text-xs text-[#635C6E]">តាមដានរាល់ការបង្កើត កែប្រែ ឬលុបទិន្នន័យដោយ Admin និង Editor (Immutable Audit Trail)</p>
      </div>

      <div className="glass-panel rounded-3xl border border-[#E2DCEB] overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-[#C89B3C]" />
          </div>
        ) : logs.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <ScrollText className="w-12 h-12 text-[#8A7B9B] mb-3" />
            <p className="font-semibold text-sm text-[#1D102F]">មិនទាន់មានកំណត់ហេតុទេ</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs min-w-[650px]">
            <thead className="bg-white/60 border-b border-[#E2DCEB] text-[#635C6E] uppercase font-semibold tracking-wider">
              <tr>
                <th className="py-3.5 px-4">សកម្មភាព (Action)</th>
                <th className="py-3.5 px-4">Entity Type</th>
                <th className="py-3.5 px-4">Actor ID</th>
                <th className="py-3.5 px-4">Metadata</th>
                <th className="py-3.5 px-4 text-right">កាលបរិច្ឆេទ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2DCEB]/60">
              {logs.map((log) => (
                <tr key={log.id} className="hover:bg-white/40 transition-colors">
                  <td className="py-3 px-4 font-bold text-[#1D102F]">
                    <span className="px-2.5 py-1 rounded-md bg-[#EDE8F5] text-[#1D102F] font-mono text-[11px]">
                      {log.action}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-[#635C6E] font-medium capitalize">
                    {log.entity_type}
                  </td>
                  <td className="py-3 px-4 text-[#8A7B9B] font-mono text-[11px]">
                    {log.actor_user_id || 'System'}
                  </td>
                  <td className="py-3 px-4">
                    <pre className="text-[10px] text-[#635C6E] bg-white/60 p-1 rounded max-w-xs truncate">
                      {JSON.stringify(log.metadata)}
                    </pre>
                  </td>
                  <td className="py-3 px-4 text-right text-[#635C6E]">
                    {formatDate(log.created_at)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      </div>
    </div>
  );
};
