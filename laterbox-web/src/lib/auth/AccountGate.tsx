'use client';
import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth } from '../store/AuthContext';
import { clerkAuthEnabled } from './config';

export function AccountGate({ children }: { children: React.ReactNode }) {
  const { user,loading,isGuest,authError,isAuthenticated,retryAuth } = useAuth();
  const router = useRouter();
  const path = usePathname();
  useEffect(() => {
    if (clerkAuthEnabled && !loading && !user && !isGuest && !authError && !isAuthenticated) router.replace(`/login?next=${encodeURIComponent(path)}`);
  },[user,loading,isGuest,authError,isAuthenticated,path,router]);
  if (!clerkAuthEnabled) return children;
  if (loading) return <main className="min-h-screen flex items-center justify-center" role="status">Checking your session…</main>;
  if (authError) return <main className="min-h-screen flex flex-col items-center justify-center gap-4 p-6"><p role="alert">{authError}</p><button onClick={retryAuth}>Retry account setup</button><a href={`/login?legacy=1&next=${encodeURIComponent(path)}`}>Link your existing account</a><a href="/login">Go to login</a></main>;
  if (!user && !isGuest) return null;
  return children;
}
