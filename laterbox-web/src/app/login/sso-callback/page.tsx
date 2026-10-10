'use client';
import { AuthenticateWithRedirectCallback } from '@clerk/nextjs';
import { Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import { safeReturnPath } from '@/lib/auth/config';

function Callback() {
  const next = safeReturnPath(useSearchParams().get('next'));
  const login = `/login?next=${encodeURIComponent(next)}`;
  return <main className="min-h-screen bg-[#f7f5ee] flex items-center justify-center" role="status">
    Completing sign-in…
    <AuthenticateWithRedirectCallback signInUrl={login} signUpUrl={login} continueSignUpUrl={login} firstFactorUrl={login} secondFactorUrl={login} signInFallbackRedirectUrl={next} signUpFallbackRedirectUrl={next} />
  </main>;
}
export default function OAuthCallbackPage() {
  return <Suspense fallback={<main role="status">Completing sign-in…</main>}><Callback /></Suspense>;
}
