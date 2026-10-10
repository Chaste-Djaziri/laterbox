export const APP_ORIGIN = process.env.NEXT_PUBLIC_APP_ORIGIN || 'https://app.laterbox.dev';

export function safeReturnPath(value: string | null | undefined): string {
  if (!value || !value.startsWith('/') || value.startsWith('//') || /[\\\u0000-\u001f]/.test(value)) return '/inbox';
  return value;
}
export function authorizedOrigins(): string[] {
  const configured = (process.env.AUTHORIZED_PARTIES || 'https://app.laterbox.dev').split(',').map(value => value.trim()).filter(Boolean);
  if (process.env.NODE_ENV !== 'production') {
    if (!configured.includes('http://localhost:3000')) configured.push('http://localhost:3000');
    if (!configured.includes('http://127.0.0.1:3000')) configured.push('http://127.0.0.1:3000');
    if (!configured.includes('http://app.localhost:3000')) configured.push('http://app.localhost:3000');
  }
  return configured;
}
