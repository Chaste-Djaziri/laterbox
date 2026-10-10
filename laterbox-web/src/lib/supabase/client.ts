import { clerkAuthEnabled } from '../auth/config';
import { getAccessToken } from '../auth/tokens';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const SUPABASE_URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ltjisrgldssqskcylcbj.supabase.co';

const SUPABASE_ANON_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  'sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p';

let browserClient: SupabaseClient | null = null;

export function getLegacySupabaseClient(): SupabaseClient {
  if (typeof window === 'undefined') {
    return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: false },
    });
  }

  if (!browserClient) {
    browserClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        storage: window.localStorage,
      },
    });
  }

  return browserClient;
}

let clerkClient: SupabaseClient | null = null;
export function getSupabaseClient(): SupabaseClient {
  if (!clerkAuthEnabled) return getLegacySupabaseClient();
  if (typeof window === 'undefined') return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { accessToken: () => getAccessToken() });
  return clerkClient ??= createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { accessToken: () => getAccessToken() });
}

export const supabase = new Proxy({} as SupabaseClient, {
  get(_target, prop) {
    if (prop === 'then' || prop === '__esModule' || prop === '$$typeof' || typeof prop === 'symbol') {
      return undefined;
    }
    const client = getSupabaseClient();
    const value = (client as any)[prop];
    return typeof value === 'function' ? value.bind(client) : value;
  },
});
