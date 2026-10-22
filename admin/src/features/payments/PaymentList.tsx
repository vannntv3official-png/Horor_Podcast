import React, { useEffect, useState, useMemo } from 'react';
import { supabase } from '../../lib/supabase';
import type { PaymentTransaction } from '../../types';
import { formatDate } from '../../lib/utils';
import {
  CreditCard,
  CheckCircle2,
  XCircle,
  Clock,
  Search,
  RefreshCw,
  Crown,
  DollarSign,
  ChevronRight,
} from 'lucide-react';

export const PaymentList: React.FC = () => {
  const [transactions, setTransactions] = useState<PaymentTransaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [selectedTx, setSelectedTx] = useState<PaymentTransaction | null>(null);

  const fetchTransactions = async () => {
    try {
      setLoading(true);
      // Fetch all transactions
      const { data: txData, error: txError } = await supabase
        .from('payment_transactions')
        .select('*')
        .order('created_at', { ascending: false });

      if (txError) throw txError;

      if (!txData || txData.length === 0) {
        setTransactions([]);
        return;
      }

      // Collect user IDs to lookup profiles safely
      const userIds = [...new Set(txData.map((t) => t.user_id).filter(Boolean))];
      const { data: profilesData } = await supabase
        .from('profiles')
        .select('id, display_name, avatar_path')
        .in('id', userIds);

      const profileMap = new Map<string, { display_name: string | null; avatar_path: string | null }>();
      profilesData?.forEach((p) => profileMap.set(p.id, p));

      const enriched: PaymentTransaction[] = txData.map((tx) => {
        const prof = profileMap.get(tx.user_id);
        return {
          ...tx,
          user_display_name: prof?.display_name || 'អ្នកប្រើប្រាស់',
          user_avatar: prof?.avatar_path || null,
        };
      });

      setTransactions(enriched);
    } catch (err) {
      console.error('Error fetching transactions:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();

    // Setup Supabase Realtime for instant synchronization with Mobile App
    const channel = supabase
      .channel('admin-payments-sync')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'payment_transactions' },
        () => {
          fetchTransactions();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // Approve VIP Transaction
  const handleApprove = async (tx: PaymentTransaction) => {
    if (!confirm(`តើអ្នកពិតជាចង់អនុម័ត VIP សម្រាប់ "${tx.user_display_name}" មែនទេ?`)) return;

    setActionLoadingId(tx.id);
    try {
      // 1. Try calling the RPC function first
      const { error: rpcErr } = await supabase.rpc('approve_vip_transaction', {
        p_transaction_id: tx.id,
      });

      if (rpcErr) {
        console.warn('RPC approve_vip_transaction fallback:', rpcErr);
        // Fallback: direct table updates
        const days = tx.plan_id === 'vip_1_year' ? 365 : tx.plan_id === 'vip_3_months' ? 90 : 30;
        const newExpiry = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();

        await supabase
          .from('profiles')
          .update({
            is_vip: true,
            vip_expires_at: newExpiry,
            updated_at: new Date().toISOString(),
          })
          .eq('id', tx.user_id);

        await supabase
          .from('payment_transactions')
          .update({
            status: 'approved',
            updated_at: new Date().toISOString(),
          })
          .eq('id', tx.id);
      }

      await fetchTransactions();
      if (selectedTx?.id === tx.id) {
        setSelectedTx(null);
      }
    } catch (err) {
      alert('បរាជ័យក្នុងការអនុម័ត: ' + (err as Error).message);
    } finally {
      setActionLoadingId(null);
    }
  };

  // Reject VIP Transaction
  const handleReject = async (tx: PaymentTransaction) => {
    const reason = prompt('សូមបញ្ជាក់មូលហេតុនៃការបដិសេធ (ស្រេចចិត្ត):', 'ព័ត៌មានមិនត្រឹមត្រូវ');
    if (reason === null) return;

    setActionLoadingId(tx.id);
    try {
      const { error: rpcErr } = await supabase.rpc('reject_vip_transaction', {
        p_transaction_id: tx.id,
        p_reason: reason,
      });

      if (rpcErr) {
        await supabase
          .from('payment_transactions')
          .update({
            status: 'rejected',
            admin_notes: reason,
            updated_at: new Date().toISOString(),
          })
          .eq('id', tx.id);
      }

      await fetchTransactions();
      if (selectedTx?.id === tx.id) {
        setSelectedTx(null);
      }
    } catch (err) {
      alert('បរាជ័យក្នុងការបដិសេធ: ' + (err as Error).message);
    } finally {
      setActionLoadingId(null);
    }
  };

  // Filter transactions
  const filteredTransactions = useMemo(() => {
    return transactions.filter((t) => {
      const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !q ||
        (t.transaction_ref && t.transaction_ref.toLowerCase().includes(q)) ||
        (t.user_display_name && t.user_display_name.toLowerCase().includes(q)) ||
        (t.plan_id && t.plan_id.toLowerCase().includes(q));

      return matchesStatus && matchesSearch;
    });
  }, [transactions, statusFilter, searchQuery]);

  // Statistics
  const stats = useMemo(() => {
    const totalRevenueUsd = transactions
      .filter((t) => t.status === 'approved')
      .reduce((sum, t) => sum + Number(t.amount_usd || 0), 0);

    const totalRevenueKhr = transactions
      .filter((t) => t.status === 'approved')
      .reduce((sum, t) => sum + Number(t.amount_khr || 0), 0);

    const pendingCount = transactions.filter((t) => t.status === 'pending').length;
    const approvedCount = transactions.filter((t) => t.status === 'approved').length;
    const rejectedCount = transactions.filter((t) => t.status === 'rejected').length;

    return {
      totalRevenueUsd,
      totalRevenueKhr,
      pendingCount,
      approvedCount,
      rejectedCount,
      totalOrders: transactions.length,
    };
  }, [transactions]);

  const getPlanLabel = (planId: string) => {
    switch (planId) {
      case 'vip_1_month':
        return 'VIP ១ ខែ (30 ថ្ងៃ)';
      case 'vip_3_months':
        return 'VIP ៣ ខែ (90 ថ្ងៃ)';
      case 'vip_1_year':
        return 'VIP ១ ឆ្នាំ (365 ថ្ងៃ)';
      default:
        return planId;
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner / Metrics Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Revenue */}
        <div className="glass-panel p-5 rounded-2xl border border-[#E2DCEB] bg-white flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#8A7B9B]">ប្រាក់ចំណូលសរុប (Revenue)</span>
            <div className="w-9 h-9 rounded-xl bg-amber-50 flex items-center justify-center text-[#C89B3C]">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <h3 className="text-2xl font-black text-[#1D102F]">
              ${stats.totalRevenueUsd.toFixed(2)}
            </h3>
            <p className="text-xs text-[#8A7B9B] mt-0.5">
              ≈ {stats.totalRevenueKhr.toLocaleString()} KHR
            </p>
          </div>
        </div>

        {/* Pending Orders */}
        <div className="glass-panel p-5 rounded-2xl border border-[#E2DCEB] bg-white flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#8A7B9B]">រង់ចាំការពិនិត្យ (Pending)</span>
            <div className="w-9 h-9 rounded-xl bg-amber-100/70 flex items-center justify-center text-amber-700">
              <Clock className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="flex items-baseline gap-2">
              <h3 className="text-2xl font-black text-[#1D102F]">{stats.pendingCount}</h3>
              {stats.pendingCount > 0 && (
                <span className="text-xs font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded-full">
                  ត្រូវការពិនិត្យ
                </span>
              )}
            </div>
            <p className="text-xs text-[#8A7B9B] mt-0.5">ប្រតិបត្តិការទូទាត់ថ្មី</p>
          </div>
        </div>

        {/* Approved Orders */}
        <div className="glass-panel p-5 rounded-2xl border border-[#E2DCEB] bg-white flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#8A7B9B]">បានអនុម័ត (Approved)</span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <CheckCircle2 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <h3 className="text-2xl font-black text-[#1D102F]">{stats.approvedCount}</h3>
            <p className="text-xs text-[#8A7B9B] mt-0.5">បានបើកសិទ្ធិ VIP ជោគជ័យ</p>
          </div>
        </div>

        {/* Total Orders */}
        <div className="glass-panel p-5 rounded-2xl border border-[#E2DCEB] bg-white flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-[#8A7B9B]">ប្រតិបត្តិការសរុប (Orders)</span>
            <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center text-purple-700">
              <CreditCard className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <h3 className="text-2xl font-black text-[#1D102F]">{stats.totalOrders}</h3>
            <p className="text-xs text-[#8A7B9B] mt-0.5">Bakong KHQR Transactions</p>
          </div>
        </div>
      </div>

      {/* Action Controls & Filters */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        {/* Status Filter Tabs */}
        <div className="flex items-center gap-1.5 p-1 bg-white rounded-xl border border-[#E2DCEB] self-start overflow-x-auto max-w-full">
          <button
            onClick={() => setStatusFilter('all')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
              statusFilter === 'all'
                ? 'bg-[#1D102F] text-white shadow-xs'
                : 'text-[#635C6E] hover:text-[#1D102F]'
            }`}
          >
            ទាំងអស់ ({transactions.length})
          </button>
          <button
            onClick={() => setStatusFilter('pending')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
              statusFilter === 'pending'
                ? 'bg-amber-600 text-white shadow-xs'
                : 'text-amber-800 hover:bg-amber-50'
            }`}
          >
            <Clock className="w-3.5 h-3.5" />
            រង់ចាំ ({stats.pendingCount})
          </button>
          <button
            onClick={() => setStatusFilter('approved')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
              statusFilter === 'approved'
                ? 'bg-emerald-600 text-white shadow-xs'
                : 'text-emerald-800 hover:bg-emerald-50'
            }`}
          >
            <CheckCircle2 className="w-3.5 h-3.5" />
            បានអនុម័ត ({stats.approvedCount})
          </button>
          <button
            onClick={() => setStatusFilter('rejected')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
              statusFilter === 'rejected'
                ? 'bg-rose-600 text-white shadow-xs'
                : 'text-rose-800 hover:bg-rose-50'
            }`}
          >
            <XCircle className="w-3.5 h-3.5" />
            បានបដិសេធ ({stats.rejectedCount})
          </button>
        </div>

        {/* Search & Refresh */}
        <div className="flex items-center gap-2">
          <div className="relative flex-1 sm:w-64">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
            <input
              type="text"
              placeholder="ស្វែងរក Ref ID ឬ ឈ្មោះ..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3.5 py-1.5 text-xs bg-white rounded-xl border border-[#E2DCEB] focus:outline-none focus:border-[#C89B3C]"
            />
          </div>

          <button
            onClick={fetchTransactions}
            disabled={loading}
            className="p-2 rounded-xl bg-white border border-[#E2DCEB] text-[#635C6E] hover:text-[#1D102F] hover:bg-gray-50 transition-all cursor-pointer disabled:opacity-50"
            title="Reload Transactions"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-[#C89B3C]' : ''}`} />
          </button>
        </div>
      </div>

      {/* Main Transactions Table */}
      <div className="glass-panel bg-white border border-[#E2DCEB] rounded-2xl overflow-hidden shadow-xs">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#E2DCEB] bg-[#FBF9F5]/70 text-[11px] font-bold text-[#8A7B9B] uppercase tracking-wider">
                <th className="py-3 px-4">កាលបរិច្ឆេទ & Ref ID</th>
                <th className="py-3 px-4">អ្នកប្រើប្រាស់</th>
                <th className="py-3 px-4">កញ្ចប់ VIP</th>
                <th className="py-3 px-4">ចំនួនទឹកប្រាក់</th>
                <th className="py-3 px-4">វិធីសាស្ត្រ</th>
                <th className="py-3 px-4">ស្ថានភាព</th>
                <th className="py-3 px-4 text-right">សកម្មភាព</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E2DCEB]/60 text-xs text-[#1D102F]">
              {loading && transactions.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-[#8A7B9B]">
                    <div className="flex flex-col items-center gap-2">
                      <RefreshCw className="w-6 h-6 animate-spin text-[#C89B3C]" />
                      <p>កំពុងទាញយកប្រតិបត្តិការបង់ប្រាក់...</p>
                    </div>
                  </td>
                </tr>
              ) : filteredTransactions.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-[#8A7B9B]">
                    <div className="flex flex-col items-center gap-2">
                      <CreditCard className="w-8 h-8 text-[#8A7B9B]/50" />
                      <p className="font-medium">មិនមានទិន្នន័យប្រតិបត្តិការត្រូវនឹងការស្វែងរកឡើយ</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredTransactions.map((tx) => {
                  const isActionLoading = actionLoadingId === tx.id;
                  return (
                    <tr
                      key={tx.id}
                      className="hover:bg-purple-50/20 transition-colors cursor-pointer"
                      onClick={() => setSelectedTx(tx)}
                    >
                      {/* Ref & Date */}
                      <td className="py-3.5 px-4">
                        <div className="font-mono font-bold text-[#1D102F] text-xs">
                          {tx.transaction_ref || 'N/A'}
                        </div>
                        <div className="text-[11px] text-[#8A7B9B] mt-0.5">
                          {formatDate(tx.created_at)}
                        </div>
                      </td>

                      {/* User */}
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2.5">
                          {tx.user_avatar ? (
                            <img
                              src={tx.user_avatar}
                              alt=""
                              className="w-7 h-7 rounded-full object-cover border border-[#E2DCEB]"
                            />
                          ) : (
                            <div className="w-7 h-7 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 font-bold text-[11px]">
                              {tx.user_display_name?.[0]?.toUpperCase() || 'U'}
                            </div>
                          )}
                          <div>
                            <span className="font-semibold block leading-tight">
                              {tx.user_display_name}
                            </span>
                            <span className="text-[10px] text-[#8A7B9B] font-mono">
                              {tx.user_id?.substring(0, 8)}...
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Plan */}
                      <td className="py-3.5 px-4">
                        <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-purple-50 border border-purple-200/60 text-purple-900 font-semibold text-[11px]">
                          <Crown className="w-3 h-3 text-[#C89B3C]" />
                          {getPlanLabel(tx.plan_id)}
                        </div>
                      </td>

                      {/* Amount */}
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-[#1D102F] text-sm">
                          ${Number(tx.amount_usd || 0).toFixed(2)}
                        </div>
                        <div className="text-[11px] text-[#8A7B9B]">
                          {Number(tx.amount_khr || 0).toLocaleString()} KHR
                        </div>
                      </td>

                      {/* Method */}
                      <td className="py-3.5 px-4">
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-red-50 text-red-700 font-bold text-[10px]">
                          KHQR
                        </span>
                      </td>

                      {/* Status */}
                      <td className="py-3.5 px-4">
                        {tx.status === 'approved' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-bold text-[11px] border border-emerald-200">
                            <CheckCircle2 className="w-3 h-3" />
                            បានអនុម័ត
                          </span>
                        )}
                        {tx.status === 'pending' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-amber-50 text-amber-700 font-bold text-[11px] border border-amber-200 animate-pulse">
                            <Clock className="w-3 h-3" />
                            រង់ចាំពិនិត្យ
                          </span>
                        )}
                        {tx.status === 'rejected' && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-rose-50 text-rose-700 font-bold text-[11px] border border-rose-200">
                            <XCircle className="w-3 h-3" />
                            បានបដិសេធ
                          </span>
                        )}
                      </td>

                      {/* Actions */}
                      <td
                        className="py-3.5 px-4 text-right"
                        onClick={(e) => e.stopPropagation()}
                      >
                        {tx.status === 'pending' ? (
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => handleApprove(tx)}
                              disabled={isActionLoading}
                              className="px-2.5 py-1 rounded-lg bg-emerald-600 text-white font-bold text-[11px] hover:bg-emerald-700 transition-all cursor-pointer shadow-xs disabled:opacity-50 flex items-center gap-1"
                            >
                              <CheckCircle2 className="w-3 h-3" />
                              យល់ព្រម
                            </button>
                            <button
                              onClick={() => handleReject(tx)}
                              disabled={isActionLoading}
                              className="px-2 py-1 rounded-lg bg-rose-50 text-rose-700 font-semibold text-[11px] hover:bg-rose-100 transition-all cursor-pointer border border-rose-200 disabled:opacity-50"
                            >
                              បដិសេធ
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => setSelectedTx(tx)}
                            className="p-1.5 rounded-lg text-[#8A7B9B] hover:bg-gray-100 cursor-pointer"
                            title="មើលព័ត៌មានលម្អិត"
                          >
                            <ChevronRight className="w-4 h-4" />
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Transaction Details Modal */}
      {selectedTx && (
        <div
          className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4"
          onClick={() => setSelectedTx(null)}
        >
          <div
            className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-[#E2DCEB] relative"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-4 border-b border-[#E2DCEB]">
              <div className="flex items-center gap-2">
                <Crown className="w-5 h-5 text-[#C89B3C]" />
                <h3 className="font-bold text-[#1D102F] text-base">
                  ព័ត៌មានលម្អិតប្រតិបត្តិការ VIP
                </h3>
              </div>
              <button
                onClick={() => setSelectedTx(null)}
                className="p-1 rounded-lg text-[#8A7B9B] hover:bg-gray-100 cursor-pointer"
              >
                ✕
              </button>
            </div>

            <div className="py-4 space-y-3.5 text-xs">
              <div className="flex justify-between items-center py-1 border-b border-gray-100">
                <span className="text-[#8A7B9B]">លេខសម្គាល់ Ref ID:</span>
                <span className="font-mono font-bold text-[#1D102F] text-sm">
                  {selectedTx.transaction_ref || 'N/A'}
                </span>
              </div>

              <div className="flex justify-between items-center py-1 border-b border-gray-100">
                <span className="text-[#8A7B9B]">អតិថិជន (User):</span>
                <span className="font-semibold text-[#1D102F]">
                  {selectedTx.user_display_name} ({selectedTx.user_id.slice(0, 8)})
                </span>
              </div>

              <div className="flex justify-between items-center py-1 border-b border-gray-100">
                <span className="text-[#8A7B9B]">កញ្ចប់ VIP:</span>
                <span className="font-bold text-purple-900">
                  {getPlanLabel(selectedTx.plan_id)}
                </span>
              </div>

              <div className="flex justify-between items-center py-1 border-b border-gray-100">
                <span className="text-[#8A7B9B]">ចំនួនទឹកប្រាក់:</span>
                <span className="font-bold text-base text-[#1D102F]">
                  ${Number(selectedTx.amount_usd).toFixed(2)} (
                  {Number(selectedTx.amount_khr).toLocaleString()} KHR)
                </span>
              </div>

              <div className="flex justify-between items-center py-1 border-b border-gray-100">
                <span className="text-[#8A7B9B]">កាលបរិច្ឆេទបញ្ជូន:</span>
                <span className="text-[#1D102F]">{formatDate(selectedTx.created_at)}</span>
              </div>

              <div className="flex justify-between items-center py-1 border-b border-gray-100">
                <span className="text-[#8A7B9B]">ស្ថានភាពបច្ចុប្បន្ន:</span>
                <div>
                  {selectedTx.status === 'approved' && (
                    <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-700 font-bold border border-emerald-200">
                      បានអនុម័តរួចរាល់
                    </span>
                  )}
                  {selectedTx.status === 'pending' && (
                    <span className="px-2.5 py-0.5 rounded-full bg-amber-50 text-amber-700 font-bold border border-amber-200">
                      រង់ចាំការពិនិត្យ
                    </span>
                  )}
                  {selectedTx.status === 'rejected' && (
                    <span className="px-2.5 py-0.5 rounded-full bg-rose-50 text-rose-700 font-bold border border-rose-200">
                      បានបដិសេធ
                    </span>
                  )}
                </div>
              </div>

              {selectedTx.admin_notes && (
                <div className="p-3 rounded-xl bg-gray-50 border border-gray-200 text-[#635C6E]">
                  <span className="font-semibold block text-[#1D102F]">កំណត់ចំណាំ Admin:</span>
                  <p className="mt-0.5">{selectedTx.admin_notes}</p>
                </div>
              )}
            </div>

            {/* Modal Actions */}
            <div className="flex items-center justify-end gap-2 pt-3 border-t border-[#E2DCEB]">
              <button
                onClick={() => setSelectedTx(null)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-[#635C6E] hover:bg-gray-100 cursor-pointer"
              >
                បិទ
              </button>
              {selectedTx.status === 'pending' && (
                <>
                  <button
                    onClick={() => handleReject(selectedTx)}
                    className="px-3.5 py-2 rounded-xl text-xs font-semibold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-200 cursor-pointer"
                  >
                    បដិសេធ
                  </button>
                  <button
                    onClick={() => handleApprove(selectedTx)}
                    className="px-4 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-md shadow-emerald-900/10 cursor-pointer"
                  >
                    យល់ព្រមផ្តល់ VIP
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
