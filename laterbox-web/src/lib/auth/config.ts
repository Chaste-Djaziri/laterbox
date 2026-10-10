export const clerkAuthEnabled = process.env.NEXT_PUBLIC_CLERK_AUTH_ENABLED === 'true';
export const APP_ORIGIN = process.env.NEXT_PUBLIC_APP_ORIGIN || 'https://app.laterbox.dev';
export const CLERK_ISSUER = process.env.CLERK_JWT_ISSUER || 'https://clerk.laterbox.dev';
export function safeReturnPath(value: string | null | undefined): string {
  if (!value || !value.startsWith('/') || value.startsWith('//') || /[\\\u0000-\u001f]/.test(value)) return '/inbox';
  return value;
}
export function authorizedOrigins(): string[] {
  return (process.env.CLERK_AUTHORIZED_PARTIES || 'https://laterbox.dev,https://www.laterbox.dev,https://app.laterbox.dev').split(',').map(value => value.trim()).filter(Boolean);
}
