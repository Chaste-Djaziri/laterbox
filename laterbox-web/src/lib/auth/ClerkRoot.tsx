'use client';
import { ClerkProvider } from '@clerk/nextjs';
import { APP_ORIGIN, clerkAuthEnabled } from './config';

export function ClerkRoot({ children }: { children: React.ReactNode }) {
  if (!clerkAuthEnabled) return children;
  return <ClerkProvider signInUrl={`${APP_ORIGIN}/login`} signUpUrl={`${APP_ORIGIN}/login?mode=signup`} signInFallbackRedirectUrl={`${APP_ORIGIN}/inbox`} signUpFallbackRedirectUrl={`${APP_ORIGIN}/inbox`}>{children}</ClerkProvider>;
}
