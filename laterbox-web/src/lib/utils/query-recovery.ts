interface QueryError {
  code?: string;
  message?: string;
}

export function isFutureIssuedJwt(error: QueryError | null): boolean {
  return !!error && /jwt issued (?:at |in (?:the )?)future/i.test(error.message || '');
}

// One recovery instance per sync prevents multiple refreshes across snapshot queries.
export function createQueryRecovery(
  refreshSession: () => PromiseLike<{ error: unknown }>,
  wait: (ms: number) => Promise<void> = ms => new Promise(resolve => setTimeout(resolve, ms)),
) {
  let refreshed = false;
  return async function fetchWithRetry<T, E extends QueryError>(
    query: () => PromiseLike<{ data: T | null; error: E | null }>,
  ): Promise<{ data: T | null; error: E | null }> {
    for (let attempt = 0; ; attempt++) {
      const result = await query();
      if (!isFutureIssuedJwt(result.error) || attempt === 3) return result;
      if (!refreshed) {
        refreshed = true;
        try {
          const refresh = await refreshSession();
          if (refresh.error) return result;
        } catch {
          return result;
        }
      }
      await wait(2500);
    }
  };
}
