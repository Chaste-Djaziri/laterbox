'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { useAuth } from '@/lib/store/AuthContext';
import { getSupabaseClient } from '@/lib/supabase/client';
import { CheckCircle, AlertCircle, Loader2, KeyRound, ShieldCheck, ArrowRight, Eye, EyeOff } from 'lucide-react';

function ExtensionConnectContent() {
  const searchParams = useSearchParams();

  // State to hold parameters extracted from query or hash
  const [requestId, setRequestId] = useState('');
  const [requestSecret, setRequestSecret] = useState('');
  const [redirectUri, setRedirectUri] = useState('/extension/connected');

  const { user, loading: authLoading, signInWithPassword, signUpWithPassword } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Inline auth state for unauthenticated users
  const [authEmail, setAuthEmail] = useState('');
  const [authPassword, setAuthPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [authMode, setAuthMode] = useState<'signin' | 'signup'>('signin');
  const [authActionLoading, setAuthActionLoading] = useState(false);

  useEffect(() => {
    // 1. Try searchParams
    let reqId = searchParams.get('request_id') || searchParams.get('requestId') || '';
    let reqSec = searchParams.get('request_secret') || searchParams.get('requestSecret') || '';
    let redUri = searchParams.get('redirect_uri') || searchParams.get('redirectUri') || '';

    // 2. Fallback to parsing window.location if not found
    if (typeof window !== 'undefined') {
      const url = new URL(window.location.href);
      if (!reqId) reqId = url.searchParams.get('request_id') || url.searchParams.get('requestId') || '';
      if (!reqSec) reqSec = url.searchParams.get('request_secret') || url.searchParams.get('requestSecret') || '';
      if (!redUri) redUri = url.searchParams.get('redirect_uri') || url.searchParams.get('redirectUri') || '';

      // Check hash fragment
      if (window.location.hash && (!reqId || !reqSec)) {
        const hashParams = new URLSearchParams(window.location.hash.replace(/^#\/?/, ''));
        if (!reqId) reqId = hashParams.get('request_id') || hashParams.get('requestId') || '';
        if (!reqSec) reqSec = hashParams.get('request_secret') || hashParams.get('requestSecret') || '';
        if (!redUri) redUri = hashParams.get('redirect_uri') || hashParams.get('redirectUri') || '';
      }
    }

    setRequestId(reqId);
    setRequestSecret(reqSec);
    if (redUri) setRedirectUri(redUri);
  }, [searchParams]);

  const isValidRequest = requestId.trim().length > 0 && requestSecret.trim().length > 0;

  const handleApprove = async () => {
    if (!isValidRequest) return;
    setBusy(true);
    setError(null);

    try {
      const supabase = getSupabaseClient();
      const response = await supabase.functions.invoke('extension-connect', {
        body: {
          action: 'approve',
          request_id: requestId.trim(),
          request_secret: requestSecret.trim(),
        },
      });

      if (response.error) {
        const msg =
          response.error.message ||
          'Connection request expired or invalid. Please click Connect in the extension popup again.';
        setError(msg);
        return;
      }

      // Resolve safe redirect URL
      let targetUrl: URL;
      try {
        targetUrl = new URL(redirectUri, window.location.origin);
      } catch {
        targetUrl = new URL('/extension/connected', window.location.origin);
      }

      targetUrl.searchParams.set('request_id', requestId.trim());
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

  const handleInlineAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!authEmail.trim() || !authPassword) {
      setError('Please enter your email and password.');
      return;
    }

    setAuthActionLoading(true);
    setError(null);

    try {
      if (authMode === 'signin') {
        const { error: err } = await signInWithPassword(authEmail.trim(), authPassword);
        if (err) throw err;
      } else {
        const { error: err } = await signUpWithPassword(authEmail.trim(), authPassword);
        if (err) {
          // If already registered, attempt sign-in
          if (err.message.toLowerCase().includes('already registered') || err.message.toLowerCase().includes('already exists')) {
            const { error: signInErr } = await signInWithPassword(authEmail.trim(), authPassword);
            if (signInErr) throw signInErr;
          } else {
            throw err;
          }
        }
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Authentication failed.');
    } finally {
      setAuthActionLoading(false);
    }
  };

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f7f5ee]">
        <Loader2 className="w-8 h-8 text-[#171711] animate-spin" />
      </div>
    );
  }

  // Not signed in: show inline sign-in card so user doesn't lose request parameters
  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4 sm:p-6 bg-[#f7f5ee] text-[#171711]">
        <div className="w-full max-w-md bg-white rounded-3xl p-6 sm:p-8 border border-[#e4e0d5] shadow-xl space-y-6">
          <div className="text-center space-y-2">
            <div className="w-12 h-12 mx-auto relative rounded-2xl overflow-hidden bg-[#e6edb0] p-2 flex items-center justify-center border border-[#d0db84]">
              <Image src="/branding/laterbox-icon.png" alt="laterbox" width={32} height={32} className="object-contain" />
            </div>
            <h1 className="text-xl font-black tracking-tight text-[#171711]">Sign In to Connect Extension</h1>
            <p className="text-xs text-[#6c6b63] leading-relaxed">
              Sign in with your LaterBox account to link your browser extension.
            </p>
          </div>

          {error && (
            <div className="p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleInlineAuth} className="space-y-4">
            <div className="space-y-1.5 text-left">
              <label className="text-xs font-bold text-[#171711]">Email</label>
              <input
                type="email"
                required
                value={authEmail}
                onChange={(e) => setAuthEmail(e.target.value)}
                placeholder="you@domain.com"
                className="w-full px-3.5 py-2.5 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] text-xs font-medium focus:outline-hidden focus:border-[#171711] transition-colors"
              />
            </div>

            <div className="space-y-1.5 text-left">
              <label className="text-xs font-bold text-[#171711]">Password</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={authPassword}
                  onChange={(e) => setAuthPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] text-xs font-medium focus:outline-hidden focus:border-[#171711] transition-colors pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#9e9b92] hover:text-[#171711]"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={authActionLoading}
              className="w-full py-3 px-4 rounded-xl bg-[#171711] hover:bg-[#282723] text-white font-bold text-xs shadow-xs transition-colors cursor-pointer flex items-center justify-center gap-2"
            >
              {authActionLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <span>{authMode === 'signin' ? 'Sign In & Continue' : 'Create Account & Continue'}</span>
              )}
            </button>
          </form>

          <div className="pt-2 border-t border-[#e4e0d5] text-center">
            <button
              type="button"
              onClick={() => setAuthMode(authMode === 'signin' ? 'signup' : 'signin')}
              className="text-xs text-[#6c6b63] hover:text-[#171711] font-semibold transition-colors cursor-pointer"
            >
              {authMode === 'signin' ? "Don't have an account? Sign up" : 'Already have an account? Sign in'}
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Signed in: show connect approval card
  return (
    <div className="min-h-screen flex items-center justify-center p-4 sm:p-6 bg-[#f7f5ee] text-[#171711]">
      <div className="w-full max-w-md bg-white rounded-3xl p-6 sm:p-8 border border-[#e4e0d5] shadow-xl space-y-6 animate-in fade-in">
        <div className="text-center space-y-3">
          <div className="w-14 h-14 mx-auto relative rounded-2xl overflow-hidden bg-[#e6edb0] p-2 flex items-center justify-center border border-[#d0db84]">
            <Image src="/branding/laterbox-icon.png" alt="laterbox" width={38} height={38} className="object-contain" />
          </div>
          <h1 className="text-2xl font-black tracking-tight text-[#171711]">Connect Extension</h1>
          <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed">
            Authorize the laterbox browser extension to save links and quick captures directly to your account.
          </p>
        </div>

        {/* Account Info Pill */}
        <div className="p-3.5 rounded-2xl bg-[#ebe7dc]/50 border border-[#e4e0d5] flex items-center gap-3">
          <div className="w-8 h-8 rounded-xl bg-white border border-[#e4e0d5] flex items-center justify-center shrink-0">
            <ShieldCheck className="w-4 h-4 text-[#171711]" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-[10px] font-bold uppercase tracking-wider text-[#9e9b92]">Connected Account</p>
            <p className="text-xs font-bold text-[#171711] truncate">{user.email}</p>
          </div>
        </div>

        {error && (
          <div className="p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {!isValidRequest && (
          <div className="p-3.5 rounded-2xl bg-amber-50 border border-amber-200 text-amber-800 text-xs font-medium">
            This authorization link is missing request parameters. Please open the extension popup and click Connect.
          </div>
        )}

        <div className="space-y-2.5 pt-2">
          <button
            onClick={handleApprove}
            disabled={busy || !isValidRequest}
            className="w-full inline-flex items-center justify-center gap-2 py-3.5 px-4 rounded-2xl bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] disabled:opacity-50 text-white font-bold text-sm shadow-sm transition-all cursor-pointer"
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
