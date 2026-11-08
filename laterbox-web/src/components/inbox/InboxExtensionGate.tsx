'use client';

import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { ArrowRight, CheckCircle2, Loader2, Puzzle, RefreshCw, X } from 'lucide-react';
import { CHROME_EXTENSION_URL, cacheExtensionConnected, extensionSessionKey, getCachedExtensionConnected, requestExtension, type ExtensionStatus } from '@/lib/extension/dashboard';
import { useAuth } from '@/lib/store/AuthContext';

type State = ExtensionStatus & { checking?: boolean };

export interface ExtensionGateRenderState {
  disconnected: boolean;
  openSetup: () => void;
}

/** Retains connection checks and setup dialog, but delegates notices to a general renderer. */
export function InboxExtensionGate({
  userId,
  children,
}: {
  userId?: string;
  children: (state: ExtensionGateRenderState) => ReactNode;
}) {
  const { session } = useAuth();
  const cacheKey = extensionSessionKey(userId, session?.access_token);
  const [state, setState] = useState<State>({ installed: false, connected: false, checking: true });
  const [connecting, setConnecting] = useState(false);
  const [error, setError] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
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

  // Synchronize modal state with dialog element
  useEffect(() => {
    const element = dialog.current;
    if (!element) return;
    if (modalOpen) {
      if (!element.open) element.showModal();
    } else {
      if (element.open) element.close();
    }
  }, [modalOpen]);

  // If extension becomes connected while modal is open, close it
  useEffect(() => {
    if (state.connected && modalOpen) {
      setModalOpen(false);
    }
  }, [state.connected, modalOpen]);

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

  const handleDialogClick = (e: React.MouseEvent<HTMLDialogElement>) => {
    // Close modal if user clicks the backdrop outside the dialog box
    if (e.target === dialog.current) {
      setModalOpen(false);
    }
  };

  return (
    <>
      {children({
        disconnected: !state.connected && !state.checking,
        openSetup: () => setModalOpen(true),
      })}

      {/* 2. Extension Setup Modal (Opens on Click) */}
      <dialog
        ref={dialog}
        onCancel={() => setModalOpen(false)}
        onClick={handleDialogClick}
        aria-labelledby="extension-setup-title"
        className="fixed inset-0 m-auto w-[calc(100%_-_2rem)] max-w-md max-h-[90dvh] overflow-y-auto rounded-3xl border border-[#e4e0d5] bg-[#f7f5ee] p-6 sm:p-8 text-[#171711] shadow-xl backdrop:bg-[#171711]/45 backdrop:backdrop-blur-sm"
      >
        <div className="flex items-start justify-between gap-4 mb-3">
          <div className="flex size-12 items-center justify-center rounded-2xl bg-[#e6edb0]">
            <Puzzle className="size-6" aria-hidden="true" />
          </div>
          <button
            type="button"
            onClick={() => setModalOpen(false)}
            title="Close"
            className="p-1.5 rounded-xl text-[#6c6b63] hover:text-[#171711] hover:bg-[#e4e0d5]/60 transition-colors cursor-pointer"
          >
            <X className="size-5" />
          </button>
        </div>

        <h2 id="extension-setup-title" className="text-2xl font-bold tracking-tight">
          Set up your LaterBox extension
        </h2>
        <p className="mt-2 text-sm leading-6 text-[#6c6b63]">
          Connect the browser extension to enable instant 1-click web captures from Chrome, Firefox, and Safari.
        </p>

        {state.checking ? (
          <p role="status" className="mt-6 flex items-center gap-2 text-sm text-[#6c6b63]">
            <Loader2 className="size-4 animate-spin text-[#171711]" />
            Checking your extension…
          </p>
        ) : (
          <div className="mt-6 space-y-4">
            <div className="rounded-2xl border border-[#e4e0d5] bg-white p-4">
              <div className="flex items-center justify-between gap-2 text-sm font-semibold">
                <span>1. Install the extension</span>
                {state.installed && (
                  <CheckCircle2 className="size-5 text-[#39744c]" aria-label="Installed" />
                )}
              </div>
              {!state.installed && (
                <>
                  <a
                    href={CHROME_EXTENSION_URL}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-3 flex min-h-11 items-center justify-center gap-2 rounded-xl bg-[#171711] px-4 text-sm font-semibold text-white hover:bg-[#2b2a22] transition-colors"
                  >
                    Install from Chrome Web Store{' '}
                    <ArrowRight className="size-4" aria-hidden="true" />
                  </a>
                  <p className="mt-3 text-xs leading-5 text-[#6c6b63]">
                    After installing or updating LaterBox, refresh this page so the extension can be detected.
                  </p>
                  <button
                    type="button"
                    onClick={() => window.location.reload()}
                    className="mt-2 flex min-h-11 items-center gap-2 text-sm font-medium hover:text-[#171711] transition-colors cursor-pointer"
                  >
                    <RefreshCw className="size-4" aria-hidden="true" />
                    I’ve installed it — refresh
                  </button>
                  <Link
                    href="/downloads"
                    className="text-xs underline text-[#6c6b63] hover:text-[#171711]"
                  >
                    Using Firefox or Safari? View downloads
                  </Link>
                </>
              )}
            </div>

            <div className="rounded-2xl border border-[#e4e0d5] bg-white p-4">
              <p className="text-sm font-semibold">2. Connect to LaterBox</p>
              <p className="mt-2 text-xs leading-5 text-[#6c6b63]">
                Approve the connection with the same LaterBox account you’re using here.
              </p>
              <button
                type="button"
                onClick={connect}
                disabled={!state.installed || connecting}
                className="mt-3 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#e6edb0] px-4 text-sm font-semibold text-[#171711] hover:bg-[#dce39e] transition-colors disabled:opacity-40 cursor-pointer disabled:cursor-not-allowed"
              >
                {connecting && <Loader2 className="size-4 animate-spin" aria-hidden="true" />}
                {connecting ? 'Opening connection…' : 'Connect extension'}
              </button>
              <p className="mt-2 text-xs leading-5 text-[#6c6b63]">
                Return here after approval. Your status will update automatically.
              </p>
            </div>

            {error && <p role="alert" className="text-sm text-[#9a3e30]">{error}</p>}

            <div className="flex items-center justify-between gap-2 pt-1">
              <button
                type="button"
                onClick={() => void check()}
                className="flex min-h-10 items-center justify-center gap-2 text-sm text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
              >
                <RefreshCw className="size-4" aria-hidden="true" />
                Check again
              </button>
              <button
                type="button"
                onClick={() => setModalOpen(false)}
                className="px-4 py-2 text-sm font-medium text-[#6c6b63] hover:text-[#171711] rounded-xl hover:bg-[#e4e0d5]/40 transition-colors cursor-pointer"
              >
                Maybe later
              </button>
            </div>
          </div>
        )}
      </dialog>
    </>
  );
}
