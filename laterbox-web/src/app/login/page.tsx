'use client';

import React, { Suspense, useState } from 'react';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { Loader2, AlertCircle, CheckCircle2, Eye, EyeOff } from 'lucide-react';

export default function LoginPage() {
  return (
    <Suspense fallback={<main className="min-h-screen bg-[#f7f5ee]" aria-busy="true" />}>
      <LoginContent />
    </Suspense>
  );
}

function LoginContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const {
    signInWithOtp,
    verifyEmailOtp,
    resendSignupOtp,
    signInWithPassword,
    signUpWithPassword,
    continueAsGuest,
  } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loadingAction, setLoadingAction] = useState<'signin' | 'create' | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [otp, setOtp] = useState('');
  const [otpPurpose, setOtpPurpose] = useState<'signin' | 'signup' | null>(null);
  const requestedNext = searchParams.get('next');
  const nextPath = requestedNext?.startsWith('/') && !requestedNext.startsWith('//')
    ? requestedNext
    : '/home';

  const handleSignIn = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!email.trim() || !password) {
      setError('Please enter your email and password.');
      return;
    }

    setLoadingAction('signin');
    setError(null);
    setMessage(null);

    try {
      const { error: err } = await signInWithPassword(email.trim(), password);
      if (err) {
        throw err;
      }
      router.push(nextPath);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Invalid login credentials.');
    } finally {
      setLoadingAction(null);
    }
  };

  const handleCreateAccount = async () => {
    if (!email.trim() || !password) {
      setError('Please enter your email and password to create an account.');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }

    setLoadingAction('create');
    setError(null);
    setMessage(null);

    try {
      const { error: err, requiresConfirmation } = await signUpWithPassword(email.trim(), password);
      if (err) {
        // If user already registered, automatically attempt sign in
        if (
          err.message.toLowerCase().includes('already registered') ||
          err.message.toLowerCase().includes('already exists')
        ) {
          const { error: signInErr } = await signInWithPassword(email.trim(), password);
          if (!signInErr) {
            router.push(nextPath);
            return;
          }
        }
        throw err;
      }

      if (requiresConfirmation) {
        setOtpPurpose('signup');
        setMessage(null);
      } else {
        router.push(nextPath);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Could not create account. Please try again.');
    } finally {
      setLoadingAction(null);
    }
  };

  const handleRequestOtp = async () => {
    if (!email.trim() || !email.includes('@')) {
      setError('Enter a valid email address first.');
      return;
    }
    setLoadingAction('signin');
    setError(null);
    setMessage(null);
    const { error: err } = await signInWithOtp(email.trim());
    if (err) setError(err.message);
    else setOtpPurpose('signin');
    setLoadingAction(null);
  };

  const handleVerifyOtp = async () => {
    if (!/^\d{8}$/.test(otp)) {
      setError('Enter the eight digit code from your email.');
      return;
    }
    setLoadingAction('signin');
    setError(null);
    setMessage(null);
    const { error: err } = await verifyEmailOtp(email.trim(), otp);
    if (err) setError(err.message);
    else router.push(nextPath);
    setLoadingAction(null);
  };

  const handleResendOtp = async () => {
    setLoadingAction('signin');
    setError(null);
    setMessage(null);
    const { error: err } = otpPurpose === 'signup'
      ? await resendSignupOtp(email.trim())
      : await signInWithOtp(email.trim());
    if (err) setError(err.message);
    else setMessage('A new code was sent.');
    setLoadingAction(null);
  };

  const handleContinueWithoutAccount = () => {
    continueAsGuest();
    router.push('/home');
  };

  if (otpPurpose) {
    return (
      <OtpVerification
        email={email.trim()}
        otp={otp}
        busy={loadingAction !== null}
        error={error}
        message={message}
        signup={otpPurpose === 'signup'}
        onOtpChange={setOtp}
        onVerify={() => void handleVerifyOtp()}
        onResend={() => void handleResendOtp()}
        onBack={() => {
          setOtpPurpose(null);
          setOtp('');
          setError(null);
          setMessage(null);
        }}
      />
    );
  }

  return (
    <main className="min-h-screen bg-[#f7f5ee] flex flex-col items-center justify-center p-6 text-[#181816] selection:bg-zinc-900 selection:text-white">
      <div className="w-full max-w-[420px] flex flex-col items-center text-center">
        {/* Brand Logo */}
        <div className="relative mb-3 flex items-center justify-center">
          <Image
            src="/branding/laterbox-logo.png"
            alt="laterbox"
            width={280}
            height={75}
            className="w-56 sm:w-64 h-auto object-contain"
            priority
          />
        </div>

        {/* Subtitle / Tagline */}
        <p className="text-[15px] text-[#6b6961] font-normal tracking-normal mb-8">
          Put it here. Find it later.
        </p>

        {/* Feedback Alerts */}
        {error && (
          <div className="w-full mb-4 p-3.5 rounded-[16px] bg-red-50/90 border border-red-200 text-red-700 text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {message && (
          <div className="w-full mb-4 p-3.5 rounded-[16px] bg-emerald-50/90 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{message}</span>
          </div>
        )}

        {/* Auth Form */}
        <form onSubmit={handleSignIn} className="w-full space-y-3.5">
          <div>
            <input
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Email"
              className="w-full h-14 px-5 bg-white border border-[#e5e1d7] rounded-[18px] text-[15px] text-[#181816] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-500 transition-all font-normal"
            />
          </div>

          <div className="relative">
            <input
              type={showPassword ? 'text' : 'password'}
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password"
              className="w-full h-14 pl-5 pr-12 bg-white border border-[#e5e1d7] rounded-[18px] text-[15px] text-[#181816] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-500 transition-all font-normal"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              aria-label={showPassword ? 'Hide password' : 'Show password'}
              className="absolute right-4 top-1/2 -translate-y-1/2 p-1.5 text-[#9e9b92] hover:text-[#181816] transition-colors rounded-lg focus:outline-none"
            >
              {showPassword ? (
                <EyeOff className="w-5 h-5" />
              ) : (
                <Eye className="w-5 h-5" />
              )}
            </button>
          </div>

          {/* Sign In Button */}
          <div className="pt-1.5 space-y-3">
            <button
              type="submit"
              disabled={loadingAction !== null}
              className="w-full h-14 bg-[#181816] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-bold text-[15px] rounded-[18px] shadow-sm transition-all duration-150 flex items-center justify-center disabled:opacity-60 cursor-pointer"
            >
              {loadingAction === 'signin' ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                'Sign In'
              )}
            </button>

            <button
              type="button"
              onClick={() => void handleRequestOtp()}
              disabled={loadingAction !== null}
              className="w-full h-14 bg-white hover:bg-[#f7f5ee] border border-[#e5e1d7] text-[#181816] font-semibold text-[15px] rounded-[18px] transition-all duration-150 disabled:opacity-60 cursor-pointer"
            >
              Email me a sign in code
            </button>

            {/* Create Account Button */}
            <button
              type="button"
              onClick={handleCreateAccount}
              disabled={loadingAction !== null}
              className="w-full h-14 bg-[#f2efe6]/80 hover:bg-[#ede9dc] active:bg-[#e6e2d4] border border-[#e5e1d7] text-[#181816] font-medium text-[15px] rounded-[18px] transition-all duration-150 flex items-center justify-center disabled:opacity-60 cursor-pointer"
            >
              {loadingAction === 'create' ? (
                <Loader2 className="w-5 h-5 animate-spin text-[#181816]" />
              ) : (
                'Create account'
              )}
            </button>
          </div>

          {/* Continue without account */}
          <div className="pt-2">
            <button
              type="button"
              onClick={handleContinueWithoutAccount}
              className="text-[14px] text-[#181816] hover:text-black font-normal transition-colors cursor-pointer py-1"
            >
              Continue without account
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}

