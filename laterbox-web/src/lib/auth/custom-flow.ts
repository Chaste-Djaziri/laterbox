import { AuthError } from '@supabase/supabase-js';
import type { SignInResource, SignUpResource } from '@clerk/shared/types';

export type EmailStartResult = { error: AuthError | null; nextStep?: 'email' | 'signup' | 'password' };
export function customAuthError(cause: unknown): AuthError {
  const error = cause as { errors?: { longMessage?: string; message?: string }[]; message?: string };
  return new AuthError(error.errors?.[0]?.longMessage || error.errors?.[0]?.message || error.message || 'Authentication could not finish. Please retry.');
}

/** Keep provider state behind LaterBox's existing email/code/password forms. */
export function createCustomClerkFlow(signIn: SignInResource, signUp: SignUpResource, activate: (session: string) => Promise<void>) {
  let mode: 'signin' | 'signup' = 'signin';
  const finish = async (attempt: SignInResource | SignUpResource) => {
    if (attempt.status !== 'complete' || !attempt.createdSessionId) {
      throw new Error(attempt.status === 'needs_second_factor' ? 'Your account requires additional verification. Contact support to complete this sign-in.' : 'Your account requires additional information before sign-in can finish.');
    }
    await activate(attempt.createdSessionId);
  };
  const sendSignupCode = async () => { await signUp.prepareEmailAddressVerification({ strategy: 'email_code' }); };
  return {
    async begin(email: string): Promise<EmailStartResult> {
      try {
        mode = 'signin';
        let attempt: SignInResource;
        try { attempt = await signIn.create({ identifier: email }); }
        catch (cause) {
          const errors = (cause as { errors?: { code?: string }[] }).errors;
          if (!errors?.some(error => error.code === 'form_identifier_not_found')) throw cause;
          mode = 'signup';
          const signup = await signUp.create({ emailAddress: email });
          if (signup.missingFields.includes('password')) return { error: null,nextStep: 'password' };
          await sendSignupCode();
          return { error: null,nextStep: 'signup' };
        }
        const emailFactor = attempt.supportedFirstFactors?.find(factor => factor.strategy === 'email_code');
        if (emailFactor?.strategy === 'email_code') {
          await signIn.prepareFirstFactor({ strategy: 'email_code',emailAddressId: emailFactor.emailAddressId });
          return { error: null,nextStep: 'email' };
        }
        if (attempt.supportedFirstFactors?.some(factor => factor.strategy === 'password')) return { error: null,nextStep: 'password' };
        throw new Error('Email-code sign-in is unavailable for this account. Use your connected Google account or contact support.');
      } catch (cause) { return { error: customAuthError(cause) }; }
    },
    async verify(code: string) {
      try {
        const attempt = mode === 'signup' ? await signUp.attemptEmailAddressVerification({ code }) : await signIn.attemptFirstFactor({ strategy: 'email_code',code });
        await finish(attempt);
        return { error: null };
      } catch (cause) { return { error: customAuthError(cause) }; }
    },
    async password(password: string) {
      try {
        if (mode === 'signin') { await finish(await signIn.attemptFirstFactor({ strategy: 'password',password })); return { error: null,requiresConfirmation: false }; }
        const attempt = await signUp.update({ password });
        if (attempt.status === 'complete') { await finish(attempt); return { error: null,requiresConfirmation: false }; }
        await sendSignupCode();
        return { error: null,requiresConfirmation: true };
      } catch (cause) { return { error: customAuthError(cause),requiresConfirmation: false }; }
    },
    async resend() {
      try {
        if (mode === 'signup') await sendSignupCode();
        else {
          const factor = signIn.supportedFirstFactors?.find(factor => factor.strategy === 'email_code');
          if (factor?.strategy !== 'email_code') throw new Error('Start your email sign-in again.');
          await signIn.prepareFirstFactor({ strategy: 'email_code',emailAddressId: factor.emailAddressId });
        }
        return { error: null };
      } catch (cause) { return { error: customAuthError(cause) }; }
    },
  };
}
