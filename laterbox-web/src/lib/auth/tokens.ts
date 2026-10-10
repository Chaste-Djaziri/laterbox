export async function getAccessToken(refresh = false): Promise<string | null> {
  const { getSupabaseClient } = await import('../supabase/client');
  const client = getSupabaseClient();
  const { data, error } = refresh ? await client.auth.refreshSession() : await client.auth.getSession();
  if (error) throw error;
  return data.session?.access_token ?? null;
}

export async function refreshAccessToken(): Promise<{ error: unknown }> {
  try {
    return { error: (await getAccessToken(true)) ? null : new Error('Sign in to continue.') };
  } catch (error) {
    return { error };
  }
}
