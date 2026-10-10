import { AuthError } from '@supabase/supabase-js';
import type { SignInResource, SignUpResource } from '@clerk/shared/types';

export type EmailStartResult = { error: AuthError | null; nextStep?: 'email' | 'signup' | 'password' };

const CLERK_FIELD_LABELS: Record<string, string> = {
  first_name: 'First Name',
  last_name: 'Last Name',
  username: 'Username',
  password: 'Password',
  phone_number: 'Phone Number',
  email_address: 'Email Address',
  legal_accepted: 'Legal Acceptance',
  protect_check: 'Security Check (Clerk Protect)',
};

function formatClerkField(field: string): string {
  const label = CLERK_FIELD_LABELS[field];
  return label ? `${label} (${field})` : field;
}

export function getClerkRequirementError(attempt: SignInResource | SignUpResource): string {
  const parts: string[] = [];

  if ('missingFields' in attempt && Array.isArray(attempt.missingFields) && attempt.missingFields.length > 0) {
    parts.push(`Missing required fields: ${attempt.missingFields.map(formatClerkField).join(', ')}`);
  }

  if ('unverifiedFields' in attempt && Array.isArray(attempt.unverifiedFields) && attempt.unverifiedFields.length > 0) {
    parts.push(`Unverified fields: ${attempt.unverifiedFields.map(formatClerkField).join(', ')}`);
  }

  if (attempt.status === 'needs_second_factor') {
    if ('supportedSecondFactors' in attempt && Array.isArray(attempt.supportedSecondFactors) && attempt.supportedSecondFactors.length > 0) {
      const strategies = attempt.supportedSecondFactors.map(f => f.strategy).join(', ');
      parts.push(`additional verification required (2FA strategies: ${strategies})`);
    } else {
      parts.push('additional verification required');
    }
  }

  if ('verifications' in attempt && attempt.verifications) {
    const verifs = attempt.verifications as unknown as Record<string, { error?: { message?: string; longMessage?: string }; status?: string } | undefined>;
    for (const [key, val] of Object.entries(verifs)) {
      if (val?.error?.longMessage || val?.error?.message) {
        parts.push(`${formatClerkField(key)}: ${val.error.longMessage || val.error.message}`);
      }
    }
  }

  if ('firstFactorVerification' in attempt && attempt.firstFactorVerification) {
    const v = attempt.firstFactorVerification as { error?: { message?: string; longMessage?: string }; status?: string };
    if (v.error?.longMessage || v.error?.message) {
      parts.push(`First factor: ${v.error.longMessage || v.error.message}`);
    }
  }

  if ('secondFactorVerification' in attempt && attempt.secondFactorVerification) {
    const v = attempt.secondFactorVerification as { error?: { message?: string; longMessage?: string }; status?: string };
    if (v.error?.longMessage || v.error?.message) {
      parts.push(`Second factor: ${v.error.longMessage || v.error.message}`);
    }
  }

  if (parts.length > 0) {
    return `Your account requires additional information before sign-in can finish. Clerk is requiring: ${parts.join('. ')}.`;
  }

  if (attempt.status === 'needs_second_factor') {
    return 'Your account requires additional verification. Contact support to complete this sign-in.';
  }

  const statusNote = attempt.status ? ` (Clerk status: ${attempt.status})` : '';
  return `Your account requires additional information before sign-in can finish${statusNote}. Please check your Clerk dashboard settings or contact support.`;
}

export function customAuthError(cause: unknown): AuthError {
  if (cause instanceof AuthError) return cause;
  const error = cause as { errors?: { longMessage?: string; message?: string }[]; message?: string };
  const clerkMessages = error.errors?.map(e => e.longMessage || e.message).filter(Boolean);
  if (clerkMessages && clerkMessages.length > 0) {
    return new AuthError(clerkMessages.join('. '));
  }
  return new AuthError(error.message || 'Authentication could not finish. Please retry.');
}

/** Keep provider state behind LaterBox's existing email/code/password forms. */
export function createCustomClerkFlow(signIn: SignInResource, signUp: SignUpResource, activate: (session: string) => Promise<void>, state: { mode: 'signin' | 'signup'; secondFactor?: 'totp' } = { mode: 'signin' }) {
  const finish = async (attempt: SignInResource | SignUpResource) => {
    if (attempt.status === 'needs_second_factor' && 'supportedSecondFactors' in attempt && attempt.supportedSecondFactors?.some(factor => factor.strategy === 'totp')) { state.secondFactor = 'totp'; return false; }
    if (attempt.status !== 'complete' || !attempt.createdSessionId) {
      throw new Error(getClerkRequirementError(attempt));
    }
    await activate(attempt.createdSessionId);
    return true;
  };
  const sendSignupCode = async () => { await signUp.prepareEmailAddressVerification({ strategy: 'email_code' }); };
  return {
    async begin(email: string): Promise<EmailStartResult> {
      try {
        state.mode = 'signin'; state.secondFactor = undefined;
        let attempt: SignInResource;
        try { attempt = await signIn.create({ identifier: email }); }
        catch (cause) {
          const errors = (cause as { errors?: { code?: string }[] }).errors;
          if (!errors?.some(error => error.code === 'form_identifier_not_found')) throw cause;
          state.mode = 'signup';
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
        const attempt = state.secondFactor ? await signIn.attemptSecondFactor({ strategy: 'totp',code }) : state.mode === 'signup' ? await signUp.attemptEmailAddressVerification({ code }) : await signIn.attemptFirstFactor({ strategy: 'email_code',code });
        const complete = await finish(attempt);
        return { error: null,secondFactor: !complete,isNewAccount: complete && state.mode === 'signup' };
      } catch (cause) { return { error: customAuthError(cause) }; }
    },
    async password(password: string) {
      try {
        if (state.mode === 'signin') { const complete = await finish(await signIn.attemptFirstFactor({ strategy: 'password',password })); return { error: null,requiresConfirmation: !complete,...(!complete ? { secondFactor: true } : {}) }; }
        const attempt = await signUp.update({ password });
        if (attempt.status === 'complete') { await finish(attempt); return { error: null,requiresConfirmation: false }; }
        await sendSignupCode();
        return { error: null,requiresConfirmation: true };
      } catch (cause) { return { error: customAuthError(cause),requiresConfirmation: false }; }
    },
    async resend() {
      try {
        if (state.mode === 'signup') await sendSignupCode();
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
