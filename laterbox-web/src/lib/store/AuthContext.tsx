'use client';

import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { User, Session, AuthError } from '@supabase/supabase-js';
import { getSupabaseClient } from '../supabase/client';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  isGuest: boolean;
  signInWithOtp: (email: string) => Promise<{ error: AuthError | null }>;
  signInWithPassword: (email: string, password: string) => Promise<{ error: AuthError | null }>;
  signUpWithPassword: (email: string, password: string) => Promise<{ error: AuthError | null }>;
  signInWithOAuth: (provider: 'google' | 'github') => Promise<{ error: AuthError | null }>;
  signOut: () => Promise<void>;
  updatePassword: (password: string) => Promise<{ error: AuthError | null }>;
  deleteAccount: () => Promise<{ error: Error | null }>;
  continueAsGuest: () => void;
  exitGuest: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const GUEST_KEY = 'laterbox_guest_mode';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [isGuest, setIsGuest] = useState(false);

  useEffect(() => {
    const supabase = getSupabaseClient();

    // Check guest mode from localStorage
    const savedGuest = localStorage.getItem(GUEST_KEY);
    if (savedGuest === 'true') {
      setIsGuest(true);
    }

    // Get current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        setIsGuest(false);
        localStorage.removeItem(GUEST_KEY);
      }
      setLoading(false);
    });

    // Listen for auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        setIsGuest(false);
        localStorage.removeItem(GUEST_KEY);
      }
      setLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const signInWithOtp = async (email: string) => {
    const supabase = getSupabaseClient();
    const redirectTo = typeof window !== 'undefined' ? `${window.location.origin}/inbox` : undefined;
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: redirectTo },
    });
    return { error };
  };

  const signInWithPassword = async (email: string, password: string) => {
    const supabase = getSupabaseClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (!error) {
      setIsGuest(false);
      localStorage.removeItem(GUEST_KEY);
    }
    return { error };
  };

  const signUpWithPassword = async (email: string, password: string) => {
    const supabase = getSupabaseClient();
    const redirectTo = typeof window !== 'undefined' ? `${window.location.origin}/inbox` : undefined;
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { emailRedirectTo: redirectTo },
    });
    if (!error) {
      setIsGuest(false);
      localStorage.removeItem(GUEST_KEY);
    }
    return { error };
  };

  const signInWithOAuth = async (provider: 'google' | 'github') => {
    const supabase = getSupabaseClient();
    const redirectTo = typeof window !== 'undefined' ? `${window.location.origin}/inbox` : undefined;
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo },
    });
    return { error };
  };

  const signOut = async () => {
    const supabase = getSupabaseClient();
    await supabase.auth.signOut();
    setUser(null);
    setSession(null);
    setIsGuest(true);
    localStorage.setItem(GUEST_KEY, 'true');
  };

  const updatePassword = async (password: string) => {
    const supabase = getSupabaseClient();
    const { error } = await supabase.auth.updateUser({ password });
    return { error };
  };

  const deleteAccount = async () => {
    try {
      const supabase = getSupabaseClient();
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (session?.access_token) {
        // Call the server deletion endpoint
        const res = await fetch('/api/account/delete', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${session.access_token}`,
          },
        });
        if (!res.ok) {
          const errData = (await res.json().catch(() => ({}))) as Record<string, any>;
          throw new Error(errData?.error || 'Failed to delete account from server');
        }
      }

      // Clear local storage and sign out
      try {
        localStorage.clear();
        sessionStorage.clear();
      } catch {}

      await supabase.auth.signOut().catch(() => {});
      setUser(null);
      setSession(null);
      setIsGuest(true);
      return { error: null };
    } catch (err: any) {
      return { error: err instanceof Error ? err : new Error(String(err)) };
    }
  };

  const continueAsGuest = () => {
    setIsGuest(true);
    localStorage.setItem(GUEST_KEY, 'true');
  };

  const exitGuest = () => {
    setIsGuest(false);
    localStorage.removeItem(GUEST_KEY);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        session,
        loading,
        isGuest,
        signInWithOtp,
        signInWithPassword,
        signUpWithPassword,
        signInWithOAuth,
        signOut,
        updatePassword,
        deleteAccount,
        continueAsGuest,
        exitGuest,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
