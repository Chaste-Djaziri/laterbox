/** The issuer is a routing hint only. Supabase verifies Clerk JWTs before the RPC runs. */
export function isClerkSession(token: string): boolean {
  try {
    const payload = token.split('.')[1];
    const encoded = payload.replace(/-/g,'+').replace(/_/g,'/');
    const issuer = JSON.parse(atob(encoded.padEnd(Math.ceil(encoded.length / 4) * 4,'='))).iss;
    return issuer === 'https://clerk.laterbox.dev' || (typeof issuer === 'string' && /^https:\/\/[a-z0-9-]+\.clerk\.accounts\.dev$/.test(issuer));
  } catch { return false; }
}
export async function authenticateAccount(token: string, options: { supabaseUrl: string; anonKey: string; fetch?: typeof fetch }): Promise<string | null> {
  const fetcher = options.fetch || fetch;
  const clerk = isClerkSession(token);
  const response = await fetcher(`${options.supabaseUrl}${clerk ? '/rest/v1/rpc/current_account_id' : '/auth/v1/user'}`, {
    method: clerk ? 'POST' : 'GET',
    headers: { apikey: options.anonKey, authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    ...(clerk ? { body: '{}' } : {}),
  });
  if (!response.ok) return null;
  const result = await response.json();
  const id = clerk ? result : result && typeof result === 'object' && 'id' in result ? result.id : null;
  return typeof id === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id) ? id : null;
}
