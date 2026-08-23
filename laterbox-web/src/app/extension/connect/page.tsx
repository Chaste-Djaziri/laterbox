'use client';

import React, { useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { useAuth } from '@/lib/store/AuthContext';
import { getSupabaseClient } from '@/lib/supabase/client';
import { Puzzle, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';

function ExtensionConnectContent() {
  const searchParams = useSearchParams();
  const requestId = searchParams.get('request_id') || '';
  const requestSecret = searchParams.get('request_secret') || '';
  const redirectUri = searchParams.get('redirect_uri') || '/extension/connected';

  const { user, loading: authLoading } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isValidRequest = requestId.length > 0 && requestSecret.length > 0;

  const handleApprove = async () => {
    if (!isValidRequest) return;
    setBusy(true);
    setError(null);

    try {
      const supabase = getSupabaseClient();
      const response = await supabase.functions.invoke('extension-connect', {
        body: {
          action: 'approve',
          request_id: requestId,
          request_secret: requestSecret,
        },
      });

      if (response.error || response.status >= 400) {
        const msg =
          response.data?.error ||
          'Connection request expired or invalid. Please click Connect in the extension again.';
        setError(msg);
        return;
      }

      // Redirect to the callback URL
      const targetUrl = new URL(redirectUri, window.location.origin);
      targetUrl.searchParams.set('request_id', requestId);
      targetUrl.searchParams.set('status', 'approved');
      window.location.href = targetUrl.toString();
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Could not connect extension. Try again from the extension popup.'
      );
    } finally {
      setBusy(false);
    }
  };

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-zinc-50 dark:bg-zinc-950">
        <Loader2 className="w-8 h-8 text-emerald-500 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100">
        <div className="w-full max-w-md bg-white dark:bg-zinc-900 rounded-3xl p-8 border border-zinc-200 dark:border-zinc-800 shadow-2xl text-center space-y-6">
          <div className="w-12 h-12 mx-auto relative">
            <Image src="/branding/laterbox-icon.png" alt="laterbox" fill className="object-contain" />
          </div>
          <div className="space-y-2">
            <h1 className="text-xl font-bold">Sign in to connect extension</h1>
            <p className="text-xs text-zinc-500">
              You must be logged into laterbox to authorize your browser extension.
            </p>
          </div>
          <Link
            href="/login"
            className="w-full inline-flex items-center justify-center py-2.5 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs"
          >
            <span>Sign In to LaterBox</span>
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-zinc-50 dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100">
      <div className="w-full max-w-md bg-white dark:bg-zinc-900 rounded-3xl p-8 border border-zinc-200/80 dark:border-zinc-800 shadow-2xl space-y-6">
        <div className="text-center space-y-3">
          <div className="w-12 h-12 mx-auto relative rounded-2xl overflow-hidden">
            <Image src="/branding/laterbox-icon.png" alt="laterbox" fill className="object-contain" />
          </div>
          <h1 className="text-2xl font-black tracking-tight">Connect Browser Extension</h1>
          <p className="text-xs text-zinc-500 dark:text-zinc-400">
            Authorize the laterbox browser extension to save links directly to{' '}
            <strong className="text-zinc-800 dark:text-zinc-200">{user.email}</strong>.
          </p>
        </div>

        {error && (
          <div className="p-3.5 rounded-2xl bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 text-red-600 dark:text-red-400 text-xs font-semibold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {!isValidRequest && (
          <div className="p-3.5 rounded-2xl bg-amber-50 dark:bg-amber-950/40 border border-amber-200 text-amber-700 dark:text-amber-300 text-xs font-medium">
            This authorization link is missing required request parameters.
          </div>
        )}

        <div className="space-y-3 pt-2">
          <button
            onClick={handleApprove}
            disabled={busy || !isValidRequest}
            className="w-full inline-flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 disabled:opacity-50 text-white font-bold text-sm shadow-md transition-all"
          >
            {busy ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Connecting…</span>
              </>
            ) : (
              <>
                <CheckCircle className="w-4 h-4" />
                <span>Approve & Connect</span>
              </>
            )}
          </button>

          <Link
            href="/inbox"
            className="w-full inline-flex items-center justify-center py-2.5 px-4 rounded-xl text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300 text-xs font-semibold"
          >
            <span>Cancel</span>
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function ExtensionConnectPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-zinc-50 dark:bg-zinc-950">
          <Loader2 className="w-8 h-8 text-emerald-500 animate-spin" />
        </div>
      }
    >
      <ExtensionConnectContent />
    </Suspense>
  );
}
