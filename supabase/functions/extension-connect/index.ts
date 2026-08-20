const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const REQUEST_TTL_MS = 10 * 60 * 1000;
const SESSION_TTL_MS = 90 * 24 * 60 * 60 * 1000;

type Dependencies = {
  fetch: typeof fetch;
  supabaseUrl: string;
  anonKey: string;
  serviceRoleKey: string;
  createId: () => string;
  createToken: () => string;
  now: () => Date;
};

type ConnectionBody = {
  action?: unknown;
  request_id?: unknown;
  request_secret?: unknown;
};

const defaultDependencies = (): Dependencies => ({
  fetch,
  supabaseUrl: Deno.env.get("SUPABASE_URL") ?? "",
  anonKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  serviceRoleKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  createId: () => crypto.randomUUID(),
  createToken: () => `lb_ext_${crypto.randomUUID().replaceAll("-", "")}`,
  now: () => new Date(),
});

export const createConnectionHandler = (
  overrides: Partial<Dependencies> = {},
): ((request: Request) => Promise<Response>) => {
  const dependencies = { ...defaultDependencies(), ...overrides };

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { status: 204, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    let body: ConnectionBody;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }

    const action = typeof body.action === "string" ? body.action : "";
    const requestId = typeof body.request_id === "string" ? body.request_id : "";
    const requestSecret =
      typeof body.request_secret === "string" ? body.request_secret : "";

    try {
      if (action === "request") {
        return await createRequest(requestId, requestSecret, dependencies);
      }
      if (action === "approve") {
        return await approveRequest(
          request,
          requestId,
          requestSecret,
          dependencies,
        );
      }
      if (action === "exchange") {
        return await exchangeRequest(requestId, requestSecret, dependencies);
      }
      if (action === "status") {
        return await statusRequest(requestId, requestSecret, dependencies);
      }
      if (action === "revoke") {
        return await revokeSession(request, dependencies);
      }
      return json({ error: "Unknown action" }, 400);
    } catch (error) {
      console.error("extension-connect internal error", error);
      return json({ error: "Internal error" }, 500);
    }
  };
};

