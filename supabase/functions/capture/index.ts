const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (data: unknown, status: number): Response =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

type CaptureBody = {
  url?: unknown;
  text?: unknown;
  title?: unknown;
  selector?: unknown;
  source?: unknown;
};

type CaptureDependencies = {
  fetch: typeof fetch;
  supabaseUrl: string;
  anonKey: string;
  serviceRoleKey: string;
  createId: () => string;
  now: () => Date;
};

const defaultDependencies = (): CaptureDependencies => ({
  fetch,
  supabaseUrl: Deno.env.get("SUPABASE_URL") ?? "",
  anonKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  serviceRoleKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  createId: () => crypto.randomUUID(),
  now: () => new Date(),
});

export const createCaptureHandler = (
  overrides: Partial<CaptureDependencies> = {},
): ((request: Request) => Promise<Response>) => {
  const dependencies = { ...defaultDependencies(), ...overrides };

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { status: 204, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const token = bearerToken(request.headers.get("authorization"));
    if (token === null) return json({ error: "Authentication required" }, 401);

    let body: CaptureBody;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }

    const capture = validateCaptureBody(body);
    if (capture === null) {
      return json(
        { error: "Expected a URL or text, with an optional title and source" },
        400,
      );
    }

    const userId = await authenticate(token, dependencies);
    if (userId === null) return json({ error: "Invalid access token" }, 401);

    const itemId = dependencies.createId();
    const timestamp = dependencies.now().toISOString();
    const row = {
      id: itemId,
      user_id: userId,
      url: capture.url,
      title: capture.title,
      text_content: capture.text,
      text_selector: capture.selector === null
        ? null
        : JSON.stringify(capture.selector),
      type: capture.text !== null ? "note" : "link",
      favorite: false,
      status: "inbox",
      created_at: timestamp,
      updated_at: timestamp,
    };
    const databaseToken = token.startsWith("lb_ext_")
      ? dependencies.serviceRoleKey
      : token;
    const databaseKey = token.startsWith("lb_ext_")
      ? dependencies.serviceRoleKey
      : dependencies.anonKey;

    const insertResponse = await dependencies.fetch(
      `${dependencies.supabaseUrl}/rest/v1/items`,
      {
        method: "POST",
        headers: {
          apikey: databaseKey,
          authorization: `Bearer ${databaseToken}`,
          "content-type": "application/json",
          prefer: "return=representation",
        },
        body: JSON.stringify(row),
      },
    );

    if (!insertResponse.ok) {
      console.error("capture insert failed", insertResponse.status);
      return json({ error: "Could not save capture" }, 502);
    }

    return json(
      {
        id: itemId,
        status: "saved",
        source: capture.source,
      },
      201,
    );
  };
};

function bearerToken(value: string | null): string | null {
  if (value === null) return null;
  const match = value.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

async function authenticate(
  token: string,
  dependencies: CaptureDependencies,
): Promise<string | null> {
  if (token.startsWith("lb_ext_")) {
    return authenticateExtension(token, dependencies);
  }

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

async function authenticateExtension(
  token: string,
  dependencies: CaptureDependencies,
): Promise<string | null> {
  if (dependencies.serviceRoleKey.length === 0) return null;
  const tokenHash = await hash(token);
  const now = encodeURIComponent(dependencies.now().toISOString());
  const response = await dependencies.fetch(
    `${dependencies.supabaseUrl}/rest/v1/extension_sessions?select=user_id&token_hash=eq.${tokenHash}&revoked_at=is.null&expires_at=gt.${now}`,
    {
      headers: {
        apikey: dependencies.serviceRoleKey,
        authorization: `Bearer ${dependencies.serviceRoleKey}`,
      },
    },
  );
  if (!response.ok) return null;
  const rows = await response.json();
  const userId = Array.isArray(rows) && typeof rows[0]?.user_id === "string"
    ? rows[0].user_id
    : null;
  if (userId === null) return null;

  await dependencies.fetch(
    `${dependencies.supabaseUrl}/rest/v1/extension_sessions?token_hash=eq.${tokenHash}`,
    {
      method: "PATCH",
      headers: {
        apikey: dependencies.serviceRoleKey,
        authorization: `Bearer ${dependencies.serviceRoleKey}`,
        "content-type": "application/json",
        prefer: "return=minimal",
      },
      body: JSON.stringify({ last_used_at: dependencies.now().toISOString() }),
    },
  );
  return userId;
}

async function hash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function validateCaptureBody(body: CaptureBody): {
  url: string | null;
  text: string | null;
  title: string | null;
  selector: { before: string; after: string } | null;
  source: string;
} | null {
  const url = typeof body.url === "string" ? body.url.trim() : "";
  const text = typeof body.text === "string" ? body.text.trim() : "";
  const title = typeof body.title === "string" ? body.title.trim() : "";
  const source = typeof body.source === "string" ? body.source : "api";
  const selector = parseSelector(body.selector);

  if (url.length === 0 && text.length === 0) return null;
  if (url.length > 0 && !isHttpUrl(url)) return null;
  if (url.length > 2048 || text.length > 10000 || title.length > 500) return null;
  if (!CAPTURE_SOURCES.has(source)) return null;

  return {
    url: url.length > 0 ? url : null,
    text: text.length > 0 ? text : null,
    title: title.length > 0 ? title : null,
    selector,
    source,
  };
}

function parseSelector(
  value: unknown,
): { before: string; after: string } | null {
  if (typeof value !== "object" || value === null) return null;
  const raw = value as Record<string, unknown>;
  const before = typeof raw.before === "string" ? raw.before.trim().slice(0, 300) : "";
  const after = typeof raw.after === "string" ? raw.after.trim().slice(0, 300) : "";
  if (!before && !after) return null;
  return { before, after };
}

function isHttpUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

const CAPTURE_SOURCES = new Set([
  "manual",
  "androidShare",
  "iosShare",
  "browserExtension",
  "desktopQuickCapture",
  "api",
]);

if (import.meta.main) {
  Deno.serve(createCaptureHandler());
}
