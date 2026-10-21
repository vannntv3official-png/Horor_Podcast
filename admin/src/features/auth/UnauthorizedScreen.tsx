import React from 'react';
import { useAuth } from './AuthContext';
import { ShieldAlert, LogOut } from 'lucide-react';

export const UnauthorizedScreen: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-[#FBF9F5]">
      <div className="w-full max-w-md glass-panel p-8 rounded-3xl text-center border border-[#E2DCEB]">
        <div className="w-16 h-16 rounded-full bg-red-100 text-red-600 flex items-center justify-center mx-auto mb-4">
          <ShieldAlert className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-bold text-[#1D102F] mb-2">មិនមានសិទ្ធិចូលប្រើប្រាស់ទេ</h2>
        <p className="text-sm text-[#635C6E] mb-6">
          គណនី <span className="font-semibold text-[#1D102F]">{user?.email}</span> មិនមានសិទ្ធិ Admin ឬ Editor សម្រាប់គ្រប់គ្រងប្រព័ន្ធនេះឡើយ។
        </p>

        <button
          onClick={logout}
          className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-[#1D102F] text-white text-sm font-semibold hover:bg-[#2E1A47] transition-all cursor-pointer"
        >
          <LogOut className="w-4 h-4" />
          <span>ចាកចេញពីគណនី (Sign Out)</span>
        </button>
      </div>
    </div>
  );
};
