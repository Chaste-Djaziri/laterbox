// laterbox-web/src/lib/billing/use-whop-prices.ts
'use client';

import { useEffect, useState } from 'react';
import { WHOP_PLAN_KEYS, type WhopPriceCatalog } from './whop-prices';

export function useWhopPrices() {
  const [retryCount, setRetryCount] = useState(0);
  const [state, setState] = useState<{
    prices: WhopPriceCatalog | null;
    loading: boolean;
    error: string | null;
  }>({ prices: null, loading: true, error: null });

  useEffect(() => {
    const controller = new AbortController();
    const load = async () => {
      try {
        const response = await fetch('/api/billing/prices', {
          signal: controller.signal,
          cache: 'no-store',
        });
        const body = await response.json() as {
          prices?: WhopPriceCatalog;
          error?: string;
        };
        if (!response.ok || !body.prices ||
          !WHOP_PLAN_KEYS.every(key => Number.isFinite(body.prices?.[key]?.renewalPrice) &&
            Boolean(body.prices?.[key]?.currency))) {
          throw new Error(body.error ?? 'Unable to load current Whop prices.');
        }
        if (!controller.signal.aborted) setState({ prices: body.prices, loading: false, error: null });
      } catch (error) {
        if (!controller.signal.aborted) {
          setState({
            prices: null,
            loading: false,
            error: error instanceof Error ? error.message : 'Unable to load live pricing.',
          });
        }
      }
    };
    void load();
    return () => controller.abort();
  }, [retryCount]);

  return { ...state, retry: () => {
    setState({ prices: null, loading: true, error: null });
    setRetryCount(count => count + 1);
  } };
}
