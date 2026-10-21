import React from 'react';
import { useAuth } from '../../features/auth/AuthContext';
import { ShieldCheck, Database } from 'lucide-react';

interface NavbarProps {
  title: string;
}

export const Navbar: React.FC<NavbarProps> = ({ title }) => {
  const { role } = useAuth();

  return (
    <header className="h-16 border-b border-[#E2DCEB] bg-[#FBF9F5]/80 backdrop-blur-md sticky top-0 z-30 px-8 flex items-center justify-between">
      <div>
        <h1 className="text-lg font-bold text-[#1D102F] capitalize">{title}</h1>
      </div>

      <div className="flex items-center gap-4">
        {/* Backend Connected Indicator */}
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-medium">
          <Database className="w-3.5 h-3.5 text-emerald-600" />
          <span>Supabase Online</span>
        </div>

        {/* Role Badge */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#1D102F] text-[#C89B3C] text-xs font-semibold">
          <ShieldCheck className="w-3.5 h-3.5" />
          <span className="capitalize">{role || 'User'}</span>
        </div>
      </div>
    </header>
  );
};
