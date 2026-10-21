import React, { useState } from 'react';
import { Sidebar } from './Sidebar';
import { Navbar } from './Navbar';
import { DashboardOverview } from '../../features/dashboard/DashboardOverview';
import { StoryList } from '../../features/stories/StoryList';
import { EpisodeList } from '../../features/episodes/EpisodeList';
import { CategoryList } from '../../features/categories/CategoryList';
import { UserList } from '../../features/users/UserList';
import { AuditLogsList } from '../../features/audit_logs/AuditLogsList';
import { SettingsView } from '../../features/settings/SettingsView';

export const AdminLayout: React.FC = () => {
  const [activeTab, setActiveTab] = useState('dashboard');

  const getTabTitle = (tab: string) => {
    switch (tab) {
      case 'dashboard':
        return 'ផ្ទាំងគ្រប់គ្រងទូទៅ (Dashboard Overview)';
      case 'stories':
        return 'គ្រប់គ្រងរឿង (Story Management)';
      case 'episodes':
        return 'គ្រប់គ្រងភាគនិទាន (Episode Management)';
      case 'categories':
        return 'ប្រភេទរឿង (Category Management)';
      case 'users':
        return 'គ្រប់គ្រងអ្នកប្រើប្រាស់ (User Management)';
      case 'audit_logs':
        return 'កំណត់ហេតុសកម្មភាព (Audit Logs)';
      case 'settings':
        return 'ការកំណត់ប្រព័ន្ធ (System Settings)';
      default:
        return 'Admin Portal';
    }
  };

  return (
    <div className="min-h-screen flex bg-[#FBF9F5]">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />
      <div className="flex-1 flex flex-col min-w-0">
        <Navbar title={getTabTitle(activeTab)} />
        <main className="flex-1 p-8 overflow-y-auto">
          {activeTab === 'dashboard' && <DashboardOverview onNavigate={setActiveTab} />}
          {activeTab === 'stories' && <StoryList />}
          {activeTab === 'episodes' && <EpisodeList />}
          {activeTab === 'categories' && <CategoryList />}
          {activeTab === 'users' && <UserList />}
          {activeTab === 'audit_logs' && <AuditLogsList />}
          {activeTab === 'settings' && <SettingsView />}
        </main>
      </div>
    </div>
  );
};
