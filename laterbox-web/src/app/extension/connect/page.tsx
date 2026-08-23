'use client';

import React, { useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { useAuth } from '@/lib/store/AuthContext';
import { getSupabaseClient } from '@/lib/supabase/client';
import { CheckCircle, AlertCircle, Loader2 } from 'lucide-react';

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

      if (response.error) {
        const msg =
          response.error.message ||
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
      <div className="min-h-screen flex items-center justify-center bg-[#f7f5ee]">
        <Loader2 className="w-8 h-8 text-[#171711] animate-spin" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 bg-[#f7f5ee] text-[#171711]">
        <div className="w-full max-w-md bg-white rounded-3xl p-8 border border-[#e4e0d5] shadow-2xl text-center space-y-6">
          <div className="w-12 h-12 mx-auto relative rounded-2xl overflow-hidden bg-[#e6edb0] p-2">
            <Image src="/branding/laterbox-icon.png" alt="laterbox" fill className="object-contain p-1" />
          </div>
          <div className="space-y-2">
            <h1 className="text-xl font-bold">Sign in to connect extension</h1>
            <p className="text-xs text-[#6c6b63]">
              You must be logged into laterbox to authorize your browser extension.
            </p>
          </div>
          <Link
            href="/login"
            className="w-full inline-flex items-center justify-center py-2.5 px-4 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-xs cursor-pointer"
          >
            <span>Sign In to LaterBox</span>
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-[#f7f5ee] text-[#171711]">
      <div className="w-full max-w-md bg-white rounded-3xl p-8 border border-[#e4e0d5] shadow-2xl space-y-6">
        <div className="text-center space-y-3">
          <div className="w-12 h-12 mx-auto relative rounded-2xl overflow-hidden bg-[#e6edb0] p-2">
            <Image src="/branding/laterbox-icon.png" alt="laterbox" fill className="object-contain p-1" />
          </div>
          <h1 className="text-2xl font-black tracking-tight text-[#171711]">Connect Browser Extension</h1>
          <p className="text-xs text-[#6c6b63]">
            Authorize the laterbox browser extension to save links directly to{' '}
            <strong className="text-[#171711]">{user.email}</strong>.
          </p>
        </div>

        {error && (
          <div className="p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {!isValidRequest && (
          <div className="p-3.5 rounded-2xl bg-amber-50 border border-amber-200 text-amber-800 text-xs font-medium">
            This authorization link is missing required request parameters.
          </div>
        )}

        <div className="space-y-3 pt-2">
          <button
            onClick={handleApprove}
            disabled={busy || !isValidRequest}
            className="w-full inline-flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] disabled:opacity-50 text-white font-bold text-sm shadow-sm transition-all cursor-pointer"
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
            className="w-full inline-flex items-center justify-center py-2.5 px-4 rounded-xl text-[#6c6b63] hover:text-[#171711] text-xs font-semibold"
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
        <div className="min-h-screen flex items-center justify-center bg-[#f7f5ee]">
          <Loader2 className="w-8 h-8 text-[#171711] animate-spin" />
        </div>
      }
    >
      <ExtensionConnectContent />
    </Suspense>
  );
}
