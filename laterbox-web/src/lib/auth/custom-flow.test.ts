import assert from 'node:assert/strict';
import test from 'node:test';
import type { SignInResource, SignUpResource } from '@clerk/shared/types';
import { createCustomClerkFlow } from './custom-flow';

function fixture(options: { unknown?: boolean; networkFailure?: boolean; password?: boolean; signupPassword?: boolean; invalidCode?: boolean } = {}) {
  const calls: string[] = [];
  const signin = {
    status: 'needs_first_factor',createdSessionId: null,
    supportedFirstFactors: options.password ? [{ strategy: 'password' }] : [{ strategy: 'email_code',emailAddressId: 'id_test' }],
    async create() { calls.push('signin'); if (options.networkFailure) throw new Error('Network unavailable'); if (options.unknown) throw { errors: [{ code: 'form_identifier_not_found' }] }; return this; },
    async prepareFirstFactor(params: { emailAddressId: string }) { assert.equal(params.emailAddressId,'id_test'); calls.push('send signin code'); return this; },
    async attemptFirstFactor() { calls.push('verify signin'); if (options.invalidCode) throw new Error('Incorrect code'); return { status: 'complete',createdSessionId: 'session_signin' }; },
  } as unknown as SignInResource;
  const signup = {
    missingFields: options.signupPassword ? ['password'] : [],
    async create() { calls.push('signup'); return this; },
    async prepareEmailAddressVerification() { calls.push('send signup code'); return this; },
    async attemptEmailAddressVerification() { if (options.invalidCode) throw new Error('Incorrect code'); return { status: 'complete',createdSessionId: 'session_signup' }; },
    async update() { calls.push('signup password'); return { status: 'missing_requirements' }; },
  } as unknown as SignUpResource;
  const activate = async (id: string) => { calls.push(`activate ${id}`); };
  return { signin,signup,activate,calls };
}

test('custom email login prepares the account factor and activates only after a valid code',async () => {
  const f = fixture(); const flow = createCustomClerkFlow(f.signin,f.signup,f.activate);
  assert.deepEqual(await flow.begin('user@example.com'),{ error: null,nextStep: 'email' });
  assert.equal((await flow.resend()).error,null);
  assert.equal((await flow.verify('123456')).error,null);
  assert.deepEqual(f.calls,['signin','send signin code','send signin code','verify signin','activate session_signin']);
  const invalid = fixture({ invalidCode: true });
  assert.ok((await createCustomClerkFlow(invalid.signin,invalid.signup,invalid.activate).verify('wrong')).error);
  assert.ok(!invalid.calls.some(call => call.startsWith('activate')));
});

test('signup is attempted only for an unknown identifier and survives hook resource updates',async () => {
  const f = fixture({ unknown: true }); const state: { mode: 'signin' | 'signup' } = { mode: 'signin' };
  assert.deepEqual(await createCustomClerkFlow(f.signin,f.signup,f.activate,state).begin('new@example.com'),{ error: null,nextStep: 'signup' });
  assert.equal((await createCustomClerkFlow(f.signin,f.signup,f.activate,state).verify('123456')).error,null);
  assert.equal(f.calls.at(-1),'activate session_signup');
  const failure = fixture({ networkFailure: true });
  assert.ok((await createCustomClerkFlow(failure.signin,failure.signup,failure.activate).begin('user@example.com')).error);
  assert.deepEqual(failure.calls,['signin']);
});

test('password login and password-required signup follow different flows',async () => {
  const f = fixture({ password: true }); const flow = createCustomClerkFlow(f.signin,f.signup,f.activate);
  assert.equal((await flow.begin('user@example.com')).nextStep,'password');
  assert.deepEqual(await flow.password('password'),{ error: null,requiresConfirmation: false });
  assert.equal(f.calls.at(-1),'activate session_signin');
  const signup = fixture({ unknown: true,signupPassword: true }); const signupFlow = createCustomClerkFlow(signup.signin,signup.signup,signup.activate);
  assert.equal((await signupFlow.begin('new@example.com')).nextStep,'password');
  assert.deepEqual(await signupFlow.password('password'),{ error: null,requiresConfirmation: true });
  assert.deepEqual(signup.calls,['signin','signup','signup password','send signup code']);
});

test('incomplete second-factor sessions are never activated',async () => {
  const f = fixture();
  f.signin.attemptFirstFactor = async () => ({ status: 'needs_second_factor',createdSessionId: null } as SignInResource);
  const result = await createCustomClerkFlow(f.signin,f.signup,f.activate).verify('123456');
  assert.match(result.error?.message || '',/additional verification/);
  assert.deepEqual(f.calls,[]);
});
