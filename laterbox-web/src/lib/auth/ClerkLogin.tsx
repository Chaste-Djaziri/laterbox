'use client';
import { useSignIn, useSignUp } from '@clerk/nextjs/legacy';
import { useSearchParams } from 'next/navigation';
import { useMemo, useRef } from 'react';
import { AuthError } from '@supabase/supabase-js';
import { CustomLoginContent } from './CustomLoginContent';
import { createCustomClerkFlow, customAuthError } from './custom-flow';
import { safeReturnPath } from './config';

export function ClerkLogin() {
  const params = useSearchParams();
  const { signIn,setActive } = useSignIn();
  const { signUp } = useSignUp();
  const state = useRef<{ mode: 'signin' | 'signup' }>({ mode: 'signin' });
  const flow = useMemo(() => signIn && signUp && setActive ? createCustomClerkFlow(signIn,signUp,async session => { await setActive({ session }); },state.current) : null,[signIn,signUp,setActive]);
  const next = safeReturnPath(params.get('next'));
  const notReady = () => ({ error: new AuthError('Authentication is still loading. Please try again.') });
  if (params.get('legacy') === '1') return <CustomLoginContent extra={<a href={`/login?next=${encodeURIComponent(next)}`} className="mb-4 text-sm underline">Back to login</a>} />;
  return <CustomLoginContent
    extra={<a href={`/login?legacy=1&next=${encodeURIComponent(next)}`} className="mb-4 text-sm text-[#6b6961] underline">Use existing account login</a>}
    actions={{
      signInWithOtp: email => flow ? flow.begin(email) : Promise.resolve(notReady()),
      verifyEmailOtp: (_email,code) => flow ? flow.verify(code) : Promise.resolve(notReady()),
      resendSignupOtp: () => flow ? flow.resend() : Promise.resolve(notReady()),
      signUpWithPassword: (_email,password) => flow ? flow.password(password) : Promise.resolve({ ...notReady(),requiresConfirmation: false }),
      signInWithPassword: (_email,password) => flow ? flow.password(password) : Promise.resolve(notReady()),
      signInWithOAuth: async provider => {
        if (!signIn) return notReady();
        try {
          await signIn.authenticateWithRedirect({ strategy: provider === 'google' ? 'oauth_google' : 'oauth_github',redirectUrl: `/login/sso-callback?next=${encodeURIComponent(next)}`,redirectUrlComplete: next });
          return { error: null };
        } catch (cause) { return { error: customAuthError(cause) }; }
      },
    }}
  />;
}
