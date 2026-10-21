import React from 'react';
import { useAuth } from '../../features/auth/AuthContext';
import {
  LayoutDashboard,
  BookOpen,
  Headphones,
  FolderTree,
  Users,
  ScrollText,
  Settings,
  LogOut,
} from 'lucide-react';

interface SidebarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, setActiveTab }) => {
  const { user, role, logout } = useAuth();

  const navItems = [
    { id: 'dashboard', label: 'ផ្ទាំងគ្រប់គ្រង (Dashboard)', icon: LayoutDashboard },
    { id: 'stories', label: 'គ្រប់គ្រងរឿង (Stories)', icon: BookOpen },
    { id: 'episodes', label: 'គ្រប់គ្រងភាគ (Episodes)', icon: Headphones },
    { id: 'categories', label: 'ប្រភេទរឿង (Categories)', icon: FolderTree },
    { id: 'users', label: 'អ្នកប្រើប្រាស់ (Users)', icon: Users },
    { id: 'audit_logs', label: 'Audit Logs', icon: ScrollText },
    { id: 'settings', label: 'ការកំណត់ (Settings)', icon: Settings },
  ];

  return (
    <aside className="w-64 glass-panel border-r border-[#E2DCEB] flex flex-col h-screen sticky top-0">
      {/* Brand Header */}
      <div className="p-6 border-b border-[#E2DCEB]/60 flex items-center gap-3">
        <img
          src="/app_logo.png"
          alt="Khmer Horror"
          className="w-10 h-10 rounded-xl object-cover shadow-md border border-[#E2DCEB]"
        />
        <div>
          <h2 className="font-bold text-[#1D102F] text-base leading-tight">Khmer Horror</h2>
          <span className="text-[11px] font-semibold tracking-wider text-[#8A7B9B] uppercase">Admin Web</span>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl font-medium text-xs transition-all cursor-pointer ${
                isActive
                  ? 'bg-[#1D102F] text-white shadow-md shadow-purple-950/15'
                  : 'text-[#635C6E] hover:bg-white/60 hover:text-[#1D102F]'
              }`}
            >
              <Icon className={`w-4 h-4 ${isActive ? 'text-[#C89B3C]' : 'text-[#8A7B9B]'}`} />
              <span className="truncate">{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer Profile & Sign Out */}
      <div className="p-4 border-t border-[#E2DCEB]/60">
        <div className="flex items-center gap-3 mb-3 p-2 rounded-xl bg-white/60 border border-[#E2DCEB]/80">
          <div className="w-8 h-8 rounded-lg bg-[#2E1A47] text-white flex items-center justify-center text-xs font-bold">
            {user?.email?.[0].toUpperCase() || 'A'}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-[#1D102F] truncate">{user?.email}</p>
            <span className="inline-block text-[10px] font-bold text-[#C89B3C] uppercase tracking-wide">
              {role}
            </span>
          </div>
        </div>

        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl text-red-600 hover:bg-red-50 text-xs font-semibold transition-all cursor-pointer"
        >
          <LogOut className="w-3.5 h-3.5" />
          <span>ចាកចេញ (Sign Out)</span>
        </button>
      </div>
    </aside>
  );
};