async function createRequest(
  requestId: string,
  requestSecret: string,
  dependencies: Dependencies,
): Promise<Response> {
  if (!validRequestValues(requestId, requestSecret)) {
    return json({ error: "Invalid connection request" }, 400);
  }

  const now = dependencies.now();
  const response = await adminFetch(
    "/rest/v1/extension_connection_requests",
    dependencies,
    {
      method: "POST",
      headers: { prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({
        request_id: requestId,
        secret_hash: await hash(requestSecret),
        created_at: now.toISOString(),
        expires_at: new Date(now.getTime() + REQUEST_TTL_MS).toISOString(),
      }),
    },
  );
  if (!response.ok) return json({ error: "Could not create request" }, 502);
  return json({ status: "pending" }, 201);
}

async function approveRequest(
  request: Request,
  requestId: string,
  requestSecret: string,
  dependencies: Dependencies,
): Promise<Response> {
  const token = bearerToken(request.headers.get("authorization"));
  if (token === null) return json({ error: "Authentication required" }, 401);
  if (!validRequestValues(requestId, requestSecret)) {
    return json({ error: "Invalid connection request" }, 400);
  }

  const userId = await authenticateUser(token, dependencies);
  if (userId === null) return json({ error: "Invalid access token" }, 401);

  const connection = await findRequest(requestId, requestSecret, dependencies);
  if (connection === null || connection.used_at !== null) {
    return json({ error: "Connection request expired or unavailable" }, 410);
  }
  if (new Date(connection.expires_at).getTime() <= dependencies.now().getTime()) {
    return json({ error: "Connection request expired" }, 410);
  }

  const response = await adminFetch(
    `/rest/v1/extension_connection_requests?request_id=eq.${encodeURIComponent(requestId)}`,
    dependencies,
    {
      method: "PATCH",
      headers: { prefer: "return=minimal" },
      body: JSON.stringify({ user_id: userId, approved_at: dependencies.now().toISOString() }),
    },
  );
  if (!response.ok) return json({ error: "Could not approve request" }, 502);
  return json({ status: "approved" }, 200);
}

async function exchangeRequest(
  requestId: string,
  requestSecret: string,
  dependencies: Dependencies,
): Promise<Response> {
  if (!validRequestValues(requestId, requestSecret)) {
    return json({ error: "Invalid connection request" }, 400);
  }

  const connection = await findRequest(requestId, requestSecret, dependencies);
  if (connection === null || connection.user_id === null || connection.used_at !== null) {
    return json({ error: "Connection request is not approved" }, 409);
  }
  if (new Date(connection.expires_at).getTime() <= dependencies.now().getTime()) {
    return json({ error: "Connection request expired" }, 410);
  }

  const token = dependencies.createToken();
  const now = dependencies.now();
  const inserted = await adminFetch(
    "/rest/v1/extension_sessions",
    dependencies,
    {
      method: "POST",
      headers: { prefer: "return=minimal" },
      body: JSON.stringify({
        id: dependencies.createId(),
        user_id: connection.user_id,
        token_hash: await hash(token),
        created_at: now.toISOString(),
        expires_at: new Date(now.getTime() + SESSION_TTL_MS).toISOString(),
      }),
    },
  );
  if (!inserted.ok) return json({ error: "Could not create extension session" }, 502);

  const markedUsed = await adminFetch(
    `/rest/v1/extension_connection_requests?request_id=eq.${encodeURIComponent(requestId)}`,
    dependencies,
    {
      method: "PATCH",
      headers: { prefer: "return=minimal" },
      body: JSON.stringify({ used_at: now.toISOString() }),
    },
  );
  if (!markedUsed.ok) return json({ error: "Could not complete connection" }, 502);

  return json({ extensionToken: token, userId: connection.user_id }, 200);
}

async function revokeSession(
  request: Request,
  dependencies: Dependencies,
): Promise<Response> {
  const token = bearerToken(request.headers.get("authorization"));
  if (token === null || !token.startsWith("lb_ext_")) {
    return json({ error: "Extension authentication required" }, 401);
  }

  const response = await adminFetch(
    `/rest/v1/extension_sessions?token_hash=eq.${encodeURIComponent(await hash(token))}`,
    dependencies,
    {
      method: "PATCH",
      headers: { prefer: "return=minimal" },
      body: JSON.stringify({ revoked_at: dependencies.now().toISOString() }),
    },
  );
  if (!response.ok) return json({ error: "Could not revoke session" }, 502);
  return json({ status: "revoked" }, 200);
}

async function statusRequest(
  requestId: string,
  requestSecret: string,
  dependencies: Dependencies,
): Promise<Response> {
  if (!validRequestValues(requestId, requestSecret)) {
    return json({ error: "Invalid connection request" }, 400);
  }

  const connection = await findRequest(requestId, requestSecret, dependencies);
  if (connection === null) {
    return json({ error: "Connection request not found" }, 404);
  }
  if (connection.used_at !== null) return json({ status: "used" }, 200);
  if (connection.user_id !== null) return json({ status: "approved" }, 200);
  return json({ status: "pending" }, 200);
}

async function findRequest(
  requestId: string,
  requestSecret: string,
  dependencies: Dependencies,
): Promise<{
  user_id: string | null;
  expires_at: string;
  used_at: string | null;
} | null> {
  const response = await adminFetch(
    `/rest/v1/extension_connection_requests?select=user_id,expires_at,used_at,secret_hash&request_id=eq.${encodeURIComponent(requestId)}`,
    dependencies,
  );
  if (!response.ok) return null;
  const rows = await response.json();
  const row = Array.isArray(rows) ? rows[0] : null;
  if (row == null || row.secret_hash !== await hash(requestSecret)) return null;
  return row;
}

async function authenticateUser(
  token: string,
  dependencies: Dependencies,
): Promise<string | null> {
  const response = await dependencies.fetch(`${dependencies.supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: dependencies.anonKey,
      authorization: `Bearer ${token}`,
    },
  });
  if (!response.ok) return null;
  const user = await response.json();
  return typeof user?.id === "string" ? user.id : null;
}

async function adminFetch(
  path: string,
  dependencies: Dependencies,
  init: RequestInit = {},
): Promise<Response> {
  return dependencies.fetch(`${dependencies.supabaseUrl}${path}`, {
    ...init,
    headers: {
      apikey: dependencies.serviceRoleKey,
      authorization: `Bearer ${dependencies.serviceRoleKey}`,
      "content-type": "application/json",
      ...init.headers,
    },
  });
}

function validRequestValues(requestId: string, requestSecret: string): boolean {
  return /^[a-zA-Z0-9_-]{16,128}$/.test(requestId) && requestSecret.length >= 32;
}

function bearerToken(value: string | null): string | null {
  const match = value?.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

async function hash(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function json(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

if (import.meta.main) {
  Deno.serve(createConnectionHandler());
}
