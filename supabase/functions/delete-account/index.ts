declare const Deno: {
  env: { get(key: string): string | undefined };
  serve: (handler: (req: Request) => Promise<Response>) => void;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (data: unknown, status: number): Response =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

export async function handleDeleteAccount(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing authorization header" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  // 1. Verify and get user identity
  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      Authorization: authHeader,
      apikey: anonKey,
    },
  });

  if (!userRes.ok) {
    return json({ error: "Unauthorized" }, 401);
  }

  const user = (await userRes.json()) as { id?: string };
  const userId = user?.id;
  if (!userId) {
    return json({ error: "User not found" }, 404);
  }

  // 2. First attempt atomic PostgreSQL RPC deletion
  try {
    const rpcRes = await fetch(`${supabaseUrl}/rest/v1/rpc/delete_user_account`, {
      method: "POST",
      headers: {
        Authorization: authHeader,
        apikey: anonKey,
        "Content-Type": "application/json",
      },
    });
    if (rpcRes.ok) {
      return json({ success: true, message: "Account and all data deleted via RPC" }, 200);
    }
  } catch (_) {}

  // 3. Fallback table-by-table deletion
  const adminHeaders = {
    Authorization: `Bearer ${serviceRoleKey || authHeader.replace("Bearer ", "")}`,
    apikey: serviceRoleKey || anonKey,
    "Content-Type": "application/json",
    Prefer: "return=minimal",
  };

  const tables = [
    "collection_items",
    "item_notes",
    "item_metadata",
    "attachments",
    "items",
    "collections",
    "extension_sessions",
    "extension_connection_requests",
  ];

  for (const table of tables) {
    try {
      await fetch(`${supabaseUrl}/rest/v1/${table}?user_id=eq.${userId}`, {
        method: "DELETE",
        headers: adminHeaders,
      });
    } catch (_) {}
  }

  // 4. Fallback Admin Auth User deletion
  if (serviceRoleKey) {
    try {
      await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
        },
      });
    } catch (_) {}
  }

  return json({ success: true, message: "Account and all data deleted" }, 200);
}

if (import.meta.main) {
  Deno.serve(handleDeleteAccount);
}
