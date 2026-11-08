// laterbox-web/src/lib/auth/flow.ts

/** Bound authentication requests so a failed connection cannot spin forever. */
export async function withAuthTimeout<T>(
  operation: PromiseLike<T>,
  timeoutMs = 12000,
): Promise<T> {
  let timeout: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      Promise.resolve(operation),
      new Promise<never>((_, reject) => {
        timeout = setTimeout(() => {
          reject(new Error('Authentication timed out. Check your Supabase connection and try again.'));
        }, timeoutMs);
      }),
    ]);
  } finally {
    if (timeout !== undefined) clearTimeout(timeout);
  }
}

export interface PasswordSubmission {
  error: { message: string } | null;
  requiresConfirmation?: boolean;
  secondFactor?: boolean;
}

/** Do not accidentally create an account during an explicit login attempt. */
export async function submitPasswordByMode(
  mode: 'login' | 'signup',
  signIn: () => Promise<PasswordSubmission>,
  signUp: () => Promise<PasswordSubmission>,
  timeoutMs = 12000,
): Promise<PasswordSubmission> {
  return withAuthTimeout(mode === 'login' ? signIn() : signUp(), timeoutMs);
}
