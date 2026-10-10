'use client';
import { Suspense } from 'react';
import { CustomLoginContent } from '@/lib/auth/CustomLoginContent';

export default function LoginPage() {
  return (
    <Suspense fallback={<main className="min-h-screen bg-[#f7f5ee]" aria-busy="true" />}>
      <CustomLoginContent />
    </Suspense>
  );
}
