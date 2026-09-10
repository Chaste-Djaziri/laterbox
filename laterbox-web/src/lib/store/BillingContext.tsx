'use client';

import { initializePaddle, type Environments, type Paddle } from '@paddle/paddle-js';
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { FREE_ENTITLEMENT, hasProAccess, type Entitlement } from '@/lib/billing/types';
import { useAuth } from './AuthContext';

type Interval = 'month' | 'year';
type CheckoutState = 'idle' | 'processing' | 'confirmed' | 'delayed';
type BillingContextValue = {
  entitlement: Entitlement;
  isPro: boolean;
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  subscribe: (interval: Interval) => Promise<void>;
  manage: () => Promise<void>;
  checkoutState: CheckoutState;
  previewPrices: (priceIds: string[]) => Promise<Record<string, string>>;
};

const BillingContext = createContext<BillingContextValue | null>(null);

export function BillingProvider({ children }: { children: React.ReactNode }) {
  const { user, session } = useAuth();
  const [entitlement, setEntitlement] = useState<Entitlement>(FREE_ENTITLEMENT);
  const [paddle, setPaddle] = useState<Paddle>();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [checkoutState, setCheckoutState] = useState<CheckoutState>('idle');
  const cacheKey = user ? `laterbox_entitlement_${user.id}` : null;

  const refresh = useCallback(async () => {
    if (!session?.access_token || !user) {
      setEntitlement(FREE_ENTITLEMENT);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/billing/entitlement', {
        headers: { Authorization: `Bearer ${session.access_token}` },
        cache: 'no-store',
      });
      if (!response.ok) throw new Error('Unable to refresh subscription status.');
      const value = (await response.json()) as Entitlement;
      setEntitlement(value);
      localStorage.setItem(`laterbox_entitlement_${user.id}`, JSON.stringify(value));
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Unable to refresh subscription status.');
    } finally {
      setLoading(false);
    }
  }, [session?.access_token, user]);

  useEffect(() => {
    if (!cacheKey) {
      setEntitlement(FREE_ENTITLEMENT);
      return;
    }
    try {
      const cached = localStorage.getItem(cacheKey);
      setEntitlement(cached ? (JSON.parse(cached) as Entitlement) : FREE_ENTITLEMENT);
    } catch {
      setEntitlement(FREE_ENTITLEMENT);
    }
    void refresh();
  }, [cacheKey, refresh]);

  const pollForPro = useCallback(async () => {
    if (!session?.access_token || !user) return;
    setCheckoutState('processing');
    for (let attempt = 0; attempt < 8; attempt += 1) {
      await new Promise((resolve) => window.setTimeout(resolve, attempt === 0 ? 800 : 1500));
      try {
        const response = await fetch('/api/billing/entitlement', {
          headers: { Authorization: `Bearer ${session.access_token}` },
          cache: 'no-store',
        });
        if (!response.ok) continue;
        const value = (await response.json()) as Entitlement;
        setEntitlement(value);
        localStorage.setItem(`laterbox_entitlement_${user.id}`, JSON.stringify(value));
        if (hasProAccess(value)) {
          setCheckoutState('confirmed');
          return;
        }
      } catch {
        // Paddle webhooks are retried; keep polling without changing access.
      }
    }
    setCheckoutState('delayed');
  }, [session?.access_token, user]);

  useEffect(() => {
    const onFocus = () => void refresh();
    window.addEventListener('focus', onFocus);
    document.addEventListener('visibilitychange', onFocus);
    return () => {
      window.removeEventListener('focus', onFocus);
      document.removeEventListener('visibilitychange', onFocus);
    };
  }, [refresh]);

  useEffect(() => {
    const environment = (process.env.NEXT_PUBLIC_PADDLE_ENV || 'sandbox') as Environments;
    const token = environment === 'production'
      ? process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD || process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN
      : process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN;
    if (!token) return;
    initializePaddle({
      token,
      environment,
      eventCallback: (event) => {
        if (event.name === 'checkout.completed') void pollForPro();
      },
    }).then((instance) => instance && setPaddle(instance));
  }, [pollForPro]);

  const authenticatedRequest = useCallback(
    async (path: string, init?: RequestInit) => {
      if (!session?.access_token) throw new Error('Sign in to manage LaterBox Pro.');
      const response = await fetch(path, {
        ...init,
        headers: {
          Authorization: `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
          ...init?.headers,
        },
      });
      const payload = (await response.json()) as { error?: string; transactionId?: string; url?: string };
      if (!response.ok) throw new Error(payload.error || 'Billing request failed.');
      return payload;
    },
    [session?.access_token]
  );

  const subscribe = useCallback(
    async (interval: Interval) => {
      setError(null);
      if (!paddle) throw new Error('Checkout is not configured yet.');
      const result = await authenticatedRequest('/api/billing/checkout', {
        method: 'POST',
        body: JSON.stringify({ interval }),
      });
      if (!result.transactionId) throw new Error('Checkout transaction was not created.');
      paddle.Checkout.open({
        transactionId: result.transactionId,
        settings: { variant: 'one-page', successUrl: `${window.location.origin}/pricing?checkout=success` },
      });
    },
    [authenticatedRequest, paddle]
  );

  const manage = useCallback(async () => {
    const result = await authenticatedRequest('/api/billing/portal', { method: 'POST', body: '{}' });
    if (!result.url) throw new Error('Subscription portal was not created.');
    window.location.assign(result.url);
  }, [authenticatedRequest]);

  const previewPrices = useCallback(async (priceIds: string[]) => {
    if (!paddle || priceIds.length === 0) return {};
    const response = await paddle.PricePreview({
      items: priceIds.map((priceId) => ({ priceId, quantity: 1 })),
    });
    return response.data.details.lineItems.reduce<Record<string, string>>((values, item) => {
      values[item.price.id] = item.formattedTotals.total;
      return values;
    }, {});
  }, [paddle]);

  const value = useMemo(
    () => ({ entitlement, isPro: hasProAccess(entitlement), loading, error, refresh, subscribe, manage, checkoutState, previewPrices }),
    [entitlement, loading, error, refresh, subscribe, manage, checkoutState, previewPrices]
  );
  return <BillingContext.Provider value={value}>{children}</BillingContext.Provider>;
}

export function useBilling() {
  const value = useContext(BillingContext);
  if (!value) throw new Error('useBilling must be used within BillingProvider.');
  return value;
}