function OtpVerification({
  email,
  otp,
  busy,
  error,
  message,
  signup,
  onOtpChange,
  onVerify,
  onResend,
  onBack,
}: {
  email: string;
  otp: string;
  busy: boolean;
  error: string | null;
  message: string | null;
  signup: boolean;
  onOtpChange: (value: string) => void;
  onVerify: () => void;
  onResend: () => void;
  onBack: () => void;
}) {
  return (
    <main className="min-h-screen bg-[#f7f5ee] flex items-center justify-center p-6 text-[#181816]">
      <section className="w-full max-w-[420px] text-center" aria-labelledby="otp-title">
        <Image
          src="/branding/laterbox-logo.png"
          alt="LaterBox"
          width={280}
          height={75}
          className="mx-auto h-auto w-56"
          priority
        />
        <h1 id="otp-title" className="mt-8 text-3xl font-black tracking-tight">
          {signup ? 'Verify your account' : 'Check your email'}
        </h1>
        <p className="mt-3 text-sm leading-6 text-[#6b6961]">
          Enter the eight digit code sent to <strong>{email}</strong>.
        </p>

        {error && <p role="alert" className="mt-5 rounded-2xl border border-red-200 bg-red-50 p-3 text-sm font-semibold text-red-700">{error}</p>}
        {message && <p role="status" className="mt-5 rounded-2xl border border-emerald-200 bg-emerald-50 p-3 text-sm font-semibold text-emerald-800">{message}</p>}

        <form
          className="mt-6 space-y-3"
          onSubmit={(event) => {
            event.preventDefault();
            onVerify();
          }}
        >
          <label htmlFor="email-otp" className="sr-only">Eight digit verification code</label>
          <input
            id="email-otp"
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            autoFocus
            maxLength={8}
            pattern="[0-9]{8}"
            value={otp}
            onChange={(event) => onOtpChange(event.target.value.replace(/\D/g, '').slice(0, 8))}
            placeholder="00000000"
            className="h-16 w-full rounded-[18px] border border-[#d8d3c7] bg-white px-5 text-center text-2xl font-black tracking-[0.45em] focus:border-zinc-500 focus:outline-none focus:ring-2 focus:ring-zinc-900/10"
          />
          <button type="submit" disabled={busy || otp.length !== 8} className="flex h-14 w-full items-center justify-center rounded-[18px] bg-[#181816] text-[15px] font-bold text-white disabled:opacity-50">
            {busy ? <Loader2 className="size-5 animate-spin" /> : 'Verify code'}
          </button>
          <button type="button" disabled={busy} onClick={onResend} className="h-12 w-full text-sm font-semibold disabled:opacity-50">
            Send a new code
          </button>
          <button type="button" disabled={busy} onClick={onBack} className="h-12 w-full text-sm text-[#6b6961] disabled:opacity-50">
            Use a different email
          </button>
        </form>
      </section>
    </main>
  );
}
