'use client';
import { SignIn, SignUp, useAuth as useClerkAuth } from '@clerk/nextjs';
import { useSearchParams } from 'next/navigation';
import { useAuth } from '../store/AuthContext';
import { safeReturnPath } from './config';

export function ClerkLogin({ legacy }: { legacy: React.ReactNode }) {
  const params = useSearchParams();
  const { user, loading, authError, retryAuth } = useAuth();
  const { isSignedIn } = useClerkAuth();
  const next = safeReturnPath(params.get('next'));
  if (params.get('legacy') === '1') return <><div className="p-4 text-center"><a href={`/login?next=${encodeURIComponent(next)}`}>Back to Clerk login</a></div>{legacy}</>;
  return <main className="min-h-screen bg-[#f7f5ee] flex flex-col items-center justify-center gap-6 p-6">
    {loading ? <p role="status">Checking your session…</p> : user ? <a href={next}>Open app</a> : isSignedIn ? <div role="alert" className="max-w-md text-center"><p>{authError || 'Your account is being connected.'}</p><button onClick={retryAuth} className="mt-4 underline">Retry account setup</button></div> : params.get('mode') === 'signup' ?
      <SignUp routing="hash" signInUrl={`/login?next=${encodeURIComponent(next)}`} fallbackRedirectUrl={next} /> :
      <SignIn routing="hash" signUpUrl={`/login?mode=signup&next=${encodeURIComponent(next)}`} fallbackRedirectUrl={next} />}
    {authError && !isSignedIn && <p role="alert">{authError}</p>}
    <a className="text-sm underline" href={`/login?legacy=1&next=${encodeURIComponent(next)}`}>Use existing Supabase account login</a>
    <a className="text-sm underline" href="/inbox?guest=1">Continue as guest</a>
  </main>;
}
