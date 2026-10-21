import React from 'react';
import { useAuth } from '../../features/auth/AuthContext';
import { ShieldCheck, Database, Menu } from 'lucide-react';

interface NavbarProps {
  title: string;
  onToggleSidebar?: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ title, onToggleSidebar }) => {
  const { role } = useAuth();

  return (
    <header className="h-16 border-b border-[#E2DCEB] bg-[#FBF9F5]/90 backdrop-blur-md sticky top-0 z-30 px-4 sm:px-6 md:px-8 flex items-center justify-between gap-3">
      <div className="flex items-center gap-3 min-w-0">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            aria-label="Open navigation menu"
            className="md:hidden p-2 rounded-xl text-[#1D102F] hover:bg-[#EDE8F5] transition-colors cursor-pointer flex-shrink-0"
          >
            <Menu className="w-5 h-5" />
          </button>
        )}
        <h1 className="text-sm sm:text-base md:text-lg font-bold text-[#1D102F] truncate capitalize">
          {title}
        </h1>
      </div>

      <div className="flex items-center gap-2 sm:gap-4 flex-shrink-0">
        {/* Backend Connected Indicator */}
        <div className="flex items-center gap-1.5 px-2.5 sm:px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-800 text-[11px] sm:text-xs font-medium">
          <Database className="w-3.5 h-3.5 text-emerald-600 flex-shrink-0" />
          <span className="hidden sm:inline">Supabase Online</span>
          <span className="sm:hidden font-bold">Online</span>
        </div>

        {/* Role Badge */}
        <div className="flex items-center gap-1.5 px-2.5 sm:px-3 py-1.5 rounded-full bg-[#1D102F] text-[#C89B3C] text-[11px] sm:text-xs font-semibold">
          <ShieldCheck className="w-3.5 h-3.5 flex-shrink-0" />
          <span className="capitalize">{role || 'User'}</span>
        </div>
      </div>
    </header>
  );
};
