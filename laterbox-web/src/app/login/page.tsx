'use client';
import { Suspense } from 'react';
import { ClerkLogin } from '@/lib/auth/ClerkLogin';
import { CustomLoginContent } from '@/lib/auth/CustomLoginContent';
import { clerkAuthEnabled } from '@/lib/auth/config';

export default function LoginPage() {
  return <Suspense fallback={<main className="min-h-screen bg-[#f7f5ee]" aria-busy="true" />}>
    {clerkAuthEnabled ? <ClerkLogin /> : <CustomLoginContent />}
  </Suspense>;
}
