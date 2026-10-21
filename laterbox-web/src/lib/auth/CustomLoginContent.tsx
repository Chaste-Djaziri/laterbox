'use client';

import { safeReturnPath } from '@/lib/auth/config';

import React, { Suspense, useState, useEffect } from 'react';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import type { AuthContextType } from '@/lib/store/AuthContext';
import { useAuth } from '@/lib/store/AuthContext';
import type { AuthError } from '@supabase/supabase-js';
import { Loader2, AlertCircle, CheckCircle2, Eye, EyeOff, Apple } from 'lucide-react';

export type EmailStartResult = { error: AuthError | null; nextStep?: 'email' | 'signup' | 'password' };

function GoogleLogo() {
  return (
    <svg aria-hidden="true" viewBox="0 0 24 24" className="size-5 shrink-0">
      <path fill="#4285F4" d="M21.35 12.23c0-.72-.06-1.42-.18-2.09H12v3.96h5.24a4.48 4.48 0 0 1-1.94 2.94v2.45h3.14c1.84-1.69 2.91-4.18 2.91-7.26Z" />
      <path fill="#34A853" d="M12 21.5c2.63 0 4.84-.87 6.45-2.36l-3.14-2.45c-.87.58-1.98.92-3.31.92-2.54 0-4.7-1.72-5.47-4.03H3.29v2.53A9.74 9.74 0 0 0 12 21.5Z" />
      <path fill="#FBBC05" d="M6.53 13.58A5.85 5.85 0 0 1 6.22 12c0-.55.1-1.08.31-1.58V7.89H3.29A9.5 9.5 0 0 0 2.25 12c0 1.48.36 2.88 1.04 4.11l3.24-2.53Z" />
      <path fill="#EA4335" d="M12 6.39c1.43 0 2.71.49 3.72 1.46l2.79-2.79C16.84 3.49 14.63 2.5 12 2.5a9.74 9.74 0 0 0-8.71 5.39l3.24 2.53c.77-2.31 2.93-4.03 5.47-4.03Z" />
    </svg>
  );
}

