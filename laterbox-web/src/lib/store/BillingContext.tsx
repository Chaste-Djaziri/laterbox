'use client';

import { initializePaddle, type Environments, type Paddle } from '@paddle/paddle-js';
import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { FREE_ENTITLEMENT, hasProAccess, type Entitlement } from '@/lib/billing/types';
import { loadCheckout, checkoutSuccessUrl, CHECKOUT_CONFIGURATION_ERROR, CHECKOUT_LOADING_ERROR } from '@/lib/billing/checkout';
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
  const { user, session } = useAuth();
  const [entitlement, setEntitlement] = useState<Entitlement>(FREE_ENTITLEMENT);
  const [paddle, setPaddle] = useState<Paddle>();
  const [checkoutError, setCheckoutError] = useState<string | null>(null);
  const paddleInitialization = useRef<Promise<Paddle | undefined> | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [checkoutState, setCheckoutState] = useState<CheckoutState>('idle');
  const cacheKey = user ? `laterbox_entitlement_${user.id}` : null;

  const refresh = useCallback(async () => {
    if (!user) {
      setEntitlement(FREE_ENTITLEMENT);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      let token = await getAccessToken();
      if (!token) { setEntitlement(FREE_ENTITLEMENT); return; }

      let response = await fetch('/api/billing/entitlement', {
        headers: { Authorization: `Bearer ${token}` },
        cache: 'no-store',
      });

      if (response.status === 401) {
        token = await getAccessToken(true);
        if (token) {
          response = await fetch('/api/billing/entitlement', {
            headers: { Authorization: `Bearer ${token}` },
            cache: 'no-store',
          });
        }
      }

      if (!response.ok) {
        if (response.status === 401) {
          setEntitlement(FREE_ENTITLEMENT);
          return;
        }
        throw new Error('Unable to refresh subscription status.');
      }
      const value = (await response.json()) as Entitlement;
      setEntitlement(value);
      localStorage.setItem(`laterbox_entitlement_${user.id}`, JSON.stringify(value));
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'Unable to refresh subscription status.');
    } finally {
      setLoading(false);
    }
  }, [session?.access_token, user?.id]);

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
  }, [cacheKey]);

  const pollForPro = useCallback(async () => {
    if (!user) return;
    setCheckoutState('processing');
    for (let attempt = 0; attempt < 8; attempt += 1) {
      await new Promise((resolve) => window.setTimeout(resolve, attempt === 0 ? 800 : 1500));
      try {
        const token = await getAccessToken();
        if (!token) break;
        const response = await fetch('/api/billing/entitlement', {
          headers: { Authorization: `Bearer ${token}` },
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
    if (new URLSearchParams(window.location.search).get('checkout') === 'success') {
      void pollForPro();
    }
  }, [pollForPro]);

  useEffect(() => {
    const onFocus = () => void refresh();
    window.addEventListener('focus', onFocus);
    document.addEventListener('visibilitychange', onFocus);
    return () => {
      window.removeEventListener('focus', onFocus);
      document.removeEventListener('visibilitychange', onFocus);
    };
  }, [refresh]);

  const pollForProRef = useRef(pollForPro);
  pollForProRef.current = pollForPro;

  useEffect(() => {
    if (window.location.origin === 'http://localhost:8080') return;
    let active = true;
    const environment = (process.env.NEXT_PUBLIC_PADDLE_ENV || 'sandbox') as Environments;
    const token = environment === 'production'
      ? process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD || process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN
      : process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN;
    if (!token) {
      setCheckoutError(CHECKOUT_CONFIGURATION_ERROR);
      return;
    }
    if (!paddleInitialization.current) {
      paddleInitialization.current = loadCheckout(() => initializePaddle({
        token,
        environment,
        eventCallback: (event) => {
          if (event.name === 'checkout.completed') void pollForProRef.current();
        },
      }));
    }
    paddleInitialization.current.then((instance) => {
      if (!instance) throw new Error('Paddle did not initialize.');
      if (active) setPaddle(instance);
    }).catch(() => {
      if (active) setCheckoutError(CHECKOUT_LOADING_ERROR);
    });
    return () => { active = false; };
  }, []);

  const authenticatedRequest = useCallback(
    async (path: string, init?: RequestInit) => {
      const token = await getAccessToken();
      if (!token) throw new Error('Sign in to manage LaterBox Pro.');
      const response = await fetch(path, {
        ...init,
        headers: {
          Authorization: `Bearer ${token}`,
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
    async (interval: Interval, returnTo?: string) => {
      setError(null);
      if (!paddle) throw new Error(checkoutError || 'Secure checkout is still loading. Please try again shortly.');
      const result = await authenticatedRequest('/api/billing/checkout', {
        method: 'POST',
        body: JSON.stringify({ interval }),
      });
      if (!result.transactionId) throw new Error('Checkout transaction was not created.');
      const successUrl = checkoutSuccessUrl(window.location.origin, window.location.pathname, interval, returnTo);
      paddle.Checkout.open({
        transactionId: result.transactionId,
        settings: { variant: 'one-page', successUrl },
      });
    },
    [authenticatedRequest, paddle, checkoutError]
  );

  const manage = useCallback(async (action: 'manage' | 'cancel' = 'manage') => {
    const result = await authenticatedRequest('/api/billing/portal', { method: 'POST', body: JSON.stringify({ action }) });
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
    () => ({ entitlement, isPro: hasProAccess(entitlement), loading, error, refresh, subscribe, manage, checkoutState, previewPrices, checkoutReady: !!paddle, checkoutError }),
    [entitlement, loading, error, refresh, subscribe, manage, checkoutState, previewPrices, paddle, checkoutError]
  );
  return <BillingContext.Provider value={value}>{children}</BillingContext.Provider>;
}

export function useBilling() {
  const value = useContext(BillingContext);
  if (!value) throw new Error('useBilling must be used within BillingProvider.');
  return value;
}
