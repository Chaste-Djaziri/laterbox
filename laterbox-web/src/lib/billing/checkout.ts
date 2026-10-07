export const CHECKOUT_CONFIGURATION_ERROR = 'Checkout is unavailable because billing configuration is missing. Please contact support.';
export const CHECKOUT_LOADING_ERROR = 'Unable to load secure checkout. Reload the page and check that your browser allows Paddle.';

export async function loadCheckout<T>(initialize: () => Promise<T | undefined>, timeoutMs = 15000): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    const instance = await Promise.race([
      initialize(),
      new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error(CHECKOUT_LOADING_ERROR)), timeoutMs);
      }),
    ]);
    if (!instance) throw new Error(CHECKOUT_LOADING_ERROR);
    return instance;
  } finally {
    clearTimeout(timer);
  }
}

export function checkoutSuccessUrl(origin: string, pathname: string, interval: 'month' | 'year', returnTo?: string): string {
  const url = new URL(pathname === '/plans' ? '/plans' : '/pricing', origin);
  url.searchParams.set('checkout', 'success');
  url.searchParams.set('plan', interval);
  if (returnTo) url.searchParams.set('return_to', returnTo);
  return url.toString();
}