export function CustomLoginContent({ actions, extra, initialMode = 'login' }: { actions?: Partial<AuthContextType> & { signInWithOtp?: (email: string) => Promise<EmailStartResult> }; extra?: React.ReactNode; initialMode?: 'login' | 'signup' }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const context = useAuth();
  const {
    user,
    loading: authLoading,
    isGuest,
    signInWithOtp,
    verifyEmailOtp,
    resendSignupOtp,
    signInWithPassword,
    signUpWithPassword,
    continueAsGuest,
    setUserName,
    signInWithOAuth,
    authError,
    retryAuth,
    isAuthenticated,
  } = { ...context,...actions };

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [otp, setOtp] = useState('');
  const [awaitingOtp, setAwaitingOtp] = useState(false);
  const [secondFactor, setSecondFactor] = useState(false);
  const [otpType, setOtpType] = useState<'email' | 'signup'>('email');
  const [awaitingPassword, setAwaitingPassword] = useState(false);
  const [awaitingName, setAwaitingName] = useState(false);
  const [displayName, setDisplayName] = useState('');
  const [authMode, setAuthMode] = useState<'login' | 'signup'>(initialMode);
  const requestedNext = searchParams.get('next');
  const nextPath = safeReturnPath(requestedNext);

  // Automatically redirect to dashboard if user is already authenticated
  useEffect(() => {
    if (!authLoading && user && !awaitingName) {
      router.replace(nextPath);
    }
  }, [authLoading, user, nextPath, router, awaitingName]);

  const handleEmailSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const cleanEmail = email.trim();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      setError('Enter a valid email address.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);

    // Try sending OTP code: if code is available (existing user), it delivers directly
    const result: EmailStartResult = await signInWithOtp(cleanEmail);
    const err = result.error;
    if (actions && err) { setError(err.message); setLoading(false); return; }
    if (result.nextStep === 'password') { setAwaitingPassword(true); setLoading(false); return; }
    if (!err) {
      setOtpType(result.nextStep === 'signup' ? 'signup' : 'email');
      setAwaitingOtp(true);
      setLoading(false);
      return;
    }

    // When code is not available (e.g. signup requires password or OTP signups disabled):
    // Prompt for password
    setAwaitingPassword(true);
    setLoading(false);
  };

  const handlePasswordSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!password || password.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);

    try {
      // First attempt signUp with password
      const passwordResult = await signUpWithPassword(email.trim(), password) as Awaited<ReturnType<AuthContextType['signUpWithPassword']>> & { secondFactor?: boolean };
      const { error: signUpErr,requiresConfirmation } = passwordResult;

      if (signUpErr) {
        const msg = signUpErr.message.toLowerCase();
        // If user already registered, attempt sign-in with password
        if (msg.includes('already registered') || msg.includes('already exists') || msg.includes('user already registered')) {
          const { error: signInErr } = await signInWithPassword(email.trim(), password);
          if (signInErr) {
            setError(signInErr.message);
            setLoading(false);
            return;
          }
          // Successfully signed in!
          return;
        } else {
          setError(signUpErr.message);
          setLoading(false);
          return;
        }
      }

      if (requiresConfirmation) {
        // Confirmation code sent!
        setAwaitingPassword(false);
        setSecondFactor(Boolean(passwordResult.secondFactor));
        setOtpType(passwordResult.secondFactor ? 'email' : 'signup');
        setAwaitingOtp(true);
        setMessage(passwordResult.secondFactor ? null : `We sent a verification code to ${email.trim()}.`);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Authentication failed.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async () => {
    const cleanOtp = otp.trim().replace(/[-\s]/g, '');
    if (cleanOtp.length < 6 || cleanOtp.length > 8) {
      setError('Enter the verification code from your email.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);
    const result = await verifyEmailOtp(email.trim(), cleanOtp, otpType) as Awaited<ReturnType<AuthContextType['verifyEmailOtp']>> & { isNewAccount?: boolean; secondFactor?: boolean };
    const { data,error: err } = result;
    if (err) {
      setError(err.message);
      setLoading(false);
      return;
    }

    if (result.secondFactor) { setSecondFactor(true); setOtp(''); setLoading(false); return; }
    if (actions) {
      setAwaitingOtp(false);
      if (result.isNewAccount) {
        setAwaitingName(true);
        setLoading(false);
      } else {
        router.replace(nextPath);
      }
      return;
    }
    const verifiedUser = data?.user;
    const existingName =
      (verifiedUser?.user_metadata?.display_name as string) ||
      (verifiedUser?.user_metadata?.name as string) ||
      (verifiedUser?.user_metadata?.full_name as string) ||
      (typeof window !== 'undefined' ? localStorage.getItem('laterbox_user_name') : null) ||
      '';

    // Check if account was newly created (created_at and last_sign_in_at within 5s)
    const isNewAccount = Boolean(
      verifiedUser?.created_at &&
      verifiedUser?.last_sign_in_at &&
      Math.abs(new Date(verifiedUser.last_sign_in_at).getTime() - new Date(verifiedUser.created_at).getTime()) < 5000
    );

    // Only ask if no name is currently saved or if this is brand new account creation
    if (!existingName.trim() || isNewAccount) {
      setAwaitingOtp(false);
      if (existingName.trim()) {
        setDisplayName(existingName.trim());
      }
      setAwaitingName(true);
      setLoading(false);
    } else {
      setAwaitingOtp(false);
      router.replace(nextPath);
    }
  };

  const handleResendOtp = async () => {
    setLoading(true);
    setError(null);
    setMessage(null);
    let err = null;
    if (otpType === 'signup') {
      const res = await resendSignupOtp(email.trim());
      err = res.error;
    } else {
      const res = await signInWithOtp(email.trim());
      err = res.error;
    }
    if (err) setError(err.message);
    else setMessage('A new code was sent.');
    setLoading(false);
  };

  const handleContinueWithoutAccount = () => {
    continueAsGuest();
    router.push('/inbox');
  };

  const handleSaveDisplayName = async (nameToSave?: string) => {
    const finalName = (nameToSave ?? displayName).trim();
    if (finalName) {
      await setUserName(finalName);
    }
    router.replace(nextPath);
  };

  const handleGoogle = async () => {
    setLoading(true); setError(null);
    const result = await signInWithOAuth('google');
    if (result.error) setError(result.error.message);
    setLoading(false);
  };

  const handleApple = async () => {
    setLoading(true); setError(null);
    const result = await signInWithOAuth('apple');
    if (result.error) setError(result.error.message);
    setLoading(false);
  };

  // If already authenticated, show redirecting state while transition completes
  if (!authLoading && user && !awaitingName) {
    return (
      <main className="min-h-screen bg-[#f7f5ee] flex flex-col items-center justify-center p-6 text-[#181816]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-6 h-6 animate-spin text-zinc-600" />
          <p className="text-sm text-zinc-600 font-medium">Redirecting to dashboard...</p>
        </div>
      </main>
    );
  }

  if (awaitingName) {
    return (
      <DisplayNameInput
        displayName={displayName}
        onChange={setDisplayName}
        onSave={() => handleSaveDisplayName(displayName)}
        onSkip={() => handleSaveDisplayName('')}
      />
    );
  }

  if (awaitingPassword) {
    return (
      <AuthLayout>
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

        {/* Title: Left-aligned */}
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2 text-white text-left">Enter your password</h1>
        <p className="text-[15px] text-white/80 font-normal tracking-normal mb-6 text-left">
          Create or enter your password for <strong className="text-white">{email.trim()}</strong> to continue.
        </p>

        {/* Password Form */}
        <form onSubmit={(e) => void handlePasswordSubmit(e)} className="w-full space-y-3.5">
          <div className="relative">
            <input
              type={showPassword ? 'text' : 'password'}
              autoComplete="current-password"
              required
              autoFocus
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password (at least 6 characters)"
              className="w-full h-14 pl-5 pr-12 bg-white rounded-[18px] text-[15px] text-[#181816] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-white/40 transition-all font-normal"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9e9b92] hover:text-[#181816] transition-colors cursor-pointer p-1"
              title={showPassword ? 'Hide password' : 'Show password'}
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>

          <div className="pt-1.5 space-y-3">
            <button
              type="submit"
              disabled={loading || password.length < 6}
              className="w-full h-14 bg-white hover:bg-zinc-100 text-[#181816] font-bold text-[15px] rounded-[18px] shadow-md transition-all duration-150 flex items-center justify-center disabled:opacity-50 cursor-pointer"
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                'Continue'
              )}
            </button>
          </div>

          {/* Back to email */}
          <div className="pt-2 text-center">
            <button
              type="button"
              onClick={() => {
                setAwaitingPassword(false);
                setPassword('');
                setError(null);
              }}
              className="text-[14px] text-white/80 hover:text-white font-normal transition-colors cursor-pointer py-1"
            >
              Use a different email
            </button>
          </div>
        </form>
      </AuthLayout>
    );
  }

  if (awaitingOtp) {
    return (
      <OtpVerification
        email={email.trim()}
        secondFactor={secondFactor}
        otp={otp}
        busy={loading}
        error={error}
        message={message}
        onOtpChange={setOtp}
        onVerify={() => void handleVerifyOtp()}
        onResend={() => void handleResendOtp()}
        onBack={() => {
          setAwaitingOtp(false);
          setSecondFactor(false);
          setAwaitingPassword(false);
          setOtp('');
          setPassword('');
          setError(null);
          setMessage(null);
        }}
      />
    );
  }

  return (
    <AuthLayout>
      {isAuthenticated && authError && <div role="alert" className="mb-4 text-sm text-red-300"><p>{authError}</p><button type="button" onClick={retryAuth} className="mt-2 underline">Retry account setup</button></div>}
      {extra}
      {/* Feedback Alerts */}
      {error && (
        <div className="w-full mb-4 p-3.5 rounded-[16px] bg-red-500/20 border border-red-400/40 text-red-200 text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {message && (
        <div className="w-full mb-4 p-3.5 rounded-[16px] bg-emerald-500/20 border border-emerald-400/40 text-emerald-200 text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
          <CheckCircle2 className="w-4 h-4 shrink-0" />
          <span>{message}</span>
        </div>
      )}

      {/* Mode Selector */}
      <div className="mb-6 flex rounded-[18px] border border-white/20 bg-black/40 p-1">
        {(['login', 'signup'] as const).map(mode => (
          <button key={mode} type="button" onClick={() => { setAuthMode(mode); setError(null); setMessage(null); }} className={`h-11 flex-1 rounded-[14px] text-sm font-bold transition-colors ${authMode === mode ? 'bg-white text-black' : 'text-white/70 hover:text-white'}`}>
            {mode === 'login' ? 'Log in' : 'Sign up'}
          </button>
        ))}
      </div>

      <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2 text-white text-left">{authMode === 'login' ? 'Welcome back' : 'Create your account'}</h1>
      <p className="text-[15px] text-white/80 font-normal tracking-normal mb-6 text-left">
        {authMode === 'login' ? 'Use email, Google, or Apple to sign in.' : 'Create a LaterBox account with Google or Apple.'}
      </p>

      <form onSubmit={(e) => void handleEmailSubmit(e)} className="w-full space-y-3.5">
        {authMode === 'login' && <>
          <input type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" className="w-full h-14 px-5 bg-white rounded-[18px] text-[15px] text-[#181816] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-white/40 transition-all font-normal" />
          <button type="submit" disabled={loading || authLoading || Boolean(isAuthenticated)} className="w-full h-14 bg-white hover:bg-zinc-100 text-[#181816] font-bold text-[15px] rounded-[18px] shadow-md transition-all flex items-center justify-center disabled:opacity-50 cursor-pointer">
            {loading || authLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Continue with email'}
          </button>
        </>}

        <button type="button" disabled={loading || authLoading || Boolean(isAuthenticated)} onClick={() => void handleGoogle()} className="w-full h-14 rounded-[18px] bg-white text-[#181816] text-[15px] font-bold disabled:opacity-50 hover:bg-zinc-100 transition-colors">
          <span className="inline-flex items-center justify-center gap-3"><GoogleLogo />{authMode === 'signup' ? 'Create account with Google' : 'Continue with Google'}</span>
        </button>

        <button type="button" disabled={loading || authLoading || Boolean(isAuthenticated)} onClick={() => void handleApple()} className="w-full h-14 rounded-[18px] bg-white text-[#181816] text-[15px] font-bold disabled:opacity-50 hover:bg-zinc-100 transition-colors cursor-pointer">
          <span className="inline-flex items-center justify-center gap-3"><Apple className="size-5" aria-hidden="true" />{authMode === 'signup' ? 'Create account with Apple' : 'Continue with Apple'}</span>
        </button>

        {/* Continue without account */}
        <div className="pt-2 text-center">
          <button
            type="button"
            onClick={handleContinueWithoutAccount}
            className="text-[14px] text-white/85 hover:text-white font-medium transition-colors cursor-pointer py-1"
          >
            Continue without account
          </button>
        </div>
      </form>
    </AuthLayout>
  );
}

function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="relative min-h-screen w-full flex flex-col justify-between overflow-x-hidden selection:bg-zinc-900 selection:text-white">
      {/* Full Page Background Image */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <Image
          src="/branding/auth-background.png"
          alt="LaterBox background"
          fill
          priority
          sizes="100vw"
          className="object-cover object-center"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/45 via-black/20 via-40% to-black/90" />
      </div>

      {/* Top Bar: Brand Logo on the Top Right */}
      <header className="relative z-10 w-full flex items-center justify-end p-6 sm:p-8">
        <Image
          src="/branding/laterbox-logo-white.png"
          alt="LaterBox"
          width={180}
          height={48}
          className="w-36 sm:w-44 h-auto object-contain drop-shadow-lg"
          priority
        />
      </header>

      {/* Contents on the Bottom (no container box background) */}
      <div className="relative z-10 w-full max-w-[440px] mx-auto mt-auto mb-6 sm:mb-10 px-4 sm:px-6 text-left">
        {children}
      </div>
    </main>
  );
}

function OtpVerification({
  email,
  secondFactor = false,
  otp,
  busy,
  error,
  message,
  onOtpChange,
  onVerify,
  onResend,
  onBack,
}: {
  email: string;
  secondFactor?: boolean;
  otp: string;
  busy: boolean;
  error: string | null;
  message: string | null;
  onOtpChange: (value: string) => void;
  onVerify: () => void;
  onResend: () => void;
  onBack: () => void;
}) {
  return (
    <AuthLayout>
      <h1 id="otp-title" className="text-2xl sm:text-3xl font-black tracking-tight text-white text-left">
        {secondFactor ? 'Verify your sign-in' : 'Check your email'}
      </h1>
      <p className="mt-2 text-sm leading-6 text-white/80 text-left">
        {secondFactor ? 'Enter the code from your authenticator app.' : <>Enter the verification code sent to <strong className="text-white">{email}</strong>.</>}
      </p>

      {error && <p role="alert" className="mt-4 rounded-2xl border border-red-400/40 bg-red-500/20 p-3 text-sm font-semibold text-red-200 text-left">{error}</p>}
      {message && <p role="status" className="mt-4 rounded-2xl border border-emerald-400/40 bg-emerald-500/20 p-3 text-sm font-semibold text-emerald-200 text-left">{message}</p>}

      <form
        className="mt-6 space-y-3"
        onSubmit={(event) => {
          event.preventDefault();
          onVerify();
        }}
      >
        <label htmlFor="email-otp" className="sr-only">Verification code</label>
        <input
          id="email-otp"
          type="text"
          inputMode="numeric"
          autoComplete="one-time-code"
          autoFocus
          maxLength={8}
          value={otp}
          onChange={(event) => onOtpChange(event.target.value.replace(/\D/g, '').slice(0, 8))}
          placeholder="00000000"
          className="h-16 w-full rounded-[18px] bg-white px-5 text-center text-2xl font-black tracking-[0.45em] text-[#181816] focus:outline-none focus:ring-2 focus:ring-white/40"
        />
        <button type="submit" disabled={busy || otp.length < 6} className="flex h-14 w-full items-center justify-center rounded-[18px] bg-white text-[15px] font-bold text-[#181816] disabled:opacity-50 cursor-pointer">
          {busy ? <Loader2 className="size-5 animate-spin" /> : 'Verify code'}
        </button>
        <div className="flex items-center justify-center gap-3 pt-2">
          {!secondFactor && <><button type="button" disabled={busy} onClick={onResend} className="text-sm font-semibold text-white/90 hover:text-white disabled:opacity-50 cursor-pointer">
            Send a new code
          </button>
          <span className="text-white/40">·</span></>}
          <button type="button" disabled={busy} onClick={onBack} className="text-sm text-white/80 hover:text-white disabled:opacity-50 cursor-pointer">
            Use a different email
          </button>
        </div>
      </form>
    </AuthLayout>
  );
}

function DisplayNameInput({
  displayName,
  onChange,
  onSave,
  onSkip,
}: {
  displayName: string;
  onChange: (value: string) => void;
  onSave: () => void;
  onSkip: () => void;
}) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-[#f7f5ee] px-4">
      <section className="flex w-full max-w-md flex-col items-center gap-8">
        <Image
          src="/branding/laterbox-icon.png"
          alt="LaterBox logo"
          width={64}
          height={64}
          className="h-16 w-auto rounded-2xl"
          priority
        />
        <div className="flex w-full flex-col items-start gap-2">
          <h1 className="text-3xl font-black tracking-tight text-[#181816]">
            What should we call you?
          </h1>
          <p className="text-[15px] text-[#6b6961]">
            Optional — we&#39;ll use your email if you skip this.
          </p>
        </div>
        <form
          onSubmit={(event) => {
            event.preventDefault();
            onSave();
          }}
          className="flex w-full flex-col gap-4"
        >
          <label htmlFor="display-name" className="sr-only">Display name</label>
          <input
            id="display-name"
            type="text"
            autoComplete="name"
            autoFocus
            value={displayName}
            onChange={(event) => onChange(event.target.value)}
            placeholder="Your name"
            className="h-16 w-full rounded-[18px] border border-[#d8d3c7] bg-white px-5 text-[17px] font-semibold text-[#181816] placeholder:text-[#9e9b92] focus:border-zinc-500 focus:outline-none focus:ring-2 focus:ring-zinc-900/10"
          />
          <button type="submit" className="flex h-14 w-full items-center justify-center rounded-[18px] bg-[#181816] text-[15px] font-bold text-white cursor-pointer">
            Continue
          </button>
          <button type="button" onClick={onSkip} className="flex h-12 w-full items-center justify-center rounded-[18px] border border-[#d8d3c7] bg-transparent text-[15px] font-semibold text-[#6b6961] cursor-pointer">
            Skip
          </button>
        </form>
      </section>
    </main>
  );
}
