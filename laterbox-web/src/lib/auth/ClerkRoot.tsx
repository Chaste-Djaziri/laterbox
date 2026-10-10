'use client';
import { ClerkProvider } from '@clerk/nextjs';
import { APP_ORIGIN, clerkAuthEnabled } from './config';

export function ClerkRoot({ children }: { children: React.ReactNode }) {
  if (!clerkAuthEnabled) return children;
  return (
    <ClerkProvider
      signInUrl="/login"
      signUpUrl="/login"
      signInFallbackRedirectUrl="/inbox"
      signUpFallbackRedirectUrl="/inbox"
    >
      {children}
    </ClerkProvider>
  );
}
