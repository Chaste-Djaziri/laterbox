const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
export async function handleDeleteAccount(request: Request): Promise<Response> {
  if (request.method === 'OPTIONS') return new Response(null,{ status: 204, headers: corsHeaders });
  if (request.method !== 'POST') return Response.json({ error: 'Method not allowed.' },{ status: 405, headers: corsHeaders });
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return Response.json({ error: 'Authentication required.' },{ status: 401, headers: corsHeaders });
  try {
    const response = await fetch('https://app.laterbox.dev/api/account/delete',{ method: 'POST', headers: { Authorization: authorization } });
    return new Response(await response.text(),{ status: response.status, headers: { ...corsHeaders,'Content-Type': 'application/json' } });
  } catch { return Response.json({ error: 'Account cleanup unavailable. Please retry.' },{ status: 503, headers: corsHeaders }); }
}
if (import.meta.main) Deno.serve(handleDeleteAccount);
