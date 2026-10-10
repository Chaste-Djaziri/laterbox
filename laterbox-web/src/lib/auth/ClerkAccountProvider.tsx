'use client';
import { useAuth as useClerkAuth, useClerk, useUser } from '@clerk/nextjs';
import { useSignIn } from '@clerk/nextjs/legacy';
import { AuthError } from '@supabase/supabase-js';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { AuthContext, type AuthContextType } from '../store/AuthContext';
import { getLegacySupabaseClient } from '../supabase/client';
import { registerClerkTokenGetter } from './tokens';
import type { AccountSession, AccountUser } from './types';
import { disableCloudNotifications, suspendCloudNotifications, resumeCloudNotifications } from '../notifications/client';
import { clearExtensionStatusCache } from '../extension/dashboard';

export function ClerkAccountProvider({ children }: { children: React.ReactNode }) {
  const { isLoaded, userId, getToken } = useClerkAuth();
  const { user: profile } = useUser();
  const clerk = useClerk();
  const { signIn, setActive } = useSignIn();
  const [user,setUser] = useState<AccountUser | null>(null);
  const [session,setSession] = useState<AccountSession | null>(null);
  const [loading,setLoading] = useState(true);
  const [isGuest,setGuest] = useState(false);
  const [authError,setAuthError] = useState<string | null>(null);
  const [attempt,setAttempt] = useState(0);
  const migration = useRef<Promise<void> | null>(null);
  const getTokenRef = useRef(getToken);
  getTokenRef.current = getToken;
  const signInRef = useRef(signIn);
  signInRef.current = signIn;
  const setActiveRef = useRef(setActive);
  setActiveRef.current = setActive;
  const userIdRef = useRef(userId);
  userIdRef.current = userId;

  const tokenGetter = useCallback(
    (refresh = false) => {
      const fn = getTokenRef.current;
      return fn ? fn({ skipCache: refresh }) : Promise.resolve(null);
    },
    []
  );

  useEffect(() => registerClerkTokenGetter(tokenGetter), [tokenGetter]);

  const migrate = useCallback(async () => {
    if (migration.current) return migration.current;
    const currentSignIn = signInRef.current;
    const currentSetActive = setActiveRef.current;
    if (!currentSignIn || !currentSetActive) return;

    migration.current = (async () => {
      try {
        const legacy = getLegacySupabaseClient();
        const { data, error } = await legacy.auth.getSession();
        if (error || !data.session) return;
        const { data: refreshed, error: refreshError } = await legacy.auth.refreshSession();
        if (refreshError || !refreshed.session) {
          await legacy.auth.signOut({ scope: 'local' }).catch(() => {});
          return;
        }
        const currentUserId = userIdRef.current;
        const proof = currentUserId ? await tokenGetter() : null;
        const response = await fetch('/api/auth/migrate', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${refreshed.session.access_token}`,
            ...(proof ? { 'X-Clerk-Token': proof } : {}),
          },
        });
        const result = (await response.json()) as { error?: string; ticket?: string; user: AccountUser };
        if (!response.ok) {
          console.warn('[auth] Legacy migration response:', result.error);
          return;
        }
        if (result.ticket) {
          const login = await currentSignIn.create({ strategy: 'ticket', ticket: result.ticket });
          if (login.status !== 'complete' || !login.createdSessionId) {
            console.warn('[auth] Legacy ticket activation incomplete:', login.status);
            return;
          }
          await currentSetActive({ session: login.createdSessionId });
        }
        await legacy.auth.signOut({ scope: 'local' });
        setAttempt(value => value + 1);
      } catch (err) {
        console.warn('[auth] Migration attempt error:', err);
      }
    })();
    try {
      await migration.current;
    } finally {
      migration.current = null;
    }
  }, [tokenGetter]);

  useEffect(() => {
    if (!isLoaded) return;
    let cancelled = false;

    setAuthError(null);
    setLoading(true);

    const initialize = async () => {
      try {
        if (!userId) {
          setUser(null);
          setSession(null);
          const savedGuest =
            typeof window !== 'undefined' &&
            (localStorage.getItem('laterbox_guest_mode') === 'true' ||
              new URLSearchParams(window.location.search).get('guest') === '1');
          if (!cancelled) {
            setGuest(savedGuest);
          }

          if (typeof window !== 'undefined') {
            const hasLegacy = Object.keys(localStorage).some(k => k.startsWith('sb-') && k.endsWith('-auth-token'));
            if (hasLegacy && (window.location.hostname.startsWith('app.') || window.location.hostname === 'localhost')) {
              void migrate().catch(() => {});
            }
          }
          return;
        }

        let token = await tokenGetter();
        if (!token) {
          await new Promise(r => setTimeout(r, 200));
          token = await tokenGetter();
        }
        if (!token) throw new Error('Your session has expired. Sign in again.');

        const response = await fetch('/api/auth/account', {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
        });
        const result = (await response.json()) as { error?: string; ticket?: string; user: AccountUser };
        if (!response.ok) throw new Error(result.error || 'Account setup could not finish.');

        if (!cancelled) {
          setUser(result.user);
          setSession({ access_token: token });
          setGuest(false);
          localStorage.removeItem('laterbox_guest_mode');
          resumeCloudNotifications();
        }
      } catch (cause) {
        if (!cancelled) {
          setAuthError(cause instanceof Error ? cause.message : 'Authentication failed.');
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    void initialize();
    return () => {
      cancelled = true;
    };
  }, [isLoaded, userId, attempt, migrate, tokenGetter]);

  // Fallback: If Clerk takes longer than 6 seconds to finish loading, release loading state
  useEffect(() => {
    if (isLoaded) return;
    const timeout = setTimeout(() => {
      setLoading(false);
    }, 6000);
    return () => clearTimeout(timeout);
  }, [isLoaded]);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    const refresh = async () => { const token = await tokenGetter().catch(() => null); if (!cancelled) setSession(token ? { access_token: token } : null); };
    const timer = setInterval(() => void refresh(),30000);
    const onFocus = () => void refresh();
    window.addEventListener('focus',onFocus);
    return () => { cancelled = true; clearInterval(timer); window.removeEventListener('focus',onFocus); };
  },[user,tokenGetter]);

  const legacy = getLegacySupabaseClient();
  const finishLegacy = async (result: { error: AuthError | null }) => {
    if (!result.error) {
      try { await migrate(); }
      catch (cause) { return { error: new AuthError(cause instanceof Error ? cause.message : 'Migration failed.') }; }
    }
    return result;
  };
  const signOut = async () => {
    suspendCloudNotifications(user?.id);
    await disableCloudNotifications().catch(() => {});
    await legacy.auth.signOut({ scope: 'local' });
    await clerk.signOut();
    clearExtensionStatusCache(); setUser(null); setSession(null); setGuest(true);
    localStorage.setItem('laterbox_guest_mode','true');
  };
  const value: AuthContextType = {
    user, session, loading, isGuest, isAuthenticated: Boolean(userId), authError, retryAuth: () => setAttempt(value => value + 1), getToken: tokenGetter,
    userName: profile?.fullName || String(user?.user_metadata.display_name || user?.email?.split('@')[0] || ''),
    setUserName: async name => { await profile?.update({ firstName: name.trim(), lastName: '' }); setAttempt(value => value + 1); },
    signInWithOtp: async email => legacy.auth.signInWithOtp({ email, options: { shouldCreateUser: false } }),
    verifyEmailOtp: async (email,token,type = 'email') => {
      const result = await legacy.auth.verifyOtp({ email,token,type });
      const finished = await finishLegacy(result); return { ...result,error: finished.error };
    },
    resendSignupOtp: async email => legacy.auth.resend({ type: 'signup',email }),
    signInWithPassword: async (email,password) => finishLegacy(await legacy.auth.signInWithPassword({ email,password })),
    signUpWithPassword: async () => ({ error: new AuthError('Create your new account with Clerk.'),requiresConfirmation: false }),
    signInWithOAuth: async () => { await clerk.openSignIn(); return { error: null }; },
    updatePassword: async () => { await clerk.openUserProfile(); return { error: null }; },
    signOut,
    deleteAccount: async () => {
      try {
        const token = await tokenGetter(true);
        if (!token) throw new Error('Sign in before deleting your account.');
        await disableCloudNotifications();
        const response = await fetch('/api/account/delete',{ method: 'POST',headers: { Authorization: `Bearer ${token}` } });
        if (!response.ok) throw new Error('Account deletion could not finish. Please retry.');
        await signOut(); localStorage.clear(); sessionStorage.clear(); return { error: null };
      } catch (cause) { return { error: cause instanceof Error ? cause : new Error('Account deletion failed.') }; }
    },
    continueAsGuest: () => { setGuest(true); localStorage.setItem('laterbox_guest_mode','true'); },
    exitGuest: () => { setGuest(false); localStorage.removeItem('laterbox_guest_mode'); },
  };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
