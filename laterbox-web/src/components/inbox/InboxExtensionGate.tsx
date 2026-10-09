'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { ArrowRight, CheckCircle2, Loader2, Puzzle, RefreshCw } from 'lucide-react';
import { CHROME_EXTENSION_URL, cacheExtensionConnected, extensionSessionKey, getCachedExtensionConnected, requestExtension, type ExtensionStatus } from '@/lib/extension/dashboard';
import { useAuth } from '@/lib/store/AuthContext';

type State = ExtensionStatus & { checking?: boolean };

export function InboxExtensionGate({ userId }: { userId?: string }) {
  const { session } = useAuth();
  const cacheKey = extensionSessionKey(userId, session?.access_token);
  const [state, setState] = useState<State>({ installed: false, connected: false, checking: true });
  const [connecting, setConnecting] = useState(false);
  const [error, setError] = useState('');
  const dialog = useRef<HTMLDialogElement>(null);
  const abort = useRef<AbortController | null>(null);
  const check = useCallback(async () => {
    const signal = abort.current?.signal;
    if (!signal || signal.aborted) return;
    if (getCachedExtensionConnected(cacheKey)) { setState({ installed: true, connected: true }); return; }
    try {
      const result = await requestExtension('status', userId || '', signal);
      if (signal.aborted) return;
      if (result.connected) cacheExtensionConnected(cacheKey);
      setState(result);
    } catch { /* Ignore checks cancelled by navigation or account changes. */ }
  }, [userId, cacheKey]);

  useEffect(() => {
    const controller = new AbortController();
    abort.current = controller;
    setError('');
    setConnecting(false);
    if (getCachedExtensionConnected(cacheKey)) {
      setState({ installed: true, connected: true });
      return () => controller.abort();
    }
    setState({ installed: false, connected: false, checking: true });
    void check();
    const interval = setInterval(() => { if (document.visibilityState === 'visible') void check(); }, 5000);
    window.addEventListener('focus', check);
    return () => {
      controller.abort();
      clearInterval(interval);
      window.removeEventListener('focus', check);
    };
  }, [check, cacheKey]);

  useEffect(() => {
    const element = dialog.current;
    if (state.connected || state.checking) { if (element?.open) element.close(); }
    else if (element && !element.open) element.showModal();
  }, [state.connected, state.checking]);

  const connect = async () => {
    const signal = abort.current?.signal;
    if (!signal) return;
    setConnecting(true);
    setError('');
    try {
      const result = await requestExtension('connect', userId || '', signal);
      if (signal.aborted) return;
      if (!result.installed) setError('Open the LaterBox extension popup and choose Connect. Then return here.');
      else if (result.error) setError(result.error);
      await check();
    } catch { /* Navigation cancels the request. */ }
    finally { if (!signal.aborted) setConnecting(false); }
  };

  return (
    <dialog ref={dialog} onCancel={event => event.preventDefault()} aria-labelledby="extension-setup-title"
      className="fixed inset-0 m-auto w-[calc(100%_-_2rem)] max-w-md max-h-[90dvh] overflow-y-auto rounded-3xl border border-[#e4e0d5] bg-[#f7f5ee] p-6 sm:p-8 text-[#171711] shadow-xl backdrop:bg-[#171711]/45 backdrop:backdrop-blur-sm">
      <div className="mb-5 flex size-12 items-center justify-center rounded-2xl bg-[#e6edb0]">
        <Puzzle className="size-6" aria-hidden="true" />
      </div>
      <h2 id="extension-setup-title" className="text-2xl font-bold tracking-tight">Set up your LaterBox extension</h2>
      <p className="mt-3 text-sm leading-6 text-[#6c6b63]">Install and connect the browser extension first. It’s required to use your LaterBox dashboard Inbox.</p>
      {state.checking ? (
        <p role="status" className="mt-6 flex items-center gap-2 text-sm"><Loader2 className="size-4 animate-spin" />Checking your extension…</p>
      ) : (
        <div className="mt-6 space-y-4">
          <div className="rounded-2xl border border-[#e4e0d5] bg-white p-4">
            <div className="flex items-center justify-between gap-2 text-sm font-semibold">
              <span>1. Install the extension</span>
              {state.installed && <CheckCircle2 className="size-5 text-[#39744c]" aria-label="Installed" />}
            </div>
            {!state.installed && <>
              <a href={CHROME_EXTENSION_URL} target="_blank" rel="noopener noreferrer"
                className="mt-3 flex min-h-11 items-center justify-center gap-2 rounded-xl bg-[#171711] px-4 text-sm font-semibold text-white">
                Install from Chrome Web Store <ArrowRight className="size-4" aria-hidden="true" />
              </a>
              <p className="mt-3 text-xs leading-5 text-[#6c6b63]">After installing or updating LaterBox, refresh this page so the extension can be detected.</p>
              <button onClick={() => window.location.reload()} className="mt-2 flex min-h-11 items-center gap-2 text-sm font-medium">
                <RefreshCw className="size-4" aria-hidden="true" />I’ve installed it — refresh
              </button>
              <Link href="/downloads" className="text-xs underline text-[#6c6b63]">Using Firefox or Safari? View downloads</Link>
            </>}
          </div>
          <div className="rounded-2xl border border-[#e4e0d5] bg-white p-4">
            <p className="text-sm font-semibold">2. Connect to LaterBox</p>
            <p className="mt-2 text-xs leading-5 text-[#6c6b63]">Approve the connection with the same LaterBox account you’re using here.</p>
            <button onClick={connect} disabled={!state.installed || connecting}
              className="mt-3 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#e6edb0] px-4 text-sm font-semibold disabled:opacity-40">
              {connecting && <Loader2 className="size-4 animate-spin" aria-hidden="true" />}
              {connecting ? 'Opening connection…' : 'Connect extension'}
            </button>
            <p className="mt-2 text-xs leading-5 text-[#6c6b63]">Return here after approval. Your Inbox will unlock automatically.</p>
          </div>
          {error && <p role="alert" className="text-sm text-[#9a3e30]">{error}</p>}
          <button onClick={() => void check()} className="flex min-h-11 w-full items-center justify-center gap-2 text-sm text-[#6c6b63]">
            <RefreshCw className="size-4" aria-hidden="true" />Check connection again
          </button>
        </div>
      )}
    </dialog>
  );
}
