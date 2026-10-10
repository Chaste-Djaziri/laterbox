import { clerkAuthEnabled } from './config';
import { getLegacySupabaseClient } from '../supabase/client';

type TokenGetter = (refresh?: boolean) => Promise<string | null>;
let clerkTokenGetter: TokenGetter | null = null;
export function registerClerkTokenGetter(getter: TokenGetter): () => void {
  clerkTokenGetter = getter;
  return () => { if (clerkTokenGetter === getter) clerkTokenGetter = null; };
}
export async function getAccessToken(refresh = false): Promise<string | null> {
  if (clerkAuthEnabled) return clerkTokenGetter?.(refresh) ?? null;
  const client = getLegacySupabaseClient();
  const { data, error } = refresh ? await client.auth.refreshSession() : await client.auth.getSession();
  if (error) throw error;
  return data.session?.access_token ?? null;
}
export async function refreshAccessToken(): Promise<{ error: unknown }> {
  try { return { error: await getAccessToken(true) ? null : new Error('Sign in to continue.') }; }
  catch (error) { return { error }; }
}
