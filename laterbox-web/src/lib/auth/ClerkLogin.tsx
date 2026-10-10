'use client';
import { useClerk } from '@clerk/nextjs';
import { useSignIn, useSignUp } from '@clerk/nextjs/legacy';
import { useSearchParams } from 'next/navigation';
import { useCallback, useRef } from 'react';
import { AuthError } from '@supabase/supabase-js';
import { CustomLoginContent } from './CustomLoginContent';
import { createCustomClerkFlow, customAuthError } from './custom-flow';
import { safeReturnPath } from './config';

export function ClerkLogin() {
  const params = useSearchParams();
  const clerk = useClerk();
  const { signIn, setActive } = useSignIn();
  const { signUp } = useSignUp();
  const state = useRef<{ mode: 'signin' | 'signup' }>({ mode: 'signin' });
  const next = safeReturnPath(params.get('next'));

  const clerkRef = useRef(clerk);
  clerkRef.current = clerk;
  const signInRef = useRef(signIn);
  signInRef.current = signIn;
  const signUpRef = useRef(signUp);
  signUpRef.current = signUp;
  const setActiveRef = useRef(setActive);
  setActiveRef.current = setActive;

  const notReady = () => ({ error: new AuthError('Authentication is still loading. Please try again.') });

  const getActiveFlow = useCallback(() => {
    const sIn = signInRef.current || (clerkRef.current?.loaded ? clerkRef.current.client?.signIn : null);
    const sUp = signUpRef.current || (clerkRef.current?.loaded ? clerkRef.current.client?.signUp : null);
    const sAct = setActiveRef.current || (clerkRef.current?.loaded ? clerkRef.current.setActive : null);
    if (sIn && sUp && sAct) {
      return createCustomClerkFlow(sIn, sUp, async session => { await sAct({ session }); }, state.current);
    }
    return null;
  }, []);

  const getFlow = useCallback(async () => {
    const immediate = getActiveFlow();
    if (immediate) return immediate;

    // Wait up to 10 seconds for Clerk to finish loading
    for (let i = 0; i < 100; i++) {
      await new Promise(r => setTimeout(r, 100));
      const ready = getActiveFlow();
      if (ready) return ready;
    }
    return null;
  }, [getActiveFlow]);

  const isReady = Boolean(
    (signIn && signUp && setActive) ||
    (clerk.loaded && clerk.client?.signIn && clerk.client?.signUp)
  );

  if (params.get('legacy') === '1') {
    return <CustomLoginContent extra={<a href={`/login?next=${encodeURIComponent(next)}`} className="mb-4 text-sm underline">Back to login</a>} />;
  }

  return (
    <CustomLoginContent
      extra={<a href={`/login?legacy=1&next=${encodeURIComponent(next)}`} className="mb-4 text-sm text-[#6b6961] underline">Use existing account login</a>}
      actions={{
        loading: !isReady,
        signInWithOtp: async email => {
          const flow = await getFlow();
          return flow ? flow.begin(email) : notReady();
        },
        verifyEmailOtp: async (_email, code) => {
          const flow = await getFlow();
          return flow ? flow.verify(code) : notReady();
        },
        resendSignupOtp: async () => {
          const flow = await getFlow();
          return flow ? flow.resend() : notReady();
        },
        signUpWithPassword: async (_email, password) => {
          const flow = await getFlow();
          return flow ? flow.password(password) : { ...notReady(), requiresConfirmation: false };
        },
        signInWithPassword: async (_email, password) => {
          const flow = await getFlow();
          return flow ? flow.password(password) : notReady();
        },
        signInWithOAuth: async provider => {
          let sIn = signInRef.current || (clerkRef.current?.loaded ? clerkRef.current.client?.signIn : null);
          if (!sIn) {
            for (let i = 0; i < 100; i++) {
              await new Promise(r => setTimeout(r, 100));
              sIn = signInRef.current || (clerkRef.current?.loaded ? clerkRef.current.client?.signIn : null);
              if (sIn) break;
            }
          }
          if (!sIn) return notReady();
          try {
            await sIn.authenticateWithRedirect({
              strategy: provider === 'google' ? 'oauth_google' : 'oauth_github',
              redirectUrl: `/login/sso-callback?next=${encodeURIComponent(next)}`,
              redirectUrlComplete: next,
            });
            return { error: null };
          } catch (cause) {
            return { error: customAuthError(cause) };
          }
        },
      }}
    />
  );
}
