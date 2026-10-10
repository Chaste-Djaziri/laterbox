'use client';

import React, { Suspense, useState, useEffect } from 'react';
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
  } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [otp, setOtp] = useState('');
  const [awaitingOtp, setAwaitingOtp] = useState(false);
  const [otpType, setOtpType] = useState<'email' | 'signup'>('email');
  const [awaitingPassword, setAwaitingPassword] = useState(false);
  const [awaitingName, setAwaitingName] = useState(false);
  const [displayName, setDisplayName] = useState('');
  const requestedNext = searchParams.get('next');
  const nextPath = requestedNext?.startsWith('/') && !requestedNext.startsWith('//')
    ? requestedNext
    : '/inbox';

  // Automatically redirect to dashboard if user is already authenticated
  useEffect(() => {
    if (!authLoading && user) {
      router.replace(nextPath);
    }
  }, [authLoading, user, nextPath, router]);

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
    const { error: err } = await signInWithOtp(cleanEmail);
    if (!err) {
      setOtpType('email');
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
      const { error: signUpErr, requiresConfirmation } = await signUpWithPassword(email.trim(), password);

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
        setOtpType('signup');
        setAwaitingOtp(true);
        setMessage(`We sent a verification code to ${email.trim()}.`);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Authentication failed.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async () => {
    if (otp.length < 6 || otp.length > 8) {
      setError('Enter the verification code from your email.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);
    const { data, error: err } = await verifyEmailOtp(email.trim(), otp, otpType);
    if (err) {
      setError(err.message);
      setLoading(false);
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

  // If already authenticated, show redirecting state while transition completes
  if (!authLoading && user) {
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
      <main className="min-h-screen bg-[#f7f5ee] flex flex-col items-center justify-center p-6 text-[#181816] selection:bg-zinc-900 selection:text-white">
        <div className="w-full max-w-[420px] flex flex-col text-left">
          {/* Brand Logo */}
          <div className="mb-3">
            <Image
              src="/branding/laterbox-logo.png"
              alt="laterbox"
              width={280}
              height={75}
              className="w-44 sm:w-48 h-auto object-contain"
              priority
            />
          </div>

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

          {/* Title */}
          <h1 className="text-3xl font-black tracking-tight mb-2">Enter your password</h1>
          <p className="text-[15px] text-[#6b6961] font-normal tracking-normal mb-8">
            Create or enter your password for <strong className="text-[#181816]">{email.trim()}</strong> to continue.
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
                className="w-full h-14 pl-5 pr-12 bg-white border border-[#e5e1d7] rounded-[18px] text-[15px] text-[#181816] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-500 transition-all font-normal"
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
                className="w-full h-14 bg-[#181816] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-bold text-[15px] rounded-[18px] shadow-sm transition-all duration-150 flex items-center justify-center disabled:opacity-60 cursor-pointer"
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
                className="text-[14px] text-[#6b6961] hover:text-[#181816] font-normal transition-colors cursor-pointer py-1"
              >
                Use a different email
              </button>
            </div>
          </form>
        </div>
      </main>
    );
  }

  if (awaitingOtp) {
    return (
      <OtpVerification
        email={email.trim()}
        otp={otp}
        busy={loading}
        error={error}
        message={message}
        onOtpChange={setOtp}
        onVerify={() => void handleVerifyOtp()}
        onResend={() => void handleResendOtp()}
        onBack={() => {
          setAwaitingOtp(false);
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
    <main className="min-h-screen bg-[#f7f5ee] flex flex-col items-center justify-center p-6 text-[#181816] selection:bg-zinc-900 selection:text-white">
      <div className="w-full max-w-[420px] flex flex-col text-left">
        {/* Brand Logo */}
        <div className="mb-3">
          <Image
            src="/branding/laterbox-logo.png"
            alt="laterbox"
            width={280}
            height={75}
            className="w-44 sm:w-48 h-auto object-contain"
            priority
          />
        </div>

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

        {/* Title */}
        <h1 className="text-3xl font-black tracking-tight mb-2">Enter your email</h1>
        <p className="text-[15px] text-[#6b6961] font-normal tracking-normal mb-8">
          We&apos;ll send you a code to sign in or create your account.
        </p>

        {/* Email Form */}
        <form onSubmit={(e) => void handleEmailSubmit(e)} className="w-full space-y-3.5">
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

          <div className="pt-1.5 space-y-3">
            <button
              type="submit"
              disabled={loading}
              className="w-full h-14 bg-[#181816] hover:bg-[#282723] active:bg-[#0f0f0e] text-white font-bold text-[15px] rounded-[18px] shadow-sm transition-all duration-150 flex items-center justify-center disabled:opacity-60 cursor-pointer"
            >
              {loading ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                'Continue'
              )}
            </button>
          </div>

          {/* Continue without account */}
          <div className="pt-2 text-center">
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
  onOtpChange: (value: string) => void;
  onVerify: () => void;
  onResend: () => void;
  onBack: () => void;
}) {
  return (
    <main className="min-h-screen bg-[#f7f5ee] flex items-center justify-center p-6 text-[#181816]">
      <section className="w-full max-w-[420px] text-left" aria-labelledby="otp-title">
        <Image
          src="/branding/laterbox-logo.png"
          alt="LaterBox"
          width={280}
          height={75}
          className="h-auto w-44"
          priority
        />
        <h1 id="otp-title" className="mt-8 text-3xl font-black tracking-tight">
          Check your email
        </h1>
        <p className="mt-3 text-sm leading-6 text-[#6b6961]">
          Enter the verification code sent to <strong>{email}</strong>.
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
            placeholder="000000"
            className="h-16 w-full rounded-[18px] border border-[#d8d3c7] bg-white px-5 text-center text-2xl font-black tracking-[0.45em] focus:border-zinc-500 focus:outline-none focus:ring-2 focus:ring-zinc-900/10"
          />
          <button type="submit" disabled={busy || otp.length < 6} className="flex h-14 w-full items-center justify-center rounded-[18px] bg-[#181816] text-[15px] font-bold text-white disabled:opacity-50 cursor-pointer">
            {busy ? <Loader2 className="size-5 animate-spin" /> : 'Verify code'}
          </button>
          <div className="flex items-center justify-center gap-3 pt-1">
            <button type="button" disabled={busy} onClick={onResend} className="text-sm font-semibold disabled:opacity-50 cursor-pointer">
              Send a new code
            </button>
            <span className="text-[#9e9b92]">·</span>
            <button type="button" disabled={busy} onClick={onBack} className="text-sm text-[#6b6961] disabled:opacity-50 cursor-pointer">
              Use a different email
            </button>
          </div>
        </form>
      </section>
    </main>
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
          src="/laterbox-icon.png"
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
