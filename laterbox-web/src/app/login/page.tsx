'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { Mail, Lock, Sparkles, Compass, AlertCircle, CheckCircle, Loader2 } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const { signInWithOtp, signInWithPassword, signUpWithPassword, continueAsGuest } = useAuth();

  const [mode, setMode] = useState<'otp' | 'password' | 'signup'>('otp');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;

    setLoading(true);
    setError(null);
    setMessage(null);

    try {
      if (mode === 'otp') {
        const { error: err } = await signInWithOtp(email.trim());
        if (err) throw err;
        setMessage('Magic login link sent! Check your email to sign in.');
      } else if (mode === 'password') {
        const { error: err } = await signInWithPassword(email.trim(), password);
        if (err) throw err;
        router.push('/inbox');
      } else if (mode === 'signup') {
        const { error: err } = await signUpWithPassword(email.trim(), password);
        if (err) throw err;
        setMessage('Account created! Check your email to confirm your account.');
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Authentication failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleGuest = () => {
    continueAsGuest();
    router.push('/inbox');
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 sm:p-6 bg-zinc-50 text-zinc-900">
      <div className="w-full max-w-md bg-white rounded-3xl p-7 sm:p-9 shadow-2xl border border-zinc-200/80 space-y-7">
        {/* Header */}
        <div className="text-center space-y-2">
          <Link href="/" className="inline-block">
            <div className="w-12 h-12 mx-auto relative rounded-2xl overflow-hidden shadow-sm">
              <Image src="/branding/laterbox-icon.png" alt="laterbox" fill className="object-contain" priority />
            </div>
          </Link>
          <h1 className="text-2xl font-black tracking-tight text-zinc-900">
            {mode === 'signup' ? 'Create your account' : 'Welcome to laterbox'}
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500">
            {mode === 'otp'
              ? 'Enter your email for a passwordless sign-in link'
              : mode === 'password'
              ? 'Sign in with your email and password'
              : 'Sign up to sync your captures across all devices'}
          </p>
        </div>

        {/* Alerts */}
        {error && (
          <div className="p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-600 text-xs font-semibold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {message && (
          <div className="p-3.5 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-semibold flex items-center gap-2">
            <CheckCircle className="w-4 h-4 shrink-0" />
            <span>{message}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-zinc-500 mb-1.5">
              Email Address
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-zinc-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                className="w-full pl-10 pr-4 py-2.5 text-sm bg-zinc-50 border border-zinc-200 rounded-xl text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            </div>
          </div>

          {(mode === 'password' || mode === 'signup') && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-zinc-500 mb-1.5">
                Password
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-zinc-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-4 py-2.5 text-sm bg-zinc-50 border border-zinc-200 rounded-xl text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full inline-flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 disabled:opacity-50 text-white font-extrabold text-sm shadow-md transition-all"
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Processing…</span>
              </>
            ) : mode === 'otp' ? (
              <>
                <Sparkles className="w-4 h-4" />
                <span>Send Magic Link</span>
              </>
            ) : mode === 'signup' ? (
              <span>Create Account</span>
            ) : (
              <span>Sign In</span>
            )}
          </button>
        </form>

        {/* Mode Toggles */}
        <div className="flex items-center justify-center gap-4 text-xs font-bold text-zinc-500">
          {mode === 'otp' ? (
            <button onClick={() => setMode('password')} className="hover:text-emerald-600">
              Sign in with password
            </button>
          ) : (
            <button onClick={() => setMode('otp')} className="hover:text-emerald-600">
              Sign in with magic link
            </button>
          )}
          <span>•</span>
          {mode === 'signup' ? (
            <button onClick={() => setMode('otp')} className="hover:text-emerald-600">
              Already have an account? Sign in
            </button>
          ) : (
            <button onClick={() => setMode('signup')} className="hover:text-emerald-600">
              Create an account
            </button>
          )}
        </div>

        {/* Guest Mode Divider */}
        <div className="pt-2 border-t border-zinc-200/80 space-y-3">
          <button
            onClick={handleGuest}
            className="w-full inline-flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl bg-zinc-100 hover:bg-zinc-200 text-zinc-700 font-bold text-xs transition-all"
          >
            <Compass className="w-4 h-4 text-zinc-500" />
            <span>Continue as Guest (No account required)</span>
          </button>
        </div>
      </div>
    </div>
  );
}
