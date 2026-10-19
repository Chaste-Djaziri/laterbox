'use client';

import { useEffect, useState } from 'react';
import { Apple, CheckCircle2, Loader2 } from 'lucide-react';
import { getSupabaseClient } from '@/lib/supabase/client';

type Provider = 'google' | 'apple';
type ConnectedIdentity = { provider: Provider; email?: string };
type PendingLink = { provider: Provider; userId: string };

const PENDING_KEY = 'laterbox_pending_identity_link';

function GoogleMark() {
  return <svg aria-hidden="true" viewBox="0 0 24 24" className="size-5 shrink-0">
    <path fill="#4285F4" d="M21.35 12.23c0-.72-.06-1.42-.18-2.09H12v3.96h5.24a4.48 4.48 0 0 1-1.94 2.94v2.45h3.14c1.84-1.69 2.91-4.18 2.91-7.26Z" />
    <path fill="#34A853" d="M12 21.5c2.63 0 4.84-.87 6.45-2.36l-3.14-2.45c-.87.58-1.98.92-3.31.92-2.54 0-4.7-1.72-5.47-4.03H3.29v2.53A9.74 9.74 0 0 0 12 21.5Z" />
    <path fill="#FBBC05" d="M6.53 13.58A5.85 5.85 0 0 1 6.22 12c0-.55.1-1.08.31-1.58V7.89H3.29A9.5 9.5 0 0 0 2.25 12c0 1.48.36 2.88 1.04 4.11l3.24-2.53Z" />
    <path fill="#EA4335" d="M12 6.39c1.43 0 2.71.49 3.72 1.46l2.79-2.79C16.84 3.49 14.63 2.5 12 2.5a9.74 9.74 0 0 0-8.71 5.39l3.24 2.53c.77-2.31 2.93-4.03 5.47-4.03Z" />
  </svg>;
}

export function connectionResult(pending: PendingLink, userId: string, identities: ConnectedIdentity[]): string {
  if (pending.userId !== userId) return 'The account changed during connection. Your original LaterBox account was not confirmed; sign back in to it and try again.';
  if (!identities.some((identity) => identity.provider === pending.provider)) return `Could not connect ${pending.provider === 'apple' ? 'Apple' : 'Google'}. Please try again.`;
  return `${pending.provider === 'apple' ? 'Apple' : 'Google'} is connected to your LaterBox account.`;
}

export function ConnectedSignIns({ userId }: { userId: string }) {
  const [identities, setIdentities] = useState<ConnectedIdentity[]>([]);
  const [loading, setLoading] = useState(true);
  const [connecting, setConnecting] = useState<Provider | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    const load = async () => {
      setLoading(true);
      const { data, error } = await getSupabaseClient().auth.getUserIdentities();
      if (!active) return;
      if (error) {
        setMessage('Could not load connected sign-in methods. Please reload Settings.');
        setLoading(false);
        return;
      }
      const connected = (data?.identities ?? [])
        .filter((identity): identity is typeof identity & { provider: Provider } => identity.provider === 'google' || identity.provider === 'apple')
        .map((identity) => ({ provider: identity.provider, email: typeof identity.identity_data?.email === 'string' ? identity.identity_data.email : undefined }));
      setIdentities(connected);
      const params = new URLSearchParams(window.location.search);
      const returnedProvider = params.get('connect');
      if (returnedProvider === 'google' || returnedProvider === 'apple') {
        const stored = sessionStorage.getItem(PENDING_KEY);
        sessionStorage.removeItem(PENDING_KEY);
        let pending: PendingLink | null = null;
        try { pending = stored ? JSON.parse(stored) as PendingLink : null; } catch { /* stale data */ }
        const providerError = params.get('error_description');
        setMessage(providerError || (pending?.provider === returnedProvider
          ? connectionResult(pending, userId, connected)
          : 'Connection could not be verified. Please try again.'));
        const cleanUrl = new URL(window.location.href);
        cleanUrl.searchParams.delete('connect');
        cleanUrl.searchParams.delete('error');
        cleanUrl.searchParams.delete('error_description');
        window.history.replaceState(null, '', cleanUrl.pathname + cleanUrl.search + cleanUrl.hash);
      }
      setLoading(false);
    };
    void load();
    return () => { active = false; };
  }, [userId]);

  const connect = async (provider: Provider) => {
    setConnecting(provider);
    setMessage(null);
    try {
      const client = getSupabaseClient();
      const { data: current, error: userError } = await client.auth.getUser();
      if (userError || current.user?.id !== userId) {
        setMessage('Your session changed. Please reload Settings and try again.');
        return;
      }
      sessionStorage.setItem(PENDING_KEY, JSON.stringify({ provider, userId } satisfies PendingLink));
      const { data, error } = await client.auth.linkIdentity({
        provider,
        options: { redirectTo: `${window.location.origin}/settings?connect=${provider}`, skipBrowserRedirect: true },
      });
      if (error || !data?.url) throw error || new Error(`Could not start ${provider === 'apple' ? 'Apple' : 'Google'} connection.`);
      window.location.assign(data.url);
    } catch (error) {
      sessionStorage.removeItem(PENDING_KEY);
      setMessage(error instanceof Error ? error.message : 'Connection could not start. Please try again.');
    } finally {
      setConnecting(null);
    }
  };

  return <div className="border-t border-[#e4e0d5] pt-5 space-y-3">
    <div>
      <h3 className="text-sm font-extrabold text-[#171711]">Connected sign-in methods</h3>
      <p className="mt-1 text-xs text-[#6c6b63]">Connect another way to sign in to this same LaterBox account.</p>
    </div>
    {(['google', 'apple'] as const).map((provider) => {
      const linked = identities.find((identity) => identity.provider === provider);
      const label = provider === 'google' ? 'Google' : 'Apple';
      return <div key={provider} className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-[#e4e0d5] bg-[#faf8f2] px-4 py-3">
        <div className="flex min-w-0 items-center gap-3">
          {provider === 'google' ? <GoogleMark /> : <Apple className="size-5 shrink-0 text-[#171711]" aria-hidden="true" />}
          <div className="min-w-0">
            <p className="text-sm font-bold text-[#171711]">{label}</p>
            <p className="truncate text-xs text-[#6c6b63]">{linked?.email || (linked ? 'Connected' : 'Not connected')}</p>
          </div>
        </div>
        {linked ? <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700"><CheckCircle2 className="size-4" />Connected</span>
          : <button type="button" disabled={loading || connecting !== null} onClick={() => void connect(provider)} className="inline-flex items-center gap-2 rounded-xl bg-[#171711] px-3.5 py-2 text-xs font-bold text-white disabled:opacity-50 cursor-pointer">
            {connecting === provider && <Loader2 className="size-3.5 animate-spin" />}
            Connect {label}
          </button>}
      </div>;
    })}
    {message && <p role="status" className="text-xs font-semibold text-[#6c6b63]">{message}</p>}
  </div>;
}
