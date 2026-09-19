'use client';

import React, { Suspense, useState } from 'react';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/lib/store/AuthContext';
import { Loader2, AlertCircle, CheckCircle2 } from 'lucide-react';

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
    continueAsGuest,
  } = useAuth();

  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [otp, setOtp] = useState('');
  const [awaitingOtp, setAwaitingOtp] = useState(false);
  const [awaitingName, setAwaitingName] = useState(false);
  const [displayName, setDisplayName] = useState('');
  const requestedNext = searchParams.get('next');
  const nextPath = requestedNext?.startsWith('/') && !requestedNext.startsWith('//')
    ? requestedNext
    : '/home';

  const handleSendOtp = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!email.trim() || !email.includes('@')) {
      setError('Enter a valid email address.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);
    const { error: err } = await signInWithOtp(email.trim());
    if (err) setError(err.message);
    else setAwaitingOtp(true);
    setLoading(false);
  };

  const handleVerifyOtp = async () => {
    if (!/^\d{8}$/.test(otp)) {
      setError('Enter the eight digit code from your email.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);
    const { error: err } = await verifyEmailOtp(email.trim(), otp);
    if (err) setError(err.message);
    else {
      setAwaitingOtp(false);
      setAwaitingName(true);
    }
    setLoading(false);
  };

  const handleResendOtp = async () => {
    setLoading(true);
    setError(null);
    setMessage(null);
    const { error: err } = await signInWithOtp(email.trim());
    if (err) setError(err.message);
    else setMessage('A new code was sent.');
    setLoading(false);
  };

  const handleContinueWithoutAccount = () => {
    continueAsGuest();
    router.push('/home');
  };

  const handleSaveDisplayName = () => {
    if (displayName.trim()) {
      localStorage.setItem('laterbox_display_name', displayName.trim());
    }
    router.push(nextPath);
  };

  if (awaitingName) {
    return (
      <DisplayNameInput
        displayName={displayName}
        onChange={setDisplayName}
        onSave={() => handleSaveDisplayName()}
        onSkip={() => handleSaveDisplayName()}
      />
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
          setOtp('');
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
        <form onSubmit={(e) => void handleSendOtp(e)} className="w-full space-y-3.5">
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
          <button type="submit" disabled={busy || otp.length !== 8} className="flex h-14 w-full items-center justify-center rounded-[18px] bg-[#181816] text-[15px] font-bold text-white disabled:opacity-50 cursor-pointer">
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
