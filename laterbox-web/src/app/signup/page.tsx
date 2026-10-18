import { Suspense } from 'react';
import { CustomLoginContent } from '@/lib/auth/CustomLoginContent';

export default function SignupPage() {
  return <Suspense fallback={<main className="min-h-screen bg-[#f7f5ee]" aria-busy="true" />}><CustomLoginContent initialMode="signup" /></Suspense>;
}
