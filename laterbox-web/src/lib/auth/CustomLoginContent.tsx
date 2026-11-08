'use client';

import { safeReturnPath } from '@/lib/auth/config';
import { submitPasswordByMode, withAuthTimeout } from '@/lib/auth/flow';

import React, { Suspense, useState, useEffect } from 'react';
import Image from 'next/image';
import Link from 'next/link';
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
    e?.preventDefault();
    const cleanEmail = email.trim();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      setError('Enter a valid email address.');
      return;
    }
    setError(null);
    setMessage(null);

    // Email sign-up collects the password on the next step.
    if (authMode === 'signup') {
      setAwaitingPassword(true);
      return;
    }

    setLoading(true);
    try {
      const result: EmailStartResult = await withAuthTimeout(signInWithOtp(cleanEmail));
      if (result.error) {
        // Network and OTP errors should be shown, not silently interpreted
        // as an instruction to switch to the password screen.
        setError(result.error.message);
        return;
      }
      if (result.nextStep === 'password') {
        setAwaitingPassword(true);
        return;
      }
      setOtpType(result.nextStep === 'signup' ? 'signup' : 'email');
      setAwaitingOtp(true);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Could not connect to authentication. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!password || password.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }
    setLoading(true);
    setError(null);
    setMessage(null);

    try {
      const result = await submitPasswordByMode(
        authMode,
        () => signInWithPassword(email.trim(), password),
        () => signUpWithPassword(email.trim(), password),
      );
      if (result.error) {
        setError(result.error.message);
        return;
      }

      if (authMode === 'signup' && result.requiresConfirmation) {
        setAwaitingPassword(false);
        setSecondFactor(Boolean(result.secondFactor));
        setOtpType(result.secondFactor ? 'email' : 'signup');
        setAwaitingOtp(true);
        setMessage(result.secondFactor ? null : `We sent a verification code to ${email.trim()}.`);
        return;
      }

      // The auth provider updates its session. Navigate without waiting for
      // a second login attempt or accidentally creating an account.
      router.replace(nextPath);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Authentication failed. Please try again.');
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
    try {
      const result = await withAuthTimeout(verifyEmailOtp(email.trim(), cleanOtp, otpType)) as
        Awaited<ReturnType<AuthContextType['verifyEmailOtp']>> & { isNewAccount?: boolean; secondFactor?: boolean };
      if (result.error) {
        setError(result.error.message);
        return;
      }
      if (result.secondFactor) {
        setSecondFactor(true);
        setOtp('');
        return;
      }
      if (actions) {
        setAwaitingOtp(false);
        if (result.isNewAccount) {
          setAwaitingName(true);
        } else {
          router.replace(nextPath);
        }
        return;
      }
      const verifiedUser = result.data?.user;
      const existingName =
        (verifiedUser?.user_metadata?.display_name as string) ||
        (verifiedUser?.user_metadata?.name as string) ||
        (verifiedUser?.user_metadata?.full_name as string) ||
        (typeof window !== 'undefined' ? localStorage.getItem('laterbox_user_name') : null) ||
        '';
      const isNewAccount = Boolean(
        verifiedUser?.created_at &&
        verifiedUser?.last_sign_in_at &&
        Math.abs(new Date(verifiedUser.last_sign_in_at).getTime() - new Date(verifiedUser.created_at).getTime()) < 5000
      );

      setAwaitingOtp(false);
      if (!existingName.trim() || isNewAccount) {
        if (existingName.trim()) setDisplayName(existingName.trim());
        setAwaitingName(true);
      } else {
        router.replace(nextPath);
      }
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Could not verify that code. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleResendOtp = async () => {
    setLoading(true);
    setError(null);
    setMessage(null);
    try {
      const result = otpType === 'signup'
        ? await withAuthTimeout(resendSignupOtp(email.trim()))
        : await withAuthTimeout(signInWithOtp(email.trim()));
      if (result.error) setError(result.error.message);
      else setMessage('A new code was sent.');
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Could not resend the code. Please try again.');
    } finally {
      setLoading(false);
    }
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

  const handleOAuth = async (provider: 'google' | 'apple') => {
    setLoading(true);
    setError(null);
    try {
      const result = await withAuthTimeout(signInWithOAuth(provider));
      if (result.error) setError(result.error.message);
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Could not start sign-in. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = () => handleOAuth('google');
  const handleApple = () => handleOAuth('apple');

  const renderDevToolbar = () => {
    if (process.env.NODE_ENV === 'production') return null;
    if (searchParams.get('dev_sim') !== 'true') return null;
    return (
      <div className="mb-4 flex flex-wrap items-center gap-1.5 p-2 rounded-xl bg-black/60 border border-white/20 text-[11px] font-mono text-white/80">
        <span className="font-bold text-white/50 pr-1">Dev Sim:</span>
        <button
          type="button"
          onClick={() => {
            setAwaitingPassword(false);
            setAwaitingOtp(false);
            setAuthMode('login');
            setError(null);
            setMessage(null);
          }}
          className="px-2 py-0.5 rounded-lg bg-white/15 hover:bg-white/25 cursor-pointer"
        >
          Email
        </button>
        <button
          type="button"
          onClick={() => {
            const targetEmail = email.trim() || 'alex@example.com';
            setEmail(targetEmail);
            setAwaitingOtp(false);
            setAuthMode('signup');
            setAwaitingPassword(true);
            setError(null);
            setMessage(null);
          }}
          className="px-2 py-0.5 rounded-lg bg-white/15 hover:bg-white/25 cursor-pointer"
        >
          Pwd (Sign Up)
        </button>
        <button
          type="button"
          onClick={() => {
            const targetEmail = email.trim() || 'alex@example.com';
            setEmail(targetEmail);
            setAwaitingOtp(false);
            setAuthMode('login');
            setAwaitingPassword(true);
            setError(null);
            setMessage(null);
          }}
          className="px-2 py-0.5 rounded-lg bg-white/15 hover:bg-white/25 cursor-pointer"
        >
          Pwd (Sign In)
        </button>
        <button
          type="button"
          onClick={() => {
            const targetEmail = email.trim() || 'alex@example.com';
            setEmail(targetEmail);
            setOtp('48291055');
            setAwaitingPassword(false);
            setAwaitingOtp(true);
            setError(null);
            setMessage(null);
          }}
          className="px-2 py-0.5 rounded-lg bg-white/15 hover:bg-white/25 cursor-pointer"
        >
          Verify Code
        </button>
      </div>
    );
  };

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
        {renderDevToolbar()}
        {/* Feedback Alerts */}
        {error && (
          <div className="w-full mb-4 p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {message && (
          <div className="w-full mb-4 p-3.5 rounded-2xl bg-[#eef7e5] border border-[#d7e8c8] text-[#456b38] text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{message}</span>
          </div>
        )}

        {/* Title: Left-aligned */}
        <h1 className="text-[30px] sm:text-[36px] font-black tracking-[-0.045em] leading-[1.15] mb-3 text-[#20281d] text-left">Enter your password</h1>
        <p className="text-[14px] sm:text-[15px] text-[#798275] font-normal leading-6 mb-7 text-left">
          {authMode === 'signup' ? 'Create a password for ' : 'Enter your password for '}<strong className="text-[#35442e]">{email.trim()}</strong> to continue.
        </p>

        {/* Password Form */}
        <form onSubmit={(e) => void handlePasswordSubmit(e)} className="w-full space-y-3.5">
          <div className="relative">
            <input
              id="auth-password"
              aria-label="Password"
              type={showPassword ? 'text' : 'password'}
              autoComplete={authMode === 'signup' ? 'new-password' : 'current-password'}
              required
              autoFocus
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password (at least 6 characters)"
              className="h-14 w-full rounded-2xl border border-[#e1e5db] bg-white pl-5 pr-12 text-[15px] text-[#20281d] placeholder:text-[#a2a9a0] shadow-sm outline-none transition-colors focus:border-[#93ab71] focus:ring-4 focus:ring-[#e6edb0]/55"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9e9b92] hover:text-[#181816] transition-colors cursor-pointer p-1 focus-visible:outline-2 focus-visible:outline-[#829b60]"
              title={showPassword ? 'Hide password' : 'Show password'}
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>

          <div className="pt-1.5 space-y-3">
            <button
              type="submit"
              disabled={loading || password.length < 6}
              className="flex h-14 w-full cursor-pointer items-center justify-center rounded-2xl bg-[#20281d] text-[15px] font-bold text-white shadow-sm transition-colors hover:bg-[#34442c] disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]"
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
              className="cursor-pointer py-1 text-sm font-semibold text-[#627b4b] transition-colors hover:text-[#273c20] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]"
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
        devToolbar={renderDevToolbar()}
      />
    );
  }

  return (
    <AuthLayout>
      {renderDevToolbar()}
      {!authLoading && authError && (
        <div role="alert" className="mb-4 rounded-xl border border-red-200 bg-red-50 p-3.5 text-xs font-semibold leading-5 text-red-700">
          <p>{authError}</p>
          {retryAuth && (
            <button type="button" onClick={retryAuth} className="mt-2 rounded-lg border border-red-200 bg-white px-3 py-1.5 text-xs font-bold text-red-700 hover:bg-red-50">
              Retry connection
            </button>
          )}
        </div>
      )}
      {extra}
      {/* Feedback Alerts */}
      {error && (
        <div className="w-full mb-4 p-3.5 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {message && (
        <div className="w-full mb-4 p-3.5 rounded-2xl bg-[#eef7e5] border border-[#d7e8c8] text-[#456b38] text-xs font-semibold flex items-center gap-2 text-left animate-in fade-in">
          <CheckCircle2 className="w-4 h-4 shrink-0" />
          <span>{message}</span>
        </div>
      )}

      {/* Mode Selector */}
      <div className="mb-8 flex rounded-2xl border border-[#e4e8dd] bg-[#edf0e7] p-1">
        {(['login', 'signup'] as const).map(mode => (
          <button key={mode} type="button" onClick={() => { setAuthMode(mode); setError(null); setMessage(null); }} className={`h-11 flex-1 rounded-[14px] text-sm font-bold transition-colors ${authMode === mode ? 'bg-white text-[#20281d] shadow-[0_2px_7px_rgba(24,35,18,0.09)]' : 'text-[#7b8773] hover:bg-white/50 hover:text-[#28391f]'}`}>
            {mode === 'login' ? 'Log in' : 'Sign up'}
          </button>
        ))}
      </div>

      <h1 className="text-[30px] sm:text-[36px] font-black tracking-[-0.045em] leading-[1.15] mb-3 text-[#20281d] text-left">{authMode === 'login' ? 'Welcome back' : 'Create your account'}</h1>
      <p className="text-[14px] sm:text-[15px] text-[#798275] font-normal leading-6 mb-7 text-left">
        {authMode === 'login' ? 'Use email, Google, or Apple to sign in.' : 'Sign up with email, Google, or Apple.'}
      </p>

      <form onSubmit={(e) => void handleEmailSubmit(e)} className="w-full space-y-3.5">
        <input id="auth-email" aria-label="Email address" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" className="h-14 w-full rounded-2xl border border-[#e1e5db] bg-white px-5 text-[15px] text-[#20281d] placeholder:text-[#a2a9a0] shadow-sm outline-none transition-colors focus:border-[#93ab71] focus:ring-4 focus:ring-[#e6edb0]/55" />
        <button type="submit" disabled={loading || authLoading || Boolean(isAuthenticated)} className="flex h-14 w-full cursor-pointer items-center justify-center rounded-2xl bg-[#20281d] text-[15px] font-bold text-white shadow-sm transition-colors hover:bg-[#34442c] disabled:cursor-not-allowed disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]">
          {loading || authLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : authMode === 'signup' ? 'Sign up with email' : 'Continue with email'}
        </button>
        {authMode === 'login' && (
          <button
            type="button"
            disabled={loading || authLoading || !email.trim().includes('@')}
            onClick={() => { setAwaitingPassword(true); setError(null); setMessage(null); }}
            className="min-h-9 w-full rounded-xl text-sm font-semibold text-[#607b4c] transition-colors hover:bg-[#eef4e5] disabled:cursor-not-allowed disabled:opacity-40"
          >
            Sign in with a password instead
          </button>
        )}

        <button type="button" disabled={loading || authLoading || Boolean(isAuthenticated)} onClick={() => void handleGoogle()} className="h-14 w-full rounded-2xl border border-[#e0e5d9] bg-white text-[15px] font-bold text-[#263320] shadow-sm transition-colors hover:border-[#afbf95] hover:bg-[#f7faf2] disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]">
          <span className="inline-flex items-center justify-center gap-3"><GoogleLogo />{authMode === 'signup' ? 'Create account with Google' : 'Continue with Google'}</span>
        </button>

        <button type="button" disabled={loading || authLoading || Boolean(isAuthenticated)} onClick={() => void handleApple()} className="h-14 w-full cursor-pointer rounded-2xl border border-[#e0e5d9] bg-white text-[15px] font-bold text-[#263320] shadow-sm transition-colors hover:border-[#afbf95] hover:bg-[#f7faf2] disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]">
          <span className="inline-flex items-center justify-center gap-3"><Apple className="size-5" aria-hidden="true" />{authMode === 'signup' ? 'Create account with Apple' : 'Continue with Apple'}</span>
        </button>

        {/* Continue without account */}
        <div className="pt-2 text-center">
          <button
            type="button"
            onClick={handleContinueWithoutAccount}
            className="cursor-pointer py-1 text-sm font-semibold text-[#627b4b] transition-colors hover:text-[#273c20] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]"
          >
            Continue without account
          </button>
        </div>

        {/* Legal Disclaimer */}
        <p className="pt-4 text-center text-[11px] leading-6 text-[#949d8e]">
          By continuing, you agree to our{' '}
          <Link href="/terms" className="font-semibold text-[#536943] underline decoration-[#aebf9c] underline-offset-2 hover:text-[#263c21]">
            Terms
          </Link>{' '}
          &{' '}
          <Link href="/privacy" className="font-semibold text-[#536943] underline decoration-[#aebf9c] underline-offset-2 hover:text-[#263c21]">
            Privacy Policy
          </Link>
        </p>
      </form>
    </AuthLayout>
  );
}

function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="grid min-h-[100dvh] w-full bg-[#f8f9f4] text-[#171711] selection:bg-[#e6edb0] selection:text-[#171711] lg:h-[100dvh] lg:grid-cols-[minmax(0,1fr)_minmax(0,1.08fr)] lg:overflow-hidden">
      {/* Left: accessible, distraction-free authentication forms. */}
      <section className="flex min-h-[100dvh] min-w-0 flex-col lg:min-h-0 lg:overflow-y-auto">
        <header className="flex shrink-0 items-center justify-between px-6 pb-4 pt-7 sm:px-10 sm:pt-9 xl:px-16">
          <Link
            href="/"
            aria-label="LaterBox home"
            className="inline-flex items-center gap-2.5 rounded-xl focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#748b50]"
          >
            <Image
              src="/branding/laterbox-icon.png"
              alt=""
              width={38}
              height={38}
              priority
              className="h-9 w-9 rounded-[11px] object-contain"
            />
            <span className="text-[22px] font-black tracking-[-0.065em] text-[#1b2319]">laterbox<span className="text-[#7b9454]">.</span></span>
          </Link>
          <Link
            href="/"
            className="rounded-full border border-[#e2e7db] bg-white px-3.5 py-2 text-[11px] font-bold text-[#647258] transition-colors hover:border-[#bccf9d] hover:text-[#26381f] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#748b50]"
          >
            Back to website
          </Link>
        </header>

        <div className="flex w-full flex-1 items-center justify-center px-6 py-10 sm:px-10 lg:py-8 xl:px-16">
          <div className="w-full max-w-[430px]">
            {children}
          </div>
        </div>

        <footer className="flex shrink-0 flex-wrap items-center justify-between gap-2 px-6 pb-6 pt-4 text-[11px] font-medium text-[#9a9f94] sm:px-10 xl:px-16">
          <span>© LaterBox · Keep what matters.</span>
          <span className="flex items-center gap-3">
            <Link href="/privacy" className="hover:text-[#526744]">Privacy</Link>
            <Link href="/terms" className="hover:text-[#526744]">Terms</Link>
          </span>
        </footer>
      </section>

      {/* Right: the existing authentic LaterBox artwork, never behind form text. */}
      <aside
        aria-label="LaterBox brand illustration"
        className="relative hidden min-h-0 flex-col overflow-hidden bg-[#1b2819] lg:flex"
      >
        <Image
          src="/branding/auth-background.png"
          alt=""
          fill
          priority
          sizes="(min-width: 1024px) 54vw, 100vw"
          className="object-cover object-center"
        />
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-[#132018]/20 via-[#15221a]/10 to-[#10180f]/80" />
        <div className="relative z-10 flex h-full flex-col justify-between p-10 xl:p-14">
          <div className="inline-flex self-start items-center gap-2 rounded-full border border-white/25 bg-black/20 px-3.5 py-2 text-[11px] font-bold tracking-wide text-white backdrop-blur-md">
            <span className="h-2 w-2 rounded-full bg-[#e6edb0]" aria-hidden="true" />
            Your personal space for later
          </div>
          <div className="max-w-[570px] pb-5">
            <p className="mb-5 text-[11px] font-black uppercase tracking-[0.23em] text-[#e6edb0]">Make room for what matters</p>
            <h2 className="text-[clamp(2.4rem,4vw,4.7rem)] font-black leading-[1.09] tracking-[-0.055em] text-white">
              Save it now.<br />
              Come back<br />
              when it matters.
            </h2>
            <p className="mt-6 max-w-[385px] text-sm leading-7 text-white/80 xl:text-base">
              Everything worth keeping, from links and ideas to the tasks you want to finish, in one calm place.
            </p>
            <div className="mt-9 flex flex-wrap gap-2">
              {['Capture anything', 'Stay organized', 'Return on time'].map(label => (
                <span
                  key={label}
                  className="rounded-full border border-white/20 bg-white/10 px-3 py-2 text-[11px] font-semibold text-white backdrop-blur-md"
                >
                  {label}
                </span>
              ))}
            </div>
          </div>
        </div>
      </aside>
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
  devToolbar,
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
  devToolbar?: React.ReactNode;
}) {
  return (
    <AuthLayout>
      {devToolbar}
      <h1 id="otp-title" className="text-[30px] sm:text-[36px] font-black leading-tight tracking-[-0.045em] text-[#20281d] text-left">
        {secondFactor ? 'Verify your sign-in' : 'Check your email'}
      </h1>
      <p className="mt-3 text-sm leading-6 text-[#798275] text-left">
        {secondFactor ? 'Enter the code from your authenticator app.' : <>Enter the verification code sent to <strong className="text-[#374c2c]">{email}</strong>.</>}
      </p>

      {error && <p role="alert" className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-sm font-semibold text-red-700 text-left">{error}</p>}
      {message && <p role="status" className="mt-4 rounded-2xl border border-[#d7e8c8] bg-[#eef7e5] p-3 text-sm font-semibold text-[#456b38] text-left">{message}</p>}

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
          className="h-16 w-full rounded-2xl border border-[#e1e5db] bg-white px-5 text-center text-2xl font-black tracking-[0.35em] text-[#20281d] shadow-sm outline-none focus:border-[#93ab71] focus:ring-4 focus:ring-[#e6edb0]/55"
        />
        <button type="submit" disabled={busy || otp.length < 6} className="flex h-14 w-full cursor-pointer items-center justify-center rounded-2xl bg-[#20281d] text-[15px] font-bold text-white transition-colors hover:bg-[#34442c] disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]">
          {busy ? <Loader2 className="size-5 animate-spin" /> : 'Verify code'}
        </button>
        <div className="flex items-center justify-center gap-3 pt-2">
          {!secondFactor && <><button type="button" disabled={busy} onClick={onResend} className="cursor-pointer text-sm font-semibold text-[#536d41] hover:text-[#24391f] disabled:opacity-50">
            Send a new code
          </button>
          <span className="text-[#b8c2ae]">·</span></>}
          <button type="button" disabled={busy} onClick={onBack} className="cursor-pointer text-sm font-semibold text-[#71806b] hover:text-[#263c20] disabled:opacity-50">
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
    <AuthLayout>
      <div className="space-y-3">
        <span className="inline-flex items-center gap-2 rounded-full border border-[#dde8c7] bg-[#eef5dd] px-3 py-1.5 text-[11px] font-bold text-[#597343]">
          <CheckCircle2 className="h-3.5 w-3.5" aria-hidden="true" />
          Almost ready
        </span>
        <h1 className="pt-2 text-[30px] font-black leading-tight tracking-[-0.045em] text-[#20281d] sm:text-[36px]">
          What should we call you?
        </h1>
        <p className="text-sm leading-6 text-[#798275]">
          This is optional. We can use your email if you prefer to skip it.
        </p>
      </div>
      <form
        onSubmit={event => { event.preventDefault(); onSave(); }}
        className="mt-7 flex w-full flex-col gap-3.5"
      >
        <label htmlFor="display-name" className="text-xs font-extrabold text-[#33402e]">Your name</label>
        <input
          id="display-name"
          type="text"
          autoComplete="name"
          autoFocus
          maxLength={120}
          value={displayName}
          onChange={event => onChange(event.target.value)}
          placeholder="How should we address you?"
          className="h-14 w-full rounded-2xl border border-[#e1e5db] bg-white px-5 text-[15px] font-semibold text-[#20281d] placeholder:text-[#a2a9a0] shadow-sm outline-none focus:border-[#93ab71] focus:ring-4 focus:ring-[#e6edb0]/55"
        />
        <button
          type="submit"
          className="mt-2 flex h-14 w-full items-center justify-center rounded-2xl bg-[#20281d] text-[15px] font-bold text-white transition-colors hover:bg-[#34442c] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]"
        >
          Continue to LaterBox
        </button>
        <button
          type="button"
          onClick={onSkip}
          className="flex h-12 w-full items-center justify-center rounded-2xl text-sm font-semibold text-[#657d50] transition-colors hover:bg-[#eef2e6] hover:text-[#2c4121] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#829b60]"
        >
          Skip for now
        </button>
      </form>
    </AuthLayout>
  );
}
