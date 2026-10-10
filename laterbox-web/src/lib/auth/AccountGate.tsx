'use client';
import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth } from '../store/AuthContext';

export function AccountGate({ children }: { children: React.ReactNode }) {
  const { user, loading, isGuest } = useAuth();
  const router = useRouter();
  const path = usePathname();

  useEffect(() => {
    if (!loading && !user && !isGuest) {
      router.replace(`/login?next=${encodeURIComponent(path)}`);
    }
  }, [user, loading, isGuest, path, router]);

  if (loading) {
    return <main className="min-h-screen flex items-center justify-center" role="status">Checking your session…</main>;
  }

  if (!user && !isGuest) return null;

  return children;
}
