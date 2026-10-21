import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './features/auth/AuthContext';
import { LoginForm } from './features/auth/LoginForm';
import { UnauthorizedScreen } from './features/auth/UnauthorizedScreen';
import { AdminLayout } from './components/layout/AdminLayout';
import { Loader2 } from 'lucide-react';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      staleTime: 60000,
    },
  },
});

const AppContent: React.FC = () => {
  const { user, isLoading, isEditor } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#FBF9F5]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-10 h-10 animate-spin text-[#C89B3C]" />
          <p className="text-xs font-semibold text-[#1D102F]">កំពុងផ្ទៀងផ្ទាត់សិទ្ធិរដ្ឋបាល...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <LoginForm />;
  }

  if (!isEditor) {
    return <UnauthorizedScreen />;
  }

  return <AdminLayout />;
};

export const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </QueryClientProvider>
  );
};

export default App;
