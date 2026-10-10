export async function authenticateAccount(token: string, options: { supabaseUrl: string; anonKey: string; fetch?: typeof fetch }): Promise<string | null> {
  const fetcher = options.fetch || fetch;
  const response = await fetcher(`${options.supabaseUrl}/auth/v1/user`, {
    method: 'GET',
    headers: { apikey: options.anonKey, authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
  if (!response.ok) return null;
  const result = await response.json();
  const id = result && typeof result === 'object' && 'id' in result ? result.id : null;
  return typeof id === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id) ? id : null;
}
