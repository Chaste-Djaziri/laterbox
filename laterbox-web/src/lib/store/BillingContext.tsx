'use client';

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { FREE_ENTITLEMENT, hasProAccess, type Entitlement } from '@/lib/billing/types';
import { useAuth } from './AuthContext';
import { getAccessToken } from '../auth/tokens';

type Interval = 'month' | 'year';
type CheckoutState = 'idle' | 'processing' | 'confirmed' | 'delayed';
type BillingContextValue = {
  entitlement: Entitlement;
  isPro: boolean;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  subscribe: (interval: Interval, returnTo?: string) => Promise<void>;
  manage: (action?: 'manage' | 'cancel') => Promise<void>;
  checkoutReady: boolean;
  checkoutError: string | null;
  checkoutState: CheckoutState;
  previewPrices: (priceIds: string[]) => Promise<Record<string, string>>;
};

const BillingContext = createContext<BillingContextValue | null>(null);
export function BillingProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const [entitlement, setEntitlement] = useState<Entitlement>(FREE_ENTITLEMENT);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const cacheKey = user ? `laterbox_entitlement_${user.id}` : null;

  const refresh = useCallback(async () => {
    if (!user) { setEntitlement(FREE_ENTITLEMENT); return; }
    setLoading(true);
    setError(null);
    try {
      let token = await getAccessToken();
      if (!token) throw new Error('Sign in to refresh your plan.');
      let response = await fetch('/api/billing/entitlement', {
        headers: { Authorization: `Bearer ${token}` }, cache: 'no-store',
      });
      if (response.status === 401) {
        token = await getAccessToken(true);
        if (token) response = await fetch('/api/billing/entitlement', {
          headers: { Authorization: `Bearer ${token}` }, cache: 'no-store',
        });
      }
      if (!response.ok) throw new Error('Unable to refresh subscription status.');
      const value = await response.json() as Entitlement;
      setEntitlement(value);
      localStorage.setItem(`laterbox_entitlement_${user.id}`, JSON.stringify(value));
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Unable to refresh subscription status.');
    } finally { setLoading(false); }
  }, [user?.id]);

  useEffect(() => {
    if (!cacheKey) { setEntitlement(FREE_ENTITLEMENT); return; }
    try {
      const cached = localStorage.getItem(cacheKey);
      setEntitlement(cached ? JSON.parse(cached) as Entitlement : FREE_ENTITLEMENT);
    } catch { setEntitlement(FREE_ENTITLEMENT); }
    void refresh();
  }, [cacheKey, refresh]);

  useEffect(() => {
    if (!user) return;
    const update = () => { if (document.visibilityState === 'visible') void refresh(); };
    window.addEventListener('focus', update);
    document.addEventListener('visibilitychange', update);
    return () => {
      window.removeEventListener('focus', update);
      document.removeEventListener('visibilitychange', update);
    };
  }, [refresh, user?.id]);

  const authenticatedRequest = useCallback(async (path: string, init: RequestInit) => {
    const token = await getAccessToken();
    if (!token) throw new Error('Sign in to manage your subscription.');
    const response = await fetch(path, {
      ...init, cache: 'no-store',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...init.headers },
    });
    const result = await response.json() as { url?: string; error?: string };
    if (!response.ok) throw new Error(result.error || 'Subscription request failed.');
    return result;
  }, []);

  // The payment form is embedded at /checkout. Starting here never charges the user.
  const subscribe = useCallback(async (interval: Interval, returnTo?: string) => {
    if (hasProAccess(entitlement)) throw new Error('You already have an active plan. Manage it before purchasing again.');
    const query = new URLSearchParams({ plan: 'plus', interval });
    if (returnTo) query.set('return_to', returnTo);
    window.location.assign(`/checkout?${query.toString()}`);
  }, [entitlement]);

  const manage = useCallback(async (action: 'manage' | 'cancel' = 'manage') => {
    const result = await authenticatedRequest('/api/billing/portal', {
      method: 'POST', body: JSON.stringify({ action }),
    });
    if (!result.url) throw new Error('Subscription management is unavailable.');
    window.location.assign(result.url);
  }, [authenticatedRequest]);

  // Retained for older consumers until the dedicated storage pricing page replaces Paddle display prices.
  const previewPrices = useCallback(async (_priceIds: string[]) => ({} as Record<string, string>), []);

  const value = useMemo(() => ({
    entitlement, isPro: hasProAccess(entitlement), loading, error, refresh,
    subscribe, manage, checkoutReady: true, checkoutError: null,
    checkoutState: 'idle' as CheckoutState, previewPrices,
  }), [entitlement, loading, error, refresh, subscribe, manage, previewPrices]);
  return <BillingContext.Provider value={value}>{children}</BillingContext.Provider>;
}

export function useBilling() {
  const context = useContext(BillingContext);
  if (!context) throw new Error('useBilling must be used within BillingProvider.');
  return context;
}
