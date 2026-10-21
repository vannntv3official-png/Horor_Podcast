import React, { useState } from 'react';
import { useAuth } from './AuthContext';
import { Lock, Mail, AlertCircle, Loader2 } from 'lucide-react';

export const LoginForm: React.FC = () => {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('សូមបញ្ចូលអ៊ីមែល និងពាក្យសម្ងាត់');
      return;
    }

    setError(null);
    setLoading(true);
    const res = await login(email, password);
    setLoading(false);

    if (!res.success) {
      setError(res.error || 'ការចូលគណនីមិនជោគជ័យទេ។ សូមពិនិត្យឡើងវិញ។');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-[#FBF9F5]">
      <div className="w-full max-w-md glass-panel p-8 rounded-3xl shadow-xl border border-[#E2DCEB]">
        <div className="flex flex-col items-center mb-8">
          <img
            src="/app_logo.png"
            alt="Khmer Horror Podcast"
            className="w-20 h-20 rounded-2xl object-cover mb-4 shadow-lg shadow-purple-950/20 border border-[#E2DCEB]"
          />
          <h1 className="text-2xl font-bold text-[#1D102F] text-center">Khmer Horror Podcast</h1>
          <p className="text-sm text-[#635C6E] text-center mt-1">Admin & Content Management Portal</p>
        </div>

        {error && (
          <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 flex items-start gap-3 text-red-800 text-sm">
            <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5 text-red-600" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-[#1D102F] uppercase tracking-wider mb-1.5">
              Email Address
            </label>
            <div className="relative">
              <Mail className="w-5 h-5 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@khmerhorror.com"
                required
                className="w-full pl-11 pr-4 py-3 rounded-xl bg-white/80 border border-[#E2DCEB] focus:outline-none focus:ring-2 focus:ring-[#1D102F] text-sm text-[#1D102F]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[#1D102F] uppercase tracking-wider mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-5 h-5 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#8A7B9B]" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                className="w-full pl-11 pr-4 py-3 rounded-xl bg-white/80 border border-[#E2DCEB] focus:outline-none focus:ring-2 focus:ring-[#1D102F] text-sm text-[#1D102F]"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3.5 px-4 mt-2 rounded-xl bg-[#1D102F] hover:bg-[#2E1A47] text-white font-semibold text-sm transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50 cursor-pointer"
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin text-[#C89B3C]" />
                <span>កំពុងផ្ទៀងផ្ទាត់...</span>
              </>
            ) : (
              <span>ចូលផ្ទាំងគ្រប់គ្រង (Sign In)</span>
            )}
          </button>
        </form>

        <div className="mt-8 text-center text-xs text-[#9B94A6]">
          Protected by Row Level Security and RBAC authorization.
        </div>
      </div>
    </div>
  );
};
